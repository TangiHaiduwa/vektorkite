import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/marketplace/application/marketplace_controller.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() =>
      _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(symbol: 'NAD ');

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(marketplaceControllerProvider.notifier).initialize(),
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final remaining = _scrollController.position.maxScrollExtent -
        _scrollController.position.pixels;
    if (remaining < 320) {
      ref.read(marketplaceControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceControllerProvider);
    final controller = ref.read(marketplaceControllerProvider.notifier);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.initialize,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 120),
          children: [
            _Hero(
              featuredCount: state.featuredProducts.length,
              totalCount: state.products.length,
              onBrowseAll: () => context.push(RoutePaths.marketplaceCategory),
            ),
            const SizedBox(height: 12),
            _Panel(
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) =>
                        controller.applyFilters(searchQuery: value),
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          controller.applyFilters(searchQuery: '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ),
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
                        child: Text('Price: Low to High'),
                      ),
                    ],
                    onChanged: (sort) {
                      if (sort == null) return;
                      controller.applyFilters(sort: sort);
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(RoutePaths.marketplaceCategory),
                      icon: const Icon(Icons.tune_outlined),
                      label: const Text('Open Advanced Filters'),
                    ),
                  ),
                ],
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              AppInlineError(
                message: state.errorMessage!,
                onRetry: controller.initialize,
              ),
            ],
            if (state.isLoading && state.products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Sponsored Picks',
                subtitle: 'Featured products from approved stores',
                icon: Icons.workspace_premium_outlined,
              ),
              const SizedBox(height: 8),
              _SponsoredStrip(
                products: state.featuredProducts,
                currency: _currency,
                onTap: (productId) => context.push(
                  RoutePaths.marketplaceProductDetail
                      .replaceFirst(':productId', productId),
                ),
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Categories',
                subtitle: 'Browse by product type',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 8),
              _Panel(
                child: state.categories.isEmpty
                    ? const Text(
                        'No categories available yet.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.categories
                            .map(
                              (category) => FilterChip(
                                selected: category.id == state.selectedCategoryId,
                                label: Text(category.name),
                                onSelected: (_) =>
                                    controller.applyFilters(categoryId: category.id),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'All Products',
                subtitle: 'Current marketplace listings',
                icon: Icons.grid_view_rounded,
              ),
              const SizedBox(height: 8),
              if (state.products.isEmpty)
                const _Panel(
                  child: ListTile(
                    title: Text('No products available yet.'),
                    subtitle: Text('Check back soon for new listings.'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.70,
                  ),
                  itemBuilder: (context, index) {
                    final product = state.products[index];
                    return _ProductTile(
                      product: product,
                      currency: _currency,
                      onTap: () => context.push(
                        RoutePaths.marketplaceProductDetail
                            .replaceFirst(':productId', product.id),
                      ),
                    );
                  },
                ),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.featuredCount,
    required this.totalCount,
    required this.onBrowseAll,
  });

  final int featuredCount;
  final int totalCount;
  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF4FF), Color(0xFFE8FBF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marketplace',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Discover products from trusted providers and local stores.',
            style: TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _MetricPill(
                text: '$featuredCount sponsored',
                bg: const Color(0xFFE0F2FE),
                fg: const Color(0xFF0C4A6E),
              ),
              _MetricPill(
                text: '$totalCount listed',
                bg: const Color(0xFFDCFCE7),
                fg: const Color(0xFF14532D),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: onBrowseAll,
              icon: const Icon(Icons.apps_outlined),
              label: const Text('Browse All Categories'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0F766E)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SponsoredStrip extends StatelessWidget {
  const _SponsoredStrip({
    required this.products,
    required this.currency,
    required this.onTap,
  });

  final List<MarketplaceProduct> products;
  final NumberFormat currency;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _Panel(
        child: Text(
          'No sponsored products available right now.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final product = products[index];
          final image = product.images.isEmpty ? null : product.images.first;
          return SizedBox(
            width: 250,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onTap(product.id),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: image == null
                          ? const ColoredBox(color: Color(0xFFEAF0F5))
                          : Image.network(image, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.68),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: _MetricPill(
                      text: 'Sponsored',
                      bg: Color(0xFFFFF2CC),
                      fg: Color(0xFF7A4A00),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Text(
                      '${product.title}\n${currency.format(product.priceNAD)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.currency,
    required this.onTap,
  });

  final MarketplaceProduct product;
  final NumberFormat currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = product.images.isEmpty ? null : product.images.first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 9,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: image == null
                    ? const ColoredBox(color: Color(0xFFEAF0F5))
                    : Image.network(
                        image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(currency.format(product.priceNAD)),
                  const SizedBox(height: 3),
                  Text(
                    product.store?.name ?? 'Store',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.text,
    required this.bg,
    required this.fg,
  });

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
