import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/marketplace/application/marketplace_controller.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';

class StoreProfileScreen extends ConsumerWidget {
  const StoreProfileScreen({
    super.key,
    required this.storeId,
  });

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(marketplaceControllerProvider.notifier);
    final currency = NumberFormat.currency(symbol: 'NAD ');

    return FutureBuilder<({MarketplaceStore? store, List<MarketplaceProduct> products})>(
      future: () async {
        final store = await controller.getStoreById(storeId);
        if (store == null) {
          return (store: null, products: const <MarketplaceProduct>[]);
        }
        final products = await controller.getProductsByStore(storeId);
        return (
          store: store,
          products: products.where((product) => product.isActive).toList(),
        );
      }(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final store = data?.store;
        final products = data?.products ?? const <MarketplaceProduct>[];

        return Scaffold(
          appBar: AppBar(
            leading: Navigator.canPop(context) ? const AppBackButton() : null,
            title: const Text('Store'),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : store == null
                  ? const Center(child: Text('Store not found.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        _StoreHeader(store: store, activeCount: products.length),
                        const SizedBox(height: 14),
                        _InfoPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${store.city}, ${store.address}',
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                              if (store.phone != null && store.phone!.trim().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      store.phone!,
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFF0F766E)),
                            const SizedBox(width: 8),
                            Text(
                              'Products',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Available products from this store',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        if (products.isEmpty)
                          const _InfoPanel(
                            child: Text('No active products available.'),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              final image = product.images.isEmpty ? null : product.images.first;
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => context.push(
                                  RoutePaths.marketplaceProductDetail
                                      .replaceFirst(':productId', product.id),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x10000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                          child: image == null
                                              ? const ColoredBox(
                                                  color: Color(0xFFEAF0F5),
                                                  child: Center(
                                                    child: Icon(Icons.image_outlined),
                                                  ),
                                                )
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
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              currency.format(product.priceNAD),
                                              style: const TextStyle(
                                                color: Color(0xFF0F766E),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
        );
      },
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.store,
    required this.activeCount,
  });

  final MarketplaceStore store;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF7FF), Color(0xFFF2FBF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.storefront_outlined, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  store.city,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                _CountPill(label: '$activeCount active products'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F6F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F766E),
        ),
      ),
    );
  }
}
