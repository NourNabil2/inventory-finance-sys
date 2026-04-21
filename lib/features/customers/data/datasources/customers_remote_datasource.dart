// lib/features/customers/data/datasources/customers_remote_datasource.dart

import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CustomersRemoteDataSource {
  Future<List<Map<String, dynamic>>> getCustomers();
  Future<void> saveCustomer(Map<String, dynamic> data);
  Future<void> deleteCustomer(String id);
  Future<bool> customerHasInvoices(String customerId);
  Future<bool> customerHasChecks(String customerId);
}

class CustomersRemoteDataSourceImpl implements CustomersRemoteDataSource {
  final SupabaseClient _supabase;
  CustomersRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      final response = await _supabase
          .from('customers')
      // wallet_balance is now included automatically via SELECT *
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> saveCustomer(Map<String, dynamic> data) async {
    try {
      await _supabase.from('customers').upsert(data);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    if (await customerHasInvoices(id)) throw const CustomerHasInvoicesException();
    if (await customerHasChecks(id))   throw const CustomerHasChecksException();
    try {
      await _supabase.from('customers').delete().eq('id', id);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<bool> customerHasInvoices(String customerId) async {
    try {
      final r = await _supabase
          .from('invoices')
          .select('id')
          .eq('customer_id', customerId)
          .limit(1);
      return r.isNotEmpty;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<bool> customerHasChecks(String customerId) async {
    try {
      final r = await _supabase
          .from('checks')
          .select('id')
          .eq('customer_id', customerId)
          .limit(1);
      return r.isNotEmpty;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }
}

class CustomerHasInvoicesException implements Exception {
  final String message;
  const CustomerHasInvoicesException([this.message = 'customer.has_invoices']);
  @override
  String toString() => message;
}

class CustomerHasChecksException implements Exception {
  final String message;
  const CustomerHasChecksException([this.message = 'customer.has_checks']);
  @override
  String toString() => message;
}