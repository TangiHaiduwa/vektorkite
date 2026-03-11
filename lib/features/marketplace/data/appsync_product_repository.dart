import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/features/marketplace/domain/product_repository.dart';

class AppSyncProductRepository implements ProductRepository {
  const AppSyncProductRepository();

  static const String _listProductsQuery = r'''
query ListProducts($filter: ModelProductFilterInput, $limit: Int, $nextToken: String) {
  listProducts(filter: $filter, limit: $limit, nextToken: $nextToken) {
    items {
      id
      ownerSub
      storeId
      categoryId
      subcategoryId
      title
      description
      priceNAD
      images
      stockQty
      isActive
      isSponsored
      createdAt
      store {
        id
        ownerSub
        name
        phone
        city
        address
        logoKey
        status
        createdAt
      }
    }
    nextToken
  }
}
''';

  static const String _getProductQuery = r'''
query GetProduct($id: ID!) {
  getProduct(id: $id) {
    id
    ownerSub
    storeId
    categoryId
    subcategoryId
    title
    description
    priceNAD
    images
    stockQty
    isActive
    isSponsored
    createdAt
    store {
      id
      ownerSub
      name
      phone
      city
      address
      logoKey
      status
      createdAt
    }
  }
}
''';

  static const String _productsByStoreQuery = r'''
query ProductsByStore($storeId: ID!) {
  productsByStore(storeId: $storeId, limit: 500) {
    items {
      id
      ownerSub
      storeId
      categoryId
      subcategoryId
      title
      description
      priceNAD
      images
      stockQty
      isActive
      isSponsored
      createdAt
      store {
        id
        ownerSub
        name
        phone
        city
        address
        logoKey
        status
        createdAt
      }
    }
  }
}
''';

  static const String _getStoreQuery = r'''
query GetStore($id: ID!) {
  getStore(id: $id) {
    id
    ownerSub
    name
    phone
    city
    address
    logoKey
    status
    createdAt
  }
}
''';

  static const String _createProductMutation = r'''
mutation CreateProduct($input: CreateProductInput!) {
  createProduct(input: $input) {
    id
    ownerSub
    storeId
    categoryId
    subcategoryId
    title
    description
    priceNAD
    images
    stockQty
    isActive
    isSponsored
    createdAt
  }
}
''';

  static const String _updateProductMutation = r'''
mutation UpdateProduct($input: UpdateProductInput!) {
  updateProduct(input: $input) {
    id
    ownerSub
    storeId
    categoryId
    subcategoryId
    title
    description
    priceNAD
    images
    stockQty
    isActive
    isSponsored
    createdAt
  }
}
''';

  static const String _deleteProductMutation = r'''
mutation DeleteProduct($input: DeleteProductInput!) {
  deleteProduct(input: $input) {
    id
  }
}
''';

