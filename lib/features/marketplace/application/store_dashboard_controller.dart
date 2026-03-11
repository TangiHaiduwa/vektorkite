import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vektorkite/core/utils/app_error_mapper.dart';
import 'package:vektorkite/core/utils/app_logger.dart';
import 'package:vektorkite/features/auth/application/current_user_role_provider.dart';
import 'package:vektorkite/features/auth/domain/app_user_role.dart';
import 'package:vektorkite/features/auth/domain/user_role_repository.dart';
import 'package:vektorkite/features/marketplace/application/store_dashboard_state.dart';
import 'package:vektorkite/features/marketplace/application/marketplace_controller.dart';
import 'package:vektorkite/features/marketplace/data/appsync_store_repository.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_product.dart';
import 'package:vektorkite/features/marketplace/domain/marketplace_store.dart';
import 'package:vektorkite/features/marketplace/domain/product_repository.dart';
import 'package:vektorkite/features/marketplace/domain/store_repository.dart';
import 'package:vektorkite/features/marketplace/domain/taxonomy_repository.dart';

final marketplaceStoreRepositoryProvider = Provider<StoreRepository>(
  (ref) => const AppSyncStoreRepository(),
);

final storeDashboardControllerProvider =
    StateNotifierProvider<StoreDashboardController, StoreDashboardState>(
      (ref) => StoreDashboardController(
        storeRepository: ref.read(marketplaceStoreRepositoryProvider),
        productRepository: ref.read(marketplaceProductRepositoryProvider),
        taxonomyRepository: ref.read(marketplaceTaxonomyRepositoryProvider),
        userRoleRepository: ref.read(userRoleRepositoryProvider),
      ),
    );

class StoreDashboardController extends StateNotifier<StoreDashboardState> {
  StoreDashboardController({
    required StoreRepository storeRepository,
    required ProductRepository productRepository,
    required TaxonomyRepository taxonomyRepository,
    required UserRoleRepository userRoleRepository,
  }) : _storeRepository = storeRepository,
       _productRepository = productRepository,
       _taxonomyRepository = taxonomyRepository,
       _userRoleRepository = userRoleRepository,
       super(const StoreDashboardState());

  final StoreRepository _storeRepository;
  final ProductRepository _productRepository;
  final TaxonomyRepository _taxonomyRepository;
  final UserRoleRepository _userRoleRepository;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final role = await _userRoleRepository.fetchCurrentUserRole();
      if (role != AppUserRole.provider) {
        state = state.copyWith(
          isLoading: false,
          isProvider: false,
          store: null,
          products: const [],
          categories: const [],
          subcategories: const [],
          errorMessage:
              'Only service providers can create and manage stores/products.',
        );
        return;
      }
      final categories = await _taxonomyRepository.fetchCategories();
      final store = await _storeRepository.getMyStore();
      List<MarketplaceProduct> products = const [];
      if (store != null) {
        products = await _productRepository.fetchProductsByStore(store.id);
      }
      state = state.copyWith(
        isLoading: false,
        isProvider: true,
        categories: categories,
        store: store,
        products: products,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize store dashboard',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to load store dashboard.',
        ),
      );
    }
  }

  Future<void> loadSubcategories(String categoryId) async {
    try {
      final subcategories = await _taxonomyRepository.fetchSubcategories(categoryId);
      state = state.copyWith(subcategories: subcategories);
    } catch (_) {
      state = state.copyWith(subcategories: const []);
    }
  }

  Future<MarketplaceStore?> saveStore(StoreUpsertInput input) async {
    if (!_canManageStore()) return null;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _storeRepository.upsertMyStore(input);
      state = state.copyWith(isSaving: false, store: saved);
      return saved;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save store profile',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to save store profile.',
        ),
      );
      return null;
    }
  }

  Future<MarketplaceProduct?> saveProduct(ProductUpsertInput input) async {
    if (!_canManageStore()) return null;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _productRepository.upsertProduct(input);
      final store = state.store;
      if (store != null) {
        final products = await _productRepository.fetchProductsByStore(store.id);
        state = state.copyWith(isSaving: false, products: products);
      } else {
        state = state.copyWith(isSaving: false);
      }
      return saved;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save product',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to save product.',
        ),
      );
      return null;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (!_canManageStore()) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _productRepository.deleteProduct(productId);
      final store = state.store;
      if (store != null) {
        final products = await _productRepository.fetchProductsByStore(store.id);
        state = state.copyWith(isSaving: false, products: products);
      } else {
        state = state.copyWith(isSaving: false);
      }
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete product',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isSaving: false,
        errorMessage: AppErrorMapper.toUserMessage(
          error,
          fallback: 'Unable to delete product.',
        ),
      );
      return false;
    }
  }

  Future<String?> uploadProductImage(String localPath) async {
    if (!_canManageStore()) return null;
    final store = state.store;
    if (store == null) return null;
    try {
      final user = await Amplify.Auth.getCurrentUser();
      final ext = localPath.split('.').last;
      final key =
          'protected/${user.userId}/stores/${store.id}/products/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(localPath),
        path: StoragePath.fromString(key),
      ).result;
      return key;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to upload product image',
        name: 'Marketplace',
        error: error,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        errorMessage: 'Unable to upload image. Please retry.',
      );
      return null;
    }
  }

  bool canToggleSponsored() {
    if (!_canManageStore()) return false;
    final store = state.store;
    if (store == null) return false;
    return store.status == MarketplaceStoreStatus.approved;
  }

  bool _canManageStore() {
    if (state.isProvider) return true;
    state = state.copyWith(
      errorMessage: 'Only service providers can manage stores/products.',
    );
    return false;
  }
}
