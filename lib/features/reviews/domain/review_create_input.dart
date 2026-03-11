class ReviewCreateInput {
  const ReviewCreateInput({
    required this.bookingId,
    required this.providerId,
    required this.rating,
    this.comment,
  });

  final String bookingId;
  final String providerId;
  final int rating;
  final String? comment;
}
