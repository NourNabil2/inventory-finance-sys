part of 'alerts_cubit.dart';

abstract class AlertsState extends Equatable {
  const AlertsState();

  @override
  List<Object> get props => [];
}

class AlertsInitial extends AlertsState {}

class AlertsLoading extends AlertsState {}

class AlertsLoaded extends AlertsState {
  final List<AlertEntity> alerts;

  const AlertsLoaded({required this.alerts});

  @override
  List<Object> get props => [alerts];
}

class AlertsError extends AlertsState {
  final String message;

  const AlertsError(this.message);

  @override
  List<Object> get props => [message];
}