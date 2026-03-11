import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/support/domain/support_repository.dart';
import 'package:vektorkite/features/support/domain/support_ticket.dart';
import 'package:vektorkite/features/support/domain/support_ticket_create_input.dart';
import 'package:vektorkite/features/support/domain/support_ticket_status.dart';
import 'package:vektorkite/features/support/domain/support_ticket_type.dart';

class AppSyncSupportRepository implements SupportRepository {
  const AppSyncSupportRepository();

  static const String _listTicketsQuery = r'''
query ListSupportTickets {
  listSupportTickets(limit: 200) {
    items {
      id
      type
      status
      subject
      message
      bookingId
      providerId
      adminNotes
      createdAt
    }
  }
}
''';

  static const String _createTicketMutation = r'''
mutation CreateSupportTicket($input: CreateSupportTicketInput!) {
  createSupportTicket(input: $input) {
    id
    type
    status
    subject
    message
    bookingId
    providerId
    adminNotes
    createdAt
  }
}
''';

  @override
  Future<List<SupportTicket>> fetchMyTickets() async {
    final request = GraphQLRequest<String>(document: _listTicketsQuery);
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['listSupportTickets'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;

    final tickets = items
        .whereType<Map<String, dynamic>>()
        .where((item) => item['id'] != null)
        .map(_parseTicket)
        .toList();
    tickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tickets;
  }

  @override
  Future<SupportTicket> createTicket(SupportTicketCreateInput input) async {
    final request = GraphQLRequest<String>(
      document: _createTicketMutation,
      variables: {
        'input': {
          'type': input.type.apiValue,
          'status': SupportTicketStatus.open.apiValue,
          'subject': input.subject,
          'message': input.message,
          'bookingId': input.bookingId,
          'providerId': input.providerId,
        },
      },
    );

    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final item = (parsed['createSupportTicket'] ?? {}) as Map<String, dynamic>;
    return _parseTicket(item);
  }

  SupportTicket _parseTicket(Map<String, dynamic> item) {
    return SupportTicket(
      id: item['id'] as String,
      type: SupportTicketType.fromApiValue(item['type'] as String?),
      status: SupportTicketStatus.fromApiValue(item['status'] as String?),
      subject: (item['subject'] as String?) ?? '',
      message: (item['message'] as String?) ?? '',
      bookingId: item['bookingId'] as String?,
      providerId: item['providerId'] as String?,
      adminNotes: item['adminNotes'] as String?,
      createdAt:
          DateTime.tryParse((item['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
