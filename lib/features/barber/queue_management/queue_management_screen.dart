import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/repository_providers.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/douri_button.dart';
import '../../../core/widgets/douri_cards.dart';
import '../../../core/widgets/douri_chrome.dart';
import '../../../core/widgets/douri_feedback.dart';
import '../../../core/widgets/douri_motion.dart';
import '../../../shared/models/queue_entry.dart';
import '../../../core/theme/douri_colors.dart';

class QueueManagementScreen extends ConsumerStatefulWidget {
  const QueueManagementScreen({super.key, required this.shopId});
  final String shopId;

  @override
  ConsumerState<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends ConsumerState<QueueManagementScreen> {
  Map<String, dynamic>? _queue;
  bool _queueLoading = true;
  int _streamVersion = 0;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  String _todayIso() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _loadQueue() async {
    try {
      final queue = await ref.read(queueRepositoryProvider).getTodayQueue(widget.shopId);
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _queueLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _queueLoading = false);
    }
  }

  void _refreshStream() => setState(() => _streamVersion++);

  /// Shows the real error instead of a generic message, so a failed
  /// queue action can actually be diagnosed (PostgREST error text is
  /// truncated to keep the snackbar readable).
  void _showFailed([Object? error]) {
    if (!mounted) return;
    var message = AppLocalizations.of(context).actionFailed;
    if (error != null) {
      final detail = error.toString();
      message = detail.length > 220 ? '${detail.substring(0, 220)}…' : detail;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startDay() async {
    setState(() => _busyAction = 'start');
    try {
      await ref.read(queueRepositoryProvider).startTodayQueue(widget.shopId);
      await _loadQueue();
      _refreshStream();
    } catch (e) {
      _showFailed(e);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  /// Completes the CURRENT entry and calls the next WAITING one.
  Future<void> _advance({required bool confirmComplete}) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDouriConfirm(
      context,
      title: confirmComplete ? l10n.confirmComplete : l10n.confirmCallNext,
      message: confirmComplete ? l10n.confirmCompleteMsg : l10n.confirmCallNextMsg,
      confirmLabel: confirmComplete ? l10n.markCompleted : l10n.callNext,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed) return;
    setState(() => _busyAction = 'advance');
    try {
      await SupabaseService.client.rpc('advance_queue', params: {
        'p_shop_id': widget.shopId,
        'p_date': _todayIso(),
      });
      await _loadQueue();
      _refreshStream();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.queueAdvanced)),
        );
      }
    } catch (e) {
      _showFailed(e);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  /// Best-effort client-side skip. There is no update policy for
  /// `queue_entries`, so this is expected to fail under RLS — the
  /// failure is surfaced, never silently pretended to work.
  Future<void> _skip(QueueEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDouriConfirm(
      context,
      title: l10n.confirmSkip,
      message: l10n.confirmSkipMsg,
      confirmLabel: l10n.skip,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _busyAction = 'skip');
    try {
      await SupabaseService.client
          .from('queue_entries')
          .update({'status': 'SKIPPED'})
          .eq('id', entry.id);
      await _loadQueue();
      _refreshStream();
    } catch (e) {
      _showFailed(e);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _endDay() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDouriConfirm(
      context,
      title: l10n.endDay,
      message: l10n.queueEnded,
      confirmLabel: l10n.endDay,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _busyAction = 'end');
    try {
      await ref.read(queueRepositoryProvider).endTodayQueue(widget.shopId);
      await _loadQueue();
      _refreshStream();
    } catch (e) {
      _showFailed(e);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _refresh() async {
    await _loadQueue();
    _refreshStream();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_queueLoading) {
      return Container(
        color: context.douriColors.background,
        padding: const EdgeInsets.all(DouriSpacing.page),
        child: const DouriSkeletonList(),
      );
    }
    final queueActive = _queue != null && _queue!['queue_status'] == 'ACTIVE';
    return Container(
      color: context.douriColors.background,
      child: StreamBuilder<List<QueueEntry>>(
        // Re-subscribe after start/end/advance: the stream resolves the
        // daily queue id once, so a queue created after the first
        // subscription needs a fresh subscription to appear.
        key: ValueKey(_streamVersion),
        stream: ref.read(queueRepositoryProvider).watchTodayEntries(widget.shopId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return DouriErrorState(
              message: snapshot.error?.toString() ?? l10n.actionFailed,
              onRetry: () => setState(() => _streamVersion++),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(DouriSpacing.page),
              child: DouriSkeletonList(),
            );
          }
          final entries = snapshot.data ?? const <QueueEntry>[];
          if (!queueActive && entries.isEmpty) {
            return DouriEmptyState(
              icon: Icons.people_outline,
              title: l10n.noQueueToday,
              message: l10n.noQueueTodayMessage,
              actionLabel: l10n.startDay,
              onAction: _busyAction == null ? _startDay : null,
            );
          }
          if (queueActive && entries.isEmpty) {
            // Day started, nobody in the queue yet — distinct from
            // "no queue today" (day not started).
            return DouriEmptyState(
              icon: Icons.hourglass_empty,
              title: l10n.queueEmpty,
              message: l10n.queueEmptyMessage,
            );
          }
          return _buildQueue(context, entries, queueActive);
        },
      ),
    );
  }

  Widget _buildQueue(BuildContext context, List<QueueEntry> entries, bool queueActive) {
    final l10n = AppLocalizations.of(context);
    QueueEntry? current;
    for (final e in entries) {
      if (e.isCurrent) {
        current = e;
        break;
      }
    }
    QueueEntry? next;
    for (final e in entries) {
      if (e.isWaiting || e.isApproaching) {
        next = e;
        break;
      }
    }
    final waiting = entries.where((e) => e.isWaiting || e.isApproaching).toList();
    final done = entries.where((e) => e.isCompleted).length;
    final total = entries.length;
    final busy = _busyAction != null;

    return RefreshIndicator(
      color: AppColors.primaryAccent,
      backgroundColor: context.douriColors.elevated,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Bottom inset clears the floating bottom nav (dashboard: 116dp).
        padding: const EdgeInsets.fromLTRB(
          DouriSpacing.page,
          DouriSpacing.page,
          DouriSpacing.page,
          116,
        ),
        children: [
          if (!queueActive) ...[
            DouriStagger(
              index: 0,
              child: DouriCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.douriColors.elevated,
                        borderRadius: BorderRadius.circular(DouriRadius.md),
                      ),
                      child: Icon(
                        Icons.flag_outlined,
                        size: 22,
                        color: context.douriColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: DouriSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.queueDayEnded,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.queueDayEndedMessage,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: context.douriColors.textSecondary,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
          ],
          if (current != null) ...[
            DouriStagger(
              index: 1,
              child: DouriCard(
                child: Column(
                  children: [
                    Text(
                      l10n.nowServing,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: context.douriColors.textSecondary),
                    ),
                    const SizedBox(height: DouriSpacing.sm),
                    // Theme-aware queue number (deep lime on light theme).
                    DouriAnimatedCounter(
                      value: current.queueNumber,
                      format: (v) => v.toString().padLeft(2, '0'),
                      style: DouriTextStyles.queueNumber(context),
                    ),
                    Text(
                      current.customerName ?? '',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (current.bookingTime != null &&
                        current.bookingTime!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          current.bookingTime!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                    const SizedBox(height: DouriSpacing.sm),
                    _statusBadge(context, current.status, l10n),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
          ],
          if (next != null) ...[
            DouriStagger(
              index: 2,
              child: DouriSectionHeader(title: l10n.nextCustomer),
            ),
            if (current == null) ...[
              const SizedBox(height: 2),
              DouriStagger(
                index: 2,
                child: Text(
                  l10n.queueNoCurrent,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.douriColors.textSecondary,
                      ),
                ),
              ),
            ],
            const SizedBox(height: DouriSpacing.sm),
            DouriStagger(
              index: 2,
              child: _queueRow(context, next, isCurrent: false),
            ),
            const SizedBox(height: DouriSpacing.lg),
          ],
          if (total > 0) ...[
            DouriStagger(
              index: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.queueProgress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.douriColors.textSecondary,
                              ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '$done / $total ${l10n.completed}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.douriColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DouriSpacing.sm),
                  DouriProgress(value: total == 0 ? 0 : done / total),
                ],
              ),
            ),
            const SizedBox(height: DouriSpacing.lg),
          ],
          if (waiting.isNotEmpty) ...[
            DouriStagger(
              index: 3,
              child: DouriSectionHeader(
                title: '${l10n.waitingCustomers} (${waiting.length})',
              ),
            ),
            const SizedBox(height: DouriSpacing.sm),
            for (var i = 0; i < waiting.length; i++)
              Padding(
                // Key on the list-level child so Realtime inserts/removals
                // reuse the existing row element in place.
                key: ValueKey(waiting[i].id),
                padding: const EdgeInsets.only(bottom: DouriSpacing.md),
                child: DouriStagger(
                  index: 4 + i,
                  child: _queueRow(context, waiting[i], isCurrent: false),
                ),
              ),
            const SizedBox(height: DouriSpacing.sm),
          ],
          const SizedBox(height: DouriSpacing.md),
          if (queueActive) ...[
            if (current != null || waiting.isNotEmpty) ...[
              DouriButton(
                label: l10n.callNext,
                icon: Icons.play_arrow_rounded,
                onPressed: busy ? null : () => _advance(confirmComplete: false),
                loading: _busyAction == 'advance',
              ),
              const SizedBox(height: DouriSpacing.md),
            ],
            if (current != null) ...[
              DouriButton(
                label: l10n.markCompleted,
                icon: Icons.check_rounded,
                variant: DouriButtonVariant.secondary,
                onPressed: busy ? null : () => _advance(confirmComplete: true),
              ),
              const SizedBox(height: DouriSpacing.md),
              DouriButton(
                label: l10n.skipCustomer,
                icon: Icons.skip_next_rounded,
                variant: DouriButtonVariant.secondary,
                onPressed: busy ? null : () => _skip(current!),
                loading: _busyAction == 'skip',
              ),
              const SizedBox(height: DouriSpacing.md),
            ],
            DouriButton(
              label: l10n.endDay,
              icon: Icons.stop_rounded,
              variant: DouriButtonVariant.danger,
              onPressed: busy ? null : _endDay,
              loading: _busyAction == 'end',
            ),
          ] else ...[
            DouriButton(
              label: l10n.startDay,
              icon: Icons.play_arrow_rounded,
              onPressed: busy ? null : _startDay,
              loading: _busyAction == 'start',
            ),
          ],
        ],
      ),
    );
  }

  /// One waiting/next queue row: number chip, name, booking time and a
  /// status badge that cross-fades on status change. The whole card is
  /// pressable (DouriPressable, ≥48dp, no layout shift) and opens a
  /// read-only detail sheet; [ValueKey(entry.id)] keeps the row stable
  /// so Realtime updates animate in place instead of rebuilding the list.
  Widget _queueRow(BuildContext context, QueueEntry entry,
      {required bool isCurrent}) {
    final l10n = AppLocalizations.of(context);
    return DouriPressable(
      key: ValueKey(entry.id),
      onTap: () => _showEntrySheet(context, entry),
      child: DouriCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(DouriRadius.md),
                border: Border.all(
                  color: isCurrent
                      ? AppColors.primaryAccent
                      : context.douriColors.border,
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: DouriAnimatedCounter(
                  value: entry.queueNumber,
                  format: (v) => v.toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(width: DouriSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.customerName ?? '',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.bookingTime != null &&
                      entry.bookingTime!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: context.douriColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              entry.bookingTime!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  _statusBadge(context, entry.status, l10n),
                ],
              ),
            ),
            const SizedBox(width: DouriSpacing.sm),
            Icon(
              Icons.arrow_forward,
              size: 18,
              color: context.douriColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  /// Read-only detail sheet for one queue entry (no actions, no new data).
  Future<void> _showEntrySheet(BuildContext context, QueueEntry entry) async {
    final l10n = AppLocalizations.of(context);
    await showDouriSheet<void>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.customerName ?? '',
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _statusBadge(context, entry.status, l10n),
            ],
          ),
          const SizedBox(height: DouriSpacing.md),
          _sheetRow(
            context,
            l10n.queueNumber,
            '#${entry.queueNumber}',
            ltr: true,
          ),
          const SizedBox(height: DouriSpacing.sm),
          if (entry.bookingTime != null && entry.bookingTime!.isNotEmpty)
            _sheetRow(context, l10n.time, entry.bookingTime!, ltr: true),
          const SizedBox(height: DouriSpacing.lg),
          DouriButton(
            label: l10n.close,
            variant: DouriButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _sheetRow(BuildContext context, String label, String value,
      {bool ltr = false}) {
    final text = Text(
      value,
      style: Theme.of(context).textTheme.titleSmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.douriColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: DouriSpacing.md),
        Expanded(
          child: ltr
              ? Directionality(textDirection: TextDirection.ltr, child: text)
              : text,
        ),
      ],
    );
  }

  /// Status pill whose content cross-fades + scales when the status
  /// changes. The pill itself carries `ValueKey(status)` so
  /// [DouriAnimatedBadge]'s AnimatedSwitcher has something to animate
  /// between; under reduced motion it renders the final state directly.
  Widget _statusBadge(
      BuildContext context, String status, AppLocalizations l10n) {
    final color = _queueStatusColor(status);
    return DouriAnimatedBadge(
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _queueStatusLabel(status, l10n),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color),
        ),
      ),
    );
  }

  String _queueStatusLabel(String status, AppLocalizations l10n) => switch (status) {
        'WAITING' => l10n.queueWaiting,
        'APPROACHING' => l10n.queueApproaching,
        'CURRENT' => l10n.queueCurrent,
        'COMPLETED' => l10n.queueCompleted,
        'SKIPPED' => l10n.queueSkipped,
        'CANCELLED' => l10n.queueCancelled,
        _ => status,
      };

  Color _queueStatusColor(String status) => switch (status) {
        'WAITING' => AppColors.warning,
        'APPROACHING' => AppColors.primaryAccent,
        'CURRENT' => AppColors.primaryAccent,
        'COMPLETED' => AppColors.success,
        'SKIPPED' => context.douriColors.textMuted,
        'CANCELLED' => AppColors.danger,
        _ => context.douriColors.textSecondary,
      };
}
