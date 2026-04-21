// lib/features/suppliers/data/datasources/suppliers_remote_datasource.dart

import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SuppliersRemoteDataSource {
  Future<List<Map<String, dynamic>>> getSuppliers();
  Future<void> saveSupplier(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getSupplierInvoices(String supplierId);
  Future<Map<String, dynamic>> getInvoiceDetails(String invoiceId);
  Future<String> createSupplierInvoice({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  });
  Future<Map<String, dynamic>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  });
}

class SuppliersRemoteDataSourceImpl implements SuppliersRemoteDataSource {
  final SupabaseClient _supabase;
  SuppliersRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final res = await _supabase
          .from('suppliers')
          .select()
          .order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> saveSupplier(Map<String, dynamic> data) async {
    try {
      await _supabase.from('suppliers').upsert(data);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSupplierInvoices(
      String supplierId) async {
    try {
      final res = await _supabase
          .from('supplier_invoices')
          .select('*, supplier_invoice_items(*)')
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> getInvoiceDetails(String invoiceId) async {
    try {
      final res = await _supabase
          .from('supplier_invoices')
          .select('*, supplier_invoice_items(*)')
          .eq('id', invoiceId)
          .single();
      return Map<String, dynamic>.from(res);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<String> createSupplierInvoice({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    try {
      final result = await _supabase.rpc('create_supplier_invoice', params: {
        'p_invoice': invoiceData,
        'p_items':   itemsData,
      });
      return result as String;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    try {
      final res = await _supabase.rpc('record_supplier_payment', params: {
        'p_invoice_id': invoiceId,
        'p_amount':     amount,
        'p_method':     method,
      });
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }
}