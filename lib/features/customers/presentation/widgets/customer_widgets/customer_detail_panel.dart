// lib/features/customers/presentation/widgets/customer_detail_panel.dart
import 'package:bungee_manage_sys/features/customers/presentation/widgets/customer_widgets/customer_export_dialog.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/di/injection_container.dart' as di;
import '../../../../../core/theme/colors.dart';
import '../../../../../core/utils/enums.dart';
import '../../../../../core/widgets/app_buton.dart';
import '../../../../../core/widgets/custom_snack_bar.dart';
import '../../../../../core/widgets/empty_state_widget.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../domain/entities/customer_entity.dart';
import '../../../domain/entities/invoice_entity.dart';
import '../../cubit/customers_cubit.dart';
import '../../cubit/invoices_cubit.dart';
import '../../pages/modern_create_invoice_page.dart';
import 'customer_stats_card.dart';

class CustomerDetailPanel extends StatelessWidget {
  final CustomerEntity customer;

  const CustomerDetailPanel({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // 1. الليسنر ده بيسمع لتغييرات الفواتير عشان يطلب تحديث العميل في الخلفية
    return BlocListener<InvoicesCubit, InvoicesState>(
      listener: (context, state) {
        if (state is InvoicesLoaded || state is InvoiceCreated || state is PaymentRecorded) {
          context.read<CustomersCubit>().fetchCustomers();
        }
        if (state is ReportExported) {
       context.showSuccess('تم تصدير التقرير بنجاح ✓');
     }
       else if (state is InvoicesError) {
          context.showError(state.message);
        }
       else if (state is ExportingReport) {
          context.showInfo('جاري تصدير التقرير... ⏳');
        }
       else if (state is ReportExported) {
          context.showSuccess('تم تصدير التقرير بنجاح ✓');
        }
       else if (state is InvoicesError) {
          context.showError(state.message);
        }
      },
      child: Column(
        children: [
          // 2. الـ Header جوه Builder لوحده عشان يتحدث بدون ما يأثر على الباقي
          BlocBuilder<CustomersCubit, CustomersState>(
            builder: (context, state) {
              final index = state.customers.indexWhere((c) => c.id == customer.id);
              final freshCustomer = index != -1 ? state.customers[index] : customer;
              return _DetailHeader(customer: freshCustomer);
            },
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. كارت الإحصائيات جوه Builder لوحده عشان يلقط المديونية الجديدة
                  BlocBuilder<CustomersCubit, CustomersState>(
                    builder: (context, state) {
                      final index = state.customers.indexWhere((c) => c.id == customer.id);
                      final freshCustomer = index != -1 ? state.customers[index] : customer;
                      return CustomerStatsCard(customer: freshCustomer);
                    },
                  ),
                  SizedBox(height: 20.h),

                  // 4. السحر هنا: قائمة الفواتير بره الـ Builder
                  // فمش هيحصلها أي Flickering لما العميل يتحدث!
                  _InvoicesSection(customer: customer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final CustomerEntity customer;

  const _DetailHeader({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'invoices.invoices_history'.tr(),
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // ── Export button ──────────────────────────────────────────────
          BlocBuilder<InvoicesCubit, InvoicesState>(
            builder: (context, state) {
              final isExporting = state is ExportingReport;
              return OutlinedButton.icon(
                onPressed: isExporting
                    ? null
                    : () => showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<InvoicesCubit>(),
                    child: CustomerExportDialog(
                      customerId: customer.id,
                      customerName: customer.name,
                    ),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorsManager.successText,
                  side: const BorderSide(color: ColorsManager.successText),
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                icon: isExporting
                    ? SizedBox(
                    width: 14.r,
                    height: 14.r,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorsManager.successText))
                    : Icon(Icons.file_download_outlined, size: 16.r),
                label: Text(
                  isExporting ? 'جاري التصدير...' : 'Excel',
                  style: TextStyle(
                      fontSize: 12.sp, fontWeight: FontWeight.w600),
                ),
              );
            },
          ),

          SizedBox(width: 8.w),

          // ── Create invoice button ──────────────────────────────────────
          SizedBox(
            width: 150.w,
            child: AppButton(
              text: 'invoices.create_invoice'.tr(),
              leadingIcon: Icons.add,
              horizontalPadding: 0,
              verticalPadding: 0,
              onPressed: () {
                final invoicesCubit = context.read<InvoicesCubit>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: invoicesCubit),
                        BlocProvider(
                            create: (_) =>
                            di.sl<InventoryCubit>()..fetchItems()),
                      ],
                      child: ModernCreateInvoicePage(customer: customer),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesSection extends StatefulWidget {
  final CustomerEntity customer;

  const _InvoicesSection({required this.customer});

  @override
  State<_InvoicesSection> createState() => _InvoicesSectionState();
}

class _InvoicesSectionState extends State<_InvoicesSection> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🚨 الجزء الجديد: شريط البحث جنب العنوان 🚨
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'invoices.title'.tr(),
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(
              width: 180.w, // عرض مناسب للبحث
              height: 36.h,
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'بحث برقم الفاتورة...',
                  hintStyle: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
                  prefixIcon: Icon(Icons.search, size: 18.r, color: ColorsManager.defaultTextSecondary),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: ColorsManager.primaryColor),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        BlocBuilder<InvoicesCubit, InvoicesState>(
          builder: (context, state) {
            if (state is InvoicesLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (state is InvoicesError) {
              return EmptyStateWidget(
                icon: Icons.cloud_off_rounded,
                title: 'errors.loadFailed'.tr(),
                subtitle: state.message,
                isFullPage: false,
                actionLabel: 'common.retry'.tr(),
                onActionPressed: () => context
                    .read<InvoicesCubit>()
                    .fetchInvoices(widget.customer.id),
              );
            }

            if (state is InvoicesLoaded) {
              if (state.invoices.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'invoices.empty_title'.tr(),
                  subtitle: 'invoices.empty_sub'.tr(),
                  isFullPage: false,
                );
              }

              // 🚨 السحر هنا: فلترة الفواتير بناءً على البحث 🚨
              final filteredInvoices = state.invoices.where((inv) {
                if (_searchQuery.isEmpty) return true;

                // بنبحث بالـ invoiceNumber اللي ضفناه آخر مرة
                // (ولو الفاتورة قديمة مفيهاش، بيبحث بأول 8 حروف من الـ ID العادي)
                final currentInvoiceNum = inv.invoiceNumber.toLowerCase();
                final legacyId = inv.id.substring(0, 8).toLowerCase();

                return currentInvoiceNum.contains(_searchQuery) || legacyId.contains(_searchQuery);
              }).toList();

              // لو بيبحث ومالقاش حاجة
              if (filteredInvoices.isEmpty && _searchQuery.isNotEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 40.r, color: theme.dividerColor),
                        SizedBox(height: 8.h),
                        Text(
                          'لا توجد فاتورة بهذا الرقم',
                          style: TextStyle(fontSize: 13.sp, color: ColorsManager.defaultTextSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return _InvoiceList(
                invoices: filteredInvoices, // 👈 بنبعت القائمة المتفلترة للستة
                customer: widget.customer,
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _InvoiceList extends StatelessWidget {
  final List<InvoiceEntity> invoices;
  final CustomerEntity customer;

  const _InvoiceList({required this.invoices, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: invoices
          .map((inv) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: _InvoiceTile(invoice: inv, customer: customer),
      ))
          .toList(),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final InvoiceEntity invoice;
  final CustomerEntity customer;

  const _InvoiceTile({required this.invoice, required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur = 'dashboard.currency'.tr();

    ChipStatus chipStatus;
    String statusKey;

    switch (invoice.status) {
      case InvoiceStatus.active:
        chipStatus = ChipStatus.active;
        statusKey = 'invoices.status_active';
        break;
      case InvoiceStatus.completed:
        chipStatus = ChipStatus.completed;
        statusKey = 'invoices.status_completed';
        break;
      case InvoiceStatus.canceled:
        chipStatus = ChipStatus.canceled;
        statusKey = 'invoices.status_canceled';
        break;
      default:
        chipStatus = ChipStatus.draft;
        statusKey = 'invoices.status_draft';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      // 🚨 هنا بنكلم الكيوبت الأب اللي هيخلي الصفحة تتغير 🚨
      onTap: () => context.read<InvoicesCubit>().selectInvoice(invoice.id),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: ColorsManager.primaryLight,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.receipt_outlined,
                size: 18.r,
                color: ColorsManager.primaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'invoices.invoice_number'.tr(namedArgs: {
                      'id': invoice.invoiceNumber,
                    }),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$cur ${invoice.netTotal.toStringAsFixed(0)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ColorsManager.successText,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: statusKey.tr(),
              status: chipStatus,
            ),
          ],
        ),
      ),
    );
  }
}



