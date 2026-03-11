import 'package:vektorkite/features/support/domain/support_ticket.dart';
import 'package:vektorkite/features/support/domain/support_ticket_create_input.dart';

abstract class SupportRepository {
  Future<List<SupportTicket>> fetchMyTickets();
  Future<SupportTicket> createTicket(SupportTicketCreateInput input);
}
