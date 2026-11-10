import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/barber_shop.dart';
import '../../../shared/models/shop_service.dart';
import '../../authentication/auth_providers.dart';
import '../home/shop_providers.dart';
import '../../../core/theme/douri_colors.dart';

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
  // Direction of the last step change, for the direction-aware step
  // transition (forward slides in from the end side, back reverses).
  bool _forward = true;
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
    if (_step < 4) setState(() {
      _forward = true;
      _step++;
    });
  }

  /// Step 4 confirm: first asks the customer to confirm the phone
  /// number that booking notifications will go to. Confirming creates
  /// the PENDING booking; "edit number" jumps back to step 3.
  Future<void> _confirmAndSubmit(BarberShop shop) async {
    final confirmed = await showDouriSheet<bool>(
      context,
      _ConfirmBookingSheet(
        shopName: shop.shopName,
        serviceName: _service?.serviceName ?? '',
        date: _date,
        time: _timeSlot ?? '',
        phoneDigits: _phoneController.text.trim(),
      ),
    );
    if (confirmed == true) {
      await _submit();
    } else if (confirmed == false) {
      setState(() {
        _forward = false;
        _step = 3;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final service = _service;
    if (service == null || _timeSlot == null) return;
    final uid = ref.read(authStateProvider).value?.uid ?? 'test_customer';
    // The phone field holds digits only (+213 is a visual prefix).
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final phone = digits.startsWith('213') ? '+$digits' : '+213$digits';
    setState(() => _submitting = true);
    try {
      final created = await ref.read(bookingRepositoryProvider).createBooking({
        'customer_id': uid,
        'barber_shop_id': widget.shopId,
        'customer_name': _nameController.text.trim(),
        'customer_phone': phone,
        'booking_date': _dateIso,
        'booking_time': _timeSlot,
        'status': 'PENDING',
      });
      // Notify the barber in-app about the new request (best-effort: a
      // failed insert must never fail the booking itself).
      try {
        final shop = ref.read(shopByIdProvider(widget.shopId)).value;
        if (shop != null) {
          await SupabaseService.client.from('notifications').insert({
            'user_id': shop.ownerId,
            'title': 'طلب حجز جديد',
            'body':
                'طلب حجز جديد من ${_nameController.text.trim()} — $_dateIso ${_timeSlot ?? ''}',
            'notification_type': 'booking_request',
            'booking_id': created.id,
          });
        }
      } catch (_) {}
      if (mounted) context.pushReplacement('/booking-success/${created.id}');
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
              setState(() {
                _forward = false;
                _step--;
              });
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
                child: AnimatedSwitcher(
                  duration: DouriMotion.scaled(context, DouriDuration.normal),
                  switchInCurve: DouriCurves.standard,
                  switchOutCurve: DouriCurves.standard,
                  transitionBuilder: (child, animation) {
                    if (DouriMotion.reduced(context)) {
                      return FadeTransition(opacity: animation, child: child);
                    }
                    // Forward enters from the end side (right in LTR,
                    // left in RTL); back reverses.
                    final rtl =
                        Directionality.of(context) == TextDirection.rtl;
                    final dx = (_forward ? 0.12 : -0.12) * (rtl ? -1 : 1);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(dx, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: SingleChildScrollView(
                    key: ValueKey(_step),
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
                          onPressed: () => setState(() {
                            _forward = false;
                            _step--;
                          }),
                        ),
                      if (_step > 0) const SizedBox(width: DouriSpacing.md),
                      Expanded(
                        child: DouriButton(
                          label: _step == 4 ? l10n.confirmBooking : l10n.next,
                          loading: _submitting,
                          onPressed: _step == 4
                              ? () => _confirmAndSubmit(shop)
                              : () => _next(l10n),
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
                    key: ValueKey(services[i].id),
                    padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                    child: DouriStagger(
                      index: i,
                      // DouriServiceCard already owns press feedback
                      // (InkWell ripple) and tap semantics, plus the
                      // animated border + check selection — wrapping it
                      // in another pressable would fire the selection
                      // twice, so no DouriPressable here.
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
            DouriStagger(
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
                for (var i = 0; i < days.length; i++)
                  DouriStagger(
                    index: i + 1,
                    child: _DayPill(
                      label: materialL10n.formatMediumDate(days[i]),
                      selected: _isSameDay(days[i], date),
                      onTap: () => onDate(days[i]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DouriSpacing.lg),
            AnimatedSwitcher(
              duration: DouriMotion.scaled(context, DouriDuration.normal),
              child: Directionality(
                key: ValueKey(date.toIso8601String().substring(0, 10)),
                textDirection: TextDirection.ltr,
                child: Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
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
                      DouriStagger(
                        index: i,
                        child: Builder(
                          builder: (_) {
                            final slot = slots[i];
                            final parts = slot.split(':');
                            final slotMinutes =
                                int.parse(parts[0]) * 60 + int.parse(parts[1]);
                            final taken = booked.contains(slot) ||
                                (isToday && slotMinutes <= nowMinutes);
                            return _TimeSlotChip(
                              slot: slot,
                              selected: timeSlot == slot,
                              taken: taken,
                              onTap: () => onTimeSlot(slot),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                if (booked.isNotEmpty) ...[
                  SizedBox(height: DouriSpacing.lg),
                  Text(
                    l10n.timeSlotTaken,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.douriColors.textSecondary,
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
              DouriStagger(
                child: DouriTextField(
                  controller: nameController,
                  label: l10n.fullName,
                  prefixIcon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? l10n.required : null,
                ),
              ),
              const SizedBox(height: DouriSpacing.lg),
              DouriStagger(
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DouriStagger(
              child: DouriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bookingSummary, style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: DouriSpacing.lg),
                    _SummaryRow(label: l10n.shopName, value: shop.shopName),
                    _SummaryRow(label: l10n.service, value: service?.serviceName ?? '—'),
                    _SummaryRow(
                      label: l10n.date,
                      value: '${d.day}/${d.month}/${d.year}',
                      ltrValue: true,
                    ),
                    _SummaryRow(
                      label: l10n.time,
                      value: timeSlot ?? '—',
                      ltrValue: true,
                    ),
                    _SummaryRow(
                      label: l10n.duration,
                      value: service == null
                          ? '—'
                          : '${service!.durationMinutes} ${l10n.minutes}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.md),
            DouriStagger(
              index: 1,
              child: DouriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryRow(
                      label: l10n.totalPrice,
                      value: service?.price == null
                          ? '—'
                          : service!.price!.toStringAsFixed(0),
                      valueColor: AppColors.primaryAccent,
                      ltrValue: true,
                    ),
                    const SizedBox(height: DouriSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(DouriSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: DouriRadius.card,
                        border: Border.all(color: context.douriColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_top, color: AppColors.warning),
                          const SizedBox(width: DouriSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.pendingApproval,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppColors.warning,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.queueNumberAfterApproval,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: context.douriColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
    }
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.ltrValue = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool ltrValue;

  @override
  Widget build(BuildContext context) {
    final valueText = Text(
      value,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: valueColor,
          ),
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: DouriSpacing.sm),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.douriColors.textSecondary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: DouriSpacing.md),
          Expanded(
            child: ltrValue
                ? Directionality(
                    textDirection: TextDirection.ltr,
                    child: valueText,
                  )
                : valueText,
          ),
        ],
      ),
    );
  }
}

/// Animated day pill: selected = lime-soft fill + lime border + check
/// icon + bold lime label (border + icon + weight, never colour alone).
/// The check slot is always laid out and only its opacity animates, so
/// selecting a day never shifts the label or the row.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DouriPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DouriDuration.normal,
        curve: DouriCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: DouriSpacing.md,
          vertical: DouriSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : context.douriColors.card,
          borderRadius: BorderRadius.circular(DouriRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : context.douriColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: DouriDuration.fast,
              child: const Icon(Icons.check, size: 16, color: AppColors.primaryAccent),
            ),
            const SizedBox(width: DouriSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? AppColors.primaryAccent
                        : context.douriColors.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated time-slot chip. Selected = lime-soft fill + lime border +
/// check icon + bold lime time (border + icon + weight, never colour
/// alone). Taken or past slots are muted, struck through and untappable —
/// real availability from [_bookedTimesProvider] is never overridden.
class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({
    required this.slot,
    required this.selected,
    required this.taken,
    required this.onTap,
  });
  final String slot;
  final bool selected;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DouriPressable(
      onTap: taken ? null : onTap,
      child: AnimatedContainer(
        duration: DouriDuration.normal,
        curve: DouriCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: DouriSpacing.md,
          vertical: DouriSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentSoft
              : taken
                  ? context.douriColors.elevated
                  : context.douriColors.card,
          borderRadius: BorderRadius.circular(DouriRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primaryAccent : context.douriColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: DouriDuration.fast,
              child: const Icon(Icons.check, size: 16, color: AppColors.primaryAccent),
            ),
            const SizedBox(width: DouriSpacing.xs),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                slot,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: taken
                          ? context.douriColors.textMuted
                          : selected
                              ? AppColors.primaryAccent
                              : context.douriColors.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      decoration: taken ? TextDecoration.lineThrough : null,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stylize shop header strip for the booking flow: cover image (real URL
/// only) with the shop name overlaid, falling back to a lime icon panel.
/// The cover shares the `'shop-image-<id>'` Hero tag with the details
/// screen, so it flies in from the shop cover the user just saw; the
/// fallback has no image and therefore no Hero.
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
        color: context.douriColors.elevated,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Hero(
                tag: 'shop-image-${shop.id}',
                child: CachedNetworkImage(
                  imageUrl: shop.coverImageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
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
                      context.douriColors.background.withValues(alpha: 0.85),
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
/// The connector lines animate their colour, the circle content
/// cross-fades between number and check, and the label line cross-fades
/// on every step change.
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
                  color: i <= step ? AppColors.primaryAccent : context.douriColors.card,
                  border: Border.all(
                    color: i <= step ? AppColors.primaryAccent : context.douriColors.border,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: DouriDuration.fast,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: i < step
                      ? Icon(
                          Icons.check,
                          key: const ValueKey('done'),
                          size: 16,
                          color: context.douriColors.background,
                        )
                      : Text(
                          '${i + 1}',
                          key: const ValueKey('number'),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: i == step
                                    ? context.douriColors.background
                                    : context.douriColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                ),
              ),
              if (i < labels.length - 1)
                Expanded(
                  child: AnimatedContainer(
                    duration: DouriDuration.normal,
                    curve: DouriCurves.standard,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: i < step ? AppColors.primaryAccent : context.douriColors.border,
                  ),
                ),
            ],
          ],
        ),
        SizedBox(height: DouriSpacing.sm),
        AnimatedSwitcher(
          duration: DouriMotion.scaled(context, DouriDuration.normal),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: Text(
            '${step + 1} / ${labels.length} — ${labels[step]}',
            key: ValueKey(step),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.douriColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}

/// Phone-confirmation sheet shown before a booking is created:
/// "Is this the number booking notifications should go to?"
/// Confirm returns true, "edit number" returns false.
class _ConfirmBookingSheet extends StatelessWidget {
  const _ConfirmBookingSheet({
    required this.shopName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.phoneDigits,
  });

  final String shopName;
  final String serviceName;
  final DateTime date;
  final String time;
  final String phoneDigits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = '+213 ${phoneDigits.replaceAll(RegExp(r'\D'), '')}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DouriStagger(
          child: Text(l10n.confirmPhoneTitle, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: DouriSpacing.md),
        DouriStagger(
          index: 1,
          child: DouriCard(
            child: Row(
              children: [
                const Icon(Icons.phone_outlined, color: AppColors.primaryAccent),
                const SizedBox(width: DouriSpacing.md),
                Expanded(
                  child: Text(
                    phone,
                    style: Theme.of(context).textTheme.titleLarge,
                    textDirection: TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DouriSpacing.md),
        DouriStagger(
          index: 2,
          child: Text(
            l10n.confirmPhoneNote,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.douriColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(height: DouriSpacing.lg),
        DouriStagger(
          index: 3,
          child: DouriSectionHeader(title: l10n.bookingSummary),
        ),
        const SizedBox(height: DouriSpacing.md),
        DouriStagger(
          index: 4,
          child: Column(
            children: [
              _SummaryRow(label: l10n.shopName, value: shopName),
              _SummaryRow(label: l10n.service, value: serviceName),
              _SummaryRow(
                label: l10n.date,
                value: '${date.day}/${date.month}/${date.year}',
                ltrValue: true,
              ),
              _SummaryRow(label: l10n.time, value: time, ltrValue: true),
            ],
          ),
        ),
        const SizedBox(height: DouriSpacing.lg),
        DouriStagger(
          index: 5,
          child: DouriButton(
            label: l10n.confirmBooking,
            icon: Icons.check,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
        const SizedBox(height: DouriSpacing.sm),
        DouriStagger(
          index: 6,
          child: DouriButton(
            label: l10n.editPhone,
            variant: DouriButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
      ],
    );
  }
}
