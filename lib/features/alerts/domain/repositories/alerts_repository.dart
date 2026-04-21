import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/alerts/domain/entities/alert_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AlertsRepository {
  Future<Either<Failure, List<AlertEntity>>> getAlerts();
  Future<Either<Failure, void>> dismissAlert(String id);
}