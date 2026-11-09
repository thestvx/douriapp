import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_fields.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/booking.dart';
import '../../../core/theme/douri_colors.dart';

class BookingRequestsScreen extends ConsumerStatefulWidget {
  const BookingRequestsScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends ConsumerState<BookingRequestsScreen>
    with SingleTickerProviderStateMixin {
  late final Stream<List<Booking>> _stream;
  late final TabController _tabController;
  List<Booking> _bookings = [];
  bool _loading = true;
  bool _loadFailed = false;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _stream = ref.read(bookingRepositoryProvider).watchShopBookings(widget.shopId);
    // Held in state (not a DefaultTabController inside the StreamBuilder)
    // so realtime stream emissions never reset the selected tab.
    _tabController = TabController(length: 6, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    final local = d.toLocal();
    return local.year == now.year && local.month == now.month && local.day == now.day;
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(bookingRepositoryProvider).getShopBookings(widget.shopId);
      if (!mounted) return;
      setState(() {
        _bookings = data;
        _loading = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _refresh() => _load();

  void _showFailed() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).actionFailed)),
    );
  }

  Future<void> _approve(Booking booking) async {
    setState(() => _busyId = booking.id);
    try {
      await SupabaseService.client.rpc('approve_booking', params: {'p_booking_id': booking.id});
      await _load();
    } catch (_) {
      _showFailed();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _showRejectSheet(Booking booking) async {
    final reason = await showDouriSheet<String>(context, const _RejectReasonSheet());
    if (reason == null) return;
    setState(() => _busyId = booking.id);
    try {
      await SupabaseService.client.rpc('reject_booking', params: {
        'p_booking_id': booking.id,
        'p_reason': reason.isEmpty ? null : reason,
      });
      await _load();
    } catch (_) {
      _showFailed();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: context.douriColors.background,
      child: StreamBuilder<List<Booking>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return DouriErrorState(message: l10n.actionFailed, onRetry: _load);
          }
          final bookings = snapshot.data ?? _bookings;
          if (_loading && !snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(DouriSpacing.page),
              child: DouriSkeletonList(),
            );
          }
          if (_loadFailed && !snapshot.hasData) {
            return DouriErrorState(message: l10n.actionFailed, onRetry: _load);
          }
          return Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primaryAccent,
                unselectedLabelColor: context.douriColors.textSecondary,
                indicatorColor: AppColors.primaryAccent,
                tabs: [
                  Tab(text: l10n.pending),
                  Tab(text: l10n.confirmed),
                  Tab(text: l10n.today),
                  Tab(text: l10n.completed),
                  Tab(text: l10n.rejected),
                  Tab(text: l10n.cancelled),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTab(bookings.where((b) => b.status == 'PENDING').toList(), isPendingTab: true),
                    _buildTab(bookings.where((b) => b.status == 'CONFIRMED').toList()),
                    _buildTab(bookings.where((b) => _isToday(b.bookingDate)).toList()),
                    _buildTab(bookings.where((b) => b.status == 'COMPLETED').toList()),
                    _buildTab(bookings.where((b) => b.status == 'REJECTED').toList()),
                    _buildTab(bookings.where((b) => b.status == 'CANCELLED').toList()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(List<Booking> bookings, {bool isPendingTab = false}) {
    final l10n = AppLocalizations.of(context);
    if (bookings.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryAccent,
        backgroundColor: context.douriColors.elevated,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            DouriSpacing.page,
            DouriSpacing.page,
            DouriSpacing.page,
            116,
          ),
          children: [
            const SizedBox(height: 80),
            DouriEmptyState(
              icon: Icons.inbox_outlined,
              // The pending tab gets its own empty state: it is the
              // barber's inbox, so "nothing waiting for your reply" is
              // the meaningful message. Other tabs keep the generic one.
              title: isPendingTab ? l10n.noPendingRequests : l10n.noRequests,
              message: isPendingTab
                  ? l10n.noPendingRequestsMessage
                  : l10n.noRequestsMessage,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryAccent,
      backgroundColor: context.douriColors.elevated,
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DouriSpacing.page,
          DouriSpacing.page,
          DouriSpacing.page,
          116,
        ),
        itemCount: bookings.length,
        itemBuilder: (context, i) {
          final booking = bookings[i];
          final meta = _bookingStatus(booking.status, l10n);
          return Padding(
            key: ValueKey(booking.id),
            padding: const EdgeInsets.only(bottom: DouriSpacing.md),
            child: DouriStagger(
              index: i,
              child: AnimatedSwitcher(
                duration: DouriDuration.normal,
                // Keyed by id + status so a status change (approve /
                // reject) cross-fades the card in place instead of
                // snapping. True exit animation on removal would need an
                // AnimatedList; the stream-driven ListView.builder is
                // kept, so a removed card disappears with the next
                // stream emission — the AnimatedSwitcher covers the
                // status-change feedback.
                child: DouriBookingCard(
                  key: ValueKey('${booking.id}_${booking.status}'),
                  title: booking.customerName,
                  // customerPhone is a required String that can be
                  // empty; never show a blank subtitle.
                  subtitle: booking.customerPhone.isNotEmpty
                      ? booking.customerPhone
                      : '—',
                  statusLabel: meta.$1,
                  statusColor: meta.$2,
                  queueNumber: booking.queueNumber,
                  dateLabel:
                      '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                  timeLabel: booking.bookingTime,
                  actions: booking.status == 'PENDING'
                      ? [
                          Expanded(
                            child: DouriButton(
                              label: l10n.approve,
                              icon: Icons.check_rounded,
                              onPressed: _busyId == null ? () => _approve(booking) : null,
                              loading: _busyId == booking.id,
                            ),
                          ),
                          const SizedBox(width: DouriSpacing.sm),
                          Expanded(
                            child: DouriButton(
                              label: l10n.reject,
                              variant: DouriButtonVariant.danger,
                              onPressed: _busyId == null ? () => _showRejectSheet(booking) : null,
                              loading: _busyId == booking.id,
                            ),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  (String, Color) _bookingStatus(String status, AppLocalizations l10n) => switch (status) {
        'PENDING' => (l10n.bookingPending, AppColors.warning),
        'CONFIRMED' => (l10n.bookingConfirmed, AppColors.success),
        'COMPLETED' => (l10n.bookingCompleted, AppColors.success),
        'REJECTED' => (l10n.bookingRejected, AppColors.danger),
        'CANCELLED' => (l10n.bookingCancelled, context.douriColors.textMuted),
        _ => (status, context.douriColors.textSecondary),
      };
}

/// Bottom-sheet content for the optional rejection reason.
class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet();

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.rejectionReason, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: DouriSpacing.md),
        DouriTextField(
          controller: _reasonController,
          label: l10n.rejectionReason,
          hint: l10n.reasonOptional,
          maxLines: 3,
        ),
        const SizedBox(height: DouriSpacing.lg),
        DouriButton(
          label: l10n.reject,
          variant: DouriButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(_reasonController.text.trim()),
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
