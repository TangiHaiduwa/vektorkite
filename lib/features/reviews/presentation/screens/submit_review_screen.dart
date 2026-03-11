import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/features/booking/application/booking_controller.dart';
import 'package:vektorkite/features/booking/domain/booking_status.dart';
import 'package:vektorkite/features/reviews/application/review_controller.dart';
import 'package:vektorkite/features/reviews/domain/review_create_input.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class SubmitReviewScreen extends ConsumerStatefulWidget {
  const SubmitReviewScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends ConsumerState<SubmitReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewControllerProvider);
    final reviewController = ref.read(reviewControllerProvider.notifier);
    final bookingController = ref.read(bookingControllerProvider.notifier);

    return FutureBuilder(
      future: bookingController.getBookingById(widget.bookingId),
      builder: (context, bookingSnapshot) {
        final booking = bookingSnapshot.data;
        if (bookingSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (booking == null) {
          return _simpleStateScaffold(context, 'Booking not found.');
        }
        if (booking.status != BookingStatus.completed) {
          return _simpleStateScaffold(context, 'Reviews are available after booking completion.');
        }
        if (booking.providerId == null || booking.providerId!.isEmpty) {
          return _simpleStateScaffold(context, 'No provider is attached to this booking yet.');
        }

        final bookingReviewAsync = ref.watch(bookingReviewProvider(widget.bookingId));
        return Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop() ? const AppBackButton() : null,
            title: const Text('Write Review'),
          ),
          body: SafeArea(
            child: bookingReviewAsync.when(
              data: (existing) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: existing != null
                    ? _panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('You already submitted a review for this booking.'),
                            const SizedBox(height: 10),
                            Text('Rating: ${existing.rating}/5'),
                            if (existing.comment != null && existing.comment!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(existing.comment!),
                              ),
                          ],
                        ),
                      )
                    : ListView(
                        children: [
                          _panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rate your provider',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(5, (index) {
                                    final star = index + 1;
                                    return IconButton(
                                      onPressed: () => setState(() => _rating = star),
                                      icon: Icon(
                                        star <= _rating ? Icons.star : Icons.star_border,
                                        color: const Color(0xFFF59F00),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _commentController,
                                  minLines: 3,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    labelText: 'Comment (optional)',
                                    hintText: 'Share what went well or what can improve.',
                                  ),
                                ),
                                if (reviewState.errorMessage != null) ...[
                                  const SizedBox(height: 8),
                                  AppInlineError(message: reviewState.errorMessage!),
                                ],
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: reviewState.isSubmitting
                                        ? null
                                        : () async {
                                            final created = await reviewController.createReview(
                                              ReviewCreateInput(
                                                bookingId: widget.bookingId,
                                                providerId: booking.providerId!,
                                                rating: _rating,
                                                comment: _commentController.text.trim().isEmpty
                                                    ? null
                                                    : _commentController.text.trim(),
                                              ),
                                            );
                                            if (!context.mounted || created == null) return;
                                            ref.invalidate(bookingReviewProvider(widget.bookingId));
                                            ref.invalidate(providerReviewsProvider(booking.providerId!));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Review submitted.')),
                                            );
                                            context.pop();
                                          },
                                    child: reviewState.isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Submit Review'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
              error: (_, _) => AppInlineError(
                message: 'Unable to load review state.',
                onRetry: () => ref.invalidate(bookingReviewProvider(widget.bookingId)),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      },
    );
  }

  Scaffold _simpleStateScaffold(BuildContext context, String text) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? const AppBackButton() : null,
        title: const Text('Write Review'),
      ),
      body: Center(child: Text(text)),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
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
