import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_taxonomy.dart';

class MarketplaceState {
  const MarketplaceState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.featuredProducts = const [],
    this.products = const [],
    this.categories = const [],
    this.subcategories = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedSubcategoryId,
    this.sort = ProductSortOption.newest,
    this.nextToken,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<MarketplaceProduct> featuredProducts;
  final List<MarketplaceProduct> products;
  final List<MarketplaceCategory> categories;
  final List<MarketplaceSubcategory> subcategories;
  final String searchQuery;
  final String? selectedCategoryId;
  final String? selectedSubcategoryId;
  final ProductSortOption sort;
  final String? nextToken;

  MarketplaceState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    List<MarketplaceProduct>? featuredProducts,
    List<MarketplaceProduct>? products,
    List<MarketplaceCategory>? categories,
    List<MarketplaceSubcategory>? subcategories,
    String? searchQuery,
    String? selectedCategoryId,
    String? selectedSubcategoryId,
    ProductSortOption? sort,
    String? nextToken,
    bool clearError = false,
  }) {
    return MarketplaceState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      featuredProducts: featuredProducts ?? this.featuredProducts,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedSubcategoryId: selectedSubcategoryId ?? this.selectedSubcategoryId,
      sort: sort ?? this.sort,
      nextToken: nextToken ?? this.nextToken,
    );
  }
}
