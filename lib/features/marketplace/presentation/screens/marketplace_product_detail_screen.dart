import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/marketplace/application/marketplace_controller.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';

class MarketplaceProductDetailScreen extends ConsumerWidget {
  const MarketplaceProductDetailScreen({
    super.key,
    required this.productId,
  });

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(marketplaceControllerProvider.notifier);
    final currency = NumberFormat.currency(symbol: 'NAD ');

    return FutureBuilder<MarketplaceProduct?>(
      future: controller.getProductById(productId),
      builder: (context, snapshot) {
        final product = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            leading: Navigator.canPop(context) ? const AppBackButton() : null,
            title: const Text('Product'),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : product == null
                  ? const Center(child: Text('Product not found.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                      children: [
                        _ImageCarousel(images: product.images),
                        const SizedBox(height: 14),
                        _InfoPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currency.format(product.priceNAD),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F766E),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                product.description ?? 'No description provided.',
                                style: const TextStyle(color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoPanel(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF7F4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_outlined),
                            ),
                            title: Text(product.store?.name ?? 'Store'),
                            subtitle: Text(
                              '${product.store?.city ?? ''}\n${product.store?.address ?? ''}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: product.store == null
                                ? null
                                : () => context.push(
                                      RoutePaths.marketplaceStoreProfile.replaceFirst(
                                        ':storeId',
                                        product.store!.id,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoPanel(
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.inventory_2_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Stock',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      product.stockQty > 0
                                          ? '${product.stockQty} available'
                                          : 'Out of stock',
                                      style: const TextStyle(color: Color(0xFF475569)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contact Seller will be connected next.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Contact Seller'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              RoutePaths.bookingCreate,
                              extra: {
                                'categoryId': product.categoryId,
                                'subcategoryId': product.subcategoryId,
                                'description': 'Related service for ${product.title}',
                              },
                            ),
                            icon: const Icon(Icons.build_circle_outlined),
                            label: const Text('Book Related Service'),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.images});
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: PageView(
        children: images.isEmpty
            ? const [ColoredBox(color: Color(0xFFE9EEF5))]
            : images
                .map((image) => Image.network(image, fit: BoxFit.cover))
                .toList(),
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
