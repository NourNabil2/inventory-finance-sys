// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/core/errors/result_handler.dart';
import 'package:bungee_manage_sys/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bungee_manage_sys/features/dashboard/data/models/dashboard_model.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, DashboardEntity>> getDashboardData() {
    return ResultHandler.handle(() async {
      final rawData = await _remoteDataSource.getDashboardData();

      return DashboardModel.fromRaw(
        transactions: rawData['transactions'],
        activeInvoices: rawData['activeInvoices'],
        customers: rawData['customers'],
        recentInvoicesRaw: rawData['recentInvoices'],
        supplierDebtsRaw: rawData['supplierDebts'],
        monthlyRaw: rawData['monthlyRevenues'],
        previousMonthRevenue: rawData['previousMonthRevenue'],
      );
    });
  }
}