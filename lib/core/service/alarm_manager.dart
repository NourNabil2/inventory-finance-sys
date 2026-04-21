// import 'package:alarm/alarm.dart';
// import 'package:clinic_app/features/alarm/screen/medication_alarm_screen.dart';
// import 'package:clinic_app/features/alarm/service/medication_alarm_service.dart';
// import 'package:flutter/material.dart';
//
// class AlarmManager {
//   final MedicationAlarmService _service = MedicationAlarmService();
//
//   void listenToAlarms(GlobalKey<NavigatorState> navKey) {
//     Alarm.ringStream.stream.listen((alarmSettings) {
//       navKey.currentState?.push(
//         MaterialPageRoute(
//           builder: (context) => MedicationAlarmScreen(alarmSettings: alarmSettings),
//           fullscreenDialog: true,
//         ),
//       );
//     });
//   }
//
//   Future<void> handleAppResume() async {
//     await _service.rescheduleRecurringAlarms();
//   }
// }