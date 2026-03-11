import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/booking/domain/service_subcategory.dart';
import 'package:vektorkite/features/booking/domain/service_taxonomy_repository.dart';
import 'package:vektorkite/features/home/domain/category_item.dart';

class AppSyncServiceTaxonomyRepository implements ServiceTaxonomyRepository {
  const AppSyncServiceTaxonomyRepository();

  static const String _listServiceCategoriesQuery = r'''
query ListServiceCategories {
  listServiceCategories(limit: 300) {
    items {
      id
      name
      slug
      isActive
      sortOrder
    }
  }
}
''';

  static const String _subcategoriesByCategoryQuery = r'''
query ServiceSubcategoriesByCategory($categoryId: ID!) {
  serviceSubcategoriesByCategory(categoryId: $categoryId, limit: 500) {
    items {
      id
      categoryId
      name
      slug
      isActive
      sortOrder
    }
  }
}
''';

  @override
  Future<List<CategoryItem>> fetchServiceCategories() async {
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
    final categories = items
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
    return categories;
  }

  @override
  Future<List<ServiceSubcategory>> fetchSubcategoriesByCategory(
    String categoryId,
  ) async {
    final request = GraphQLRequest<String>(
      document: _subcategoriesByCategoryQuery,
      variables: {'categoryId': categoryId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root =
        (parsed['serviceSubcategoriesByCategory'] ?? {})
            as Map<String, dynamic>;
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
          (e) => ServiceSubcategory(
            id: e['id'] as String,
            categoryId: (e['categoryId'] as String?) ?? categoryId,
            name: e['name'] as String,
            slug: (e['slug'] as String?) ?? '',
          ),
        )
        .toList();
  }

  String _resolveIcon(String categoryName) {
    final value = categoryName.toLowerCase();
    if (value.contains('clean')) return '🧹';
    if (value.contains('plumb')) return '🔧';
    if (value.contains('elect')) return '💡';
    if (value.contains('it') || value.contains('tech')) return '💻';
    if (value.contains('garden')) return '🌿';
    if (value.contains('photo')) return '📷';
    return '🛠️';
  }
}
