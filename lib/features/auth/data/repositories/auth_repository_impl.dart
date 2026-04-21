// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:bungee_manage_sys/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bungee_manage_sys/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _remoteDataSource.login(email: email, password: password);
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDataSource.logout();
      return const Right(null);
    } on Failure catch (f) {
      return Left(f);
    }
  }
}