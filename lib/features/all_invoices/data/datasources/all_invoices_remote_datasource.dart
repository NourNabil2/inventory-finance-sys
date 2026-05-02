// lib/features/all_invoices/data/datasources/all_invoices_remote_datasource.dart

import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AllInvoicesRemoteDataSource {
  Future<Map<String, dynamic>> getAllInvoicesPaginated({
    required InvoiceFilterParams filters,
    required int page,
    required int pageSize,
  });
}

class AllInvoicesRemoteDataSourceImpl implements AllInvoicesRemoteDataSource {
  final SupabaseClient _supabase;

  AllInvoicesRemoteDataSourceImpl(this._supabase);

  @override
  Future<Map<String, dynamic>> getAllInvoicesPaginated({
    required InvoiceFilterParams filters,
    required int page,
    required int pageSize,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      // ── Step 1: جيب البيانات عبر RPC (بيدعم OR على customers.name) ──
      final statusStr = switch (filters.statusFilter) {
        InvoiceStatusFilter.active    => 'active',
        InvoiceStatusFilter.completed => 'completed',
        InvoiceStatusFilter.canceled  => 'canceled',
        InvoiceStatusFilter.draft     => 'draft',
        InvoiceStatusFilter.all       => 'all',
      };

      final endOfDay = filters.endDate == null ? null : DateTime(
        filters.endDate!.year,
        filters.endDate!.month,
        filters.endDate!.day,
        23, 59, 59, 999,
      );

      final rpcRes = await _supabase.rpc(
        'search_invoices_paginated',
        params: {
          'p_search':     filters.searchQuery.isEmpty
              ? null
              : filters.searchQuery.trim(),
          'p_status':     statusStr,
          'p_start_date': filters.startDate?.toIso8601String(),
          'p_end_date':   endOfDay?.toIso8601String(),
          'p_offset':     offset,
          'p_limit':      pageSize,
        },
      ) as Map<String, dynamic>;

      final totalCount = (rpcRes['total'] as num).toInt();
      final dataList   = (rpcRes['data']  as List? ?? [])
          .cast<Map<String, dynamic>>();

      // ── Step 2: حوّل الـ raw rows لـ format مناسب للـ model ──────────
      final normalizedList = dataList.map((row) => <String, dynamic>{
        'id':             row['id'],
        'customer_id':    row['customer_id'],
        'invoice_number': row['invoice_number'],
        'total_amount':   row['total_amount'],
        'discount':       row['discount'],
        'status':         row['status'],
        'created_at':     row['created_at'],
        'customers': {
          'id':    row['cust_id'],
          'name':  row['cust_name'],
          'phone': row['cust_phone'],
        },
      }).toList();

      // ── Step 3: جيب payment summaries بـ batch RPC ──────────────────
      Map<String, Map<String, dynamic>> summariesMap = {};

      if (normalizedList.isNotEmpty) {
        final invoiceIds =
        normalizedList.map((r) => r['id'] as String).toList();

        final summariesRes = await _supabase.rpc(
          'get_invoices_payment_summary_batch',
          params: {'p_invoice_ids': invoiceIds},
        ) as List;

        summariesMap = {
          for (final s in summariesRes)
            (s['invoice_id'] as String): s as Map<String, dynamic>,
        };
      }

      // ── Step 4: اربط الـ summaries بالـ rows ────────────────────────
      var processed = normalizedList.map((row) {
        final summary = summariesMap[row['id'] as String];

        final fallbackNet =
            ((row['total_amount'] as num?)?.toDouble() ?? 0.0) -
                ((row['discount']     as num?)?.toDouble() ?? 0.0);

        final netTotal  = (summary?['net_total']  as num?)?.toDouble()
            ?? fallbackNet.clamp(0.0, double.infinity);
        final totalPaid = (summary?['total_paid'] as num?)?.toDouble() ?? 0.0;
        final remaining = (summary?['remaining']  as num?)?.toDouble()
            ?? (netTotal - totalPaid).clamp(0.0, double.infinity);

        return <String, dynamic>{
          ...row,
          '_net_total':  netTotal,
          '_total_paid': totalPaid,
          '_remaining':  remaining,
        };
      }).toList();

      // ── Step 5: payment filter client-side ───────────────────────────
      if (filters.paymentFilter != PaymentStatusFilter.all) {
        processed = processed.where((row) {
          final totalPaid = row['_total_paid'] as double;
          final remaining = row['_remaining']  as double;
          final netTotal  = row['_net_total']  as double;
          return switch (filters.paymentFilter) {
            PaymentStatusFilter.fullyPaid =>
            remaining <= 0 && totalPaid > 0,
            PaymentStatusFilter.hasDebt =>
            remaining > 0 && totalPaid > 0,
            PaymentStatusFilter.unpaid =>
            totalPaid == 0 && netTotal > 0,
            PaymentStatusFilter.all => true,
          };
        }).toList();
      }

      return {
        'data':        processed,
        'total_count': totalCount,
      };
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  /// مشترك بين dataQuery و countQuery عشان منكررش نفس الكود
  T _applyFilters<T>(T query, InvoiceFilterParams filters) {
    var q = query as dynamic;

    if (filters.startDate != null) {
      q = q.gte('created_at', filters.startDate!.toIso8601String());
    }
    if (filters.endDate != null) {
      final endOfDay = DateTime(
        filters.endDate!.year,
        filters.endDate!.month,
        filters.endDate!.day,
        23, 59, 59, 999,
      );
      q = q.lte('created_at', endOfDay.toIso8601String());
    }
    if (filters.statusFilter != InvoiceStatusFilter.all) {
      final statusStr = switch (filters.statusFilter) {
        InvoiceStatusFilter.active    => 'active',
        InvoiceStatusFilter.completed => 'completed',
        InvoiceStatusFilter.canceled  => 'canceled',
        InvoiceStatusFilter.draft     => 'draft',
        InvoiceStatusFilter.all       => null,
      };
      if (statusStr != null) q = q.eq('status', statusStr);
    }

    // ── Search: اسم العميل أو رقم الفاتورة ──────────────────────────────
    if (filters.searchQuery.isNotEmpty) {
      final term = filters.searchQuery.trim();

      // لو الـ search رقم — ابحث في invoice_number بالظبط أو بالـ ilike
      // لو نص — ابحث في اسم العميل
      // الـ OR في PostgREST بيتعمل عن طريق passing comma-separated conditions
      q = q.or(
        'invoice_number.ilike.%$term%,customers.name.ilike.%$term%',
      );
    }

    return q as T;
  }
}