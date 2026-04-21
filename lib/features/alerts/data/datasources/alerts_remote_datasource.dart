import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AlertsRemoteDataSource {
  Future<List<Map<String, dynamic>>> getAlerts();
  Future<void> dismissAlert(String id);
}

class AlertsRemoteDataSourceImpl implements AlertsRemoteDataSource {
  final SupabaseClient _supabase;
  AlertsRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getAlerts() async {
    try {
      final res = await _supabase.rpc('get_overdue_alerts');
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> dismissAlert(String id) async {
    try {
      await _supabase.rpc('dismiss_alert', params: {'p_invoice_item_id': id});
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }
}