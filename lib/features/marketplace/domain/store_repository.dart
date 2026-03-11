import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';

abstract class StoreRepository {
  Future<MarketplaceStore?> getMyStore();
  Future<MarketplaceStore> upsertMyStore(StoreUpsertInput input);
}
