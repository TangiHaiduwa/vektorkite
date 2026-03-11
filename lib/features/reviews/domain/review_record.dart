class ReviewRecord {
  const ReviewRecord({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String providerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
}
