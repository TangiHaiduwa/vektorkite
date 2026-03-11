import 'package:vektorkite/features/support/domain/support_ticket.dart';

class SupportState {
  const SupportState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.tickets = const [],
  });

  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<SupportTicket> tickets;

  SupportState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    List<SupportTicket>? tickets,
    bool clearError = false,
  }) {
    return SupportState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      tickets: tickets ?? this.tickets,
    );
  }
}
