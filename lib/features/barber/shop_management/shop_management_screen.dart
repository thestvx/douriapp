import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../shared/models/barber_shop.dart';
import '../../../shared/models/shop_service.dart';
import '../../authentication/auth_providers.dart';
import '../dashboard/shop_provider.dart';

/// Standalone route /barber/shop. Loads the shop itself via
/// [currentShopProvider]; the form creates the shop when none exists.
/// Images are URL text fields only — there is no Storage upload flow
/// in this codebase, so no upload is faked.
class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends ConsumerState<ShopManagementScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverController = TextEditingController();
  final _logoController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxBookingsController = TextEditingController();

  bool _isOpen = false;
  bool _saving = false;
  bool _uploadingLogo = false;
  bool _uploadingCover = false;
  String? _prefilledShopId;
  List<ShopService> _services = [];
  bool _servicesLoading = false;
  String? _servicesShopId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _coverController.dispose();
    _logoController.dispose();
    _durationController.dispose();
    _maxBookingsController.dispose();
    super.dispose();
  }

  void _prefill(BarberShop shop) {
    _nameController.text = shop.shopName;
    _descriptionController.text = shop.description ?? '';
    _addressController.text = shop.address ?? '';
    _phoneController.text = shop.phoneNumber ?? '';
    _coverController.text = shop.coverImageUrl ?? '';
    _logoController.text = shop.logoUrl ?? '';
    _durationController.text = '${shop.appointmentDuration}';
    _maxBookingsController.text = '${shop.maximumDailyBookings}';
    _isOpen = shop.isOpen;
    _prefilledShopId = shop.id;
  }

  Future<void> _loadServices(String shopId) async {
    setState(() {
      _servicesLoading = true;
      _servicesShopId = shopId;
    });
    try {
      final services = await ref.read(shopServiceRepositoryProvider).listAllServices(shopId);
      if (!mounted) return;
      setState(() {
        _services = services;
        _servicesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _servicesLoading = false);
    }
  }

  void _showFailed([Object? error]) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    var message = l10n.actionFailed;
    if (error != null) {
      final detail = error.toString();
      message = detail.length > 220 ? '${detail.substring(0, 220)}…' : detail;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Picks a photo from the gallery, uploads it to Cloudinary and puts
  /// the returned URL in the matching field. The URL is only saved to
  /// the shop when the user presses Save below.
  Future<void> _uploadShopImage({required bool isLogo}) async {
    final l10n = AppLocalizations.of(context);
    final picked = await pickGalleryImage();
    if (picked == null) return;
    setState(() {
      if (isLogo) {
        _uploadingLogo = true;
      } else {
        _uploadingCover = true;
      }
    });
    try {
      final url = await CloudinaryService.uploadImage(
        picked,
        folder: isLogo ? 'douri/logos' : 'douri/covers',
      );
      if (!mounted) return;
      setState(() {
        if (isLogo) {
          _logoController.text = url;
        } else {
          _coverController.text = url;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.uploadDone)),
      );
    } catch (e) {
      _showFailed(e);
    } finally {
      if (mounted) {
        setState(() {
          if (isLogo) {
            _uploadingLogo = false;
          } else {
            _uploadingCover = false;
          }
        });
      }
    }
  }

  Future<void> _save(BarberShop? shop, String? uid) async {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.required)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(barberShopRepositoryProvider).upsertShop({
        if (shop != null) 'id': shop.id,
        if (shop == null) 'owner_id': uid,
        'shop_name': _nameController.text.trim(),
        'description':
            _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'phone_number':
            _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'cover_image_url':
            _coverController.text.trim().isEmpty ? null : _coverController.text.trim(),
        'logo_url': _logoController.text.trim().isEmpty ? null : _logoController.text.trim(),
        'appointment_duration': int.tryParse(_durationController.text.trim()) ?? 30,
        'maximum_daily_bookings': int.tryParse(_maxBookingsController.text.trim()) ?? 30,
        'is_open': _isOpen,
      });
      ref.invalidate(currentShopProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saved)),
        );
      }
    } catch (_) {
      _showFailed();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddService(String shopId) async {
    final created = await showDouriSheet<bool>(
      context,
      _AddServiceSheet(shopId: shopId),
    );
    if (created == true) await _loadServices(shopId);
  }

  Future<void> _deleteService(ShopService service) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDouriConfirm(
      context,
      title: l10n.deleteService,
      message: l10n.confirmDeleteMsg,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await ref.read(shopServiceRepositoryProvider).deleteService(service.id);
      await _loadServices(service.barberShopId);
    } catch (_) {
      _showFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopAsync = ref.watch(currentShopProvider);
    final uid = ref.watch(authStateProvider).value?.uid;
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: DouriAppBar(title: l10n.shopManagement),
      body: shopAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(DouriSpacing.page),
          child: DouriSkeletonList(),
        ),
        error: (_, __) => DouriErrorState(
          message: l10n.actionFailed,
          onRetry: () => ref.invalidate(currentShopProvider),
        ),
        data: (shop) {
          if (shop == null && uid == null) {
            return DouriEmptyState(
              icon: Icons.store_outlined,
              title: l10n.noShopYet,
              message: l10n.noShopMessage,
            );
          }
          if (shop != null && _prefilledShopId != shop.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _prefilledShopId == shop.id) return;
              setState(() => _prefill(shop));
              _loadServices(shop.id);
            });
          }
          return _buildForm(context, shop, uid);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, BarberShop? shop, String? uid) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DouriSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DouriEntrance(
            index: 0,
            child: DouriTextField(controller: _nameController, label: l10n.shopName),
          ),
          const SizedBox(height: DouriSpacing.md),
          DouriEntrance(
            index: 1,
            child: DouriTextField(
              controller: _descriptionController,
              label: l10n.shopDescription,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: DouriSpacing.md),
          DouriEntrance(
            index: 2,
            child: DouriTextField(controller: _addressController, label: l10n.shopAddress),
          ),
          const SizedBox(height: DouriSpacing.md),
          DouriEntrance(
            index: 3,
            child: DouriTextField(
              controller: _phoneController,
              label: l10n.shopPhone,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: DouriSpacing.md),
          DouriEntrance(
            index: 4,
            child: _buildImageUpload(
              controller: _coverController,
              label: l10n.coverImageUrl,
              uploadLabel: l10n.uploadCover,
              uploading: _uploadingCover,
              isLogo: false,
            ),
          ),
          const SizedBox(height: DouriSpacing.md),
          DouriEntrance(
            index: 5,
            child: _buildImageUpload(
              controller: _logoController,
              label: l10n.logoImageUrl,
              uploadLabel: l10n.uploadLogo,
              uploading: _uploadingLogo,
              isLogo: true,
            ),
          ),
          const SizedBox(height: DouriSpacing.md),
          Row(
            children: [
              Expanded(
                child: DouriTextField(
                  controller: _durationController,
                  label: l10n.appointmentDuration,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: DouriSpacing.md),
              Expanded(
                child: DouriTextField(
                  controller: _maxBookingsController,
                  label: l10n.maxDailyBookings,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: DouriSpacing.md),
          DouriCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isOpen ? l10n.shopOpen : l10n.shopClosed,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: _isOpen,
                  onChanged: (v) => setState(() => _isOpen = v),
                  activeColor: AppColors.primaryAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: DouriSpacing.xl),
          DouriButton(
            label: l10n.saveChanges,
            icon: Icons.save_outlined,
            onPressed: _saving ? null : () => _save(shop, uid),
            loading: _saving,
          ),
          if (shop != null) ...[
            const SizedBox(height: DouriSpacing.xxl),
            DouriSectionHeader(
              title: l10n.servicesManagement,
              actionLabel: l10n.addService,
              onAction: () => _showAddService(shop.id),
            ),
            const SizedBox(height: DouriSpacing.md),
            _buildServices(shop.id),
          ],
        ],
      ),
    );
  }

  /// Cover/logo section: live preview + URL field + gallery upload
  /// button (Cloudinary). The preview follows the field's text.
  Widget _buildImageUpload({
    required TextEditingController controller,
    required String label,
    required String uploadLabel,
    required bool uploading,
    required bool isLogo,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final url = value.text.trim();
        final hasImage = url.startsWith('http');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(DouriRadius.md),
                child: isLogo
                    ? Image.network(
                        url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      )
                    : Image.network(
                        url,
                        width: double.infinity,
                        height: 140,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
              ),
              const SizedBox(height: DouriSpacing.sm),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DouriTextField(
                    controller: controller,
                    label: label,
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: DouriSpacing.sm),
                DouriButton(
                  label: uploadLabel,
                  icon: Icons.upload_outlined,
                  expanded: false,
                  loading: uploading,
                  onPressed: uploading
                      ? null
                      : () => _uploadShopImage(isLogo: isLogo),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildServices(String shopId) {
    final l10n = AppLocalizations.of(context);
    if (_servicesShopId == null || _servicesLoading) {
      return const DouriSkeletonList(itemCount: 2);
    }
    if (_services.isEmpty) {
      return DouriEmptyState(
        icon: Icons.content_cut,
        title: l10n.noServices,
        message: l10n.noServicesMessage,
        actionLabel: l10n.addService,
        onAction: () => _showAddService(shopId),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < _services.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DouriSpacing.md),
            child: DouriEntrance(
              index: i,
              child: _ServiceRow(
                service: _services[i],
                onDelete: () => _deleteService(_services[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.service, required this.onDelete});

  final ShopService service;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = <String>['${service.durationMinutes} ${l10n.min}'];
    if (service.price != null) details.add(service.price!.toStringAsFixed(0));
    return DouriCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  details.join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
          DouriIconButton(
            icon: Icons.delete_outline,
            onPressed: onDelete,
            tooltip: l10n.deleteService,
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet form for adding a service (name, price, duration).
class _AddServiceSheet extends ConsumerStatefulWidget {
  const _AddServiceSheet({required this.shopId});

  final String shopId;

  @override
  ConsumerState<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends ConsumerState<_AddServiceSheet> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.required)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(shopServiceRepositoryProvider).addService(
            ShopService(
              id: '',
              barberShopId: widget.shopId,
              serviceName: _nameController.text.trim(),
              durationMinutes: int.tryParse(_durationController.text.trim()) ?? 30,
              price: double.tryParse(_priceController.text.trim()),
              isActive: true,
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.actionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.addService, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DouriSpacing.md),
        DouriTextField(controller: _nameController, label: l10n.serviceName),
        const SizedBox(height: DouriSpacing.md),
        Row(
          children: [
            Expanded(
              child: DouriTextField(
                controller: _priceController,
                label: l10n.servicePrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: DouriSpacing.md),
            Expanded(
              child: DouriTextField(
                controller: _durationController,
                label: l10n.serviceDuration,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: DouriSpacing.lg),
        DouriButton(
          label: l10n.addService,
          onPressed: _saving ? null : _submit,
          loading: _saving,
        ),
        const SizedBox(height: DouriSpacing.sm),
        DouriButton(
          label: l10n.cancel,
          variant: DouriButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
