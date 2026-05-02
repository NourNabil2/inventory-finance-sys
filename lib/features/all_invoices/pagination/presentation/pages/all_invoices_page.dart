// lib/features/all_invoices/presentation/pages/all_invoices_page.dart

import 'dart:async';
import 'package:bungee_manage_sys/core/di/injection_container.dart' as di;
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/core/widgets/page_header.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:bungee_manage_sys/features/all_invoices/pagination/presentation/cubit/all_invoices_cubit.dart';
import 'package:bungee_manage_sys/features/all_invoices/pagination/presentation/widgets/all_invoices_export_dialog.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:bungee_manage_sys/features/customers/presentation/pages/modern_invoice_details_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AllInvoicesPage extends StatefulWidget {
  const AllInvoicesPage({super.key});

  @override
  State<AllInvoicesPage> createState() => _AllInvoicesPageState();
}

class _AllInvoicesPageState extends State<AllInvoicesPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  InvoiceFilterParams _filters = const InvoiceFilterParams();
  bool _showFilters = false;

  // ── Split layout state ──────────────────────────────────────────────
  AllInvoiceEntity? _selectedInvoice; // الفاتورة المختارة على desktop
  InvoicesCubit?    _invoicesCubit;   // cubit خاص بالتفاصيل

  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;

  @override
  void initState() {
    super.initState();
    context.read<AllInvoicesCubit>().loadInvoices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _invoicesCubit?.close();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      setState(() => _filters = _filters.copyWith(searchQuery: query));
      context.read<AllInvoicesCubit>().loadInvoices(filters: _filters);
    });
  }

  void _applyFilters(InvoiceFilterParams filters) {
    setState(() {
      _filters     = filters;
      _showFilters = false;
    });
    context.read<AllInvoicesCubit>().loadInvoices(filters: _filters);
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _filters     = const InvoiceFilterParams();
      _showFilters = false;
    });
    context.read<AllInvoicesCubit>().clearFilters();
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AllInvoicesCubit>(),
        child: const AllInvoicesExportDialog(),
      ),
    );
  }

  // ── فتح التفاصيل ────────────────────────────────────────────────────
  void _openInvoiceDetails(BuildContext context, AllInvoiceEntity allInvoice) {
    if (_isDesktop) {
      // ── Desktop: غيّر الـ state فقط — split يتحدث تلقائياً ──
      // أغلق الـ cubit القديم لو موجود
      _invoicesCubit?.close();

      final newCubit = di.sl<InvoicesCubit>()
        ..selectInvoice(allInvoice.id);

      setState(() {
        _selectedInvoice = allInvoice;
        _invoicesCubit   = newCubit;
      });
    } else {
      // ── Mobile: Navigator.push كما كان ──────────────────────────────
      final customer = CustomerEntity(
        id:        allInvoice.customerId,
        name:      allInvoice.customerName,
        phone:     allInvoice.customerPhone,
        totalPaid: 0,
        totalDebt: 0,
        createdAt: allInvoice.createdAt,
      );

      final invoicesCubit = di.sl<InvoicesCubit>()
        ..selectInvoice(allInvoice.id);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BlocProvider<InvoicesCubit>(
            create: (_) => invoicesCubit,
            child: BlocBuilder<InvoicesCubit, InvoicesState>(
              builder: (ctx, state) {
                if (state is InvoicesLoaded &&
                    state.selectedInvoice != null) {
                  return ModernInvoiceDetailsPage(
                    invoice:  state.selectedInvoice!,
                    customer: customer,
                  );
                }
                return Scaffold(
                  appBar: AppBar(
                    backgroundColor:  Theme.of(ctx).cardColor,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20.r),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    title: Text(
                      allInvoice.invoiceNumber != null
                          ? '#${allInvoice.invoiceNumber}'
                          : 'invoices.invoice_number'.tr(namedArgs: {
                        'id': allInvoice.id
                            .substring(0, 8)
                            .toUpperCase(),
                      }),
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  body: state is InvoicesError
                      ? Center(child: Text(state.message))
                      : const Center(
                      child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AllInvoicesCubit, AllInvoicesState>(
      listener: (context, state) {
        if (state is AllInvoicesError) context.showError(state.message);
      },
      builder: (context, state) {
        // ── Desktop: split layout ──────────────────────────────────────
        if (_isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: القائمة ──────────────────────────────────────
              SizedBox(
                width: 420.w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: Theme.of(context).dividerColor),
                    ),
                  ),
                  child: _buildListPanel(context, state),
                ),
              ),

              // ── Right: التفاصيل أو placeholder ────────────────────
              Expanded(
                child: _buildDetailPanel(context),
              ),
            ],
          );
        }

        // ── Mobile: القائمة فقط ────────────────────────────────────────
        return _buildListPanel(context, state);
      },
    );
  }

  // ── Panel: القائمة (مشترك بين mobile و desktop) ─────────────────────
  Widget _buildListPanel(BuildContext context, AllInvoicesState state) {
    return Column(
      children: [
        PageHeader(
          titleKey: 'all_invoices.title',
          actionWidget: _filters.hasActiveFilters
              ? Padding(
            padding: EdgeInsetsDirectional.only(end: 8.w),
            child: _ClearFiltersBtn(onClear: _clearFilters),
          )
              : null,
          actionButton: PageHeaderAction(
            textKey: 'all_invoices.filter',
            icon: Icons.tune_rounded,
            onPressed: () =>
                setState(() => _showFilters = !_showFilters),
          ),
        ),

        _SearchBar(
          controller:       _searchCtrl,
          onChanged:        _onSearch,
          hasActiveFilters: _filters.hasActiveFilters,
          onFilterTap: () =>
              setState(() => _showFilters = !_showFilters),
          onExportTap: () => _showExportDialog(context),
        ),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              SizeTransition(sizeFactor: animation, child: child),
          child: _showFilters
              ? _FilterPanel(
            key:            const ValueKey('filter_panel'),
            initialFilters: _filters,
            onApply:        _applyFilters,
            onClear:        _clearFilters,
          )
              : const SizedBox.shrink(key: ValueKey('no_filter')),
        ),

        if (_filters.hasActiveFilters)
          _ActiveFilterChips(
            filters:        _filters,
            onRemoveDate:   () => _applyFilters(_filters.copyWith(
                clearStartDate: true, clearEndDate: true)),
            onRemoveStatus: () => _applyFilters(_filters.copyWith(
                statusFilter: InvoiceStatusFilter.all)),
            onRemovePayment: () => _applyFilters(_filters.copyWith(
                paymentFilter: PaymentStatusFilter.all)),
          ),

        Expanded(child: _buildContent(context, state)),
      ],
    );
  }

  // ── Panel: التفاصيل (desktop فقط) ───────────────────────────────────
  Widget _buildDetailPanel(BuildContext context) {
    // مفيش فاتورة مختارة → placeholder
    if (_selectedInvoice == null || _invoicesCubit == null) {
      return EmptyStateWidget(
        icon:      Icons.receipt_long_outlined,
        title:     'invoices.empty_title'.tr(),
        subtitle:  '',
        isFullPage: false,
      );
    }

    final customer = CustomerEntity(
      id:        _selectedInvoice!.customerId,
      name:      _selectedInvoice!.customerName,
      phone:     _selectedInvoice!.customerPhone,
      totalPaid: 0,
      totalDebt: 0,
      createdAt: _selectedInvoice!.createdAt,
    );

    return BlocProvider<InvoicesCubit>.value(
      value: _invoicesCubit!,
      child: BlocBuilder<InvoicesCubit, InvoicesState>(
        builder: (ctx, state) {
          if (state is InvoicesLoaded &&
              state.selectedInvoice != null) {
            return ModernInvoiceDetailsPage(
              invoice:  state.selectedInvoice!,
              customer: customer,
            );
          }
          return Scaffold(
            appBar: AppBar(
              backgroundColor:  Theme.of(ctx).cardColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.close, size: 20.r),
                onPressed: () =>
                    setState(() => _selectedInvoice = null),
              ),
              title: Text(
                _selectedInvoice!.invoiceNumber != null
                    ? '#${_selectedInvoice!.invoiceNumber}'
                    : 'invoices.invoice_number'.tr(namedArgs: {
                  'id': _selectedInvoice!.id
                      .substring(0, 8)
                      .toUpperCase(),
                }),
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w700),
              ),
            ),
            body: state is InvoicesError
                ? Center(child: Text(state.message))
                : const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  // ── Content (invoice list + pagination) ─────────────────────────────
  Widget _buildContent(BuildContext context, AllInvoicesState state) {
    if (state is AllInvoicesInitial || state is AllInvoicesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is AllInvoicesError) {
      return EmptyStateWidget(
        icon:        Icons.cloud_off_rounded,
        title:       'errors.loadFailed'.tr(),
        subtitle:    state.message,
        isFullPage:  false,
        actionLabel: 'common.retry'.tr(),
        onActionPressed: () => context
            .read<AllInvoicesCubit>()
            .loadInvoices(filters: _filters),
      );
    }

    List<AllInvoiceEntity> invoices = [];
    int  totalCount  = 0;
    int  currentPage = 1;
    int  pageSize    = 10;
    bool isPaginating = false;
    int  totalPages  = 1;
    bool hasNext     = false;
    bool hasPrev     = false;

    if (state is AllInvoicesLoaded) {
      invoices    = state.invoices;
      totalCount  = state.totalCount;
      currentPage = state.currentPage;
      pageSize    = state.pageSize;
      totalPages  = state.totalPages;
      hasNext     = state.hasNextPage;
      hasPrev     = state.hasPreviousPage;
    } else if (state is AllInvoicesPaginating) {
      invoices     = state.currentInvoices;
      totalCount   = state.totalCount;
      currentPage  = state.currentPage;
      isPaginating = true;
      totalPages   = (totalCount / 10).ceil();
    }

    if (invoices.isEmpty && !isPaginating) {
      return EmptyStateWidget(
        icon:      Icons.receipt_long_outlined,
        title:     'all_invoices.empty_title'.tr(),
        subtitle:  'all_invoices.empty_sub'.tr(),
        isFullPage: false,
      );
    }

    return Column(
      children: [
        _StatsBar(
          totalCount:   totalCount,
          currentPage:  currentPage,
          pageSize:     pageSize,
          isPaginating: isPaginating,
        ),
        Expanded(
          child: Stack(
            children: [
              ListView.separated(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                itemCount: invoices.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) => _InvoiceTile(
                  invoice:    invoices[index],
                  isSelected: _isDesktop &&
                      _selectedInvoice?.id == invoices[index].id,
                  onTap: () =>
                      _openInvoiceDetails(context, invoices[index]),
                ),
              ),
              if (isPaginating)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        if (totalPages > 1)
          _PaginationBar(
            currentPage:  currentPage,
            totalPages:   totalPages,
            hasNext:      hasNext,
            hasPrev:      hasPrev,
            isPaginating: isPaginating,
            onPrev:  () =>
                context.read<AllInvoicesCubit>().previousPage(),
            onNext:  () =>
                context.read<AllInvoicesCubit>().nextPage(),
            onPage:  (p) =>
                context.read<AllInvoicesCubit>().goToPage(p),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar  (+ Export button)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasActiveFilters;
  final VoidCallback onFilterTap;
  final VoidCallback onExportTap;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.hasActiveFilters,
    required this.onFilterTap,
    required this.onExportTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: 'all_invoices.search_hint'.tr(),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: ColorsManager.defaultTextSecondary,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close,
                      color: ColorsManager.defaultTextSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
                    : null,
                filled: true,
                fillColor: isDark
                    ? ColorsManager.secondaryDarkColor
                    : ColorsManager.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.grey.shade700
                        : ColorsManager.inputBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.grey.shade700
                        : ColorsManager.inputBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(
                    color: ColorsManager.primaryColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          _IconActionBtn(
            icon: Icons.tune_rounded,
            isActive: hasActiveFilters,
            onTap: onFilterTap,
            tooltip: 'all_invoices.filter'.tr(),
          ),
          SizedBox(width: 8.w),
          _ExportIconBtn(onTap: onExportTap),
        ],
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _IconActionBtn({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: isActive
                ? ColorsManager.primaryColor
                : (isDark
                ? ColorsManager.secondaryDarkColor
                : ColorsManager.backgroundCard),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isActive
                  ? ColorsManager.primaryColor
                  : (isDark
                  ? Colors.grey.shade700
                  : ColorsManager.inputBorder),
            ),
          ),
          child: Icon(
            icon,
            size: 20.r,
            color: isActive
                ? Colors.white
                : ColorsManager.defaultTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _ExportIconBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _ExportIconBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'all_invoices.export_excel'.tr(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: ColorsManager.successFill
                .withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: ColorsManager.successFill.withOpacity(0.4),
            ),
          ),
          child: Icon(
            Icons.file_download_outlined,
            size: 20.r,
            color: ColorsManager.successText,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter panel
// ─────────────────────────────────────────────────────────────────────────────

class _FilterPanel extends StatefulWidget {
  final InvoiceFilterParams initialFilters;
  final void Function(InvoiceFilterParams) onApply;
  final VoidCallback onClear;

  const _FilterPanel({
    super.key,
    required this.initialFilters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late InvoiceStatusFilter _statusFilter;
  late PaymentStatusFilter _paymentFilter;

  @override
  void initState() {
    super.initState();
    _startDate     = widget.initialFilters.startDate;
    _endDate       = widget.initialFilters.endDate;
    _statusFilter  = widget.initialFilters.statusFilter;
    _paymentFilter = widget.initialFilters.paymentFilter;
  }

  Future<void> _pickDate(bool isStart) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) _startDate = picked;
      else _endDate = picked;
    });
  }

  void _apply() {
    widget.onApply(InvoiceFilterParams(
      startDate:     _startDate,
      endDate:       _endDate,
      statusFilter:  _statusFilter,
      paymentFilter: _paymentFilter,
      searchQuery:   widget.initialFilters.searchQuery,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Container(
      margin:  EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark
            ? ColorsManager.secondaryDarkColor
            : ColorsManager.backgroundCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : ColorsManager.inputBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'all_invoices.filter_date_range'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.defaultTextSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _DatePickerBtn(
                  label: _startDate != null
                      ? dateFmt.format(_startDate!)
                      : 'all_invoices.from'.tr(),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDate(true),
                  onClear: _startDate != null
                      ? () => setState(() => _startDate = null)
                      : null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _DatePickerBtn(
                  label: _endDate != null
                      ? dateFmt.format(_endDate!)
                      : 'all_invoices.to'.tr(),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDate(false),
                  onClear: _endDate != null
                      ? () => setState(() => _endDate = null)
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            'all_invoices.filter_status'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.defaultTextSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: InvoiceStatusFilter.values
                .map((f) => _FilterChip(
              label: _statusFilterLabel(f),
              isSelected: _statusFilter == f,
              onTap: () => setState(() => _statusFilter = f),
            ))
                .toList(),
          ),
          SizedBox(height: 14.h),
          Text(
            'all_invoices.filter_payment'.tr(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.defaultTextSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: PaymentStatusFilter.values
                .map((f) => _FilterChip(
              label: _paymentFilterLabel(f),
              isSelected: _paymentFilter == f,
              onTap: () => setState(() => _paymentFilter = f),
            ))
                .toList(),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.defaultTextSecondary,
                    side: BorderSide(
                      color: isDark
                          ? Colors.grey.shade600
                          : ColorsManager.inputBorder,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text('common.clear'.tr()),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text('all_invoices.apply_filter'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusFilterLabel(InvoiceStatusFilter f) => switch (f) {
    InvoiceStatusFilter.all       => 'all_invoices.status_all'.tr(),
    InvoiceStatusFilter.active    => 'invoices.status_active'.tr(),
    InvoiceStatusFilter.completed => 'invoices.status_completed'.tr(),
    InvoiceStatusFilter.canceled  => 'invoices.status_canceled'.tr(),
    InvoiceStatusFilter.draft     => 'invoices.status_draft'.tr(),
  };

  String _paymentFilterLabel(PaymentStatusFilter f) => switch (f) {
    PaymentStatusFilter.all       => 'all_invoices.payment_all'.tr(),
    PaymentStatusFilter.fullyPaid => 'all_invoices.payment_paid'.tr(),
    PaymentStatusFilter.hasDebt   => 'all_invoices.payment_partial'.tr(),
    PaymentStatusFilter.unpaid    => 'all_invoices.payment_unpaid'.tr(),
  };
}

class _DatePickerBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.grey.shade700
                : ColorsManager.inputBorder,
          ),
          borderRadius: BorderRadius.circular(8.r),
          color: isDark
              ? ColorsManager.darkColor
              : ColorsManager.defaultSurface,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14.r,
                color: ColorsManager.defaultTextSecondary),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark
                      ? Colors.white70
                      : ColorsManager.defaultText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14.r,
                  color: ColorsManager.defaultTextSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor
              : (isDark
              ? ColorsManager.darkColor
              : ColorsManager.defaultSurface),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? ColorsManager.primaryColor
                : (isDark
                ? Colors.grey.shade700
                : ColorsManager.inputBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : (isDark
                ? Colors.white70
                : ColorsManager.defaultText),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active filter chips bar
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveFilterChips extends StatelessWidget {
  final InvoiceFilterParams filters;
  final VoidCallback onRemoveDate;
  final VoidCallback onRemoveStatus;
  final VoidCallback onRemovePayment;

  const _ActiveFilterChips({
    required this.filters,
    required this.onRemoveDate,
    required this.onRemoveStatus,
    required this.onRemovePayment,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          if (filters.startDate != null || filters.endDate != null)
            _ActiveChip(
              label: filters.startDate != null && filters.endDate != null
                  ? '${dateFmt.format(filters.startDate!)} → ${dateFmt.format(filters.endDate!)}'
                  : filters.startDate != null
                  ? 'من ${dateFmt.format(filters.startDate!)}'
                  : 'حتى ${dateFmt.format(filters.endDate!)}',
              onRemove: onRemoveDate,
            ),
          if (filters.statusFilter != InvoiceStatusFilter.all) ...[
            SizedBox(width: 6.w),
            _ActiveChip(
              label: _statusLabel(filters.statusFilter),
              onRemove: onRemoveStatus,
            ),
          ],
          if (filters.paymentFilter != PaymentStatusFilter.all) ...[
            SizedBox(width: 6.w),
            _ActiveChip(
              label: _paymentLabel(filters.paymentFilter),
              onRemove: onRemovePayment,
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(InvoiceStatusFilter f) => switch (f) {
    InvoiceStatusFilter.all       => '',
    InvoiceStatusFilter.active    => 'نشط',
    InvoiceStatusFilter.completed => 'مكتمل',
    InvoiceStatusFilter.canceled  => 'ملغي',
    InvoiceStatusFilter.draft     => 'مسودة',
  };

  String _paymentLabel(PaymentStatusFilter f) => switch (f) {
    PaymentStatusFilter.all       => '',
    PaymentStatusFilter.fullyPaid => 'مدفوع',
    PaymentStatusFilter.hasDebt   => 'جزئي',
    PaymentStatusFilter.unpaid    => 'غير مدفوع',
  };
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ColorsManager.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
            color: ColorsManager.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.primaryColor,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 12.r,
              color: ColorsManager.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats bar
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool isPaginating;

  const _StatsBar({
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.isPaginating,
  });

  @override
  Widget build(BuildContext context) {
    final start = ((currentPage - 1) * pageSize) + 1;
    final end   = (currentPage * pageSize).clamp(0, totalCount);

    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        children: [
          Text(
            'all_invoices.showing'.tr(namedArgs: {
              'start': '$start',
              'end':   '$end',
              'total': '$totalCount',
            }),
            style: TextStyle(
              fontSize: 12.sp,
              color: ColorsManager.defaultTextSecondary,
            ),
          ),
          if (isPaginating) ...[
            SizedBox(width: 8.w),
            SizedBox(
              width: 12.r,
              height: 12.r,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: ColorsManager.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice tile  ← now tappable
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {

  final AllInvoiceEntity invoice;
  final VoidCallback onTap;
  final bool isSelected;
  const _InvoiceTile({
    required this.invoice,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final isDark  = theme.brightness == Brightness.dark;
    final cur     = 'dashboard.currency'.tr();
    final dateFmt = DateFormat('d MMM yyyy');

    final ChipStatus chipStatus;
    final String statusKey;

    switch (invoice.status) {
      case InvoiceStatus.active:
        chipStatus = ChipStatus.active;
        statusKey  = 'invoices.status_active';
        break;
      case InvoiceStatus.completed:
        chipStatus = ChipStatus.completed;
        statusKey  = 'invoices.status_completed';
        break;
      case InvoiceStatus.canceled:
        chipStatus = ChipStatus.canceled;
        statusKey  = 'invoices.status_canceled';
        break;
      default:
        chipStatus = ChipStatus.draft;
        statusKey  = 'invoices.status_draft';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorsManager.primaryColor.withOpacity(0.06)
                : (isDark
                ? ColorsManager.secondaryDarkColor
                : ColorsManager.backgroundCard),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isSelected
                  ? ColorsManager.primaryColor
                  : (isDark
                  ? Colors.grey.shade800
                  : ColorsManager.inputBorder),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
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
                          invoice.invoiceNumber != null
                              ? '#${invoice.invoiceNumber}'
                              : 'invoices.invoice_number'.tr(
                            namedArgs: {
                              'id': invoice.id
                                  .substring(0, 8)
                                  .toUpperCase(),
                            },
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: isDark
                                ? Colors.white
                                : ColorsManager.defaultText,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 11.r,
                              color: ColorsManager.defaultTextSecondary,
                            ),
                            SizedBox(width: 3.w),
                            Flexible(
                              child: Text(
                                invoice.customerName,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: ColorsManager
                                      .defaultTextSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusChip(
                      label: statusKey.tr(), status: chipStatus),
                ],
              ),

              SizedBox(height: 10.h),
              Divider(
                height: 1,
                color: isDark
                    ? Colors.grey.shade800
                    : ColorsManager.inputBorder,
              ),
              SizedBox(height: 10.h),

              // ── Bottom row: financials + date ───────────────────────
              Row(
                children: [
                  _FinancialCell(
                    label: 'invoices.net_total'.tr(),
                    value:
                    '$cur ${invoice.netTotal.toStringAsFixed(0)}',
                    valueColor: ColorsManager.primaryColor,
                  ),
                  SizedBox(width: 16.w),
                  _FinancialCell(
                    label: 'invoices.paid'.tr(),
                    value:
                    '$cur ${invoice.totalPaid.toStringAsFixed(0)}',
                    valueColor: ColorsManager.successText,
                  ),
                  SizedBox(width: 16.w),
                  _FinancialCell(
                    label: 'invoices.remaining'.tr(),
                    value:
                    '$cur ${invoice.remaining.toStringAsFixed(0)}',
                    valueColor: invoice.remaining > 0
                        ? ColorsManager.errorText
                        : ColorsManager.successText,
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 11.r,
                        color: ColorsManager.defaultTextSecondary,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        dateFmt.format(invoice.createdAt),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: ColorsManager.defaultTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Debt badge ────────────────────────────────────────────
              if (invoice.remaining > 0 &&
                  invoice.status == InvoiceStatus.active)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.errorSurface,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'all_invoices.has_debt'.tr(namedArgs: {
                        'amount':
                        invoice.remaining.toStringAsFixed(0),
                        'currency': cur,
                      }),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: ColorsManager.errorText,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialCell extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _FinancialCell({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: ColorsManager.defaultTextSecondary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination bar
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;
  final bool isPaginating;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(int) onPage;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
    required this.isPaginating,
    required this.onPrev,
    required this.onNext,
    required this.onPage,
  });

  List<int?> _buildPageNumbers() {
    if (totalPages <= 7) {
      return List.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>[];
    pages.add(1);
    if (currentPage > 3) pages.add(null);
    for (int i = (currentPage - 1).clamp(2, totalPages - 1);
    i <= (currentPage + 1).clamp(2, totalPages - 1);
    i++) {
      pages.add(i);
    }
    if (currentPage < totalPages - 2) pages.add(null);
    pages.add(totalPages);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? ColorsManager.secondaryDarkColor
            : ColorsManager.backgroundCard,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.grey.shade800
                : ColorsManager.inputBorder,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: hasPrev && !isPaginating,
            onTap: onPrev,
          ),
          SizedBox(width: 8.w),
          ..._buildPageNumbers().map((p) {
            if (p == null) {
              return Padding(
                padding:
                EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(
                  '…',
                  style: TextStyle(
                    color: ColorsManager.defaultTextSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              );
            }
            final isActive = p == currentPage;
            return GestureDetector(
              onTap: (!isActive && !isPaginating)
                  ? () => onPage(p)
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: isActive
                      ? ColorsManager.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isActive
                        ? ColorsManager.primaryColor
                        : (isDark
                        ? Colors.grey.shade700
                        : ColorsManager.inputBorder),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : (isDark
                          ? Colors.white70
                          : ColorsManager.defaultText),
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(width: 8.w),
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: hasNext && !isPaginating,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32.r,
        height: 32.r,
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.grey.shade700
                : ColorsManager.inputBorder,
          ),
          borderRadius: BorderRadius.circular(6.r),
          color: enabled
              ? (isDark
              ? ColorsManager.secondaryDarkColor
              : ColorsManager.backgroundCard)
              : (isDark
              ? ColorsManager.darkColor
              : ColorsManager.defaultSurface),
        ),
        child: Icon(
          icon,
          size: 18.r,
          color: enabled
              ? (isDark ? Colors.white70 : ColorsManager.defaultText)
              : ColorsManager.defaultTextSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clear filters button
// ─────────────────────────────────────────────────────────────────────────────

class _ClearFiltersBtn extends StatelessWidget {
  final VoidCallback onClear;
  const _ClearFiltersBtn({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding:
        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: ColorsManager.errorSurface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
              color: ColorsManager.errorFill.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 14.r,
              color: ColorsManager.errorText,
            ),
            SizedBox(width: 4.w),
            Text(
              'all_invoices.clear_filters'.tr(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: ColorsManager.errorText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}