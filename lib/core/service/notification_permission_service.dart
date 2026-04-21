// // lib/core/services/notification_permission_service.dart
//
// import 'package:permission_handler/permission_handler.dart';
//
// class NotificationPermissionService {
//   /// Returns true if granted, false if denied — never throws
//   static Future<bool> requestPermission() async {
//     try {
//       final status = await Permission.notification.status;
//
//       if (status.isGranted) return true;
//
//       // Ask every time app launches (as required)
//       if (status.isDenied) {
//         final result = await Permission.notification.request();
//         return result.isGranted;
//       }
//
//       // Permanently denied — open settings silently, return false
//       if (status.isPermanentlyDenied) return false;
//
//       return false;
//     } catch (_) {
//       return false;
//     }
//   }
//
//   static Future<bool> isGranted() async {
//     try {
//       return await Permission.notification.isGranted;
//     } catch (_) {
//       return false;
//     }
//   }
// }