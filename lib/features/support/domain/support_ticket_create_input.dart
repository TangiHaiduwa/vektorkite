import 'package:vektorkite/features/support/domain/support_ticket_type.dart';

class SupportTicketCreateInput {
  const SupportTicketCreateInput({
    required this.type,
    required this.subject,
    required this.message,
    this.bookingId,
    this.providerId,
  });

  final SupportTicketType type;
  final String subject;
  final String message;
  final String? bookingId;
  final String? providerId;
}