  @override
  Future<ProductPage> fetchProducts({
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    ProductSortOption sort = ProductSortOption.newest,
    bool sponsoredOnly = false,
    int limit = 20,
    String? nextToken,
  }) async {
    final filter = <String, dynamic>{
      'isActive': {'eq': true},
    };
    if (sponsoredOnly) {
      filter['isSponsored'] = {'eq': true};
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      filter['categoryId'] = {'eq': categoryId};
    }
    if (subcategoryId != null && subcategoryId.isNotEmpty) {
      filter['subcategoryId'] = {'eq': subcategoryId};
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      filter['title'] = {'contains': searchQuery.trim()};
    }

    final request = GraphQLRequest<String>(
      document: _listProductsQuery,
      variables: {
        'filter': filter,
        'limit': limit,
        'nextToken': nextToken,
      },
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['listProducts'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    final mapped = items
        .whereType<Map<String, dynamic>>()
        .map(_parseProduct)
        .whereType<MarketplaceProduct>()
        .where(
          (product) =>
              product.isActive &&
              product.store != null &&
              product.store!.status == MarketplaceStoreStatus.approved,
        )
        .toList();
    final hydrated = await _hydrateImageUrls(mapped);

    _sortProducts(hydrated, sort);
    return ProductPage(
      items: hydrated,
      nextToken: root['nextToken'] as String?,
    );
  }

  @override
  Future<MarketplaceProduct?> getProductById(String productId) async {
    final request = GraphQLRequest<String>(
      document: _getProductQuery,
      variables: {'id': productId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final raw = parsed['getProduct'];
    if (raw is! Map<String, dynamic>) return null;
    final product = _parseProduct(raw);
    if (product == null) return null;
    if (!product.isActive) return null;
    if (product.store == null) return null;
    if (product.store!.status != MarketplaceStoreStatus.approved) return null;
    return (await _hydrateImageUrls([product])).first;
  }

  @override
  Future<List<MarketplaceProduct>> fetchProductsByStore(String storeId) async {
    final request = GraphQLRequest<String>(
      document: _productsByStoreQuery,
      variables: {'storeId': storeId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['productsByStore'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    final mapped = items
        .whereType<Map<String, dynamic>>()
        .map(_parseProduct)
        .whereType<MarketplaceProduct>()
        .toList();
    final hydrated = await _hydrateImageUrls(mapped);
    _sortProducts(hydrated, ProductSortOption.newest);
    return hydrated;
  }

  @override
  Future<MarketplaceStore?> getStoreById(String storeId) async {
    final request = GraphQLRequest<String>(
      document: _getStoreQuery,
      variables: {'id': storeId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final raw = parsed['getStore'];
    if (raw is! Map<String, dynamic>) return null;
    final store = MarketplaceStore(
      id: (raw['id'] as String?) ?? '',
      ownerSub: (raw['ownerSub'] as String?) ?? '',
      name: (raw['name'] as String?) ?? '',
      phone: raw['phone'] as String?,
      city: (raw['city'] as String?) ?? '',
      address: (raw['address'] as String?) ?? '',
      logoKey: raw['logoKey'] as String?,
      status: marketplaceStoreStatusFromApi(raw['status'] as String?),
      createdAt:
          DateTime.tryParse((raw['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
    if (store.status != MarketplaceStoreStatus.approved) return null;
    return store;
  }

  @override
  Future<MarketplaceProduct> upsertProduct(ProductUpsertInput input) async {
    final user = await Amplify.Auth.getCurrentUser();
    final payload = <String, dynamic>{
      if (input.id != null) 'id': input.id,
      if (input.id == null) 'ownerSub': user.userId,
      'storeId': input.storeId,
      'categoryId': input.categoryId,
      'subcategoryId': input.subcategoryId,
      'title': input.title,
      'description': input.description,
      'priceNAD': input.priceNAD,
      'images': input.images,
      'stockQty': input.stockQty,
      'isActive': input.isActive,
      'isSponsored': input.isSponsored,
    };
    final request = GraphQLRequest<String>(
      document: input.id == null ? _createProductMutation : _updateProductMutation,
      variables: {'input': payload},
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final key = input.id == null ? 'createProduct' : 'updateProduct';
    final raw = (parsed[key] ?? {}) as Map<String, dynamic>;
    return MarketplaceProduct(
      id: (raw['id'] as String?) ?? '',
      ownerSub: (raw['ownerSub'] as String?) ?? user.userId,
      storeId: (raw['storeId'] as String?) ?? input.storeId,
      categoryId: (raw['categoryId'] as String?) ?? input.categoryId,
      subcategoryId: raw['subcategoryId'] as String?,
      title: (raw['title'] as String?) ?? input.title,
      description: raw['description'] as String?,
      priceNAD: (raw['priceNAD'] as num?)?.toDouble() ?? input.priceNAD,
      images: (raw['images'] as List<dynamic>? ?? input.images).map((e) => e.toString()).toList(),
      stockQty: (raw['stockQty'] as num?)?.toInt() ?? input.stockQty,
      isActive: (raw['isActive'] as bool?) ?? input.isActive,
      isSponsored: (raw['isSponsored'] as bool?) ?? input.isSponsored,
      createdAt:
          DateTime.tryParse((raw['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      store: null,
    );
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final request = GraphQLRequest<String>(
      document: _deleteProductMutation,
      variables: {
        'input': {'id': productId},
      },
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
  }

  MarketplaceProduct? _parseProduct(Map<String, dynamic> item) {
    final id = item['id'] as String?;
    if (id == null || id.isEmpty) return null;
    final storeRaw = item['store'];
    MarketplaceStore? store;
    if (storeRaw is Map<String, dynamic>) {
      store = MarketplaceStore(
        id: (storeRaw['id'] as String?) ?? '',
        ownerSub: (storeRaw['ownerSub'] as String?) ?? '',
        name: (storeRaw['name'] as String?) ?? '',
        phone: storeRaw['phone'] as String?,
        city: (storeRaw['city'] as String?) ?? '',
        address: (storeRaw['address'] as String?) ?? '',
        logoKey: storeRaw['logoKey'] as String?,
        status: marketplaceStoreStatusFromApi(storeRaw['status'] as String?),
        createdAt:
            DateTime.tryParse((storeRaw['createdAt'] as String?) ?? '')?.toLocal() ??
            DateTime.now(),
      );
    }

    return MarketplaceProduct(
      id: id,
      ownerSub: (item['ownerSub'] as String?) ?? '',
      storeId: (item['storeId'] as String?) ?? '',
      categoryId: (item['categoryId'] as String?) ?? '',
      subcategoryId: item['subcategoryId'] as String?,
      title: (item['title'] as String?) ?? '',
      description: item['description'] as String?,
      priceNAD: (item['priceNAD'] as num?)?.toDouble() ?? 0,
      images: (item['images'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
      stockQty: (item['stockQty'] as num?)?.toInt() ?? 0,
      isActive: (item['isActive'] as bool?) ?? false,
      isSponsored: (item['isSponsored'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((item['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
      store: store,
    );
  }

  void _sortProducts(List<MarketplaceProduct> items, ProductSortOption sort) {
    items.sort((a, b) {
      if (a.isSponsored != b.isSponsored) {
        return a.isSponsored ? -1 : 1;
      }
      switch (sort) {
        case ProductSortOption.newest:
          return b.createdAt.compareTo(a.createdAt);
        case ProductSortOption.priceLowToHigh:
          return a.priceNAD.compareTo(b.priceNAD);
      }
    });
  }

  Future<List<MarketplaceProduct>> _hydrateImageUrls(
    List<MarketplaceProduct> products,
  ) async {
    final hydrated = <MarketplaceProduct>[];
    for (final product in products) {
      final resolvedImages = <String>[];
      for (final image in product.images) {
        resolvedImages.add(await _resolveImageUrl(image));
      }
      hydrated.add(product.copyWith(images: resolvedImages));
    }
    return hydrated;
  }

  Future<String> _resolveImageUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    try {
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(trimmed),
      ).result;
      return result.url.toString();
    } catch (_) {
      return trimmed;
    }
  }
}
