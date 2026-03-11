import 'package:vektorkite/features/marketplace/domain/marketplace_taxonomy.dart';

abstract class TaxonomyRepository {
  Future<List<MarketplaceCategory>> fetchCategories();
  Future<List<MarketplaceSubcategory>> fetchSubcategories(String categoryId);
}
