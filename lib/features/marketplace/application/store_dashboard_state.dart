import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_taxonomy.dart';

class StoreDashboardState {
  const StoreDashboardState({
    this.isLoading = false,
    this.isSaving = false,
    this.isProvider = false,
    this.errorMessage,
    this.store,
    this.products = const [],
    this.categories = const [],
    this.subcategories = const [],
  });

  final bool isLoading;
  final bool isSaving;
  final bool isProvider;
  final String? errorMessage;
  final MarketplaceStore? store;
  final List<MarketplaceProduct> products;
  final List<MarketplaceCategory> categories;
  final List<MarketplaceSubcategory> subcategories;

  StoreDashboardState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isProvider,
    String? errorMessage,
    MarketplaceStore? store,
    List<MarketplaceProduct>? products,
    List<MarketplaceCategory>? categories,
    List<MarketplaceSubcategory>? subcategories,
    bool clearError = false,
  }) {
    return StoreDashboardState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isProvider: isProvider ?? this.isProvider,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      store: store ?? this.store,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
    );
  }
}
