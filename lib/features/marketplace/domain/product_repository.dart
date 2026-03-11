import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';

abstract class ProductRepository {
  Future<ProductPage> fetchProducts({
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    ProductSortOption sort = ProductSortOption.newest,
    bool sponsoredOnly = false,
    int limit = 20,
    String? nextToken,
  });

  Future<MarketplaceProduct?> getProductById(String productId);

  Future<List<MarketplaceProduct>> fetchProductsByStore(String storeId);
  Future<MarketplaceStore?> getStoreById(String storeId);

  Future<MarketplaceProduct> upsertProduct(ProductUpsertInput input);

  Future<void> deleteProduct(String productId);
}
