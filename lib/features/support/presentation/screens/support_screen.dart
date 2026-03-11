import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/support/application/support_controller.dart';
import 'package:vektorkite/features/support/domain/support_ticket.dart';
import 'package:vektorkite/features/support/domain/support_ticket_status.dart';
import 'package:vektorkite/features/support/domain/support_ticket_type.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(supportControllerProvider.notifier).loadTickets(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? const AppBackButton() : null,
        title: const Text('Support'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(supportControllerProvider.notifier).loadTickets(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ticketActionButton(context: context, label: 'General Support', type: SupportTicketType.generalSupport),
                      _ticketActionButton(context: context, label: 'Report Provider', type: SupportTicketType.reportProvider),
                      _ticketActionButton(context: context, label: 'Dispute Booking', type: SupportTicketType.disputeBooking),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('My Tickets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (supportState.isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (supportState.errorMessage != null)
              AppInlineError(
                message: supportState.errorMessage!,
                onRetry: () => ref.read(supportControllerProvider.notifier).loadTickets(),
              )
            else if (supportState.tickets.isEmpty)
              _panel(
                child: const ListTile(
                  title: Text('No support tickets yet.'),
                  subtitle: Text('Create one to contact support.'),
                ),
              )
            else
              ...supportState.tickets.map(_ticketCard),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.supportCreate),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('New Ticket'),
      ),
    );
  }

  Widget _ticketActionButton({
    required BuildContext context,
    required String label,
    required SupportTicketType type,
  }) {
    return OutlinedButton(
      onPressed: () => context.push('${RoutePaths.supportCreate}?type=${type.apiValue}'),
      child: Text(label),
    );
  }

  Widget _ticketCard(SupportTicket ticket) {
    final color = _statusColor(ticket.status);
    return _panel(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${ticket.type.label} | ${DateFormat('d MMM yyyy, HH:mm').format(ticket.createdAt)}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(ticket.status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }

  Color _statusColor(SupportTicketStatus status) {
    return switch (status) {
      SupportTicketStatus.open => const Color(0xFF0B7285),
      SupportTicketStatus.inReview => const Color(0xFFB26A00),
      SupportTicketStatus.resolved => const Color(0xFF2B8A3E),
      SupportTicketStatus.closed => const Color(0xFF6C757D),
    };
  }
}
