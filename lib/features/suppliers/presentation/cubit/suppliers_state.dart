// lib/features/suppliers/presentation/cubit/suppliers_state.dart
part of 'suppliers_cubit.dart';

// ── Status enums ──────────────────────────────────────────────
enum SuppliersStatus { initial, loading, success, failure }
enum SupplierFormStatus { idle, submitting, submitted, error }

// ── Main state ────────────────────────────────────────────────
final class SuppliersState extends Equatable {
  final SuppliersStatus     status;
  final SupplierFormStatus  formStatus;
  final List<SupplierEntity> suppliers;
  final List<SupplierEntity> filtered;
  final SupplierEntity?     selectedSupplier;
  final List<SupplierInvoiceEntity> invoices;
  final SupplierInvoiceEntity?      selectedInvoice;
  final String? errorMessage;
  final String  searchQuery;

  const SuppliersState({
    this.status       = SuppliersStatus.initial,
    this.formStatus   = SupplierFormStatus.idle,
    this.suppliers    = const [],
    this.filtered     = const [],
    this.selectedSupplier,
    this.invoices     = const [],
    this.selectedInvoice,
    this.errorMessage,
    this.searchQuery  = '',
  });

  SuppliersState copyWith({
    SuppliersStatus?    status,
    SupplierFormStatus? formStatus,
    List<SupplierEntity>? suppliers,
    List<SupplierEntity>? filtered,
    SupplierEntity?     selectedSupplier,
    List<SupplierInvoiceEntity>? invoices,
    SupplierInvoiceEntity?       selectedInvoice,
    String?  errorMessage,
    String?  searchQuery,
    bool clearSelectedSupplier = false,
    bool clearSelectedInvoice  = false,
    bool clearError            = false,
    bool clearInvoices         = false,
  }) {
    return SuppliersState(
      status:           status          ?? this.status,
      formStatus:       formStatus      ?? this.formStatus,
      suppliers:        suppliers       ?? this.suppliers,
      filtered:         filtered        ?? this.filtered,
      selectedSupplier: clearSelectedSupplier ? null : selectedSupplier ?? this.selectedSupplier,
      invoices:         clearInvoices   ? [] : invoices ?? this.invoices,
      selectedInvoice:  clearSelectedInvoice ? null : selectedInvoice ?? this.selectedInvoice,
      errorMessage:     clearError      ? null : errorMessage ?? this.errorMessage,
      searchQuery:      searchQuery     ?? this.searchQuery,
    );
  }

  bool get isLoading   => status == SuppliersStatus.loading;
  bool get hasError    => status == SuppliersStatus.failure;
  bool get hasSuppliers => filtered.isNotEmpty;

  @override
  List<Object?> get props => [
    status, formStatus, suppliers, filtered, selectedSupplier,
    invoices, selectedInvoice, errorMessage, searchQuery,
  ];
}