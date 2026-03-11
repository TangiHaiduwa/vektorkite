import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/booking/domain/booking_create_input.dart';
import 'package:vektorkite/features/booking/domain/booking_record.dart';
import 'package:vektorkite/features/booking/domain/booking_repository.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';
import 'package:vektorkite/features/booking/domain/provider_candidate.dart';

class AppSyncBookingRepository implements BookingRepository {
  const AppSyncBookingRepository();

  static const String _createBookingMutation = r'''
mutation CreateBooking($input: CreateBookingInput!) {
  createBooking(input: $input) {
    id
    customerId
    categoryId
    subcategoryId
    providerId
    description
    addressText
    status
    isScheduled
    scheduledFor
    requestedAt
    estimatedMin
    estimatedMax
    finalPrice
    currency
    lat
    lng
    createdAt
  }
}
''';

  static const String _bookingsByCustomerQuery = r'''
query BookingsByCustomer($customerId: ID!) {
  bookingsByCustomer(customerId: $customerId, limit: 200) {
    items {
      id
      customerId
      categoryId
      subcategoryId
      providerId
      description
      addressText
      status
      isScheduled
      scheduledFor
      requestedAt
      estimatedMin
      estimatedMax
      finalPrice
      currency
      lat
      lng
      createdAt
    }
  }
}
''';

  static const String _getBookingQuery = r'''
query GetBooking($id: ID!) {
  getBooking(id: $id) {
    id
    customerId
    categoryId
    subcategoryId
    providerId
    description
    addressText
    status
    isScheduled
    scheduledFor
    requestedAt
    estimatedMin
    estimatedMax
    finalPrice
    currency
    lat
    lng
    createdAt
  }
}
''';

  static const String _providersBySubcategoryQuery = r'''
query ProviderServiceOfferingsBySubcategory($subcategoryId: ID!) {
  providerServiceOfferingsBySubcategory(subcategoryId: $subcategoryId, limit: 200) {
    items {
      id
      providerId
      subcategoryId
      isActive
      hourlyRate
      calloutFee
      currency
      provider {
        id
        displayName
        isVerified
        ratingAverage
        ratingCount
        serviceAreaText
      }
      subcategory {
        id
        name
      }
    }
  }
}
''';

  static const String _updateBookingMutation = r'''
mutation UpdateBooking($input: UpdateBookingInput!) {
  updateBooking(input: $input) {
    id
    customerId
    categoryId
    subcategoryId
    providerId
    description
    addressText
    status
    isScheduled
    scheduledFor
    requestedAt
    estimatedMin
    estimatedMax
    finalPrice
    currency
    lat
    lng
    createdAt
  }
}
''';

