class ProviderCandidate {
  const ProviderCandidate({
    required this.providerId,
    required this.providerOfferingId,
    required this.displayName,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.serviceArea,
    required this.subcategoryName,
    this.hourlyRate,
    this.calloutFee,
    this.currency = 'NAD',
  });

  final String providerId;
  final String providerOfferingId;
  final String displayName;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final String serviceArea;
  final String subcategoryName;
  final double? hourlyRate;
  final double? calloutFee;
  final String currency;
}
