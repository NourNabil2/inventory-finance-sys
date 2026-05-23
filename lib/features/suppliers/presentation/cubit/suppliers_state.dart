// lib/features/suppliers/presentation/cubit/suppliers_state.dart
part of 'suppliers_cubit.dart';

enum SuppliersStatus       { initial, loading, success, failure }
enum SupplierFormStatus    { idle, submitting, submitted, error }
enum ClearingStatus        { idle, loading, success, failure }
enum LinkCustomerStatus    { idle, loading, success, failure }
enum ServiceInvoicesStatus { idle, loading, success, failure }
enum InvoiceEditStatus          { idle, loading, success, failure } // 🆕
enum InvoiceCancelStatus        { idle, loading, success, failure } // 🆕
enum ServiceInvoiceEditStatus   { idle, loading, success, failure } // 🆕
enum ServiceInvoiceCancelStatus { idle, loading, success, failure } // 🆕

enum SupplierLedgerTab { purchases, services }

final class SuppliersState extends Equatable {
  final SuppliersStatus      status;
  final SupplierFormStatus   formStatus;
  final List<SupplierEntity> suppliers;
  final List<SupplierEntity> filtered;
  final SupplierEntity?      selectedSupplier;
  final String?              errorMessage;
  final String               searchQuery;

  final List<SupplierInvoiceEntity> invoices;
  final SupplierInvoiceEntity?      selectedInvoice;

  final List<ServiceInvoiceEntity>  serviceInvoices;
  final ServiceInvoiceEntity?       selectedServiceInvoice;
  final ServiceInvoicesStatus       serviceInvoicesStatus;

  final SupplierLedgerTab activeTab;

  final ClearingStatus  clearingStatus;
  final ClearingResult? lastClearingResult;

  final LinkCustomerStatus          linkCustomerStatus;
  final InvoiceEditStatus           invoiceEditStatus;          // 🆕
  final InvoiceCancelStatus         invoiceCancelStatus;        // 🆕
  final ServiceInvoiceEditStatus    serviceInvoiceEditStatus;   // 🆕
  final ServiceInvoiceCancelStatus  serviceInvoiceCancelStatus; // 🆕

  const SuppliersState({
    this.status                = SuppliersStatus.initial,
    this.formStatus            = SupplierFormStatus.idle,
    this.suppliers             = const [],
    this.filtered              = const [],
    this.selectedSupplier,
    this.errorMessage,
    this.searchQuery           = '',
    this.invoices              = const [],
    this.selectedInvoice,
    this.serviceInvoices       = const [],
    this.selectedServiceInvoice,
    this.serviceInvoicesStatus = ServiceInvoicesStatus.idle,
    this.activeTab             = SupplierLedgerTab.purchases,
    this.clearingStatus        = ClearingStatus.idle,
    this.lastClearingResult,
    this.linkCustomerStatus             = LinkCustomerStatus.idle,
    this.invoiceEditStatus              = InvoiceEditStatus.idle,
    this.invoiceCancelStatus            = InvoiceCancelStatus.idle,
    this.serviceInvoiceEditStatus       = ServiceInvoiceEditStatus.idle,
    this.serviceInvoiceCancelStatus     = ServiceInvoiceCancelStatus.idle,
  });

