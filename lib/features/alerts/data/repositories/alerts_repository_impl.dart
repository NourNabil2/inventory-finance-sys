import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/alerts/data/datasources/alerts_remote_datasource.dart';
import 'package:bungee_manage_sys/features/alerts/data/model/alert_model.dart';
import 'package:bungee_manage_sys/features/alerts/domain/entities/alert_entity.dart';
import 'package:bungee_manage_sys/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:dartz/dartz.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  final AlertsRemoteDataSource _ds;

  AlertsRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<AlertEntity>>> getAlerts() async {
    try {
      final raw = await _ds.getAlerts();

      final alerts = raw.map((json) => AlertModel.fromJson(json)).toList();

      return Right(alerts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> dismissAlert(String id) async {
    try {
      await _ds.dismissAlert(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}