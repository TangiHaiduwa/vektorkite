import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';

class MarketplaceProduct {
  const MarketplaceProduct({
    required this.id,
    required this.ownerSub,
    required this.storeId,
    required this.categoryId,
    required this.subcategoryId,
    required this.title,
    required this.description,
    required this.priceNAD,
    required this.images,
    required this.stockQty,
    required this.isActive,
    required this.isSponsored,
    required this.createdAt,
    required this.store,
  });

  final String id;
  final String ownerSub;
  final String storeId;
  final String categoryId;
  final String? subcategoryId;
  final String title;
  final String? description;
  final double priceNAD;
  final List<String> images;
  final int stockQty;
  final bool isActive;
  final bool isSponsored;
  final DateTime createdAt;
  final MarketplaceStore? store;

  MarketplaceProduct copyWith({
    String? id,
    String? ownerSub,
    String? storeId,
    String? categoryId,
    String? subcategoryId,
    String? title,
    String? description,
    double? priceNAD,
    List<String>? images,
    int? stockQty,
    bool? isActive,
    bool? isSponsored,
    DateTime? createdAt,
    MarketplaceStore? store,
  }) {
    return MarketplaceProduct(
      id: id ?? this.id,
      ownerSub: ownerSub ?? this.ownerSub,
      storeId: storeId ?? this.storeId,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      priceNAD: priceNAD ?? this.priceNAD,
      images: images ?? this.images,
      stockQty: stockQty ?? this.stockQty,
      isActive: isActive ?? this.isActive,
      isSponsored: isSponsored ?? this.isSponsored,
      createdAt: createdAt ?? this.createdAt,
      store: store ?? this.store,
    );
  }
}

class ProductUpsertInput {
  const ProductUpsertInput({
    this.id,
    required this.storeId,
    required this.categoryId,
    required this.subcategoryId,
    required this.title,
    required this.description,
    required this.priceNAD,
    required this.images,
    required this.stockQty,
    required this.isActive,
    required this.isSponsored,
  });

  final String? id;
  final String storeId;
  final String categoryId;
  final String? subcategoryId;
  final String title;
  final String? description;
  final double priceNAD;
  final List<String> images;
  final int stockQty;
  final bool isActive;
  final bool isSponsored;
}

enum ProductSortOption {
  newest,
  priceLowToHigh,
}

class ProductPage {
  const ProductPage({
    required this.items,
    required this.nextToken,
  });

  final List<MarketplaceProduct> items;
  final String? nextToken;
}
