import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/marketplace/application/marketplace_controller.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class MarketplaceCategoryScreen extends ConsumerStatefulWidget {
  const MarketplaceCategoryScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  ConsumerState<MarketplaceCategoryScreen> createState() =>
      _MarketplaceCategoryScreenState();
}

class _MarketplaceCategoryScreenState extends ConsumerState<MarketplaceCategoryScreen> {
  final _currency = NumberFormat.currency(symbol: 'NAD ');
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final controller = ref.read(marketplaceControllerProvider.notifier);
      final current = ref.read(marketplaceControllerProvider);
      if (current.categories.isEmpty && current.products.isEmpty) {
        await controller.initialize();
      }
      if (widget.initialCategoryId != null) {
        await controller.applyFilters(categoryId: widget.initialCategoryId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceControllerProvider);
    final controller = ref.read(marketplaceControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const AppBackButton() : null,
        title: const Text('Browse Products'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFE),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => controller.applyFilters(searchQuery: value),
              decoration: const InputDecoration(
                labelText: 'Search by title',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: state.selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: state.categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              controller.applyFilters(categoryId: value, subcategoryId: '');
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: state.selectedSubcategoryId,
            decoration: const InputDecoration(labelText: 'Subcategory'),
            items: [
              const DropdownMenuItem<String>(
                value: '',
                child: Text('All subcategories'),
              ),
              ...state.subcategories.map(
                (subcategory) => DropdownMenuItem<String>(
                  value: subcategory.id,
                  child: Text(subcategory.name),
                ),
              ),
            ],
            onChanged: (value) {
              controller.applyFilters(subcategoryId: value == '' ? null : value);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<ProductSortOption>(
            initialValue: state.sort,
            decoration: const InputDecoration(labelText: 'Sort'),
            items: const [
              DropdownMenuItem(
                value: ProductSortOption.newest,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: ProductSortOption.priceLowToHigh,
                child: Text('Price: low to high'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              controller.applyFilters(sort: value);
            },
          ),
          const SizedBox(height: 14),
          if (state.errorMessage != null)
            AppInlineError(message: state.errorMessage!),
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.products.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No products found for this filter.'),
              ),
            )
          else
            ...state.products.map(
              (product) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  onTap: () => context.push(
                    RoutePaths.marketplaceProductDetail.replaceFirst(':productId', product.id),
                  ),
                  title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${_currency.format(product.priceNAD)} | ${product.store?.name ?? 'Store'}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