  @override
  Future<BookingRecord> createBooking(BookingCreateInput input) async {
    final request = GraphQLRequest<String>(
      document: _createBookingMutation,
      variables: {
        'input': {
          'customerId': input.customerId,
          'categoryId': input.categoryId,
          'subcategoryId': input.subcategoryId,
          'providerId': input.providerId,
          'providerOfferingId': input.providerOfferingId,
          'description': input.description,
          'addressText': input.addressText,
          'isScheduled': input.isScheduled,
          'scheduledFor': input.scheduledFor?.toUtc().toIso8601String(),
          'requestedAt': DateTime.now().toUtc().toIso8601String(),
          'status': input.status.apiValue,
          'estimatedMin': input.estimatedMin,
          'estimatedMax': input.estimatedMax,
          'customerNote': input.customerNote,
          'lat': input.lat,
          'lng': input.lng,
        },
      },
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final item = (parsed['createBooking'] ?? {}) as Map<String, dynamic>;
    return _parseBooking(item);
  }

  @override
  Future<List<BookingRecord>> fetchBookingHistory() async {
    final currentUser = await Amplify.Auth.getCurrentUser();
    final request = GraphQLRequest<String>(
      document: _bookingsByCustomerQuery,
      variables: {'customerId': currentUser.userId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['bookingsByCustomer'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .where((e) => e['id'] != null)
        .map(_parseBooking)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  @override
  Future<BookingRecord?> getBookingById(String bookingId) async {
    final request = GraphQLRequest<String>(
      document: _getBookingQuery,
      variables: {'id': bookingId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final item = parsed['getBooking'];
    if (item == null || item is! Map<String, dynamic>) return null;
    return _parseBooking(item);
  }

  @override
  Future<List<ProviderCandidate>> fetchProviderCandidates({
    required String subcategoryId,
    required String areaQuery,
  }) async {
    final request = GraphQLRequest<String>(
      document: _providersBySubcategoryQuery,
      variables: {'subcategoryId': subcategoryId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['providerServiceOfferingsBySubcategory'] ?? {})
        as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    final normalizedArea = areaQuery.trim().toLowerCase();

    return items
        .whereType<Map<String, dynamic>>()
        .where((offering) => (offering['isActive'] as bool?) ?? true)
        .map(_parseProviderCandidate)
        .whereType<ProviderCandidate>()
        .where((candidate) => candidate.isVerified)
        .where((candidate) {
          if (normalizedArea.isEmpty) return true;
          return candidate.serviceArea.toLowerCase().contains(normalizedArea);
        })
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  @override
  Future<BookingRecord> cancelBooking(String bookingId) async {
    final request = GraphQLRequest<String>(
      document: _updateBookingMutation,
      variables: {
        'input': {'id': bookingId, 'status': BookingStatus.cancelled.apiValue},
      },
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final item = (parsed['updateBooking'] ?? {}) as Map<String, dynamic>;
    return _parseBooking(item);
  }

  ProviderCandidate? _parseProviderCandidate(Map<String, dynamic> data) {
    final provider = data['provider'];
    final subcategory = data['subcategory'];
    if (provider is! Map<String, dynamic>) return null;
    if (subcategory is! Map<String, dynamic>) return null;

    final providerId = provider['id'] as String?;
    final offeringId = data['id'] as String?;
    if (providerId == null || providerId.isEmpty) return null;
    if (offeringId == null || offeringId.isEmpty) return null;

    return ProviderCandidate(
      providerId: providerId,
      providerOfferingId: offeringId,
      displayName: (provider['displayName'] as String?) ?? 'Provider',
      isVerified: (provider['isVerified'] as bool?) ?? false,
      rating: ((provider['ratingAverage'] as num?) ?? 0).toDouble(),
      reviewCount: ((provider['ratingCount'] as num?) ?? 0).toInt(),
      serviceArea: (provider['serviceAreaText'] as String?) ?? 'Namibia',
      subcategoryName: (subcategory['name'] as String?) ?? 'Service',
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
      calloutFee: (data['calloutFee'] as num?)?.toDouble(),
      currency: (data['currency'] as String?) ?? 'NAD',
    );
  }

  BookingRecord _parseBooking(Map<String, dynamic> data) {
    final scheduledRaw = data['scheduledFor'] as String?;
    final requestedRaw = (data['requestedAt'] ?? data['createdAt']) as String?;
    return BookingRecord(
      id: data['id'] as String,
      customerId: (data['customerId'] as String?) ?? '',
      categoryId: (data['categoryId'] as String?) ?? '',
      subcategoryId: data['subcategoryId'] as String?,
      providerId: data['providerId'] as String?,
      description: (data['description'] as String?) ?? '',
      addressText: (data['addressText'] as String?) ?? '',
      status: BookingStatus.fromApiValue(data['status'] as String?),
      isScheduled: (data['isScheduled'] as bool?) ?? false,
      scheduledFor: scheduledRaw == null
          ? null
          : DateTime.tryParse(scheduledRaw)?.toLocal(),
      requestedAt:
          DateTime.tryParse(requestedRaw ?? '')?.toLocal() ?? DateTime.now(),
      estimatedMin: (data['estimatedMin'] as num?)?.toDouble(),
      estimatedMax: (data['estimatedMax'] as num?)?.toDouble(),
      finalPrice: (data['finalPrice'] as num?)?.toDouble(),
      currency: (data['currency'] as String?) ?? 'NAD',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
    );
  }
}
