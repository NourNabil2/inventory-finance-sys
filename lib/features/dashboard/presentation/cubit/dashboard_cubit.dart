// lib/features/dashboard/presentation/cubit/dashboard_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/repositories/dashboard_repository.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit(this._repository) : super(DashboardInitial());

  Future<void> load() async {
    emit(DashboardLoading());

    final result = await _repository.getDashboardData();

    result.fold(
          (failure) => emit(DashboardError(failure.message)),
          (data) => emit(DashboardLoaded(data)),
    );
  }
}