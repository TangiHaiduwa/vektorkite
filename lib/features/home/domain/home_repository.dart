import 'package:vektorkite/features/home/domain/category_item.dart';
import 'package:vektorkite/features/home/domain/home_product_item.dart';
import 'package:vektorkite/features/home/domain/service_provider.dart';

abstract class HomeRepository {
  Future<List<CategoryItem>> fetchCategories();
  Future<List<ServiceProvider>> fetchProviders();
  Future<List<HomeProductItem>> fetchSponsoredProducts();
}
