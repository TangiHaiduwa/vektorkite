import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/home/application/home_controller.dart';
import 'package:vektorkite/features/reviews/application/review_controller.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key, required this.providerId});
  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.read(providerBrowseControllerProvider.notifier).findProviderById(providerId);
    final providerReviews = ref.watch(providerReviewsProvider(providerId));

    if (provider == null) {
      return Scaffold(
        appBar: AppBar(
          leading: context.canPop() ? const AppBackButton() : null,
          title: const Text('Provider'),
        ),
        body: const Center(child: Text('Provider not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const AppBackButton() : null,
        title: const Text('Provider Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(colors: [Color(0xFFEEF7FF), Color(0xFFF2FBF8)]),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(provider.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Rating ${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)'),
              Text('Service Area: ${provider.serviceArea}'),
              if (provider.availabilityText != null) Text('Availability: ${provider.availabilityText}'),
            ]),
          ),
          const SizedBox(height: 12),
          _panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Services Offered', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.subcategoryNames.map((name) => Chip(label: Text(name))).toList(),
              ),
              const SizedBox(height: 10),
              if (provider.hourlyRate != null) Text('From NAD ${provider.hourlyRate!.toStringAsFixed(2)} / hour'),
              if (provider.calloutFee != null) Text('Callout fee: NAD ${provider.calloutFee!.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text(provider.bio),
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.push(
              RoutePaths.bookingCreate,
              extra: {'providerId': provider.id, 'description': 'Booking request for ${provider.displayName}'},
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Book Now'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.push(
              '${RoutePaths.supportCreate}?type=REPORT_PROVIDER&providerId=${Uri.encodeComponent(provider.id)}',
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Report this provider'),
          ),
          const SizedBox(height: 14),
          Text('Recent Reviews', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          providerReviews.when(
            data: (reviews) {
              if (reviews.isEmpty) return const Text('No reviews yet for this provider.');
              return Column(
                children: reviews.take(3).map((review) {
                  return _panel(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Rating: ${review.rating}/5'),
                      subtitle: Text('${review.comment ?? 'No comment'}\n${DateFormat('d MMM yyyy').format(review.createdAt)}'),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
            error: (_, _) => const AppInlineError(message: 'Unable to load reviews.'),
            loading: () => const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}
