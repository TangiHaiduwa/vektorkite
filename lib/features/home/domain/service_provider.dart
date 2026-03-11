class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.displayName,
    required this.categoryIds,
    required this.subcategoryNames,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.serviceArea,
    this.calloutFee,
    this.hourlyRate,
    this.lat,
    this.lng,
    this.availabilityText,
  });

  final String id;
  final String displayName;
  final List<String> categoryIds;
  final List<String> subcategoryNames;
  final double rating;
  final int reviewCount;
  final String bio;
  final String serviceArea;
  final double? calloutFee;
  final double? hourlyRate;
  final double? lat;
  final double? lng;
  final String? availabilityText;
}
