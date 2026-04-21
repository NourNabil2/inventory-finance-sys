import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/alerts/domain/entities/alert_entity.dart';
import 'package:bungee_manage_sys/features/alerts/domain/usecases/dismiss_alert_usecase.dart';
import 'package:bungee_manage_sys/features/alerts/domain/usecases/get_alerts_usecase.dart';
import 'package:equatable/equatable.dart';

part 'alerts_state.dart';

class AlertsCubit extends Cubit<AlertsState> {
  final GetAlertsUseCase _getAlertsUseCase;
  final DismissAlertUseCase _dismissAlertUseCase;

  AlertsCubit(this._getAlertsUseCase, this._dismissAlertUseCase) : super(AlertsInitial());

  Future<void> fetchAlerts() async {
    emit(AlertsLoading());
    final result = await _getAlertsUseCase();
    result.fold(
          (failure) => emit(AlertsError(failure.message)),
          (alerts) => emit(AlertsLoaded(alerts: alerts)),
    );
  }

  Future<void> dismissAlert(String id) async {
    final currentState = state;
    if (currentState is! AlertsLoaded) return;

    // Optimistic UI Update: نمسح الإشعار من الشاشة فوراً عشان اليوزر ميحسش بتأخير
    final updatedList = currentState.alerts.where((a) => a.id != id).toList();
    emit(AlertsLoaded(alerts: updatedList));

    // ننفذ الحذف في الخلفية
    final result = await _dismissAlertUseCase(id);
    result.fold(
          (failure) => fetchAlerts(), // لو حصل إيرور في السيرفر، نرجع نحمل اللستة القديمة
          (_) {}, // لو نجح مفيش حاجة هنعملها لأننا مسحناه من الشاشة خلاص
    );
  }
}