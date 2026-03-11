import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/reviews/application/review_state.dart';
import 'package:vektorkite/features/reviews/data/appsync_review_repository.dart';
import 'package:vektorkite/features/reviews/domain/review_create_input.dart';
import 'package:vektorkite/features/reviews/domain/review_record.dart';
import 'package:vektorkite/features/reviews/domain/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => const AppSyncReviewRepository(),
);

final reviewControllerProvider = StateNotifierProvider<ReviewController, ReviewState>(
  (ref) => ReviewController(ref.read(reviewRepositoryProvider)),
);

final providerReviewsProvider = FutureProvider.family<List<ReviewRecord>, String>(
  (ref, providerId) => ref
      .read(reviewRepositoryProvider)
      .fetchReviewsByProviderId(providerId),
);

final bookingReviewProvider = FutureProvider.family<ReviewRecord?, String>(
  (ref, bookingId) => ref
      .read(reviewRepositoryProvider)
      .getReviewByBookingId(bookingId),
);

class ReviewController extends StateNotifier<ReviewState> {
  ReviewController(this._repository) : super(const ReviewState());

  final ReviewRepository _repository;

  Future<ReviewRecord?> getReviewByBookingId(String bookingId) {
    return _repository.getReviewByBookingId(bookingId);
  }

  Future<List<ReviewRecord>> fetchReviewsByProviderId(String providerId) {
    return _repository.fetchReviewsByProviderId(providerId);
  }

  Future<ReviewRecord?> createReview(ReviewCreateInput input) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final review = await _repository.createReview(input);
      state = state.copyWith(isSubmitting: false);
      return review;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create review',
        name: 'Reviews',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to submit review.',
        ),
      );
      return null;
    }
  }
}
