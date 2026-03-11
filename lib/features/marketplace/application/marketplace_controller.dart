import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/marketplace/application/marketplace_state.dart';
import 'package:vektorkite/features/marketplace/data/appsync_product_repository.dart';
import 'package:vektorkite/features/marketplace/data/appsync_taxonomy_repository.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/features/marketplace/domain/product_repository.dart';
import 'package:vektorkite/features/marketplace/domain/taxonomy_repository.dart';

final marketplaceProductRepositoryProvider = Provider<ProductRepository>(
  (ref) => const AppSyncProductRepository(),
);

final marketplaceTaxonomyRepositoryProvider = Provider<TaxonomyRepository>(
  (ref) => const AppSyncTaxonomyRepository(),
);

final marketplaceControllerProvider =
    StateNotifierProvider<MarketplaceController, MarketplaceState>(
      (ref) => MarketplaceController(
        productRepository: ref.read(marketplaceProductRepositoryProvider),
        taxonomyRepository: ref.read(marketplaceTaxonomyRepositoryProvider),
      ),
    );

class MarketplaceController extends StateNotifier<MarketplaceState> {
  MarketplaceController({
    required ProductRepository productRepository,
    required TaxonomyRepository taxonomyRepository,
  }) : _productRepository = productRepository,
       _taxonomyRepository = taxonomyRepository,
       super(const MarketplaceState());

  final ProductRepository _productRepository;
  final TaxonomyRepository _taxonomyRepository;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _taxonomyRepository.fetchCategories();
      final featured = await _productRepository.fetchProducts(
        sponsoredOnly: true,
        limit: 12,
      );
      final products = await _productRepository.fetchProducts(limit: 20);
      state = state.copyWith(
        isLoading: false,
        categories: categories,
        featuredProducts: featured.items,
        products: products.items,
        nextToken: products.nextToken,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load marketplace',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load marketplace products.',
        ),
      );
    }
  }

  Future<void> applyFilters({
    String? categoryId,
    String? subcategoryId,
    ProductSortOption? sort,
    String? searchQuery,
  }) async {
    final selectedCategoryId = categoryId ?? state.selectedCategoryId;
    final selectedSubcategoryId = subcategoryId ?? state.selectedSubcategoryId;
    final selectedSort = sort ?? state.sort;
    final selectedSearch = searchQuery ?? state.searchQuery;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      selectedCategoryId: selectedCategoryId,
      selectedSubcategoryId: selectedSubcategoryId,
      sort: selectedSort,
      searchQuery: selectedSearch,
    );

    try {
      var subcategories = state.subcategories;
      if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
        subcategories = await _taxonomyRepository.fetchSubcategories(selectedCategoryId);
      } else {
        subcategories = const [];
      }

      final products = await _productRepository.fetchProducts(
        categoryId: selectedCategoryId,
        subcategoryId: selectedSubcategoryId,
        searchQuery: selectedSearch,
        sort: selectedSort,
        limit: 20,
      );
      state = state.copyWith(
        isLoading: false,
        products: products.items,
        nextToken: products.nextToken,
        subcategories: subcategories,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to apply marketplace filters',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to filter marketplace products.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final token = state.nextToken;
    if (token == null || token.isEmpty || state.isLoadingMore || state.isLoading) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = await _productRepository.fetchProducts(
        categoryId: state.selectedCategoryId,
        subcategoryId: state.selectedSubcategoryId,
        searchQuery: state.searchQuery,
        sort: state.sort,
        limit: 20,
        nextToken: token,
      );
      state = state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...nextPage.items],
        nextToken: nextPage.nextToken,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load more marketplace products',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load more products.',
        ),
      );
    }
  }

  Future<MarketplaceProduct?> getProductById(String productId) {
    return _productRepository.getProductById(productId);
  }

  Future<MarketplaceStore?> getStoreById(String storeId) {
    return _productRepository.getStoreById(storeId);
  }

  Future<List<MarketplaceProduct>> getProductsByStore(String storeId) {
    return _productRepository.fetchProductsByStore(storeId);
  }
}
