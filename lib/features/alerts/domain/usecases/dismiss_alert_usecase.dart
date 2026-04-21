import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:dartz/dartz.dart';

class DismissAlertUseCase {
  final AlertsRepository repository;

  DismissAlertUseCase(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.dismissAlert(id);
  }
}