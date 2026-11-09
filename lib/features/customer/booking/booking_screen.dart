import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../shared/models/barber_shop.dart';
import '../../../shared/models/shop_service.dart';
import '../../authentication/auth_providers.dart';
import '../home/shop_providers.dart';

/// Times already booked for a shop on one date (real availability).
final _bookedTimesProvider =
    FutureProvider.family<List<String>, ({String shopId, String dateIso})>(
        (ref, arg) async {
  return ref.read(bookingRepositoryProvider).bookedTimes(arg.shopId, arg.dateIso);
});

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _step = 0;
  ShopService? _service;
  DateTime _date = DateTime.now();
  String? _timeSlot;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _prefilled = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _dateIso => _date.toIso8601String().substring(0, 10);

  List<String> _slots(int durationMinutes) {
    final slots = <String>[];
    var minutes = 9 * 60;
    while (minutes <= 20 * 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      slots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      minutes += durationMinutes;
    }
    return slots;
  }

  bool _canContinue(AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _service != null;
      case 1:
        return true;
      case 2:
        return _timeSlot != null;
      case 3:
        return _formKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _next(AppLocalizations l10n) {
    if (!_canContinue(l10n)) {
      if (_step == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chooseServiceFirst)),
        );
      }
      return;
    }
    if (_step < 4) setState(() => _step++);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final service = _service;
    if (service == null || _timeSlot == null) return;
    final uid = ref.read(authStateProvider).value?.uid ?? 'test_customer';
    setState(() => _submitting = true);
    try {
      final created = await ref.read(bookingRepositoryProvider).createBooking({
        'customer_id': uid,
        'barber_shop_id': widget.shopId,
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        'booking_date': _dateIso,
        'booking_time': _timeSlot,
        'status': 'PENDING',
      });
      if (mounted) context.go('/booking-success/${created.id}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.actionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shopAsync = ref.watch(shopByIdProvider(widget.shopId));
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    if (profile != null && !_prefilled) {
      _prefilled = true;
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phoneNumber ?? '';
    }

    final stepLabels = [
      l10n.selectService,
      l10n.selectDate,
      l10n.selectTime,
      l10n.contactInfo,
      l10n.reviewBooking,
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(l10n.bookingTitle),
      ),
      body: shopAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryAccent),
        ),
        error: (e, _) => DouriErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(shopByIdProvider(widget.shopId)),
        ),
        data: (shop) {
          if (shop == null) {
            return DouriEmptyState(
              icon: Icons.store_outlined,
              title: l10n.noShops,
              message: l10n.noShopsMessage,
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DouriSpacing.page,
                  DouriSpacing.sm,
                  DouriSpacing.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stylize shop header strip: cover + name.
                    _ShopHeader(shop: shop),
                    const SizedBox(height: DouriSpacing.lg),
                    // Stylize step indicator: numbered circles + labels.
                    _StepIndicator(step: _step, labels: stepLabels),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(DouriSpacing.page),
                  child: _StepBody(
                    step: _step,
                    shop: shop,
                    service: _service,
                    onService: (s) => setState(() => _service = s),
                    date: _date,
                    onDate: (d) => setState(() {
                      _date = d;
                      _timeSlot = null;
                    }),
                    timeSlot: _timeSlot,
                    onTimeSlot: (t) => setState(() => _timeSlot = t),
                    slots: _slots(shop.appointmentDuration),
                    formKey: _formKey,
                    nameController: _nameController,
                    phoneController: _phoneController,
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DouriSpacing.page,
                    DouriSpacing.sm,
                    DouriSpacing.page,
                    DouriSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      if (_step > 0)
                        DouriButton(
                          label: l10n.back,
                          variant: DouriButtonVariant.secondary,
                          expanded: false,
                          onPressed: () => setState(() => _step--),
                        ),
                      if (_step > 0) const SizedBox(width: DouriSpacing.md),
                      Expanded(
                        child: DouriButton(
                          label: _step == 4 ? l10n.confirmBooking : l10n.next,
                          loading: _submitting,
                          onPressed: _step == 4 ? _submit : () => _next(l10n),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StepBody extends ConsumerWidget {
  const _StepBody({
    required this.step,
    required this.shop,
    required this.service,
    required this.onService,
    required this.date,
    required this.onDate,
    required this.timeSlot,
    required this.onTimeSlot,
    required this.slots,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
  });

  final int step;
  final BarberShop shop;
  final ShopService? service;
  final ValueChanged<ShopService> onService;
  final DateTime date;
  final ValueChanged<DateTime> onDate;
  final String? timeSlot;
  final ValueChanged<String> onTimeSlot;
  final List<String> slots;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    switch (step) {
      case 0:
        final servicesAsync = ref.watch(shopServicesProvider(shop.id));
        return servicesAsync.when(
          loading: () => const DouriSkeletonList(),
          error: (e, _) => DouriErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(shopServicesProvider(shop.id)),
          ),
          data: (services) {
            if (services.isEmpty) {
              return DouriEmptyState(
                icon: Icons.content_cut,
                title: l10n.noServices,
                message: l10n.noServicesMessage,
              );
            }
            return Column(
              children: [
                for (var i = 0; i < services.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                    child: DouriEntrance(
                      index: i,
                      child: DouriServiceCard(
                        name: services[i].serviceName,
                        description: services[i].description,
                        durationMinutes: services[i].durationMinutes,
                        priceLabel: services[i].price == null
                            ? null
                            : services[i].price!.toStringAsFixed(0),
                        selected: service?.id == services[i].id,
                        onTap: () => onService(services[i]),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      case 1:
        final days = List.generate(7, (i) {
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day + i);
        });
        final materialL10n = MaterialLocalizations.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DouriEntrance(
              child: DouriButton(
                label: l10n.selectDate,
                icon: Icons.calendar_today_outlined,
                variant: DouriButtonVariant.secondary,
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) onDate(picked);
                },
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
            Wrap(
              spacing: DouriSpacing.sm,
              runSpacing: DouriSpacing.sm,
              children: [
                for (final d in days)
                  DouriEntrance(
                    index: days.indexOf(d),
                    child: ChoiceChip(
                      label: Text(materialL10n.formatMediumDate(d)),
                      selected: _isSameDay(d, date),
                      selectedColor: AppColors.accentSoft,
                      checkmarkColor: AppColors.primaryAccent,
                      onSelected: (_) => onDate(d),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DouriSpacing.lg),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        );
      case 2:
        final bookedAsync = ref.watch(
          _bookedTimesProvider((shopId: shop.id, dateIso: date.toIso8601String().substring(0, 10))),
        );
        return bookedAsync.when(
          loading: () => const DouriSkeletonList(),
          error: (e, _) => DouriErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(
              _bookedTimesProvider(
                (shopId: shop.id, dateIso: date.toIso8601String().substring(0, 10)),
              ),
            ),
          ),
          data: (booked) {
            final now = DateTime.now();
            final isToday = _isSameDay(date, now);
            final nowMinutes = now.hour * 60 + now.minute;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: DouriSpacing.sm,
                  runSpacing: DouriSpacing.sm,
                  children: [
                    for (var i = 0; i < slots.length; i++)
                      Builder(
                        builder: (_) {
                          final slot = slots[i];
                          final parts = slot.split(':');
                          final slotMinutes =
                              int.parse(parts[0]) * 60 + int.parse(parts[1]);
                          final taken = booked.contains(slot) ||
                              (isToday && slotMinutes <= nowMinutes);
                          return DouriEntrance(
                            index: i,
                            child: ChoiceChip(
                              label: Text(slot),
                              selected: timeSlot == slot,
                              selectedColor: AppColors.accentSoft,
                              checkmarkColor: AppColors.primaryAccent,
                              onSelected: taken ? null : (_) => onTimeSlot(slot),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                if (booked.isNotEmpty) ...[
                  const SizedBox(height: DouriSpacing.lg),
                  Text(
                    l10n.timeSlotTaken,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                  ),
                ],
              ],
            );
          },
        );
      case 3:
        return Form(
          key: formKey,
          child: Column(
            children: [
              DouriEntrance(
                child: DouriTextField(
                  controller: nameController,
                  label: l10n.fullName,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
              ),
              const SizedBox(height: DouriSpacing.lg),
              DouriEntrance(
                index: 1,
                child: DouriPhoneField(
                  controller: phoneController,
                  hint: l10n.phoneHint,
                ),
              ),
            ],
          ),
        );
      default:
        final d = date;
        return DouriEntrance(
          child: DouriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.bookingSummary, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: DouriSpacing.lg),
                _SummaryRow(label: l10n.shopName, value: shop.shopName),
                _SummaryRow(label: l10n.service, value: service?.serviceName ?? '—'),
                _SummaryRow(label: l10n.date, value: '${d.day}/${d.month}/${d.year}'),
                _SummaryRow(label: l10n.time, value: timeSlot ?? '—'),
                _SummaryRow(
                  label: l10n.duration,
                  value: service == null
                      ? '—'
                      : '${service!.durationMinutes} ${l10n.minutes}',
                ),
                const Divider(color: AppColors.border, height: 32),
                _SummaryRow(
                  label: l10n.totalPrice,
                  value: service?.price == null
                      ? '—'
                      : service!.price!.toStringAsFixed(0),
                ),
                const SizedBox(height: DouriSpacing.md),
                Text(
                  l10n.pendingApproval,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                ),
              ],
            ),
          ),
        );
    }
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DouriSpacing.sm),
      child: Row(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondaryText,
              )),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Stylize shop header strip for the booking flow: cover image (real URL
/// only) with the shop name overlaid, falling back to a lime icon panel.
class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});
  final BarberShop shop;

  @override
  Widget build(BuildContext context) {
    final hasImage = shop.coverImageUrl != null && shop.coverImageUrl!.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DouriRadius.xl),
      child: Container(
        height: 110,
        width: double.infinity,
        color: AppColors.elevatedSurface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              CachedNetworkImage(
                imageUrl: shop.coverImageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              )
            else
              const Center(
                child: Icon(Icons.content_cut, size: 44, color: AppColors.primaryAccent),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primaryBackground.withValues(alpha: 0.85),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: DouriSpacing.lg,
              right: DouriSpacing.lg,
              bottom: DouriSpacing.md,
              child: Text(
                shop.shopName,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Numbered step indicator (Stylize style): lime for the current/completed
/// steps, muted outline for upcoming ones, with the current step label.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              AnimatedContainer(
                duration: DouriDuration.normal,
                curve: DouriCurves.standard,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= step ? AppColors.primaryAccent : AppColors.cardBackground,
                  border: Border.all(
                    color: i <= step ? AppColors.primaryAccent : AppColors.border,
                  ),
                ),
                child: i < step
                    ? const Icon(Icons.check, size: 16, color: AppColors.primaryBackground)
                    : Text(
                        '${i + 1}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: i == step
                                  ? AppColors.primaryBackground
                                  : AppColors.mutedText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: i < step ? AppColors.primaryAccent : AppColors.border,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: DouriSpacing.sm),
        Text(
          '${step + 1} / ${labels.length} — ${labels[step]}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
              ),
        ),
      ],
    );
  }
}
