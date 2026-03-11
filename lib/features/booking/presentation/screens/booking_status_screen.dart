import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/booking/application/booking_controller.dart';
import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';

class BookingStatusScreen extends ConsumerStatefulWidget {
  const BookingStatusScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingStatusScreen> createState() =>
      _BookingStatusScreenState();
}

class _BookingStatusScreenState extends ConsumerState<BookingStatusScreen> {
  Future<BookingRecord?>? _bookingFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(bookingControllerProvider.notifier).loadHistory(),
    );
    _reloadBooking();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      _reloadBooking();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _reloadBooking() {
    setState(() {
      _bookingFuture = ref
          .read(bookingControllerProvider.notifier)
          .getBookingById(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingControllerProvider);
    final bookingController = ref.read(bookingControllerProvider.notifier);

    return FutureBuilder<BookingRecord?>(
      future: _bookingFuture,
      builder: (context, snapshot) {
        final booking = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop() ? const AppBackButton() : null,
            title: const Text('Booking Status'),
            actions: [
              IconButton(
                onPressed: _reloadBooking,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: bookingState.isLoading && booking == null
              ? const Center(child: CircularProgressIndicator())
              : booking == null
                  ? const Center(child: Text('Booking not found.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        _SummaryCard(booking: booking),
                        const SizedBox(height: 12),
                        _TimelinePanel(currentStatus: booking.status),
                        const SizedBox(height: 14),
                        _ActionPanel(
                          booking: booking,
                          isSubmitting: bookingState.isSubmitting,
                          onCancel: () async {
                            final result =
                                await bookingController.cancelBooking(booking.id);
                            if (!context.mounted) return;
                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Booking cancelled.')),
                              );
                              _reloadBooking();
                            }
                          },
                          onReview: () => context.push(
                            RoutePaths.bookingReview.replaceFirst(
                              ':bookingId',
                              booking.id,
                            ),
                          ),
                          onSupport: () => context.push(
                            '${RoutePaths.supportCreate}?type=DISPUTE_BOOKING&bookingId=${Uri.encodeComponent(booking.id)}'
                            '${booking.providerId == null ? '' : '&providerId=${Uri.encodeComponent(booking.providerId!)}'}',
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    final requestedAt = DateFormat('d MMM yyyy, HH:mm').format(booking.requestedAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF7FF), Color(0xFFF2FBF8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking ${booking.id}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Requested $requestedAt',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          _StatusPill(status: booking.status),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({required this.currentStatus});

  final BookingStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...BookingStatus.values.map((status) {
            final reached = _hasReachedStatus(currentStatus, status);
            final isCurrent = status == currentStatus;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    reached ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: reached ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _hasReachedStatus(BookingStatus current, BookingStatus candidate) {
    const flow = <BookingStatus>[
      BookingStatus.pendingMatch,
      BookingStatus.requested,
      BookingStatus.assigned,
      BookingStatus.inProgress,
      BookingStatus.completed,
    ];
    if (current == BookingStatus.cancelled) {
      return candidate == BookingStatus.cancelled;
    }
    final currentIndex = flow.indexOf(current);
    final candidateIndex = flow.indexOf(candidate);
    if (candidate == BookingStatus.cancelled) return false;
    if (currentIndex < 0 || candidateIndex < 0) return false;
    return candidateIndex <= currentIndex;
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.booking,
    required this.isSubmitting,
    required this.onCancel,
    required this.onReview,
    required this.onSupport,
  });

  final BookingRecord booking;
  final bool isSubmitting;
  final Future<void> Function() onCancel;
  final VoidCallback onReview;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (booking.status.canCustomerCancel)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel Booking'),
              ),
            ),
          if (booking.status == BookingStatus.completed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Leave a Review'),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSupport,
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Dispute / Get Support'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case BookingStatus.pendingMatch:
      case BookingStatus.requested:
        bg = const Color(0xFFE0F2FE);
        fg = const Color(0xFF0C4A6E);
        break;
      case BookingStatus.assigned:
      case BookingStatus.inProgress:
        bg = const Color(0xFFFDF4C8);
        fg = const Color(0xFF92400E);
        break;
      case BookingStatus.completed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case BookingStatus.cancelled:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
