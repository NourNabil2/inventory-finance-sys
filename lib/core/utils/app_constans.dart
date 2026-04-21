// ==================== app_constants.dart ====================
// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  // ==================== Storage Keys ====================
  static const String userKey = 'userKey';
  static const String tokenKey = 'tokenKey';
  static const String languageKey = 'languageKey';
  static const String themeKey = 'themeKey';
  static const String onboardingKey = 'onboardingKey';
  static const String themeMode       = 'settings_theme_mode';
  static const String languageCode    = 'settings_language_code';
  static const String notifications   = 'settings_notifications';

  // ==================== API Constants ====================
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // ==================== Pagination ====================
  static const int defaultPageSize = 10;
  static const int initialPage = 1;

  // ==================== Status Codes ====================
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusUnprocessable = 422;
  static const int statusServerError = 500;
  static const int statusBadGateway = 502;
  static const int statusServiceUnavailable = 503;

  // ==================== Validation ====================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // ==================== Error Keywords ====================
  static const String socketException = 'SocketException';
  static const String unauthorizedKeyword = '401';
  static const String authKeyword = 'مصرح';
}

class ErrorMessages {
  ErrorMessages._();

  // ==================== Network Error Messages ====================
  static const String networkTitle = 'errors.network.title';
  static const String networkSubtitle = 'errors.network.subtitle';
  static const String networkAction = 'errors.network.action';

  static const String connectionTimeout = 'errors.network.timeout';
  static const String requestCancelled = 'errors.network.cancelled';
  static const String networkError = 'errors.network.connection';
  static const String certificateError = 'errors.network.certificate';
  static const String serverConnectionError = 'errors.network.serverConnection';
  static const String noServerResponse = 'errors.network.noResponse';

  // ==================== Server Error Messages ====================
  static const String serverTitle = 'errors.server.title';
  static const String serverSubtitle = 'errors.server.subtitle';
  static const String serverAction = 'errors.server.action';

  static const String badRequest = 'errors.server.badRequest';
  static const String unauthorized = 'errors.server.unauthorized';
  static const String forbidden = 'errors.server.forbidden';
  static const String notFound = 'errors.server.notFound';
  static const String invalidData = 'errors.server.invalidData';
  static const String serverError = 'errors.server.internal';
  static const String unexpectedError = 'errors.server.unexpected';

  // ==================== Auth Error Messages ====================
  static const String authTitle = 'errors.auth.title';
  static const String authSubtitle = 'errors.auth.subtitle';
  static const String authAction = 'errors.auth.action';

  // ==================== Cache Error Messages ====================
  static const String cacheTitle = 'errors.cache.title';
  static const String cacheSubtitle = 'errors.cache.subtitle';
  static const String cacheAction = 'errors.cache.action';

  // ==================== Validation Error Messages ====================
  static const String validationTitle = 'errors.validation.title';
  static const String validationSubtitle = 'errors.validation.subtitle';
  static const String validationAction = 'errors.validation.action';

  // ==================== Unknown Error Messages ====================
  static const String unknownTitle = 'errors.unknown.title';
  static const String unknownSubtitle = 'errors.unknown.subtitle';
  static const String unknownAction = 'errors.unknown.action';

  // ==================== Feature-specific Errors ====================
  static const String featuredClinicsError = 'errors.clinics.featured';
  static const String nearbyClinicsError = 'errors.clinics.nearby';
  static const String allClinicsError = 'errors.clinics.all';
  static const String toggleFavoriteError = 'errors.clinics.toggleFavorite';
}