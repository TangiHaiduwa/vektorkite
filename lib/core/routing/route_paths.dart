class RoutePaths {
  const RoutePaths._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const confirmSignUp = '/auth/confirm';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const home = '/home';
  static const marketplace = '/marketplace';
  static const bookings = '/bookings';
  static const support = '/support';
  static const profile = '/profile';

  static const bookingCreate = '/booking/create';
  static const bookingProviderSelection = '/booking/provider-selection';
  static const bookingConfirmation = '/booking/confirmation/:bookingId';
  static const bookingStatus = '/booking/status/:bookingId';
  static const bookingReview = '/booking/review/:bookingId';

  static const providerProfile = '/provider/:providerId';
  static const marketplaceCategory = '/marketplace/category';
  static const marketplaceProductDetail = '/marketplace/product/:productId';
  static const marketplaceStoreProfile = '/marketplace/store/:storeId';

  static const supportCreate = '/support/create';

  static const terms = '/legal/terms';
  static const privacy = '/legal/privacy';
}
