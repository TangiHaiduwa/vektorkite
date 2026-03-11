import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/booking/application/booking_controller.dart';
import 'package:vektorkite/features/booking/domain/booking_create_input.dart';
import 'package:vektorkite/features/booking/domain/booking_request_draft.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';
import 'package:vektorkite/features/booking/domain/provider_candidate.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';

class ProviderSelectionScreen extends ConsumerStatefulWidget {
  const ProviderSelectionScreen({super.key, required this.draft});

  final BookingRequestDraft draft;

  @override
  ConsumerState<ProviderSelectionScreen> createState() =>
      _ProviderSelectionScreenState();
}

class _ProviderSelectionScreenState extends ConsumerState<ProviderSelectionScreen> {
  String? _selectedOfferingId;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(bookingControllerProvider.notifier).loadProviderCandidates(
            subcategoryId: widget.draft.subcategoryId,
            areaQuery: widget.draft.cityArea,
          );
    });
  }

  Future<void> _confirmWithProvider(ProviderCandidate provider) async {
    final controller = ref.read(bookingControllerProvider.notifier);
    final user = await Amplify.Auth.getCurrentUser();
    final booking = await controller.createBooking(
      BookingCreateInput(
        customerId: user.userId,
        categoryId: widget.draft.categoryId,
        subcategoryId: widget.draft.subcategoryId,
        providerId: provider.providerId,
        providerOfferingId: provider.providerOfferingId,
        description: widget.draft.description,
        addressText: widget.draft.addressText,
        isScheduled: widget.draft.isScheduled,
        scheduledFor: widget.draft.scheduledFor,
        status: BookingStatus.requested,
        estimatedMin: widget.draft.budgetMin,
        estimatedMax: widget.draft.budgetMax,
        customerNote: widget.draft.customerNote,
        lat: widget.draft.lat,
        lng: widget.draft.lng,
      ),
    );
    if (!mounted || booking == null) return;
    context.go(
      RoutePaths.bookingConfirmation.replaceFirst(':bookingId', booking.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final providers = state.providerCandidates;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? const AppBackButton() : null,
        title: const Text('Choose Provider'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopSummary(
                area: widget.draft.cityArea,
                count: providers.length,
              ),
              const SizedBox(height: 12),
              if (state.isLoadingProviders)
                const Expanded(child: _ProviderListSkeleton())
              else if (providers.isEmpty)
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(18),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 34,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No verified providers found for this area.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Recommended: use auto-match for fastest assignment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => context.pop(),
                              child: const Text('Back to Auto-match'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: providers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      final isSelected =
                          provider.providerOfferingId == _selectedOfferingId;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(
                          () => _selectedOfferingId = provider.providerOfferingId,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : const Color(0xFFDCE2EA),
                              width: isSelected ? 1.6 : 1,
                            ),
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      provider.displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if (provider.isVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDDF6E8),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.subcategoryName,
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Area: ${provider.serviceArea}',
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rating ${provider.rating.toStringAsFixed(1)} (${provider.reviewCount} reviews)',
                                style: const TextStyle(color: Color(0xFF334155)),
                              ),
                              if (provider.hourlyRate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'From ${provider.currency} ${provider.hourlyRate!.toStringAsFixed(2)} / hr',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                              if (provider.calloutFee != null)
                                Text(
                                  'Callout ${provider.currency} ${provider.calloutFee!.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isSubmitting || _selectedOfferingId == null
                      ? null
                      : () {
                          ProviderCandidate? selected;
                          for (final provider in providers) {
                            if (provider.providerOfferingId == _selectedOfferingId) {
                              selected = provider;
                              break;
                            }
                          }
                          if (selected == null) return;
                          _confirmWithProvider(selected);
                        },
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm Selected Provider'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopSummary extends StatelessWidget {
  const _TopSummary({
    required this.area,
    required this.count,
  });

  final String area;
  final int count;

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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_outlined, color: Color(0xFF0F766E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Area: $area',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count verified providers available',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderListSkeleton extends StatelessWidget {
  const _ProviderListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => Container(
        height: 132,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFE9EDF3),
        ),
      ),
    );
  }
}
