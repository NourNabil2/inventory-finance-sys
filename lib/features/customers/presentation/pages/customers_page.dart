// lib/features/customers/presentation/pages/customers_page.dart
import 'package:bungee_manage_sys/features/customers/presentation/widgets/customer_widgets/customer_form_dialog.dart';
import 'package:bungee_manage_sys/features/customers/presentation/widgets/customer_widgets/customer_list_panel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/colors.dart';
import '../../../../core/widgets/custom_snack_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/page_header.dart';
import '../../domain/entities/customer_entity.dart';
import '../cubit/customers_cubit.dart';
import '../cubit/invoices_cubit.dart';
import '../pages/modern_invoice_details_page.dart';
import '../widgets/customer_widgets/customer_detail_panel.dart';
import '../widgets/customer_widgets/export_customers_dialog.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
          di.sl<CustomersCubit>()..fetchCustomers(),
        ),
        BlocProvider(create: (_) => di.sl<InvoicesCubit>()),
      ],
      child: const _CustomersLayout(),
    );
  }
}

class _CustomersLayout extends StatefulWidget {
  const _CustomersLayout();

  @override
  State<_CustomersLayout> createState() => _CustomersLayoutState();
}

class _CustomersLayoutState extends State<_CustomersLayout> {
  CustomerEntity? _selected;

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= 900;

  void _onSelectCustomer(CustomerEntity c) {
    setState(() => _selected = c);
    context.read<InvoicesCubit>().fetchInvoices(c.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomersCubit, CustomersState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          context.showError(state.errorMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _Header(onAdd: () => showCustomerFormDialog(context)),
            Expanded(
              child: _isDesktop
                  ? _DesktopBody(
                selected: _selected,
                onSelect: _onSelectCustomer,
              )
                  : _MobileBody(onSelect: _onSelectCustomer),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return PageHeader(
      titleKey: 'customers.title',
      subtitleKey: isDesktop ? 'customers.subtitle' : null,
      actionWidget: Padding(
        padding: EdgeInsetsDirectional.only(end: 12.w),
        child: OutlinedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<CustomersCubit>(),
                child: const ExportCustomersDialog(),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorsManager.successText,
            side: const BorderSide(color: ColorsManager.successText),
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          icon: const Icon(Icons.file_download_outlined),
          label: Text(
            'تصدير لكل العملاء Excel',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      actionButton: PageHeaderAction(
        textKey: 'customers.add_customer',
        icon: Icons.person_add_alt_1_outlined,
        onPressed: onAdd,
      ),
    );
  }
}

// ─── Desktop: split layout ────────────────────────────────────────────────────

class _DesktopBody extends StatelessWidget {
  final CustomerEntity? selected;
  final ValueChanged<CustomerEntity> onSelect;

  const _DesktopBody({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: list
        SizedBox(
          width: 300,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: CustomerListPanel(
              selectedId: selected?.id,
              onSelect: onSelect,
            ),
          ),
        ),
        // Right: detail or placeholder
        Expanded(
          child: BlocBuilder<InvoicesCubit, InvoicesState>(
            builder: (context, invoiceState) {
              // Invoice details page open
              if (invoiceState is InvoicesLoaded &&
                  invoiceState.selectedInvoice != null &&
                  selected != null) {
                return ModernInvoiceDetailsPage(
                  invoice: invoiceState.selectedInvoice!,
                  customer: selected!,
                );
              }

              if (selected == null) {
                return EmptyStateWidget(
                  icon: Icons.people_outline,
                  title: 'customers.select_customer_hint'.tr(),
                  subtitle: '',
                  isFullPage: false,
                );
              }

              return CustomerDetailPanel(customer: selected!);
            },
          ),
        ),
      ],
    );
  }
}

// ─── Mobile: list only, navigate to detail ────────────────────────────────────

class _MobileBody extends StatelessWidget {
  final ValueChanged<CustomerEntity> onSelect;
  const _MobileBody({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return CustomerListPanel(
      onSelect: (customer) {
        onSelect(customer);

        // 🚨 اصطاد الـ Cubits هنا قبل ما تفتح الـ Navigator 🚨
        final customersCubit = context.read<CustomersCubit>();
        final invoicesCubit = di.sl<InvoicesCubit>()..fetchInvoices(customer.id);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: customersCubit),
                BlocProvider(create: (_) => invoicesCubit),
              ],
              child: _MobileCustomerDetailPage(customer: customer),
            ),
          ),
        );
      },
    );
  }
}

// ─── Mobile full detail page ──────────────────────────────────────────────────

class _MobileCustomerDetailPage extends StatelessWidget {
  final CustomerEntity customer;

  const _MobileCustomerDetailPage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(customer.name),
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: Theme.of(context).dividerColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20.r),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 18.r),
            onPressed: () => showCustomerFormDialog(
              context,
              initialCustomer: customer,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: BlocBuilder<InvoicesCubit, InvoicesState>(
        builder: (context, state) {
          if (state is InvoicesLoaded &&
              state.selectedInvoice != null) {
            return ModernInvoiceDetailsPage(
              invoice: state.selectedInvoice!,
              customer: customer,
            );
          }
          return CustomerDetailPanel(customer: customer);
        },
      ),
    );
  }
}