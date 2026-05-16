// lib/features/suppliers/data/datasources/suppliers_remote_datasource.dart

import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SuppliersRemoteDataSource {
  // ── Supplier CRUD ─────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSuppliers();
  Future<void> saveSupplier(Map<String, dynamic> data);

  // ── Purchase invoices ─────────────────────────────────────
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

  // ── Service invoices (rental billed TO supplier) ──────────
  Future<List<Map<String, dynamic>>> getSupplierServiceInvoices(
      String supplierId);

  /// Full itemised invoice via new RPC.
  Future<String> createFullServiceInvoiceForSupplier({
    required String supplierId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  });

  /// Legacy simple amount-only invoice.
  Future<String> createServiceInvoiceForSupplier({
    required String supplierId,
    required double totalAmount,
    String? notes,
  });

  // ── Unified supplier clearing ─────────────────────────────
  Future<Map<String, dynamic>> executeSupplierClearing({
    required String supplierId,
    required double amount,
    String? notes,
    String? createdBy,
  });

  // ── Legacy cross-customer clearing ────────────────────────
  Future<void> updateLinkedCustomer({
    required String supplierId,
    required String? customerId,
  });
  Future<Map<String, dynamic>> executeClearing({
    required String supplierId,
    required String customerId,
    required double amount,
    String? notes,
    String? createdBy,
  });

  Future<Map<String, dynamic>> executeFlexibleClearing({
    required String supplierId,
    required String clearingType,
    double offsetAmount,
    double cashAmount,
    String cashMethod,
    String? notes,
    String? createdBy,
  });

  Future<void> recordServicePayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class SuppliersRemoteDataSourceImpl implements SuppliersRemoteDataSource {
  final SupabaseClient _supabase;
  SuppliersRemoteDataSourceImpl(this._supabase);

  // ── Suppliers ─────────────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    try {
      final res = await _supabase.from('suppliers').select().order('name');
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

  // ── Purchase invoices ─────────────────────────────────────

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
        'p_items': itemsData,
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
        'p_amount': amount,
        'p_method': method,
      });
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  // ── Service invoices ──────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getSupplierServiceInvoices(
      String supplierId) async {
    try {
      final res = await _supabase.rpc(
        'get_supplier_service_invoices',
        params: {'p_supplier_id': supplierId},
      );
      // RPC returns a JSONB array — cast each element
      final list = (res as List?) ?? [];
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<String> createFullServiceInvoiceForSupplier({
    required String supplierId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    try {
      final result = await _supabase.rpc(
        'create_full_supplier_service_invoice',
        params: {
          'p_supplier_id': supplierId,
          'p_invoice': invoiceData,
          'p_items': itemsData,
        },
      );
      return result as String;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<String> createServiceInvoiceForSupplier({
    required String supplierId,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      final res = await _supabase.rpc(
        'create_service_invoice_for_supplier',
        params: {
          'p_supplier_id': supplierId,
          'p_total_amount': totalAmount,
          if (notes != null && notes.isNotEmpty) 'p_notes': notes,
        },
      );
      return res as String;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  // ── Unified supplier clearing ─────────────────────────────

  @override
  Future<Map<String, dynamic>> executeSupplierClearing({
    required String supplierId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    try {
      final res = await _supabase.rpc(
        'execute_supplier_clearing',
        params: {
          'p_supplier_id': supplierId,
          'p_amount': amount,
          if (notes != null) 'p_notes': notes,
          if (createdBy != null) 'p_created_by': createdBy,
        },
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  // ── Legacy cross-customer clearing ────────────────────────

  @override
  Future<void> updateLinkedCustomer({
    required String supplierId,
    required String? customerId,
  }) async {
    try {
      await _supabase
          .from('suppliers')
          .update({'linked_customer_id': customerId}).eq('id', supplierId);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> executeClearing({
    required String supplierId,
    required String customerId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    try {
      final res = await _supabase.rpc(
        'execute_clearing_transaction',
        params: {
          'p_supplier_id': supplierId,
          'p_customer_id': customerId,
          'p_amount': amount,
          if (notes != null) 'p_notes': notes,
          if (createdBy != null) 'p_created_by': createdBy,
        },
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> executeFlexibleClearing({
    required String supplierId,
    required String clearingType,
    double offsetAmount = 0,
    double cashAmount = 0,
    String cashMethod = 'safe',
    String? notes,
    String? createdBy,
  }) async {
    try {
      final res = await _supabase.rpc(
        'execute_flexible_supplier_clearing',
        params: {
          'p_supplier_id': supplierId,
          'p_clearing_type': clearingType,
          'p_offset_amount': offsetAmount,
          'p_cash_amount': cashAmount,
          'p_cash_method': cashMethod,
          if (notes != null) 'p_notes': notes,
          if (createdBy != null) 'p_created_by': createdBy,
        },
      );
      return Map<String, dynamic>.from(res as Map);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> recordServicePayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  }) async {
    try {
      await _supabase.rpc('record_service_invoice_payment', params: {
        'p_invoice_id': invoiceId,
        'p_supplier_id': supplierId,
        'p_amount': amount,
        'p_method': method,
      });
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }
}