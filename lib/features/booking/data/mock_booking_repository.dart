import 'dart:math';

import 'package:vektorkite/features/booking/domain/booking_create_input.dart';
import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/booking_repository.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';
import 'package:vektorkite/features/booking/domain/provider_candidate.dart';

class MockBookingRepository implements BookingRepository {
  MockBookingRepository();

  static final List<BookingRecord> _bookings = [];
  static final Random _random = Random();

  @override
  Future<BookingRecord> createBooking(BookingCreateInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final booking = BookingRecord(
      id: 'b-${DateTime.now().millisecondsSinceEpoch}',
      customerId: input.customerId,
      categoryId: input.categoryId,
      subcategoryId: input.subcategoryId,
      providerId: input.providerId,
      description: input.description,
      addressText: input.addressText,
      status: input.status,
      isScheduled: input.isScheduled,
      scheduledFor: input.scheduledFor,
      requestedAt: DateTime.now(),
      estimatedMin: input.estimatedMin,
      estimatedMax: input.estimatedMax,
    );
    _bookings.insert(0, booking);
    return booking;
  }

  @override
  Future<List<BookingRecord>> fetchBookingHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _bookings.map(_simulateProgress).toList();
  }

  @override
  Future<BookingRecord?> getBookingById(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    for (final booking in _bookings) {
      if (booking.id == bookingId) return _simulateProgress(booking);
    }
    return null;
  }

  @override
  Future<List<ProviderCandidate>> fetchProviderCandidates({
    required String subcategoryId,
    required String areaQuery,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (areaQuery.toLowerCase().contains('no-provider')) return const [];
    return const [
      ProviderCandidate(
        providerId: 'p-1',
        providerOfferingId: 'off-1',
        displayName: 'Verified Pro',
        isVerified: true,
        rating: 4.8,
        reviewCount: 49,
        serviceArea: 'Windhoek',
        subcategoryName: 'General',
        hourlyRate: 230,
        calloutFee: 80,
      ),
    ];
  }

  @override
  Future<BookingRecord> cancelBooking(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final booking = _bookings.firstWhere((entry) => entry.id == bookingId);
    final cancelled = BookingRecord(
      id: booking.id,
      customerId: booking.customerId,
      categoryId: booking.categoryId,
      subcategoryId: booking.subcategoryId,
      providerId: booking.providerId,
      description: booking.description,
      addressText: booking.addressText,
      status: BookingStatus.cancelled,
      isScheduled: booking.isScheduled,
      scheduledFor: booking.scheduledFor,
      requestedAt: booking.requestedAt,
      estimatedMin: booking.estimatedMin,
      estimatedMax: booking.estimatedMax,
      finalPrice: booking.finalPrice,
      currency: booking.currency,
    );
    final index = _bookings.indexWhere((entry) => entry.id == bookingId);
    if (index >= 0) _bookings[index] = cancelled;
    return cancelled;
  }

  BookingRecord _simulateProgress(BookingRecord booking) {
    final ageMinutes = DateTime.now().difference(booking.requestedAt).inMinutes;
    final nextStatus = switch (ageMinutes) {
      < 2 => booking.status == BookingStatus.requested
          ? BookingStatus.requested
          : BookingStatus.pendingMatch,
      < 5 => booking.status == BookingStatus.requested
          ? BookingStatus.assigned
          : BookingStatus.assigned,
      < 9 => BookingStatus.inProgress,
      _ =>
        _random.nextInt(12) == 0
            ? BookingStatus.cancelled
            : BookingStatus.completed,
    };
    return BookingRecord(
      id: booking.id,
      customerId: booking.customerId,
      categoryId: booking.categoryId,
      subcategoryId: booking.subcategoryId,
      providerId: booking.providerId,
      description: booking.description,
      addressText: booking.addressText,
      status: nextStatus,
      isScheduled: booking.isScheduled,
      scheduledFor: booking.scheduledFor,
      requestedAt: booking.requestedAt,
      estimatedMin: booking.estimatedMin,
      estimatedMax: booking.estimatedMax,
      finalPrice: booking.finalPrice,
      currency: booking.currency,
    );
  }
}
