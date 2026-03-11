import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/home/domain/category_item.dart';
import 'package:vektorkite/features/home/domain/home_product_item.dart';
import 'package:vektorkite/features/home/domain/home_repository.dart';
import 'package:vektorkite/features/home/domain/service_provider.dart';
import 'package:vektorkite/features/marketplace/data/appsync_product_repository.dart';

class AppSyncHomeRepository implements HomeRepository {
  const AppSyncHomeRepository();
  static const _productRepository = AppSyncProductRepository();

  static const String _listServiceCategoriesQuery = r'''
query ListServiceCategories {
  listServiceCategories(limit: 300) {
    items {
      id
      name
      isActive
      sortOrder
    }
  }
}
''';

  static const String _listProviderOfferingsQuery = r'''
query ListProviderServiceOfferings {
  listProviderServiceOfferings(limit: 1000) {
    items {
      providerId
      hourlyRate
      calloutFee
      isActive
      provider {
        id
        displayName
        ratingAverage
        ratingCount
        bio
        serviceAreaText
        verificationNotes
        lat
        lng
      }
      subcategory {
        id
        name
        categoryId
      }
    }
  }
}
''';

  static const String _listReviewsQuery = r'''
query ListReviews {
  listReviews(limit: 2000) {
    items {
      id
      providerId
      rating
    }
  }
}
''';

