// lib/features/all_invoices/domain/entities/all_invoices_entity.dart

import 'package:equatable/equatable.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';

/// Extended invoice entity that includes customer name for display in the all-invoices list
class AllInvoiceEntity extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? invoiceNumber;
  final double totalAmount;
  final double discount;
  final InvoiceStatus status;
  final DateTime createdAt;
  final List<InvoiceItemEntity> items;
  final double totalPaid;
  final double remaining;

  const AllInvoiceEntity({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.invoiceNumber,
    required this.totalAmount,
    this.discount = 0,
    required this.status,
    required this.createdAt,
    this.items = const [],
    this.totalPaid = 0,
    this.remaining = 0,
  });

  double get netTotal => (totalAmount - discount).clamp(0, double.infinity);

  double get discountPercent =>
      totalAmount == 0 ? 0 : (discount / totalAmount) * 100;

  bool get isFullyPaid => remaining <= 0;

  bool get hasDebt => remaining > 0;

  bool get isActive => status == InvoiceStatus.active;

  int get itemsCount => items.length;

  @override
  List<Object?> get props => [
        id,
        customerId,
        totalAmount,
        discount,
        status,
        createdAt,
        totalPaid,
        remaining,
      ];
}

/// Filter options for the all invoices page
class InvoiceFilterParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final InvoiceStatusFilter statusFilter;
  final PaymentStatusFilter paymentFilter;
  final String searchQuery;

  const InvoiceFilterParams({
    this.startDate,
    this.endDate,
    this.statusFilter = InvoiceStatusFilter.all,
    this.paymentFilter = PaymentStatusFilter.all,
    this.searchQuery = '',
  });

  InvoiceFilterParams copyWith({
    DateTime? startDate,
    DateTime? endDate,
    InvoiceStatusFilter? statusFilter,
    PaymentStatusFilter? paymentFilter,
    String? searchQuery,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return InvoiceFilterParams(
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      statusFilter: statusFilter ?? this.statusFilter,
      paymentFilter: paymentFilter ?? this.paymentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      statusFilter != InvoiceStatusFilter.all ||
      paymentFilter != PaymentStatusFilter.all ||
      searchQuery.isNotEmpty;

  @override
  List<Object?> get props =>
      [startDate, endDate, statusFilter, paymentFilter, searchQuery];
}

enum InvoiceStatusFilter { all, active, completed, canceled, draft }

enum PaymentStatusFilter { all, fullyPaid, hasDebt, unpaid }

/// Paginated result wrapper
class PaginatedInvoices extends Equatable {
  final List<AllInvoiceEntity> invoices;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  const PaginatedInvoices({
    required this.invoices,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  bool get hasNextPage => (currentPage * pageSize) < totalCount;
  bool get hasPreviousPage => currentPage > 1;
  int get totalPages => (totalCount / pageSize).ceil();

  @override
  List<Object?> get props =>
      [invoices, totalCount, currentPage, pageSize];
}
