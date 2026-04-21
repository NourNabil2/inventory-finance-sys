import 'package:easy_localization/easy_localization.dart';
import '../errors/failures.dart';
import '../utils/app_constans.dart';
import '../utils/enums.dart';


class FailureMessageMapper {
  /// Map failure to error type
  static ErrorType mapFailureToErrorType(Failure failure) {
    if (failure is NetworkFailure) {
      return ErrorType.network;
    } else if (failure is UnauthorizedFailure) {
      return ErrorType.auth;
    } else if (failure is ValidationFailure) {
      return ErrorType.validation;
    } else if (failure is CacheFailure) {
      return ErrorType.cache;
    } else if (failure is ServerFailure) {
      return ErrorType.server;
    } else {
      return ErrorType.unknown;
    }
  }

  /// Get title based on failure type
  static String mapFailureToMessage(Failure failure) {
    final errorType = mapFailureToErrorType(failure);

    switch (errorType) {
      case ErrorType.network:
        return ErrorMessages.networkTitle.tr();
      case ErrorType.auth:
        return ErrorMessages.authTitle.tr();
      case ErrorType.cache:
        return ErrorMessages.cacheTitle.tr();
      case ErrorType.server:
        return ErrorMessages.serverTitle.tr();
      case ErrorType.validation:
        return ErrorMessages.serverTitle.tr();
      case ErrorType.unknown:
        return ErrorMessages.unknownTitle.tr();
    }
  }

  /// Get subtitle - returns the actual error message or default
  static String getSubtitle(Failure failure) {
    // If the failure has a custom message, use it
    if (failure.message.isNotEmpty && !failure.message.startsWith('errors.')) {
      return failure.message;
    }

    // Otherwise, return the default subtitle based on error type
    final errorType = mapFailureToErrorType(failure);

    switch (errorType) {
      case ErrorType.network:
        return ErrorMessages.networkSubtitle.tr();
      case ErrorType.auth:
        return ErrorMessages.authSubtitle.tr();
      case ErrorType.cache:
        return ErrorMessages.cacheSubtitle.tr();
      case ErrorType.server:
        return ErrorMessages.serverSubtitle.tr();
      case ErrorType.validation:
        return failure.message.isNotEmpty
            ? failure.message
            : ErrorMessages.serverSubtitle.tr();
      case ErrorType.unknown:
        return ErrorMessages.unknownSubtitle.tr();
    }
  }

  /// Get action button label
  static String getActionMessage(Failure failure) {
    final errorType = mapFailureToErrorType(failure);

    switch (errorType) {
      case ErrorType.network:
        return ErrorMessages.networkAction.tr();
      case ErrorType.auth:
        return ErrorMessages.authAction.tr();
      case ErrorType.cache:
        return ErrorMessages.cacheAction.tr();
      case ErrorType.server:
        return ErrorMessages.serverAction.tr();
      case ErrorType.validation:
        return ErrorMessages.serverAction.tr();
      case ErrorType.unknown:
        return ErrorMessages.unknownAction.tr();
    }
  }
}