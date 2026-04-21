abstract class Routes {
  static const String onboarding = '/onboarding';

  static const String dashBoard = '/dashBoard';
  static const String inventory = '/inventory';
  static const String customers  = '/customers';   // TODO
  static const String invoices   = '/invoices';    // TODO
  static const String finance    = '/finance';     // TODO
  static const String checks     = '/checks';      // TODO
  static const String suppliers  = '/suppliers';   // TODO

  // auth
  static const String auth = '/auth';
  static const String verification = '/verification';
  static const String forgotPassword = '/forgotPassword';
  static const String resetPassword = '/resetPassword';
  // Patient sub-routes
  static const String patientHome = '/patient-home';
  static const String medicationDetails = '/medication-details';
  // booking
  static const String booking = '/booking';
  static const String bookingDetails = '/booking-details';
  // screens
  static const String search = '/search';
}