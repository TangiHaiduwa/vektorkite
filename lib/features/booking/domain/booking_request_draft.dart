class BookingRequestDraft {
  const BookingRequestDraft({
    required this.categoryId,
    required this.subcategoryId,
    required this.description,
    required this.addressText,
    required this.cityArea,
    required this.isScheduled,
    this.scheduledFor,
    this.budgetMin,
    this.budgetMax,
    this.customerNote,
    this.lat,
    this.lng,
  });

  final String categoryId;
  final String subcategoryId;
  final String description;
  final String addressText;
  final String cityArea;
  final bool isScheduled;
  final DateTime? scheduledFor;
  final double? budgetMin;
  final double? budgetMax;
  final String? customerNote;
  final double? lat;
  final double? lng;
}
