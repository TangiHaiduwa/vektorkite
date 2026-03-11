enum BookingStatus {
  pendingMatch('Pending Match', 'PENDING_MATCH'),
  requested('Requested', 'REQUESTED'),
  assigned('Assigned', 'ASSIGNED'),
  inProgress('In Progress', 'IN_PROGRESS'),
  completed('Completed', 'COMPLETED'),
  cancelled('Cancelled', 'CANCELLED');

  const BookingStatus(this.label, this.apiValue);

  final String label;
  final String apiValue;

  bool get canCustomerCancel =>
      this == BookingStatus.pendingMatch || this == BookingStatus.requested;

  static BookingStatus fromApiValue(String? value) {
    for (final status in BookingStatus.values) {
      if (status.apiValue == value) return status;
    }
    return BookingStatus.pendingMatch;
  }
}
