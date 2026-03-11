import 'package:vektorkite/features/booking/domain/booking_create_input.dart';
import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/provider_candidate.dart';

abstract class BookingRepository {
  Future<BookingRecord> createBooking(BookingCreateInput input);
  Future<List<BookingRecord>> fetchBookingHistory();
  Future<BookingRecord?> getBookingById(String bookingId);
  Future<List<ProviderCandidate>> fetchProviderCandidates({
    required String subcategoryId,
    required String areaQuery,
  });
  Future<BookingRecord> cancelBooking(String bookingId);
}
