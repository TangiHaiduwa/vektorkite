import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/home/application/home_controller.dart';
import 'package:vektorkite/features/home/domain/home_product_item.dart';
import 'package:vektorkite/features/home/domain/location_permission_service.dart';
import 'package:vektorkite/features/home/domain/service_provider.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _maxRateController = TextEditingController();
  final _currency = NumberFormat.currency(symbol: 'NAD ');

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(providerBrowseControllerProvider.notifier).initialize(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _maxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerBrowseControllerProvider);
    final controller = ref.read(providerBrowseControllerProvider.notifier);
    final locationBanner = switch (state.locationStatus) {
      LocationPermissionStatus.granted => null,
      LocationPermissionStatus.denied => 'Location denied. Enable for nearby recommendations.',
      LocationPermissionStatus.deniedForever =>
        'Location permanently denied. Enable in app settings.',
      LocationPermissionStatus.serviceDisabled => 'Location services are disabled.',
      LocationPermissionStatus.unknown => 'Share location for better nearby matching.',
    };

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.initialize,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
          children: [
            _Hero(
              featuredCount: state.featuredProviders.length,
              sponsoredCount: state.sponsoredProducts.length,
              onBookTap: () => context.push(RoutePaths.bookingCreate),
              onMarketplaceTap: () => context.push(RoutePaths.marketplace),
            ),
            const SizedBox(height: 14),
            _CardSurface(
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: controller.updateSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search providers, services, or skills',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        onPressed: () {
                          _searchController.clear();
                          controller.updateSearchQuery('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          initialValue: state.minRatingFilter,
                          decoration: const InputDecoration(labelText: 'Min rating'),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('Any')),
                            DropdownMenuItem(value: 3, child: Text('3.0+')),
                            DropdownMenuItem(value: 4, child: Text('4.0+')),
                            DropdownMenuItem(value: 4.5, child: Text('4.5+')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            controller.setMinRatingFilter(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _maxRateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onSubmitted: (value) => controller.setMaxHourlyRateFilter(
                            double.tryParse(value.trim()),
                          ),
                          decoration: InputDecoration(
                            labelText: 'Max rate (NAD)',
                            suffixIcon: IconButton(
                              onPressed: () {
                                _maxRateController.clear();
                                controller.setMaxHourlyRateFilter(null);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (locationBanner != null) ...[
              const SizedBox(height: 12),
              _CardSurface(
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(locationBanner)),
                    TextButton(
                      onPressed: controller.requestLocationPermission,
                      child: const Text('Allow'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            _Section(
              icon: Icons.category_outlined,
              title: 'Categories',
              subtitle: 'Choose what you need',
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    final selected = category.id == state.selectedCategoryId;
                    return FilterChip(
                      selected: selected,
                      onSelected: (_) => controller.toggleCategory(category.id),
                      label: Text(category.name),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.workspace_premium_outlined,
              title: 'Featured Providers',
              subtitle: 'Top professionals',
              child: _ProviderCards(
                providers: state.featuredProviders,
                emptyText: 'No featured providers yet.',
                onTap: (id) =>
                    context.push(RoutePaths.providerProfile.replaceFirst(':providerId', id)),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.local_offer_outlined,
              title: 'Sponsored Products',
              subtitle: 'Promoted marketplace picks',
              child: _ProductCards(
                items: state.sponsoredProducts,
                currency: _currency,
                onTap: (id) => context.push(
                  RoutePaths.marketplaceProductDetail.replaceFirst(':productId', id),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.near_me_outlined,
              title: 'Popular Near You',
              subtitle: 'Closest options first',
              child: _ProviderList(
                providers: state.nearbyProviders,
                emptyText: 'No nearby providers for current filters.',
                onTap: (id) =>
                    context.push(RoutePaths.providerProfile.replaceFirst(':providerId', id)),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              icon: Icons.grid_view_rounded,
              title: 'Browse Services',
              subtitle: 'All matching providers',
              child: _ProviderList(
                providers: state.filteredProviders,
                emptyText: 'No providers found.',
                onTap: (id) =>
                    context.push(RoutePaths.providerProfile.replaceFirst(':providerId', id)),
              ),
            ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: 16),
              AppInlineError(message: state.errorMessage!, onRetry: controller.initialize),
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
    required this.sponsoredCount,
    required this.onBookTap,
    required this.onMarketplaceTap,
  });
  final int featuredCount;
  final int sponsoredCount;
  final VoidCallback onBookTap;
  final VoidCallback onMarketplaceTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF7FF), Color(0xFFEFFBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Find help fast,\nwith confidence.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Trusted providers and quality products in one place.', style: TextStyle(color: Color(0xFF475569))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          _Pill(label: '$featuredCount Featured', color: const Color(0xFFE0F2FE), textColor: const Color(0xFF0C4A6E)),
          _Pill(label: '$sponsoredCount Sponsored', color: const Color(0xFFDCFCE7), textColor: const Color(0xFF14532D)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: onBookTap, icon: const Icon(Icons.calendar_month_outlined), label: const Text('Book Service'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonalIcon(onPressed: onMarketplaceTap, icon: const Icon(Icons.storefront_outlined), label: const Text('Marketplace'))),
        ]),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.subtitle, required this.child});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 18, color: const Color(0xFF0F766E)),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 2),
      Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      const SizedBox(height: 10),
      _CardSurface(child: child),
    ]);
  }
}

class _ProviderCards extends StatelessWidget {
  const _ProviderCards({required this.providers, required this.emptyText, required this.onTap});
  final List<ServiceProvider> providers;
  final String emptyText;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return Text(emptyText);
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: providers.take(8).length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = providers[i];
          return SizedBox(
            width: 220,
            child: InkWell(
              onTap: () => onTap(p.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(p.subcategoryNames.take(2).join(', '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B))),
                  const Spacer(),
                  Text('Rating ${p.rating.toStringAsFixed(1)} (${p.reviewCount})'),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductCards extends StatelessWidget {
  const _ProductCards({required this.items, required this.currency, required this.onTap});
  final List<HomeProductItem> items;
  final NumberFormat currency;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('No sponsored products right now.');
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final p = items[i];
          return SizedBox(
            width: 180,
            child: InkWell(
              onTap: () => onTap(p.id),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: p.imageUrl == null
                          ? const ColoredBox(color: Color(0xFFEAF0F5), child: Center(child: Icon(Icons.image_outlined)))
                          : Image.network(p.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(currency.format(p.priceNad), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProviderList extends StatelessWidget {
  const _ProviderList({required this.providers, required this.emptyText, required this.onTap});
  final List<ServiceProvider> providers;
  final String emptyText;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return Text(emptyText);
    return Column(
      children: providers.take(8).map((p) {
        final rateText = p.hourlyRate == null ? 'Rate unavailable' : 'From NAD ${p.hourlyRate!.toStringAsFixed(0)}/hr';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFEAF7F4), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.handyman_outlined, color: Color(0xFF0F766E)),
            ),
            title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              '${p.subcategoryNames.take(2).join(', ')}\nRating ${p.rating.toStringAsFixed(1)} (${p.reviewCount}) - $rateText',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onTap(p.id),
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }
}

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.textColor});
  final String label;
  final Color color;
  final Color textColor;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: textColor)),
    );
  }
}
