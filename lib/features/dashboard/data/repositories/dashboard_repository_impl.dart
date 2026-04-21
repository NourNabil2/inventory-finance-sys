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
      final raw = await _remoteDataSource.getDashboardData();

      return DashboardModel.fromRaw(
        transactions: raw['transactions'],
        activeInvoices: raw['activeInvoices'],
        customers: raw['customers'],
        recentInvoicesRaw: raw['recentInvoices'],
        monthlyRaw: raw['monthlyRevenues'],
        previousMonthRevenue: raw['previousMonthRevenue'] as double, // NEW
      );
    });
  }
}