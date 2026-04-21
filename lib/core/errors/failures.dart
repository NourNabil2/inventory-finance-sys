import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

/// Base Failure class
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];

  /// Get localized error message key
  String get errorKey;

  /// Get error type for tracking/analytics
  String get errorType;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.code]);

  @override
  String get errorKey => 'errors.server.title'.tr();

  @override
  String get errorType => 'server_error'.tr();
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.code]);

  @override
  String get errorKey => 'errors.network.title'.tr();

  @override
  String get errorType => 'network_error'.tr();
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.code]);

  @override
  String get errorKey => 'errors.cache.title'.tr();

  @override
  String get errorType => 'cache_error'.tr();
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.code]);

  @override
  String get errorKey => 'errors.server.invalidData'.tr();

  @override
  String get errorType => 'validation_error'.tr();
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message, [super.code]);

  @override
  String get errorKey => 'errors.auth.title'.tr();

  @override
  String get errorType => 'unauthorized_error'.tr();
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);

  @override
  String get errorKey => 'errors.auth.title'.tr();

  @override
  String get errorType => 'unauthorized_error'.tr();
}

class AccountNotVerifiedFailure extends Failure {
  final String email;

  const AccountNotVerifiedFailure(this.email)
      : super('errors.server.accountNotVerified');

  @override
  String get errorKey => 'errors.server.accountNotVerified'.tr();

  @override
  String get errorType => 'account_not_verified';

  @override
  List<Object?> get props => [email, message, code];
}


