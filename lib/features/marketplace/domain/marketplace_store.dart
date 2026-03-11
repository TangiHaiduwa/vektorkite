enum MarketplaceStoreStatus {
  pending,
  approved,
  rejected,
}

MarketplaceStoreStatus marketplaceStoreStatusFromApi(String? value) {
  switch (value) {
    case 'APPROVED':
      return MarketplaceStoreStatus.approved;
    case 'REJECTED':
      return MarketplaceStoreStatus.rejected;
    default:
      return MarketplaceStoreStatus.pending;
  }
}

String marketplaceStoreStatusToApi(MarketplaceStoreStatus status) {
  switch (status) {
    case MarketplaceStoreStatus.pending:
      return 'PENDING';
    case MarketplaceStoreStatus.approved:
      return 'APPROVED';
    case MarketplaceStoreStatus.rejected:
      return 'REJECTED';
  }
}

class MarketplaceStore {
  const MarketplaceStore({
    required this.id,
    required this.ownerSub,
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    required this.logoKey,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String ownerSub;
  final String name;
  final String? phone;
  final String city;
  final String address;
  final String? logoKey;
  final MarketplaceStoreStatus status;
  final DateTime createdAt;
}

class StoreUpsertInput {
  const StoreUpsertInput({
    this.id,
    required this.name,
    required this.phone,
    required this.city,
    required this.address,
    this.logoKey,
  });

  final String? id;
  final String name;
  final String? phone;
  final String city;
  final String address;
  final String? logoKey;
}
