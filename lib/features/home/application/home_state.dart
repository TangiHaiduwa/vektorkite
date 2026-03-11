import 'package:vektorkite/features/home/domain/category_item.dart';
import 'package:vektorkite/features/home/domain/home_product_item.dart';
import 'package:vektorkite/features/home/domain/location_permission_service.dart';
import 'package:vektorkite/features/home/domain/service_provider.dart';

class HomeState {
  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.locationStatus = LocationPermissionStatus.unknown,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.categories = const [],
    this.providers = const [],
    this.filteredProviders = const [],
    this.featuredProviders = const [],
    this.nearbyProviders = const [],
    this.sponsoredProducts = const [],
    this.minRatingFilter = 0,
    this.maxHourlyRateFilter,
    this.currentLatitude,
    this.currentLongitude,
  });

  final bool isLoading;
  final String? errorMessage;
  final LocationPermissionStatus locationStatus;
  final String? selectedCategoryId;
  final String searchQuery;
  final List<CategoryItem> categories;
  final List<ServiceProvider> providers;
  final List<ServiceProvider> filteredProviders;
  final List<ServiceProvider> featuredProviders;
  final List<ServiceProvider> nearbyProviders;
  final List<HomeProductItem> sponsoredProducts;
  final double minRatingFilter;
  final double? maxHourlyRateFilter;
  final double? currentLatitude;
  final double? currentLongitude;

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    LocationPermissionStatus? locationStatus,
    String? selectedCategoryId,
    String? searchQuery,
    List<CategoryItem>? categories,
    List<ServiceProvider>? providers,
    List<ServiceProvider>? filteredProviders,
    List<ServiceProvider>? featuredProviders,
    List<ServiceProvider>? nearbyProviders,
    List<HomeProductItem>? sponsoredProducts,
    double? minRatingFilter,
    double? maxHourlyRateFilter,
    double? currentLatitude,
    double? currentLongitude,
    bool clearError = false,
    bool clearCategory = false,
    bool clearMaxHourlyRateFilter = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      locationStatus: locationStatus ?? this.locationStatus,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      providers: providers ?? this.providers,
      filteredProviders: filteredProviders ?? this.filteredProviders,
      featuredProviders: featuredProviders ?? this.featuredProviders,
      nearbyProviders: nearbyProviders ?? this.nearbyProviders,
      sponsoredProducts: sponsoredProducts ?? this.sponsoredProducts,
      minRatingFilter: minRatingFilter ?? this.minRatingFilter,
      maxHourlyRateFilter: clearMaxHourlyRateFilter
          ? null
          : (maxHourlyRateFilter ?? this.maxHourlyRateFilter),
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
    );
  }
}