  @override
  Future<List<CategoryItem>> fetchCategories() async {
    final request = GraphQLRequest<String>(
      document: _listServiceCategoriesQuery,
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root =
        (parsed['listServiceCategories'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;

    return items
        .whereType<Map<String, dynamic>>()
        .where(
          (e) =>
              e['id'] != null &&
              e['name'] != null &&
              (e['isActive'] as bool? ?? true),
        )
        .map(
          (e) => CategoryItem(
            id: e['id'] as String,
            name: e['name'] as String,
            icon: _resolveIcon(e['name'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<List<ServiceProvider>> fetchProviders() async {
    final offeringsRequest = GraphQLRequest<String>(
      document: _listProviderOfferingsQuery,
    );
    final reviewsRequest = GraphQLRequest<String>(document: _listReviewsQuery);

    final offeringsResponse = await Amplify.API.query(request: offeringsRequest).response;
    final reviewsResponse = await Amplify.API.query(request: reviewsRequest).response;
    if (offeringsResponse.errors.isNotEmpty) {
      throw Exception(offeringsResponse.errors.first.message);
    }
    if (reviewsResponse.errors.isNotEmpty) {
      throw Exception(reviewsResponse.errors.first.message);
    }

    final offeringsParsed =
        jsonDecode(offeringsResponse.data ?? '{}') as Map<String, dynamic>;
    final offeringsRoot =
        (offeringsParsed['listProviderServiceOfferings'] ?? {}) as Map<String, dynamic>;
    final offeringsItems = (offeringsRoot['items'] ?? const []) as List<dynamic>;

    final reviewsParsed =
        jsonDecode(reviewsResponse.data ?? '{}') as Map<String, dynamic>;
    final reviewsRoot = (reviewsParsed['listReviews'] ?? {}) as Map<String, dynamic>;
    final reviewItems = (reviewsRoot['items'] ?? const []) as List<dynamic>;

    return _aggregateProvidersFromOfferings(offeringsItems, reviewItems);
  }

  @override
  Future<List<HomeProductItem>> fetchSponsoredProducts() async {
    final page = await _productRepository.fetchProducts(
      sponsoredOnly: true,
      limit: 10,
    );
    return page.items
        .map(
          (product) => HomeProductItem(
            id: product.id,
            title: product.title,
            priceNad: product.priceNAD,
            imageUrl: product.images.isEmpty ? null : product.images.first,
            storeName: product.store?.name ?? 'Store',
          ),
        )
        .toList();
  }

  List<ServiceProvider> _aggregateProvidersFromOfferings(
    List<dynamic> rawItems,
    List<dynamic> rawReviews,
  ) {
    final map = <String, _ProviderAggregate>{};

    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) continue;
      if ((raw['isActive'] as bool?) == false) continue;

      final provider = raw['provider'];
      final subcategory = raw['subcategory'];
      if (provider is! Map<String, dynamic>) continue;
      if (subcategory is! Map<String, dynamic>) continue;

      final providerId = provider['id'] as String?;
      if (providerId == null || providerId.isEmpty) continue;

      final aggregate = map.putIfAbsent(
        providerId,
        () => _ProviderAggregate(
          id: providerId,
          displayName: (provider['displayName'] as String?) ?? 'Provider',
          rating: ((provider['ratingAverage'] as num?) ?? 0).toDouble(),
          reviewCount: ((provider['ratingCount'] as num?) ?? 0).toInt(),
          bio: (provider['bio'] as String?) ?? 'No bio available.',
          serviceArea: (provider['serviceAreaText'] as String?) ?? 'Namibia',
          availabilityText: _parseAvailabilityText(
            provider['verificationNotes'] as String?,
          ),
          lat: (provider['lat'] as num?)?.toDouble(),
          lng: (provider['lng'] as num?)?.toDouble(),
        ),
      );

      final categoryId = subcategory['categoryId'] as String?;
      final subcategoryName = subcategory['name'] as String?;
      if (categoryId != null && categoryId.isNotEmpty) {
        aggregate.categoryIds.add(categoryId);
      }
      if (subcategoryName != null && subcategoryName.isNotEmpty) {
        aggregate.subcategoryNames.add(subcategoryName);
      }

      final hourlyRate = (raw['hourlyRate'] as num?)?.toDouble();
      final calloutFee = (raw['calloutFee'] as num?)?.toDouble();
      if (hourlyRate != null &&
          (aggregate.hourlyRate == null ||
              hourlyRate < aggregate.hourlyRate!)) {
        aggregate.hourlyRate = hourlyRate;
      }
      if (calloutFee != null &&
          (aggregate.calloutFee == null ||
              calloutFee < aggregate.calloutFee!)) {
        aggregate.calloutFee = calloutFee;
      }
    }

    final reviewStats = <String, _ReviewAggregate>{};
    for (final raw in rawReviews) {
      if (raw is! Map<String, dynamic>) continue;
      final providerId = raw['providerId'] as String?;
      final rating = (raw['rating'] as num?)?.toDouble();
      if (providerId == null || providerId.isEmpty || rating == null) continue;
      final stat = reviewStats.putIfAbsent(providerId, _ReviewAggregate.new);
      stat.totalRating += rating;
      stat.count += 1;
    }

    for (final entry in map.entries) {
      final stat = reviewStats[entry.key];
      if (stat == null || stat.count == 0) continue;
      entry.value.rating = stat.totalRating / stat.count;
      entry.value.reviewCount = stat.count;
    }

    return map.values
        .map(
          (aggregate) => ServiceProvider(
            id: aggregate.id,
            displayName: aggregate.displayName,
            categoryIds: aggregate.categoryIds.toList(),
            subcategoryNames: aggregate.subcategoryNames.toList(),
            rating: aggregate.rating,
            reviewCount: aggregate.reviewCount,
            bio: aggregate.bio,
            serviceArea: aggregate.serviceArea,
            calloutFee: aggregate.calloutFee,
            hourlyRate: aggregate.hourlyRate,
            availabilityText: aggregate.availabilityText,
            lat: aggregate.lat,
            lng: aggregate.lng,
          ),
        )
        .toList();
  }

  String? _parseAvailabilityText(String? verificationNotes) {
    if (verificationNotes == null || verificationNotes.trim().isEmpty) {
      return null;
    }
    try {
      final parsed = jsonDecode(verificationNotes) as Map<String, dynamic>;
      final availability = parsed['availability'];
      if (availability is! Map<String, dynamic>) return null;
      final days = (availability['days'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList();
      final startTime = availability['startTime']?.toString();
      final endTime = availability['endTime']?.toString();
      if (days.isEmpty || startTime == null || endTime == null) return null;
      return '${days.join(', ')} | $startTime - $endTime';
    } catch (_) {
      return null;
    }
  }

  String _resolveIcon(String categoryName) {
    final value = categoryName.toLowerCase();
    if (value.contains('clean')) return 'CL';
    if (value.contains('plumb')) return 'PL';
    if (value.contains('elect')) return 'EL';
    if (value.contains('it') || value.contains('tech')) return 'IT';
    if (value.contains('garden')) return 'GD';
    if (value.contains('photo')) return 'PH';
    return 'SV';
  }
}

class _ProviderAggregate {
  _ProviderAggregate({
    required this.id,
    required this.displayName,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.serviceArea,
    this.availabilityText,
    this.lat,
    this.lng,
  });

  final String id;
  final String displayName;
  final Set<String> categoryIds = <String>{};
  final Set<String> subcategoryNames = <String>{};
  double rating;
  int reviewCount;
  final String bio;
  final String serviceArea;
  String? availabilityText;
  double? calloutFee;
  double? hourlyRate;
  double? lat;
  double? lng;
}

class _ReviewAggregate {
  double totalRating = 0;
  int count = 0;
}
