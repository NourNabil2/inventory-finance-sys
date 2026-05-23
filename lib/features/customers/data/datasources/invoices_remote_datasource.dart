// lib/features/customers/data/datasources/invoices_remote_datasource.dart

import 'dart:convert';
import 'dart:developer';

import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class InvoicesRemoteDataSource {
  Future<List<Map<String, dynamic>>> getCustomerInvoices(String customerId);
  Future<Map<String, dynamic>> getInvoiceDetails(String invoiceId);
  Future<Map<String, dynamic>> getInvoicePaymentSummary(String invoiceId);
  Future<List<Map<String, dynamic>>> getCustomerInvoicesForExport({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<String> createInvoiceWithPayment({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
    required double amountPaid,
    required String method,
  });

  Future<Map<String, dynamic>> recordPaymentAndGetSummary({
    required String invoiceId,
    required double amount,
    required String method,
  });

  /// [existingUpdates] — list of objects already converted by the repository:
  /// each item: { id, new_days, qty, price_per_day, item_discount }
  Future<void> editInvoice({
    required String invoiceId,
    required List<Map<String, dynamic>> newItems,
    required List<Map<String, dynamic>> existingUpdates, // ← List جاهزة من الـ repository
    List<String>? deletedItemIds,
    double? newDiscount,
    String? newStatus,
    String? jobName,
    String? production,
  });

  Future<void> updateInvoiceStatus(String invoiceId, String status);
  Future<void> returnSingleItem(String invoiceItemId, {int? qty});
  Future<void> returnItems(String invoiceId, List<String> itemIds);
}

class InvoicesRemoteDataSourceImpl implements InvoicesRemoteDataSource {
  final SupabaseClient _supabase;
  InvoicesRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getCustomerInvoices(String customerId) async {
    try {
      final res = await _supabase
          .from('invoices')
          .select('''
            id, customer_id, created_by, invoice_number,
            total_amount, discount, status, created_at,
            job_name, production,
            invoice_items(id, qty, returned_qty, status)
          ''')
          .eq('customer_id', customerId)
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
          .from('invoices')
          .select('*, invoice_items(*, items(id, name, model))')
          .eq('id', invoiceId)
          .single();
      return Map<String, dynamic>.from(res);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> getInvoicePaymentSummary(String invoiceId) async {
    try {
      final res = await _supabase.rpc(
        'get_invoice_payment_summary',
        params: {'p_invoice_id': invoiceId},
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<String> createInvoiceWithPayment({
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
    required double amountPaid,
    required String method,
  }) async {
    try {
      final result = await _supabase.rpc('create_invoice_with_payment', params: {
        'p_invoice':      invoiceData,
        'p_items':        itemsData,
        'p_amount_paid':  amountPaid,
        'p_method':       method,
      });
      return result as String;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> recordPaymentAndGetSummary({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    try {
      final res = await _supabase.rpc('record_invoice_payment', params: {
        'p_invoice_id': invoiceId,
        'p_amount':     amount,
        'p_method':     method,
      });
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> editInvoice({
    required String invoiceId,
    required List<Map<String, dynamic>> newItems,
    required List<Map<String, dynamic>> existingUpdates, // ← List جاهزة، مش Map
    List<String>? deletedItemIds,
    double? newDiscount,
    String? newStatus,
    String? jobName,
    String? production,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_invoice_id':        invoiceId,
        'p_new_items':         newItems,
        'p_existing_updates':  existingUpdates, // ← بنبعتها مباشرة للـ RPC
      };
      if (newDiscount != null)  params['p_new_discount']      = newDiscount;
      if (jobName != null)      params['p_job_name']          = jobName;
      if (production != null)   params['p_production']        = production;
      if (newStatus != null)    params['p_new_status']        = newStatus;
      if (deletedItemIds != null && deletedItemIds.isNotEmpty) {
        params['p_deleted_item_ids'] = deletedItemIds
            .map((id) => {'id': id})
            .toList();
      }
      log('=== editInvoice params ===');
      log('p_invoice_id: $invoiceId');
      log('p_new_items: ${jsonEncode(newItems)}');
      log('p_existing_updates: ${jsonEncode(existingUpdates)}');
      log('p_deleted_item_ids: $deletedItemIds');
      log('p_new_discount: $newDiscount');
      log('p_new_status: $newStatus');
      await _supabase.rpc('edit_invoice_transaction', params: params);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      await _supabase.rpc('change_invoice_status', params: {
        'p_invoice_id': invoiceId,
        'p_new_status': status,
      });
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> returnSingleItem(String invoiceItemId, {int? qty}) async {
    try {
      await _supabase.rpc('return_single_invoice_item', params: {
        'p_invoice_item_id': invoiceItemId,
        if (qty != null) 'p_qty': qty,
      });
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> returnItems(String invoiceId, List<String> itemIds) async {
    try {
      await _supabase.rpc('return_invoice_items', params: {
        'p_invoice_id': invoiceId,
        'p_item_ids':   itemIds,
      });
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCustomerInvoicesForExport({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('invoices')
          .select('*, invoice_items(*, items(id, name, model))')
          .eq('customer_id', customerId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
        query = query.lte('created_at', endOfDay.toIso8601String());
      }

      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }
}