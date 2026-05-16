// lib/features/suppliers/presentation/cubit/suppliers_state.dart
part of 'suppliers_cubit.dart';

// ── Status enums ──────────────────────────────────────────────
enum SuppliersStatus       { initial, loading, success, failure }
enum SupplierFormStatus    { idle, submitting, submitted, error }
enum ClearingStatus        { idle, loading, success, failure }
enum LinkCustomerStatus    { idle, loading, success, failure }
enum ServiceInvoicesStatus { idle, loading, success, failure }

/// Which tab is visible on the unified supplier profile page.
enum SupplierLedgerTab { purchases, services }

// ── Main state ────────────────────────────────────────────────
final class SuppliersState extends Equatable {
  final SuppliersStatus      status;
  final SupplierFormStatus   formStatus;
  final List<SupplierEntity> suppliers;
  final List<SupplierEntity> filtered;
  final SupplierEntity?      selectedSupplier;
  final String?              errorMessage;
  final String               searchQuery;

  // ── Purchase invoices (we buy FROM supplier) ──────────────
  final List<SupplierInvoiceEntity> invoices;
  final SupplierInvoiceEntity?      selectedInvoice;

  // ── Service invoices (supplier rents FROM us) ─────────────
  final List<ServiceInvoiceEntity>  serviceInvoices;
  final ServiceInvoiceEntity?       selectedServiceInvoice;   // ← ADDED
  final ServiceInvoicesStatus       serviceInvoicesStatus;

  // ── Active tab ────────────────────────────────────────────
  final SupplierLedgerTab activeTab;

  // ── Clearing ──────────────────────────────────────────────
  final ClearingStatus  clearingStatus;
  final ClearingResult? lastClearingResult;

  // ── Legacy link-customer ──────────────────────────────────
  final LinkCustomerStatus linkCustomerStatus;

  const SuppliersState({
    this.status                = SuppliersStatus.initial,
    this.formStatus            = SupplierFormStatus.idle,
    this.suppliers             = const [],
    this.filtered              = const [],
    this.selectedSupplier,
    this.invoices              = const [],
    this.selectedInvoice,
    this.serviceInvoices       = const [],
    this.selectedServiceInvoice,                               // ← ADDED
    this.serviceInvoicesStatus = ServiceInvoicesStatus.idle,
    this.activeTab             = SupplierLedgerTab.purchases,
    this.errorMessage,
    this.searchQuery           = '',
    this.clearingStatus        = ClearingStatus.idle,
    this.lastClearingResult,
    this.linkCustomerStatus    = LinkCustomerStatus.idle,
  });

  SuppliersState copyWith({
    SuppliersStatus?      status,
    SupplierFormStatus?   formStatus,
    List<SupplierEntity>? suppliers,
    List<SupplierEntity>? filtered,
    SupplierEntity?       selectedSupplier,
    List<SupplierInvoiceEntity>? invoices,
    SupplierInvoiceEntity?       selectedInvoice,
    List<ServiceInvoiceEntity>?  serviceInvoices,
    ServiceInvoiceEntity?        selectedServiceInvoice,       // ← ADDED
    ServiceInvoicesStatus?       serviceInvoicesStatus,
    SupplierLedgerTab?    activeTab,
    String?  errorMessage,
    String?  searchQuery,
    // ── clear flags ──────────────────────────────────────────
    bool clearSelectedSupplier       = false,
    bool clearSelectedInvoice        = false,
    bool clearSelectedServiceInvoice = false,                  // ← ADDED
    bool clearError                  = false,
    bool clearInvoices               = false,
    bool clearServiceInvoices        = false,
    bool clearClearingResult         = false,
    // ── clearing ─────────────────────────────────────────────
    ClearingStatus?    clearingStatus,
    ClearingResult?    lastClearingResult,
    // ── link-customer ─────────────────────────────────────────
    LinkCustomerStatus? linkCustomerStatus,
  }) {
    return SuppliersState(
      status:                 status               ?? this.status,
      formStatus:             formStatus           ?? this.formStatus,
      suppliers:              suppliers            ?? this.suppliers,
      filtered:               filtered             ?? this.filtered,
      selectedSupplier:       clearSelectedSupplier
          ? null
          : selectedSupplier  ?? this.selectedSupplier,
      invoices:               clearInvoices
          ? []
          : invoices          ?? this.invoices,
      selectedInvoice:        clearSelectedInvoice
          ? null
          : selectedInvoice   ?? this.selectedInvoice,
      serviceInvoices:        clearServiceInvoices
          ? []
          : serviceInvoices   ?? this.serviceInvoices,
      selectedServiceInvoice: clearSelectedServiceInvoice      // ← ADDED
          ? null
          : selectedServiceInvoice ?? this.selectedServiceInvoice,
      serviceInvoicesStatus:  serviceInvoicesStatus ?? this.serviceInvoicesStatus,
      activeTab:              activeTab            ?? this.activeTab,
      errorMessage:           clearError
          ? null
          : errorMessage      ?? this.errorMessage,
      searchQuery:            searchQuery          ?? this.searchQuery,
      clearingStatus:         clearingStatus       ?? this.clearingStatus,
      lastClearingResult:     clearClearingResult
          ? null
          : lastClearingResult ?? this.lastClearingResult,
      linkCustomerStatus:     linkCustomerStatus   ?? this.linkCustomerStatus,
    );
  }

  // ── Convenience getters ───────────────────────────────────
  bool get isLoading              => status == SuppliersStatus.loading;
  bool get hasError               => status == SuppliersStatus.failure;
  bool get hasSuppliers           => filtered.isNotEmpty;
  bool get isClearingInProgress   => clearingStatus == ClearingStatus.loading;
  bool get isLinkingInProgress    => linkCustomerStatus == LinkCustomerStatus.loading;
  bool get isServiceInvoicesLoading =>
      serviceInvoicesStatus == ServiceInvoicesStatus.loading;

  @override
  List<Object?> get props => [
    status, formStatus, suppliers, filtered, selectedSupplier,
    invoices, selectedInvoice,
    serviceInvoices, selectedServiceInvoice, serviceInvoicesStatus,
    activeTab,
    errorMessage, searchQuery,
    clearingStatus, lastClearingResult,
    linkCustomerStatus,
  ];
}