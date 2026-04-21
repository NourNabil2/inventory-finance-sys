// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  /// Login — updates UserRepository singleton on success
  Future<Either<Failure, void>> login({
    required String email,
    required String password,
  });

  /// Logout — clears UserRepository singleton
  Future<Either<Failure, void>> logout();
}