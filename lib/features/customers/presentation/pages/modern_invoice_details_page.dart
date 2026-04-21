// lib/features/customers/presentation/pages/modern_invoice_details_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/confirmation_dialog.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:bungee_manage_sys/features/customers/presentation/pages/modern_edit_invoice_page.dart';
import 'package:bungee_manage_sys/features/customers/presentation/widgets/invoice_widgets/invoice_details_widgets.dart';
import 'package:bungee_manage_sys/features/customers/presentation/widgets/invoice_widgets/invoice_items_table.dart';
import 'package:bungee_manage_sys/features/customers/presentation/widgets/invoice_widgets/invoice_pdf_generator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:bungee_manage_sys/core/widgets/responsive_layout.dart';
import '../widgets/invoice_widgets/invoice_widgets.dart';

class ModernInvoiceDetailsPage extends StatefulWidget {
  final InvoiceEntity  invoice;
  final CustomerEntity customer;

  const ModernInvoiceDetailsPage({
    super.key,
    required this.invoice,
    required this.customer,
  });

  @override
  State<ModernInvoiceDetailsPage> createState() =>
      _ModernInvoiceDetailsPageState();
}

class _ModernInvoiceDetailsPageState extends State<ModernInvoiceDetailsPage> {
  late InvoiceEntity   _invoice;
  late CustomerEntity  _customer;
  InvoicePaymentSummary? _paymentSummary;

  final Set<String> _returningIds = {};

  @override
  void initState() {
    super.initState();
    _invoice  = widget.invoice;
    _customer = widget.customer;
    final s = context.read<InvoicesCubit>().state;
    if (s is InvoicesLoaded) _paymentSummary = s.paymentSummary;
  }

  double get _hPad => pageHPad(context);

  Future<void> _returnItem(InvoiceItemEntity item) async {
    final qty = await showDialog<int>(
      context: context,
      builder: (_) => InvoiceReturnQtyDialog(item: item),
    );
    if (qty == null || !mounted) return;

    setState(() => _returningIds.add(item.id));
    final cubit = context.read<InvoicesCubit>();
    cubit.returnSingleItem(
        invoiceItemId: item.id, invoiceId: _invoice.id, qty: qty);
  }

  void _showPaymentDialog() {
    final remaining = _paymentSummary?.remaining ?? _invoice.netTotal;
    if (remaining <= 0) {
      context.showSuccess('invoices.fully_paid'.tr());
      return;
    }

    final cubit = context.read<InvoicesCubit>();

    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: InvoiceRecordPaymentDialog(
          invoiceId: _invoice.id,
          maxAmount: remaining,
          customer:  _customer,
        ),
      ),
    );
  }

  void _openEdit() {
    final cubit = context.read<InvoicesCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: ModernEditInvoicePage(
              invoice: _invoice, customer: _customer),
        ),
      ),
    );
  }

  Future<void> _confirmStatus(InvoiceStatus newStatus) async {
    if (newStatus == InvoiceStatus.completed) {
      final rem = _paymentSummary?.remaining ?? _invoice.netTotal;
      if (rem > 0) {
        context.showError(
          'invoices.cannot_complete_unpaid'.tr(
            namedArgs: {'remaining': rem.toStringAsFixed(0)},
          ),
        );
        return;
      }
    }

    final ok = await showConfirmationDialog(
      context:     context,
      title:       'invoices.change_status_title'.tr(),
      message:     'invoices.change_status_confirm'.tr(
          namedArgs: {'status': _statusLabel(newStatus).tr()}),
      confirmText: 'common.confirm'.tr(),
      cancelText:  'common.cancel'.tr(),
      icon:        Icons.swap_horiz_outlined,
      isDangerous: newStatus == InvoiceStatus.canceled,
    );

    if (ok == true && mounted) {
      context
          .read<InvoicesCubit>()
          .updateStatus(_invoice.id, newStatus, _invoice.customerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<InvoicesCubit, InvoicesState>(
      listener: (context, state) {
        if (state is InvoicesLoaded) {
          if (state.selectedInvoice != null &&
              state.selectedInvoice!.id == _invoice.id) {
            setState(() {
              _invoice        = state.selectedInvoice!;
              _paymentSummary = state.paymentSummary ?? _paymentSummary;
              _returningIds.clear();
            });
          }
        } else if (state is PaymentRecorded) {
          setState(() => _paymentSummary = state.summary);
          context.showSuccess('invoices.payment_recorded'.tr());
        } else if (state is ItemReturned) {
          setState(() => _returningIds.remove(state.invoiceItemId));
          context.showSuccess('invoices.item_returned'.tr());
        } else if (state is InvoicesError) {
          setState(() => _returningIds.clear());
          context.showError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = constraints.maxWidth > kContentMaxWidth
                ? kContentMaxWidth
                : constraints.maxWidth;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                        horizontal: _hPad, vertical: 24.h),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InvoiceHeaderCard(
                                invoice: _invoice, customer: _customer),
                            SizedBox(height: 16.h),
                            if (_paymentSummary != null)
                              InvoicePaymentCard(summary: _paymentSummary!),
                            SizedBox(height: 16.h),
                            InvoiceSummaryRow(invoice: _invoice),
                            SizedBox(height: 24.h),
                            InvoiceItemsTable(
                              invoice:      _invoice,
                              returningIds: _returningIds,
                              onReturn:     _returnItem,
                            ),
                            SizedBox(height: 24.h),
                            InvoiceTotalsCard(invoice: _invoice),
                            SizedBox(height: 24.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                InvoiceActionBar(
                  invoice:       _invoice,
                  paymentSummary: _paymentSummary,
                  hPad:          _hPad,
                  onPay:         _showPaymentDialog,
                  onEdit:        _openEdit,
                  onComplete:    () => _confirmStatus(InvoiceStatus.completed),
                  onCancel:      () => _confirmStatus(InvoiceStatus.canceled),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) => AppBar(
    backgroundColor:  theme.cardColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
      onPressed: () {
        final isDesktop = MediaQuery.of(context).size.width >= 900;
        if (isDesktop) {
          context.read<InvoicesCubit>().selectInvoice(null);
        } else {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'invoices.invoice_number'
              .tr(namedArgs: {'id': _invoice.invoiceNumber}),
          style: TextStyle(
            fontSize:   16.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color:      theme.textTheme.titleLarge?.color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          DateFormat('MMMM d, yyyy').format(_invoice.createdAt),
          style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: ColorsManager.defaultTextSecondary),
        ),
      ],
    ),
    actions: [
      if (_paymentSummary != null)
        Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Center(
            child: ShareInvoicePdfButton(
              invoice:        _invoice,
              customer:       _customer,
              paymentSummary: _paymentSummary!,
            ),
          ),
        ),
      Padding(
        padding: EdgeInsets.only(right: 16.w),
        child: InvoiceStatusPill(
            invoice: _invoice, paymentSummary: _paymentSummary),
      ),
    ],
  );
}

String _statusLabel(InvoiceStatus s) => switch (s) {
  InvoiceStatus.draft     => 'invoices.status_draft',
  InvoiceStatus.active    => 'invoices.status_active',
  InvoiceStatus.completed => 'invoices.status_completed',
  InvoiceStatus.canceled  => 'invoices.status_canceled',
};