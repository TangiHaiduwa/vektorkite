import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vektorkite/core/routing/route_paths.dart';
import 'package:vektorkite/features/auth/application/auth_controller.dart';
import 'package:vektorkite/features/auth/application/auth_state.dart';
import 'package:vektorkite/features/auth/presentation/screens/confirm_sign_up_screen.dart';
import 'package:vektorkite/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:vektorkite/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:vektorkite/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:vektorkite/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:vektorkite/features/auth/presentation/screens/splash_screen.dart';
import 'package:vektorkite/features/auth/presentation/screens/welcome_screen.dart';
import 'package:vektorkite/features/booking/domain/booking_request_draft.dart';
import 'package:vektorkite/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:vektorkite/features/booking/presentation/screens/booking_create_screen.dart';
import 'package:vektorkite/features/booking/presentation/screens/booking_history_screen.dart';
import 'package:vektorkite/features/booking/presentation/screens/booking_status_screen.dart';
import 'package:vektorkite/features/booking/presentation/screens/provider_selection_screen.dart';
import 'package:vektorkite/features/home/presentation/screens/home_screen.dart';
import 'package:vektorkite/features/home/presentation/screens/provider_profile_screen.dart';
import 'package:vektorkite/features/legal/presentation/screens/privacy_policy_screen.dart';
import 'package:vektorkite/features/legal/presentation/screens/terms_screen.dart';
import 'package:vektorkite/features/marketplace/presentation/screens/marketplace_category_screen.dart';
import 'package:vektorkite/features/marketplace/presentation/screens/marketplace_home_screen.dart';
import 'package:vektorkite/features/marketplace/presentation/screens/marketplace_product_detail_screen.dart';
import 'package:vektorkite/features/marketplace/presentation/screens/store_profile_screen.dart';
import 'package:vektorkite/features/profile/presentation/screens/profile_screen.dart';
import 'package:vektorkite/features/reviews/presentation/screens/submit_review_screen.dart';
import 'package:vektorkite/features/support/domain/support_ticket_type.dart';
import 'package:vektorkite/features/support/presentation/screens/support_screen.dart';
import 'package:vektorkite/features/support/presentation/screens/support_ticket_form_screen.dart';
import 'package:vektorkite/shared/widgets/app_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRefreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(authRefreshNotifier.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: authRefreshNotifier,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.confirmSignUp,
        builder: (context, state) => const ConfirmSignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.marketplace,
                builder: (context, state) => const MarketplaceHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.bookings,
                builder: (context, state) => const BookingHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.support,
                builder: (context, state) => const SupportScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.marketplaceCategory,
        builder: (context, state) {
          final extra = state.extra;
          String? categoryId;
          if (extra is Map<String, dynamic>) {
            categoryId = extra['categoryId'] as String?;
          }
          return MarketplaceCategoryScreen(initialCategoryId: categoryId);
        },
      ),
      GoRoute(
        path: RoutePaths.marketplaceProductDetail,
        builder: (context, state) {
          final productId = state.pathParameters['productId'];
          if (productId == null || productId.isEmpty) {
            return const MarketplaceHomeScreen();
          }
          return MarketplaceProductDetailScreen(productId: productId);
        },
      ),
      GoRoute(
        path: RoutePaths.marketplaceStoreProfile,
        builder: (context, state) {
          final storeId = state.pathParameters['storeId'];
          if (storeId == null || storeId.isEmpty) {
            return const MarketplaceHomeScreen();
          }
          return StoreProfileScreen(storeId: storeId);
        },
      ),
      GoRoute(
        path: RoutePaths.bookingCreate,
        builder: (context, state) {
          final extra = state.extra;
          String? categoryId;
          String? subcategoryId;
          String? providerId;
          String? description;
          if (extra is Map<String, dynamic>) {
            categoryId = extra['categoryId'] as String?;
            subcategoryId = extra['subcategoryId'] as String?;
            providerId = extra['providerId'] as String?;
            description = extra['description'] as String?;
          }
          return BookingCreateScreen(
            initialCategoryId: categoryId,
            initialSubcategoryId: subcategoryId,
            initialProviderId: providerId,
            initialDescription: description,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bookingProviderSelection,
        builder: (context, state) {
          final draft = state.extra;
          if (draft is! BookingRequestDraft) {
            return const BookingCreateScreen();
          }
          return ProviderSelectionScreen(draft: draft);
        },
      ),
      GoRoute(
        path: RoutePaths.bookingConfirmation,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'];
          if (bookingId == null || bookingId.isEmpty) {
            return const BookingHistoryScreen();
          }
          return BookingConfirmationScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: RoutePaths.bookingStatus,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'];
          if (bookingId == null || bookingId.isEmpty) {
            return const BookingHistoryScreen();
          }
          return BookingStatusScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: RoutePaths.bookingReview,
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'];
          if (bookingId == null || bookingId.isEmpty) {
            return const BookingHistoryScreen();
          }
          return SubmitReviewScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: RoutePaths.providerProfile,
        builder: (context, state) {
          final providerId = state.pathParameters['providerId'];
          if (providerId == null || providerId.isEmpty) {
            return const HomeScreen();
          }
          return ProviderProfileScreen(providerId: providerId);
        },
      ),
      GoRoute(
        path: RoutePaths.supportCreate,
        builder: (context, state) {
          final typeValue = state.uri.queryParameters['type'];
          final bookingId = state.uri.queryParameters['bookingId'];
          final providerId = state.uri.queryParameters['providerId'];
          final type = SupportTicketType.fromApiValue(typeValue);
          return SupportTicketFormScreen(
            initialType: type,
            bookingId: bookingId,
            providerId: providerId,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.terms,
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: RoutePaths.privacy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.uri.path;
      final publicRoutes = <String>{
        RoutePaths.welcome,
        RoutePaths.signIn,
        RoutePaths.signUp,
        RoutePaths.confirmSignUp,
        RoutePaths.forgotPassword,
        RoutePaths.resetPassword,
        RoutePaths.terms,
        RoutePaths.privacy,
      };

      if (authState.status == AuthStatus.unknown ||
          authState.status == AuthStatus.loading) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      if (authState.status == AuthStatus.needsConfirmation &&
          location != RoutePaths.confirmSignUp) {
        return RoutePaths.confirmSignUp;
      }

      if (authState.status == AuthStatus.authenticated) {
        if (location == RoutePaths.splash || publicRoutes.contains(location)) {
          return RoutePaths.home;
        }
        return null;
      }

      if (location == RoutePaths.splash || !publicRoutes.contains(location)) {
        return RoutePaths.welcome;
      }
      return null;
    },
  );
});

class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(this._ref) {
    _subscription = _ref.listen<AuthState>(authControllerProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
