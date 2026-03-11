import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/support/application/support_state.dart';
import 'package:vektorkite/features/support/data/appsync_support_repository.dart';
import 'package:vektorkite/features/support/domain/support_repository.dart';
import 'package:vektorkite/features/support/domain/support_ticket.dart';
import 'package:vektorkite/features/support/domain/support_ticket_create_input.dart';

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => const AppSyncSupportRepository(),
);

final supportControllerProvider =
    StateNotifierProvider<SupportController, SupportState>(
      (ref) => SupportController(ref.read(supportRepositoryProvider)),
    );

class SupportController extends StateNotifier<SupportState> {
  SupportController(this._repository) : super(const SupportState());

  final SupportRepository _repository;

  Future<void> loadTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tickets = await _repository.fetchMyTickets();
      state = state.copyWith(isLoading: false, tickets: tickets);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to load support tickets',
        name: 'Support',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load support tickets.',
        ),
      );
    }
  }

  Future<SupportTicket?> createTicket(SupportTicketCreateInput input) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final ticket = await _repository.createTicket(input);
      state = state.copyWith(
        isSubmitting: false,
        tickets: [ticket, ...state.tickets],
      );
      return ticket;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create support ticket',
        name: 'Support',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to submit ticket. Please try again.',
        ),
      );
      return null;
    }
  }
}
