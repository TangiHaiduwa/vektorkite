enum SupportTicketType {
  generalSupport('General Support', 'GENERAL_SUPPORT'),
  reportProvider('Report Provider', 'REPORT_PROVIDER'),
  disputeBooking('Dispute Booking', 'DISPUTE_BOOKING');

  const SupportTicketType(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static SupportTicketType fromApiValue(String? value) {
    for (final type in SupportTicketType.values) {
      if (type.apiValue == value) return type;
    }
    return SupportTicketType.generalSupport;
  }
}
