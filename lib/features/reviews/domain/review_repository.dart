import 'package:vektorkite/features/reviews/domain/review_create_input.dart';
import 'package:vektorkite/features/reviews/domain/review_record.dart';

abstract class ReviewRepository {
  Future<ReviewRecord> createReview(ReviewCreateInput input);
  Future<ReviewRecord?> getReviewByBookingId(String bookingId);
  Future<List<ReviewRecord>> fetchReviewsByProviderId(String providerId);
}