  SuppliersState copyWith({
    SuppliersStatus?      status,
    SupplierFormStatus?   formStatus,
    List<SupplierEntity>? suppliers,
    List<SupplierEntity>? filtered,
    SupplierEntity?       selectedSupplier,
    bool                  clearSelectedSupplier = false,
    String?               errorMessage,
    bool                  clearError = false,
    String?               searchQuery,
    List<SupplierInvoiceEntity>? invoices,
    bool                  clearInvoices = false,
    SupplierInvoiceEntity?       selectedInvoice,
    bool                  clearSelectedInvoice = false,
    List<ServiceInvoiceEntity>?  serviceInvoices,
    bool                  clearServiceInvoices = false,
    ServiceInvoiceEntity?        selectedServiceInvoice,
    bool                  clearSelectedServiceInvoice = false,
    ServiceInvoicesStatus?       serviceInvoicesStatus,
    SupplierLedgerTab?           activeTab,
    ClearingStatus?              clearingStatus,
    ClearingResult?              lastClearingResult,
    bool                         clearClearingResult = false,
    LinkCustomerStatus?          linkCustomerStatus,
    InvoiceEditStatus?           invoiceEditStatus,
    InvoiceCancelStatus?         invoiceCancelStatus,
    ServiceInvoiceEditStatus?    serviceInvoiceEditStatus,
    ServiceInvoiceCancelStatus?  serviceInvoiceCancelStatus,
  }) {
    return SuppliersState(
      status:                 status             ?? this.status,
      formStatus:             formStatus         ?? this.formStatus,
      suppliers:              suppliers          ?? this.suppliers,
      filtered:               filtered           ?? this.filtered,
      selectedSupplier:       clearSelectedSupplier ? null : selectedSupplier ?? this.selectedSupplier,
      invoices:               clearInvoices ? const [] : invoices ?? this.invoices,
      selectedInvoice:        clearSelectedInvoice ? null : selectedInvoice ?? this.selectedInvoice,
      serviceInvoices:        clearServiceInvoices ? const [] : serviceInvoices ?? this.serviceInvoices,
      selectedServiceInvoice: clearSelectedServiceInvoice ? null : selectedServiceInvoice ?? this.selectedServiceInvoice,
      serviceInvoicesStatus:  serviceInvoicesStatus  ?? this.serviceInvoicesStatus,
      activeTab:              activeTab          ?? this.activeTab,
      errorMessage:           clearError         ? null : errorMessage ?? this.errorMessage,
      searchQuery:            searchQuery        ?? this.searchQuery,
      clearingStatus:         clearingStatus     ?? this.clearingStatus,
      lastClearingResult:     clearClearingResult ? null : lastClearingResult ?? this.lastClearingResult,
      linkCustomerStatus:         linkCustomerStatus    ?? this.linkCustomerStatus,
      invoiceEditStatus:          invoiceEditStatus     ?? this.invoiceEditStatus,
      invoiceCancelStatus:        invoiceCancelStatus   ?? this.invoiceCancelStatus,
      serviceInvoiceEditStatus:   serviceInvoiceEditStatus   ?? this.serviceInvoiceEditStatus,
      serviceInvoiceCancelStatus: serviceInvoiceCancelStatus ?? this.serviceInvoiceCancelStatus,
    );
  }

  bool get isLoading                       => status == SuppliersStatus.loading;
  bool get hasError                        => status == SuppliersStatus.failure;
  bool get hasSuppliers                    => filtered.isNotEmpty;
  bool get isClearingInProgress            => clearingStatus == ClearingStatus.loading;
  bool get isLinkingInProgress             => linkCustomerStatus == LinkCustomerStatus.loading;
  bool get isServiceInvoicesLoading        => serviceInvoicesStatus == ServiceInvoicesStatus.loading;
  bool get isInvoiceEditLoading            => invoiceEditStatus == InvoiceEditStatus.loading;
  bool get isInvoiceCancelLoading          => invoiceCancelStatus == InvoiceCancelStatus.loading;
  bool get isServiceInvoiceEditLoading     => serviceInvoiceEditStatus == ServiceInvoiceEditStatus.loading;
  bool get isServiceInvoiceCancelLoading   => serviceInvoiceCancelStatus == ServiceInvoiceCancelStatus.loading;

  @override
  List<Object?> get props => [
    status, formStatus, suppliers, filtered, selectedSupplier,
    invoices, selectedInvoice,
    serviceInvoices, selectedServiceInvoice, serviceInvoicesStatus,
    activeTab, errorMessage, searchQuery,
    clearingStatus, lastClearingResult,
    linkCustomerStatus, invoiceEditStatus, invoiceCancelStatus,
    serviceInvoiceEditStatus, serviceInvoiceCancelStatus,
  ];
}