import 'package:vektorkite/features/support/domain/support_ticket_status.dart';
import 'package:vektorkite/features/support/domain/support_ticket_type.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.type,
    required this.status,
    required this.subject,
    required this.message,
    this.bookingId,
    this.providerId,
    this.adminNotes,
    required this.createdAt,
  });

  final String id;
  final SupportTicketType type;
  final SupportTicketStatus status;
  final String subject;
  final String message;
  final String? bookingId;
  final String? providerId;
  final String? adminNotes;
  final DateTime createdAt;
}
