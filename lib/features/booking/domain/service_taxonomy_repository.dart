import 'package:vektorkite/features/booking/domain/service_subcategory.dart';
import 'package:vektorkite/features/home/domain/category_item.dart';

abstract class ServiceTaxonomyRepository {
  Future<List<CategoryItem>> fetchServiceCategories();
  Future<List<ServiceSubcategory>> fetchSubcategoriesByCategory(
    String categoryId,
  );
}
