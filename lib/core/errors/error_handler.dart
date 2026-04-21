import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {

  static const Map<String, String> _authMessageMap = {
    'invalid login credentials':                'errors.server.invalidCredentials',
    'email not confirmed':                      'errors.server.accountNotVerified',
    'user already registered':                  'errors.server.emailTaken',
    'user not found':                           'errors.server.userNotFound',
    'token has expired':                        'errors.server.tokenExpired',
    'email link is invalid or has expired':     'errors.server.tokenExpired',
    'too many requests':                        'errors.server.tooManyRequests',
    'password should be at least 6 characters': 'errors.validation.passwordMinLength',
  };

  static const Map<String, String> _pgCodeMap = {
    '23505': 'errors.server.emailTaken',    // unique_violation
    '23503': 'errors.server.badRequest',    // foreign_key_violation
    '23502': 'errors.server.invalidData',   // not_null_violation
    '42P01': 'errors.server.notFound',      // undefined_table
    'PGRST116': 'errors.server.notFound',   // row not found
  };

  // ── Entry point ───────────────────────────────────────────────────────────
  static Failure handleException(Object error, [StackTrace? stackTrace]) {
    _log(error, stackTrace);

    return switch (error) {
      PostgrestException e  => _handlePostgrest(e),
      AuthException e       => _handleAuth(e),
      StorageException e    => ServerFailure(e.message, 'STORAGE_ERROR'),
      SocketException _     => NetworkFailure('errors.network.connection'.tr(), 'NO_INTERNET'),
      ServerException e     => ServerFailure(e.message, e.code),
      NetworkException e    => NetworkFailure(e.message, e.code),
      CacheException e      => CacheFailure(e.message, e.code),
      ValidationException e => ValidationFailure(e.message, e.code),
      UnauthorizedException e => UnauthorizedFailure(e.message, e.code),
      _ => ServerFailure('errors.server.unexpected'.tr(), 'UNKNOWN_ERROR'),
    };
  }

  // ── Handlers ──────────────────────────────────────────────────────────────
  static Failure _handleAuth(AuthException e) {
    final key = _authMessageMap[e.message.toLowerCase().trim()];
    final message = key != null ? key.tr() : e.message;
    final isUnauth = e.statusCode == '401' || e.message.contains('credentials');
    return isUnauth
        ? UnauthorizedFailure(message, e.statusCode ?? 'AUTH_ERROR')
        : ServerFailure(message, e.statusCode ?? 'AUTH_ERROR');
  }

  static Failure _handlePostgrest(PostgrestException e) {
    final key = _pgCodeMap[e.code];
    if (key != null) return ValidationFailure(key.tr(), e.code ?? 'DB_ERROR');
    return ServerFailure(
      e.message.isNotEmpty ? e.message : 'errors.server.unexpected'.tr(),
      e.code ?? 'DB_ERROR',
    );
  }

  // ── Logging ───────────────────────────────────────────────────────────────
  static void _log(Object error, StackTrace? stackTrace) {
    print('Error: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');
  }
}