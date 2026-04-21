import 'package:dartz/dartz.dart';
import 'failures.dart';
import 'error_handler.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultVoid = Future<Either<Failure, Unit>>;

class ResultHandler {
  /// Handle async operations that return a value
  static Future<Either<Failure, T>> handle<T>(
      Future<T> Function() function,
      ) async {
    try {
      final result = await function();
      return Right(result);
    } catch (error, stackTrace) {
      return Left(ErrorHandler.handleException(error, stackTrace));
    }
  }

  /// Handle async operations that return void
  static Future<Either<Failure, Unit>> handleVoid(
      Future<void> Function() function,
      ) async {
    try {
      await function();
      return const Right(unit);
    } catch (error, stackTrace) {
      return Left(ErrorHandler.handleException(error, stackTrace));
    }
  }
}