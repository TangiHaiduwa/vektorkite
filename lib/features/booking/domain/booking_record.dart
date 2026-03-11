import 'package:vektorkite/features/booking/domain/booking_status.dart';

class BookingRecord {
  const BookingRecord({
    required this.id,
    required this.customerId,
    required this.categoryId,
    this.subcategoryId,
    this.providerId,
    required this.description,
    required this.addressText,
    required this.status,
    required this.isScheduled,
    this.scheduledFor,
    required this.requestedAt,
    this.estimatedMin,
    this.estimatedMax,
    this.finalPrice,
    this.currency = 'NAD',
    this.lat,
    this.lng,
  });

  final String id;
  final String customerId;
  final String categoryId;
  final String? subcategoryId;
  final String? providerId;
  final String description;
  final String addressText;
  final BookingStatus status;
  final bool isScheduled;
  final DateTime? scheduledFor;
  final DateTime requestedAt;
  final double? estimatedMin;
  final double? estimatedMax;
  final double? finalPrice;
  final String currency;
  final double? lat;
  final double? lng;
}
