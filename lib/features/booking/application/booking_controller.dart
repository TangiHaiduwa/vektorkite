import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/booking/application/booking_state.dart';
import 'package:vektorkite/features/booking/data/appsync_booking_repository.dart';
import 'package:vektorkite/features/booking/data/appsync_service_taxonomy_repository.dart';
import 'package:vektorkite/features/booking/domain/booking_create_input.dart';
import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/booking_repository.dart';
import 'package:vektorkite/features/booking/domain/provider_candidate.dart';
import 'package:vektorkite/features/booking/domain/service_subcategory.dart';
import 'package:vektorkite/features/booking/domain/service_taxonomy_repository.dart';
import 'package:vektorkite/features/home/domain/category_item.dart';

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => const AppSyncBookingRepository(),
);

final serviceTaxonomyRepositoryProvider = Provider<ServiceTaxonomyRepository>(
  (ref) => const AppSyncServiceTaxonomyRepository(),
);

final bookingControllerProvider =
    StateNotifierProvider<BookingController, BookingState>(
      (ref) => BookingController(
        bookingRepository: ref.read(bookingRepositoryProvider),
        taxonomyRepository: ref.read(serviceTaxonomyRepositoryProvider),
      ),
    );

class BookingController extends StateNotifier<BookingState> {
  BookingController({
    required BookingRepository bookingRepository,
    required ServiceTaxonomyRepository taxonomyRepository,
  }) : _bookingRepository = bookingRepository,
       _taxonomyRepository = taxonomyRepository,
       super(const BookingState());

  final BookingRepository _bookingRepository;
  final ServiceTaxonomyRepository _taxonomyRepository;

  Future<void> initializeForm() async {
    if (state.categories.isNotEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _taxonomyRepository.fetchServiceCategories();
      state = state.copyWith(isLoading: false, categories: categories);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load booking categories',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load categories.',
        ),
      );
    }
  }

  Future<void> loadSubcategories(String categoryId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final subcategories = await _taxonomyRepository
          .fetchSubcategoriesByCategory(categoryId);
      state = state.copyWith(isLoading: false, subcategories: subcategories);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load subcategories',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load service options.',
        ),
      );
    }
  }

  Future<BookingRecord?> createBooking(BookingCreateInput input) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final booking = await _bookingRepository.createBooking(input);
      if (booking.customerId != user.userId) {
        AppLogger.info(
          'Created booking customerId did not match current user id',
          name: 'Booking',
        );
      }
      state = state.copyWith(
        isSubmitting: false,
        history: [booking, ...state.history],
      );
      return booking;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create booking',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to create booking. Please try again.',
        ),
      );
      return null;
    }
  }

  Future<List<ProviderCandidate>> loadProviderCandidates({
    required String subcategoryId,
    required String areaQuery,
  }) async {
    state = state.copyWith(
      isLoadingProviders: true,
      providerCandidates: const [],
      clearError: true,
    );
    try {
      final providers = await _bookingRepository.fetchProviderCandidates(
        subcategoryId: subcategoryId,
        areaQuery: areaQuery,
      );
      state = state.copyWith(
        isLoadingProviders: false,
        providerCandidates: providers,
      );
      return providers;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load provider candidates',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingProviders: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load providers.',
        ),
      );
      return const [];
    }
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final history = await _bookingRepository.fetchBookingHistory();
      state = state.copyWith(isLoading: false, history: history);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load booking history',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load booking history.',
        ),
      );
    }
  }

  Future<BookingRecord?> getBookingById(String bookingId) async {
    for (final booking in state.history) {
      if (booking.id == bookingId) return booking;
    }
    try {
      return await _bookingRepository.getBookingById(bookingId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load booking details',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<BookingRecord?> cancelBooking(String bookingId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _bookingRepository.cancelBooking(bookingId);
      final updatedHistory = state.history
          .map((item) => item.id == bookingId ? updated : item)
          .toList();
      state = state.copyWith(isSubmitting: false, history: updatedHistory);
      return updated;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to cancel booking',
        name: 'Booking',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to cancel booking.',
        ),
      );
      return null;
    }
  }

  CategoryItem? categoryById(String categoryId) {
    for (final category in state.categories) {
      if (category.id == categoryId) return category;
    }
    return null;
  }

  ServiceSubcategory? subcategoryById(String subcategoryId) {
    for (final subcategory in state.subcategories) {
      if (subcategory.id == subcategoryId) return subcategory;
    }
    return null;
  }
}
