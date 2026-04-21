part of 'invoices_cubit.dart';

abstract class InvoicesState extends Equatable {
  const InvoicesState();
  @override
  List<Object?> get props => [];
}

class InvoicesInitial extends InvoicesState {}

class InvoicesLoading extends InvoicesState {}

class InvoicesLoaded extends InvoicesState {
  final List<InvoiceEntity> invoices;
  final InvoiceEntity? selectedInvoice;
  final InvoicePaymentSummary? paymentSummary;

  const InvoicesLoaded({
    required this.invoices,
    this.selectedInvoice,
    this.paymentSummary,
  });

  @override
  List<Object?> get props => [invoices, selectedInvoice, paymentSummary];
}

class InvoiceCreated extends InvoicesState {
  final String invoiceId;
  const InvoiceCreated({required this.invoiceId});
  @override
  List<Object?> get props => [invoiceId];
}

class PaymentRecording extends InvoicesState {}

class PaymentRecorded extends InvoicesState {
  /// Fresh summary returned directly from the RPC — no extra round-trip.
  final InvoicePaymentSummary summary;
  const PaymentRecorded({required this.summary});
  @override
  List<Object?> get props => [summary];
}

class ItemReturning extends InvoicesState {
  final String invoiceItemId;
  const ItemReturning({required this.invoiceItemId});
  @override
  List<Object?> get props => [invoiceItemId];
}

class ItemReturned extends InvoicesState {
  final String invoiceItemId;
  const ItemReturned({required this.invoiceItemId});
  @override
  List<Object?> get props => [invoiceItemId];
}

class InvoicesError extends InvoicesState {
  final String message;
  const InvoicesError(this.message);
  @override
  List<Object?> get props => [message];
}

class ExportingReport extends InvoicesState {}

class ReportExported extends InvoicesState {}