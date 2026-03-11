import 'package:vektorkite/features/home/domain/category_item.dart';
import 'package:vektorkite/features/home/domain/home_product_item.dart';
import 'package:vektorkite/features/home/domain/home_repository.dart';
import 'package:vektorkite/features/home/domain/service_provider.dart';

class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  @override
  Future<List<CategoryItem>> fetchCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      CategoryItem(id: 'cleaning', name: 'Cleaning', icon: '🧹'),
      CategoryItem(id: 'plumbing', name: 'Plumbing', icon: '🔧'),
      CategoryItem(id: 'electrical', name: 'Electrical', icon: '💡'),
      CategoryItem(id: 'it_support', name: 'IT Support', icon: '💻'),
    ];
  }

  @override
  Future<List<ServiceProvider>> fetchProviders() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const [
      ServiceProvider(
        id: 'p1',
        displayName: 'NamClean Pro',
        categoryIds: ['cleaning'],
        subcategoryNames: ['Regular House Cleaning', 'Deep Cleaning'],
        rating: 4.8,
        reviewCount: 132,
        bio: 'Residential and office deep cleaning services.',
        serviceArea: 'Windhoek',
      ),
      ServiceProvider(
        id: 'p2',
        displayName: 'PipeFix Namibia',
        categoryIds: ['plumbing'],
        subcategoryNames: ['Drainage & Wastewater', 'Toilet Services'],
        rating: 4.6,
        reviewCount: 88,
        bio: 'Leak repair, geyser installation, and drainage solutions.',
        serviceArea: 'Windhoek, Okahandja',
      ),
      ServiceProvider(
        id: 'p3',
        displayName: 'VoltCare Electric',
        categoryIds: ['electrical'],
        subcategoryNames: ['Power Supply & Wiring', 'Lighting Services'],
        rating: 4.7,
        reviewCount: 105,
        bio: 'Certified electricians for home and business callouts.',
        serviceArea: 'Swakopmund',
      ),
      ServiceProvider(
        id: 'p4',
        displayName: 'TechNest Assist',
        categoryIds: ['it_support'],
        subcategoryNames: ['Computer & Laptop Support', 'Cloud & Remote Work'],
        rating: 4.9,
        reviewCount: 63,
        bio: 'Network setup, troubleshooting, and device support.',
        serviceArea: 'Windhoek, Walvis Bay',
      ),
      ServiceProvider(
        id: 'p5',
        displayName: 'Handy Hub',
        categoryIds: ['cleaning', 'plumbing'],
        subcategoryNames: ['General Repairs', 'Kitchen Plumbing'],
        rating: 4.5,
        reviewCount: 49,
        bio: 'Multi-service team for urgent household jobs.',
        serviceArea: 'Rehoboth',
      ),
    ];
  }

  @override
  Future<List<HomeProductItem>> fetchSponsoredProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      HomeProductItem(
        id: 'mp1',
        title: 'Window Cleaning Kit',
        priceNad: 299,
        imageUrl: null,
        storeName: 'NamClean Store',
      ),
      HomeProductItem(
        id: 'mp2',
        title: 'Plumbing Repair Set',
        priceNad: 499,
        imageUrl: null,
        storeName: 'PipeFix Supplies',
      ),
    ];
  }
}
