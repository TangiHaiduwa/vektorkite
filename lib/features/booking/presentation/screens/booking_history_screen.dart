import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/booking/application/booking_controller.dart';
import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(bookingControllerProvider.notifier).loadHistory(),
    );
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      ref.read(bookingControllerProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final bookings = state.history;
    final pendingCount = bookings.where(_isPending).length;
    final activeCount = bookings
        .where((booking) => booking.status == BookingStatus.assigned || booking.status == BookingStatus.inProgress)
        .length;
    final completedCount = bookings.where((booking) => booking.status == BookingStatus.completed).length;

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 5,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _HeaderSummary(
                      pendingCount: pendingCount,
                      activeCount: activeCount,
                      completedCount: completedCount,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const TabBar(
                      isScrollable: true,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      labelColor: Color(0xFF0F172A),
                      unselectedLabelColor: Color(0xFF64748B),
                      tabs: [
                        Tab(text: 'Pending'),
                        Tab(text: 'Accepted'),
                        Tab(text: 'In Progress'),
                        Tab(text: 'Completed'),
                        Tab(text: 'Cancelled'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _bookingList(
                          context: context,
                          bookings: bookings.where(_isPending).toList(),
                        ),
                        _bookingList(
                          context: context,
                          bookings: bookings
                              .where((booking) => booking.status == BookingStatus.assigned)
                              .toList(),
                        ),
                        _bookingList(
                          context: context,
                          bookings: bookings
                              .where((booking) => booking.status == BookingStatus.inProgress)
                              .toList(),
                        ),
                        _bookingList(
                          context: context,
                          bookings: bookings
                              .where((booking) => booking.status == BookingStatus.completed)
                              .toList(),
                        ),
                        _bookingList(
                          context: context,
                          bookings: bookings
                              .where((booking) => booking.status == BookingStatus.cancelled)
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.bookingCreate),
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
      ),
    );
  }

  bool _isPending(BookingRecord booking) {
    return booking.status == BookingStatus.pendingMatch ||
        booking.status == BookingStatus.requested;
  }

  Widget _bookingList({
    required BuildContext context,
    required List<BookingRecord> bookings,
  }) {
    if (bookings.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'No bookings in this status.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(bookingControllerProvider.notifier).loadHistory(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              title: Text(
                booking.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusChip(status: booking.status),
                    const SizedBox(height: 6),
                    Text(DateFormat('d MMM yyyy, HH:mm').format(booking.requestedAt)),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                RoutePaths.bookingStatus.replaceFirst(':bookingId', booking.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  const _HeaderSummary({
    required this.pendingCount,
    required this.activeCount,
    required this.completedCount,
  });

  final int pendingCount;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF7FF), Color(0xFFF2FBF8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Bookings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Track your requests, active jobs, and completed work.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _CountPill(
                label: '$pendingCount pending',
                color: const Color(0xFFE0F2FE),
                textColor: const Color(0xFF0C4A6E),
              ),
              _CountPill(
                label: '$activeCount active',
                color: const Color(0xFFFDF4C8),
                textColor: const Color(0xFF92400E),
              ),
              _CountPill(
                label: '$completedCount completed',
                color: const Color(0xFFDCFCE7),
                textColor: const Color(0xFF166534),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
