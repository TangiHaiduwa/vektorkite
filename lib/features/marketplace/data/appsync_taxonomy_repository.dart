import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_taxonomy.dart';
import 'package:vektorkite/features/marketplace/domain/taxonomy_repository.dart';

class AppSyncTaxonomyRepository implements TaxonomyRepository {
  const AppSyncTaxonomyRepository();

  static const String _listCategoriesQuery = r'''
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

  static const String _subcategoriesByCategoryQuery = r'''
query ServiceSubcategoriesByCategory($categoryId: ID!) {
  serviceSubcategoriesByCategory(categoryId: $categoryId, limit: 500) {
    items {
      id
      categoryId
      name
      isActive
      sortOrder
    }
  }
}
''';

  @override
  Future<List<MarketplaceCategory>> fetchCategories() async {
    final request = GraphQLRequest<String>(document: _listCategoriesQuery);
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['listServiceCategories'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => (item['isActive'] as bool?) ?? true)
        .map(
          (item) => MarketplaceCategory(
            id: (item['id'] as String?) ?? '',
            name: (item['name'] as String?) ?? '',
          ),
        )
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }

  @override
  Future<List<MarketplaceSubcategory>> fetchSubcategories(String categoryId) async {
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
        (parsed['serviceSubcategoriesByCategory'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => (item['isActive'] as bool?) ?? true)
        .map(
          (item) => MarketplaceSubcategory(
            id: (item['id'] as String?) ?? '',
            categoryId: (item['categoryId'] as String?) ?? categoryId,
            name: (item['name'] as String?) ?? '',
          ),
        )
        .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
        .toList();
  }
}
