import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/alerts/domain/entities/alert_entity.dart';
import 'package:bungee_manage_sys/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:dartz/dartz.dart';

class GetAlertsUseCase {
  final AlertsRepository repository;

  GetAlertsUseCase(this.repository);

  Future<Either<Failure, List<AlertEntity>>> call() async {
    return await repository.getAlerts();
  }
}