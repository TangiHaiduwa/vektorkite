import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/features/marketplace/domain/store_repository.dart';

class AppSyncStoreRepository implements StoreRepository {
  const AppSyncStoreRepository();

  static const String _storesByOwnerQuery = r'''
query StoresByOwnerSub($ownerSub: ID!) {
  storesByOwnerSub(ownerSub: $ownerSub, limit: 1) {
    items {
      id
      ownerSub
      name
      phone
      city
      address
      logoKey
      status
      createdAt
    }
  }
}
''';

  static const String _createStoreMutation = r'''
mutation CreateStore($input: CreateStoreInput!) {
  createStore(input: $input) {
    id
    ownerSub
    name
    phone
    city
    address
    logoKey
    status
    createdAt
  }
}
''';

  static const String _updateStoreMutation = r'''
mutation UpdateStore($input: UpdateStoreInput!) {
  updateStore(input: $input) {
    id
    ownerSub
    name
    phone
    city
    address
    logoKey
    status
    createdAt
  }
}
''';

  @override
  Future<MarketplaceStore?> getMyStore() async {
    final user = await Amplify.Auth.getCurrentUser();
    final request = GraphQLRequest<String>(
      document: _storesByOwnerQuery,
      variables: {'ownerSub': user.userId},
    );
    final response = await Amplify.API.query(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }

    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final root = (parsed['storesByOwnerSub'] ?? {}) as Map<String, dynamic>;
    final items = (root['items'] ?? const []) as List<dynamic>;
    final stores = items.whereType<Map<String, dynamic>>().toList();
    if (stores.isEmpty) return null;
    return _parseStore(stores.first);
  }

  @override
  Future<MarketplaceStore> upsertMyStore(StoreUpsertInput input) async {
    final user = await Amplify.Auth.getCurrentUser();
    final existing = await getMyStore();
    final payload = <String, dynamic>{
      if (existing != null) 'id': existing.id,
      if (input.id != null) 'id': input.id,
      'ownerSub': user.userId,
      'name': input.name,
      'phone': input.phone,
      'city': input.city,
      'address': input.address,
      'logoKey': input.logoKey,
      if (existing == null) 'status': marketplaceStoreStatusToApi(MarketplaceStoreStatus.pending),
    };

    final request = GraphQLRequest<String>(
      document: existing == null ? _createStoreMutation : _updateStoreMutation,
      variables: {'input': payload},
    );
    final response = await Amplify.API.mutate(request: request).response;
    if (response.errors.isNotEmpty) {
      throw Exception(response.errors.first.message);
    }
    final parsed = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    final key = existing == null ? 'createStore' : 'updateStore';
    return _parseStore((parsed[key] ?? {}) as Map<String, dynamic>);
  }

  MarketplaceStore _parseStore(Map<String, dynamic> item) {
    return MarketplaceStore(
      id: (item['id'] as String?) ?? '',
      ownerSub: (item['ownerSub'] as String?) ?? '',
      name: (item['name'] as String?) ?? '',
      phone: item['phone'] as String?,
      city: (item['city'] as String?) ?? '',
      address: (item['address'] as String?) ?? '',
      logoKey: item['logoKey'] as String?,
      status: marketplaceStoreStatusFromApi(item['status'] as String?),
      createdAt:
          DateTime.tryParse((item['createdAt'] as String?) ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
