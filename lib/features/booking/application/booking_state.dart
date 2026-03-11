import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/provider_candidate.dart';
import 'package:vektorkite/features/booking/domain/service_subcategory.dart';
import 'package:vektorkite/features/home/domain/category_item.dart';

class BookingState {
  const BookingState({
    this.isLoading = false,
    this.isLoadingProviders = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.categories = const [],
    this.subcategories = const [],
    this.providerCandidates = const [],
    this.history = const [],
  });

  final bool isLoading;
  final bool isLoadingProviders;
  final bool isSubmitting;
  final String? errorMessage;
  final List<CategoryItem> categories;
  final List<ServiceSubcategory> subcategories;
  final List<ProviderCandidate> providerCandidates;
  final List<BookingRecord> history;

  BookingState copyWith({
    bool? isLoading,
    bool? isLoadingProviders,
    bool? isSubmitting,
    String? errorMessage,
    List<CategoryItem>? categories,
    List<ServiceSubcategory>? subcategories,
    List<ProviderCandidate>? providerCandidates,
    List<BookingRecord>? history,
    bool clearError = false,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingProviders: isLoadingProviders ?? this.isLoadingProviders,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
      providerCandidates: providerCandidates ?? this.providerCandidates,
      history: history ?? this.history,
    );
  }
}
