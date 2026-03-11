enum SupportTicketStatus {
  open('Open', 'OPEN'),
  inReview('In Review', 'IN_REVIEW'),
  resolved('Resolved', 'RESOLVED'),
  closed('Closed', 'CLOSED');

  const SupportTicketStatus(this.label, this.apiValue);

  final String label;
  final String apiValue;

  static SupportTicketStatus fromApiValue(String? value) {
    for (final status in SupportTicketStatus.values) {
      if (status.apiValue == value) return status;
    }
    return SupportTicketStatus.open;
  }
}
