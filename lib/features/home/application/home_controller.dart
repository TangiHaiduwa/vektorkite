import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/home/data/appsync_home_repository.dart';
import 'package:vektorkite/features/home/data/geolocator_location_permission_service.dart';
import 'package:vektorkite/features/home/application/home_state.dart';
import 'package:vektorkite/features/home/domain/home_repository.dart';
import 'package:vektorkite/features/home/domain/location_permission_service.dart';
import 'package:vektorkite/features/home/domain/service_provider.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const AppSyncHomeRepository(),
);

final locationPermissionServiceProvider = Provider<LocationPermissionService>(
  (ref) => const GeolocatorLocationPermissionService(),
);

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) => HomeController(
    ref.read(homeRepositoryProvider),
    ref.read(locationPermissionServiceProvider),
  ),
);

final providerBrowseControllerProvider = homeControllerProvider;

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repository, this._locationPermissionService)
    : super(const HomeState());

  final HomeRepository _repository;
  final LocationPermissionService _locationPermissionService;

  Future<void> initialize() async {
    if (state.categories.isNotEmpty && state.providers.isNotEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.fetchCategories();
      final providers = await _repository.fetchProviders();
      final sponsoredProducts = await _repository.fetchSponsoredProducts();
      final coordinates = await _locationPermissionService.getCurrentCoordinates();
      final filtered = _applyFilters(
        providers: providers,
        selectedCategoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
        minRatingFilter: state.minRatingFilter,
        maxHourlyRateFilter: state.maxHourlyRateFilter,
      );
      final featuredProviders = _buildFeaturedProviders(providers);
      final nearbyProviders = _buildNearbyProviders(
        providers: filtered,
        currentLatitude: coordinates?.latitude,
        currentLongitude: coordinates?.longitude,
      );

      state = state.copyWith(
        isLoading: false,
        categories: categories,
        providers: providers,
        filteredProviders: filtered,
        featuredProviders: featuredProviders,
        nearbyProviders: nearbyProviders,
        sponsoredProducts: sponsoredProducts,
        currentLatitude: coordinates?.latitude,
        currentLongitude: coordinates?.longitude,
      );
      await requestLocationPermission();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load discovery data',
        name: 'Home',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load providers right now.',
        ),
      );
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      final status = await _locationPermissionService.requestPermission();
      state = state.copyWith(locationStatus: status);
      if (status == LocationPermissionStatus.granted) {
        final coordinates = await _locationPermissionService.getCurrentCoordinates();
        if (coordinates != null) {
          state = state.copyWith(
            currentLatitude: coordinates.latitude,
            currentLongitude: coordinates.longitude,
            nearbyProviders: _buildNearbyProviders(
              providers: state.filteredProviders,
              currentLatitude: coordinates.latitude,
              currentLongitude: coordinates.longitude,
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to request location permission',
        name: 'Home',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(locationStatus: LocationPermissionStatus.denied);
    }
  }

  void updateSearchQuery(String query) {
    final filtered = _applyFilters(
      providers: state.providers,
      selectedCategoryId: state.selectedCategoryId,
      searchQuery: query,
      minRatingFilter: state.minRatingFilter,
      maxHourlyRateFilter: state.maxHourlyRateFilter,
    );
    state = state.copyWith(
      searchQuery: query,
      filteredProviders: filtered,
      nearbyProviders: _buildNearbyProviders(
        providers: filtered,
        currentLatitude: state.currentLatitude,
        currentLongitude: state.currentLongitude,
      ),
    );
  }

  void toggleCategory(String categoryId) {
    final isSameCategory = state.selectedCategoryId == categoryId;
    final selectedCategory = isSameCategory ? null : categoryId;
    final filtered = _applyFilters(
      providers: state.providers,
      selectedCategoryId: selectedCategory,
      searchQuery: state.searchQuery,
      minRatingFilter: state.minRatingFilter,
      maxHourlyRateFilter: state.maxHourlyRateFilter,
    );
    state = state.copyWith(
      selectedCategoryId: selectedCategory,
      filteredProviders: filtered,
      nearbyProviders: _buildNearbyProviders(
        providers: filtered,
        currentLatitude: state.currentLatitude,
        currentLongitude: state.currentLongitude,
      ),
      clearCategory: isSameCategory,
    );
  }

  void setMinRatingFilter(double value) {
    final filtered = _applyFilters(
      providers: state.providers,
      selectedCategoryId: state.selectedCategoryId,
      searchQuery: state.searchQuery,
      minRatingFilter: value,
      maxHourlyRateFilter: state.maxHourlyRateFilter,
    );
    state = state.copyWith(
      minRatingFilter: value,
      filteredProviders: filtered,
      nearbyProviders: _buildNearbyProviders(
        providers: filtered,
        currentLatitude: state.currentLatitude,
        currentLongitude: state.currentLongitude,
      ),
    );
  }

  void setMaxHourlyRateFilter(double? value) {
    final filtered = _applyFilters(
      providers: state.providers,
      selectedCategoryId: state.selectedCategoryId,
      searchQuery: state.searchQuery,
      minRatingFilter: state.minRatingFilter,
      maxHourlyRateFilter: value,
    );
    state = state.copyWith(
      maxHourlyRateFilter: value,
      clearMaxHourlyRateFilter: value == null,
      filteredProviders: filtered,
      nearbyProviders: _buildNearbyProviders(
        providers: filtered,
        currentLatitude: state.currentLatitude,
        currentLongitude: state.currentLongitude,
      ),
    );
  }

  ServiceProvider? findProviderById(String providerId) {
    for (final provider in state.providers) {
      if (provider.id == providerId) return provider;
    }
    return null;
  }

  List<ServiceProvider> _applyFilters({
    required List<ServiceProvider> providers,
    required String? selectedCategoryId,
    required String searchQuery,
    required double minRatingFilter,
    required double? maxHourlyRateFilter,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    return providers.where((provider) {
      final categoryMatch =
          selectedCategoryId == null ||
          provider.categoryIds.contains(selectedCategoryId);
      final searchMatch =
          normalizedQuery.isEmpty ||
          provider.displayName.toLowerCase().contains(normalizedQuery) ||
          provider.bio.toLowerCase().contains(normalizedQuery) ||
          provider.subcategoryNames.any(
            (name) => name.toLowerCase().contains(normalizedQuery),
          );
      final ratingMatch = provider.rating >= minRatingFilter;
      final rateMatch = maxHourlyRateFilter == null
          ? true
          : (provider.hourlyRate == null ||
                provider.hourlyRate! <= maxHourlyRateFilter);
      return categoryMatch && searchMatch && ratingMatch && rateMatch;
    }).toList();
  }

  List<ServiceProvider> _buildFeaturedProviders(List<ServiceProvider> providers) {
    final ranked = [...providers]
      ..sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) return byRating;
        return b.reviewCount.compareTo(a.reviewCount);
      });
    return ranked.take(8).toList();
  }

  List<ServiceProvider> _buildNearbyProviders({
    required List<ServiceProvider> providers,
    required double? currentLatitude,
    required double? currentLongitude,
  }) {
    if (currentLatitude == null || currentLongitude == null) {
      return providers.take(8).toList();
    }
    final withDistance = providers
        .map((provider) {
          final distance = _distanceKm(
            startLat: currentLatitude,
            startLng: currentLongitude,
            endLat: provider.lat,
            endLng: provider.lng,
          );
          return (provider: provider, distance: distance);
        })
        .where((entry) => entry.distance != null)
        .toList()
      ..sort((a, b) => a.distance!.compareTo(b.distance!));
    if (withDistance.isEmpty) return providers.take(8).toList();
    return withDistance.take(8).map((entry) => entry.provider).toList();
  }

  double? _distanceKm({
    required double startLat,
    required double startLng,
    required double? endLat,
    required double? endLng,
  }) {
    if (endLat == null || endLng == null) return null;
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return 6371 * c;
  }

  double _toRadians(double value) => value * pi / 180;
}
