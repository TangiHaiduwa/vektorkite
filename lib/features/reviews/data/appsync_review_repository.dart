import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/reviews/domain/review_create_input.dart';
import 'package:vektorkite/features/reviews/domain/review_record.dart';
import 'package:vektorkite/features/reviews/domain/review_repository.dart';

class AppSyncReviewRepository implements ReviewRepository {
  const AppSyncReviewRepository();

  static const String _createReviewMutation = r'''
mutation CreateReview($input: CreateReviewInput!) {
  createReview(input: $input) {
    id
    bookingId
    providerId
    rating
    comment
    createdAt
  }
}
''';

  static const String _reviewsByBookingQuery = r'''
query ReviewsByBooking($bookingId: ID!) {
  reviewsByBooking(bookingId: $bookingId, limit: 20) {
    items {
      id
      bookingId
      providerId
      rating
      comment
      createdAt
    }
  }
}
''';

  static const String _reviewsByProviderQuery = r'''
query ReviewsByProvider($providerId: ID!) {
  reviewsByProvider(providerId: $providerId, limit: 200) {
    items {
      id
      bookingId
      providerId
      rating
      comment
      createdAt
    }
  }
}
''';

  @override
  Future<ReviewRecord> createReview(ReviewCreateInput input) async {
    final request = GraphQLRequest<String>(
      document: _createReviewMutation,
      variables: {
        'input': {
          'bookingId': input.bookingId,
          'providerId': input.providerId,
          'rating': input.rating,
          'comment': input.comment,
        },
      },
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final item = (parsed['createReview'] ?? {}) as Map<String, dynamic>;
    return _parseReview(item);
  }

  @override
  Future<ReviewRecord?> getReviewByBookingId(String bookingId) async {
    final request = GraphQLRequest<String>(
      document: _reviewsByBookingQuery,
      variables: {'bookingId': bookingId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['reviewsByBooking'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      if (item['id'] == null) continue;
      return _parseReview(item);
    }
    return null;
  }

  @override
  Future<List<ReviewRecord>> fetchReviewsByProviderId(String providerId) async {
    final request = GraphQLRequest<String>(
      document: _reviewsByProviderQuery,
      variables: {'providerId': providerId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['reviewsByProvider'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    final reviews = items
        .whereType<Map<String, dynamic>>()
        .where((item) => item['id'] != null)
        .map(_parseReview)
        .toList();
    reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reviews;
  }

  ReviewRecord _parseReview(Map<String, dynamic> item) {
    return ReviewRecord(
      id: item['id'] as String,
      bookingId: (item['bookingId'] as String?) ?? '',
      providerId: (item['providerId'] as String?) ?? '',
      rating: ((item['rating'] as num?) ?? 0).toInt(),
      comment: item['comment'] as String?,
      createdAt:
          DateTime.tryParse((item['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
