import 'package:vektorkite/features/booking/domain/booking_status.dart';

class BookingCreateInput {
  const BookingCreateInput({
    required this.customerId,
    required this.categoryId,
    required this.subcategoryId,
    required this.description,
    required this.addressText,
    required this.isScheduled,
    required this.status,
    this.scheduledFor,
    this.providerId,
    this.providerOfferingId,
    this.estimatedMin,
    this.estimatedMax,
    this.customerNote,
    this.lat,
    this.lng,
  });

  final String customerId;
  final String categoryId;
  final String subcategoryId;
  final String description;
  final String addressText;
  final bool isScheduled;
  final BookingStatus status;
  final DateTime? scheduledFor;
  final String? providerId;
  final String? providerOfferingId;
  final double? estimatedMin;
  final double? estimatedMax;
  final String? customerNote;
  final double? lat;
  final double? lng;
}
