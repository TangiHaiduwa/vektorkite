import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/features/support/application/support_controller.dart';
import 'package:vektorkite/features/support/domain/support_ticket_create_input.dart';
import 'package:vektorkite/features/support/domain/support_ticket_type.dart';
import 'package:vektorkite/shared/widgets/app_back_button.dart';
import 'package:vektorkite/shared/widgets/app_inline_error.dart';

class SupportTicketFormScreen extends ConsumerStatefulWidget {
  const SupportTicketFormScreen({
    super.key,
    required this.initialType,
    this.bookingId,
    this.providerId,
  });

  final SupportTicketType initialType;
  final String? bookingId;
  final String? providerId;

  @override
  ConsumerState<SupportTicketFormScreen> createState() =>
      _SupportTicketFormScreenState();
}

class _SupportTicketFormScreenState extends ConsumerState<SupportTicketFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  late SupportTicketType _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportControllerProvider);
    final supportController = ref.read(supportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop() ? const AppBackButton() : null,
        title: const Text('New Support Ticket'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFDFE),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<SupportTicketType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(labelText: 'Ticket Type'),
                      items: SupportTicketType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: supportState.isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _selectedType = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(labelText: 'Subject'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Subject is required';
                        }
                        if (value.trim().length < 5) {
                          return 'Subject must be at least 5 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _messageController,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe the issue in detail.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Message is required';
                        }
                        if (value.trim().length < 15) {
                          return 'Message must be at least 15 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              if (widget.bookingId != null) ...[
                const SizedBox(height: 12),
                Text('Booking ID: ${widget.bookingId}'),
              ],
              if (widget.providerId != null) ...[
                const SizedBox(height: 8),
                Text('Provider ID: ${widget.providerId}'),
              ],
              if (supportState.errorMessage != null) ...[
                const SizedBox(height: 8),
                AppInlineError(
                  message: supportState.errorMessage!,
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: supportState.isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final ticket = await supportController.createTicket(
                            SupportTicketCreateInput(
                              type: _selectedType,
                              subject: _subjectController.text.trim(),
                              message: _messageController.text.trim(),
                              bookingId: widget.bookingId,
                              providerId: widget.providerId,
                            ),
                          );
                          if (!context.mounted || ticket == null) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support ticket submitted.'),
                            ),
                          );
                          context.pop();
                        },
                  child: supportState.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
