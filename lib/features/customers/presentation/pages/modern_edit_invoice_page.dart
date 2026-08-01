// lib/features/customers/presentation/pages/modern_edit_invoice_page.dart
import 'dart:developer';

import 'package:bungee_manage_sys/core/di/injection_container.dart' as di;
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/app_dropdown.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/user_data/user_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModernEditInvoicePage extends StatefulWidget {
  final InvoiceEntity invoice;
  final CustomerEntity customer;

  const ModernEditInvoicePage(
      {super.key, required this.invoice, required this.customer});

  @override
  State<ModernEditInvoicePage> createState() => _ModernEditInvoicePageState();
}

class _ModernEditInvoicePageState extends State<ModernEditInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  late final List<_ExistingRow> _existing;
  final List<_NewRow> _newRows = [];
  late final TextEditingController _discCtrl;
  final List<String> _deletedItemIds = [];
  late final TextEditingController _jobNameCtrl;
  late final TextEditingController _productionCtrl;

  bool _submitting = false;
  late bool _isDraft;

  @override
  void initState() {
    super.initState();
    _discCtrl = TextEditingController(
        text: widget.invoice.discountPercent.toStringAsFixed(1));
    _jobNameCtrl = TextEditingController(text: widget.invoice.jobName ?? '');
    _productionCtrl = TextEditingController(text: widget.invoice.production ?? '');
    _isDraft = widget.invoice.status == InvoiceStatus.draft;
    final sortedItems = widget.invoice.items.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    _existing = sortedItems
        .map(_ExistingRow.new)
        .toList();
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    _jobNameCtrl.dispose();
    _productionCtrl.dispose();
    for (final r in _existing) r.dispose();
    for (final r in _newRows) r.dispose();
    super.dispose();
  }

  double get _hPad {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return (w - 920) / 2;
    if (w > 700) return 40.w;
    return 16.w;
  }

  double get _oldNet => widget.invoice.netTotal;
  double _existingSubtotal() => _existing.fold(0.0, (s, r) => s + r.lineNet);
  double _newSubtotal() => _newRows.fold(0.0, (s, r) => s + r.lineNet);
  double _newInvDiscount() {
    final pct = (double.tryParse(_discCtrl.text) ?? 0).clamp(0, 100);
    return (_existingSubtotal() + _newSubtotal()) * (pct / 100);
  }

  double get _newNet => (_existingSubtotal() + _newSubtotal() - _newInvDiscount()).clamp(0, double.infinity);
 // double get _additionalDebt => (_newNet - _oldNet).clamp(0, double.infinity);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_existing.isEmpty && _newRows.isEmpty) {
      context.showError('بالعقل كده لا يمكن أن تكون الفاتورة فارغة'.tr());
      return;
    }

    setState(() => _submitting = true);

    if (!mounted) return;

    final isAdmin = context.read<UserCubit>().isAdmin;
    final canEditAll = isAdmin || _isDraft;

    final modifiedItems = <String, Map<String, dynamic>>{};
    int existingIdx = 0;
    for (final r in _existing) {
      final currentSortOrder = existingIdx++;
      final sortOrderChanged = r.original.sortOrder != currentSortOrder;
      final daysChanged  = r.days != r.original.days;
      final qtyChanged   = canEditAll && r.qty != r.original.qty;
      final priceChanged = canEditAll && r.pricePerDay != r.original.pricePerDay;
      final discChanged  = canEditAll && r.flatDiscount != r.original.itemDiscount;

      if (daysChanged || qtyChanged || priceChanged || discChanged || sortOrderChanged) {
        modifiedItems[r.original.id] = {
          'days':         r.days,
          'qty':          canEditAll ? r.qty          : r.original.qty,
          'pricePerDay':  canEditAll ? r.pricePerDay  : r.original.pricePerDay,
          'flatDiscount': canEditAll ? r.flatDiscount : r.original.itemDiscount,
          'sort_order':   currentSortOrder,
        };
      }
    }

    final newItemEntities = _newRows.asMap().entries.map((e) {
      final r = e.value;
      return InvoiceItemEntity(
        id:           '',
        invoiceId:    widget.invoice.id,
        itemId:       r.item!.id,
        itemName:     r.item!.name,
        qty:          r.qty,
        days:         r.days,
        pricePerDay:  r.pricePerDay,
        itemDiscount: r.flatDiscount,
        status:       InvoiceItemStatus.out,
        sortOrder:    _existing.length + e.key,
      );
    }).toList();

    final pct         = (double.tryParse(_discCtrl.text) ?? 0).clamp(0, 100);
    final newDiscFlat = (_existingSubtotal() + _newSubtotal()) * (pct / 100);

    context.read<InvoicesCubit>().editInvoice(
      invoiceId:       widget.invoice.id,
      originalInvoice: widget.invoice,
      newItems:        newItemEntities,
      modifiedItems:   modifiedItems,
      newDiscountFlat: newDiscFlat,
      deletedItemIds:  _deletedItemIds,
      jobName:         _jobNameCtrl.text.trim().isEmpty ? null : _jobNameCtrl.text.trim(),
      production:      _productionCtrl.text.trim().isEmpty ? null : _productionCtrl.text.trim(),
      newStatus:       _isDraft ? 'draft' : 'active',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double paidAmount = 0;
    final cubitState = context.read<InvoicesCubit>().state;
    if (cubitState is InvoicesLoaded && cubitState.paymentSummary != null) {
      paidAmount = cubitState.paymentSummary!.totalPaid;
    }
    final hasPayments = paidAmount > 0;
    return BlocProvider(
      create: (_) => di.sl<InventoryCubit>()..fetchItems(),
      child: BlocListener<InvoicesCubit, InvoicesState>(
        listener: (context, state) {
          if (state is InvoicesLoaded) {
            context.showSuccess('invoices.edit_success'.tr());
            Navigator.of(context).pop();
          } else if (state is InvoicesError) {
            setState(() => _submitting = false);
            context.showError(state.message);
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: _buildAppBar(theme),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 24.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🚨 حقول الإدخال لاسم العمل والإنتاج في صفحة التعديل 🚨
                        _JobProductionRow(
                          jobNameCtrl: _jobNameCtrl,
                          productionCtrl: _productionCtrl,
                        ),
                        SizedBox(height: 24.h),
                        if (!hasPayments) ...[
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: _isDraft ? ColorsManager.warningFill.withOpacity(0.3) : ColorsManager.primaryColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isDraft ? Icons.drafts_outlined : Icons.check_circle_outline,
                                  color: _isDraft ? ColorsManager.warningText : ColorsManager.successText,
                                  size: 20.r,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isDraft ? 'وضع الفاتورة: مسودة (Draft)' : 'وضع الفاتورة: معتمدة ونشطة (Active)',
                                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _isDraft ? 'معزولة ماليًا ولا تدخل في حساب مديونية العميل.' : 'محتسبة رسميًا وتؤثر على مديونية العميل الحالية.',
                                        style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  activeColor: ColorsManager.primaryColor,
                                  activeTrackColor: ColorsManager.primaryColor.withOpacity(0.2),
                                  inactiveThumbColor: ColorsManager.warningFill,
                                  inactiveTrackColor: ColorsManager.warningSurface,
                                  value: _isDraft,
                                  onChanged: (value) {
                                    setState(() {
                                      _isDraft = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],

                        _ExistingItemsSection(
                          rows: _existing,
                          isDraft: widget.invoice.status == InvoiceStatus.draft,
                          onRemove: (index) {
                            setState(() {
                              _deletedItemIds.add(_existing[index].original.id);
                              _existing[index].dispose();
                              _existing.removeAt(index);
                            });
                          },
                          onChanged: () => setState(() {}),
                          onReorder: (oldIndex, newIndex) => setState(() {
                            final item = _existing.removeAt(oldIndex);
                            _existing.insert(newIndex, item);
                          }),
                        ),
                        SizedBox(height: 20.h),
                        _NewItemsSection(
                          rows: _newRows,
                          onAdd: (item) => setState(() => _newRows.add(_NewRow(item: item))),
                          onRemove: (i) => setState(() {
                            _newRows[i].dispose();
                            _newRows.removeAt(i);
                          }),
                          onChanged: () => setState(() {}),
                          onReorder: (oldIndex, newIndex) => setState(() {
                            final item = _newRows.removeAt(oldIndex);
                            _newRows.insert(newIndex, item);
                          }),
                        ),
                        SizedBox(height: 20.h),
                        _SectionLabel('invoices.invoice_disc_pct'.tr()),
                        SizedBox(height: 8.h),
                        SizedBox(
                          width: 120.w,
                          child: _NumCell(
                            ctrl: _discCtrl,
                            allowDecimal: true,
                            suffix: '%',
                            onChanged: () => setState(() {}),
                            validator: (v) {
                              final n = double.tryParse(v ?? '');
                              if (n == null || n < 0 || n > 100) return '0–100';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _EditFooter(
                oldNet: _oldNet,
                newNet: _newNet,
                submitting: _submitting,
                hPad: _hPad,
                onSubmit: _submit,
                isDraft: widget.invoice.status == InvoiceStatus.draft,
                invoiceId: widget.invoice.id,
                customerId: widget.customer.id,
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) => AppBar(
    backgroundColor: theme.cardColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: theme.dividerColor)),
    leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 20.r),
        onPressed: () => Navigator.of(context).pop()),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('invoices.edit_invoice'.tr(),
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color)),
        Text(
            'invoices.invoice_number'.tr(namedArgs: {
              'id': widget.invoice.invoiceNumber
            }),
            style: TextStyle(
                fontSize: 12.sp,
                color: ColorsManager.defaultTextSecondary)),
      ],
    ),
  );
}

// ─── Job Production Row ───────────────────────────────────────────────────────
class _JobProductionRow extends StatelessWidget {
  final TextEditingController jobNameCtrl;
  final TextEditingController productionCtrl;

  const _JobProductionRow({
    required this.jobNameCtrl,
    required this.productionCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      color: ColorsManager.defaultTextSecondary,
      letterSpacing: 0.2,
    );

    InputDecoration fieldDeco(String hint) => InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: theme.dividerColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: theme.dividerColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: ColorsManager.primaryColor, width: 1.5)),
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('invoices.job_name'.tr(), style: labelStyle),
              SizedBox(height: 4.h),
              TextField(
                controller: jobNameCtrl,
                style: TextStyle(fontSize: 13.sp),
                decoration: fieldDeco('invoices.job_name_hint'.tr()),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('invoices.production'.tr(), style: labelStyle),
              SizedBox(height: 4.h),
              TextField(
                controller: productionCtrl,
                style: TextStyle(fontSize: 13.sp),
                decoration: fieldDeco('invoices.production_hint'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Existing items section ───────────────────────────────────────────────────

class _ExistingItemsSection extends StatelessWidget {
  final List<_ExistingRow> rows;
  final VoidCallback onChanged;
  final bool isDraft;
  final void Function(int) onRemove;
  final void Function(int, int)? onReorder;

  const _ExistingItemsSection({
    required this.rows,
    required this.onChanged,
    required this.onRemove,
    required this.isDraft,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('invoices.existing_items'.tr()),
        SizedBox(height: 10.h),
        if (rows.isEmpty)
          Text('invoices.no_out_items'.tr(),
              style: TextStyle(
                  fontSize: 13.sp,
                  color: ColorsManager.defaultTextSecondary))
        else
          Container(
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: theme.dividerColor)),
            child: Column(
              children: [
                _ExistingHeader(),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: true,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    onReorder?.call(oldIndex, newIndex);
                  },
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Column(
                      key: ValueKey(row),
                      children: [
                        Container(height: 1, color: theme.dividerColor),
                        _ExistingRowWidget(
                          row: row,
                          onChanged: onChanged,
                          isDraft: isDraft,
                          onRemove: () => onRemove(index),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExistingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: ColorsManager.defaultTextSecondary);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('invoices.col_item'.tr(), style: s)),
          _Hdr('invoices.col_qty'.tr(), s),
          _Hdr('invoices.col_days'.tr(), s),
          _Hdr('invoices.col_price'.tr(), s),
          _Hdr('invoices.col_disc_pct'.tr(), s),
          _Hdr('invoices.col_total'.tr(), s, end: true),
          SizedBox(width: 32.w), // 🚨 مساحة لزرار الـ X
        ],
      ),
    );
  }
}

class _ExistingRowWidget extends StatefulWidget {
  final _ExistingRow row;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool isDraft;

  const _ExistingRowWidget({
    required this.row,
    required this.onChanged,
    required this.onRemove,
    required this.isDraft,
  });

  @override
  State<_ExistingRowWidget> createState() => _ExistingRowWidgetState();
}

class _ExistingRowWidgetState extends State<_ExistingRowWidget> {
  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final r       = widget.row;
    final isAdmin = context.read<UserCubit>().isAdmin;
    final canEditAll = isAdmin || widget.isDraft;
    final isExtended = r.days > r.original.days;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: theme.cardColor,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(r.original.itemName ?? '—',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (!r.original.isOut) ...[
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: ColorsManager.errorSurface,
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(color: ColorsManager.errorText),
                        ),
                        child: Text(
                          'مُسترجع',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                            color: ColorsManager.errorText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isExtended)
                  Text(
                    'invoices.days_extended'.tr(namedArgs: {
                      'old': '${r.original.days}', 'new': '${r.days}'
                    }),
                    style: TextStyle(fontSize: 10.sp, color: ColorsManager.warningText),
                  ),
              ],
            ),
          ),
          canEditAll
              ? _EditableCell(ctrl: r.qtyCtrl, onChanged: widget.onChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1) ? '≥1' : null;
              })
              : _LockedCell('${r.original.qty}'),
          SizedBox(
            width: 70.w,
            child: TextFormField(
              controller: r.daysCtrl,
              enabled: canEditAll,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isExtended ? ColorsManager.warningText : theme.textTheme.bodyMedium?.color),
              decoration: _cellDecoration(context, highlight: isExtended),
              onChanged: (_) { setState(() {}); widget.onChanged(); },
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < r.original.days) return '≥${r.original.days}';
                return null;
              },
            ),
          ),
          canEditAll
              ? _EditableCell(ctrl: r.priceCtrl, allowDecimal: true, onChanged: widget.onChanged)
              : _LockedCell(r.original.pricePerDay.toStringAsFixed(0)),
          canEditAll
              ? _EditableCell(ctrl: r.discCtrl, allowDecimal: true, suffix: '%', onChanged: widget.onChanged,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return (n == null || n < 0 || n > 100) ? '0–100' : null;
              })
              : _LockedCell(r.original.itemDiscount > 0
              ? '${r.original.itemDiscountPercent.toStringAsFixed(1)}%'
              : '—'),
          SizedBox(
            width: 70.w,
            child: Text(r.lineNet.toStringAsFixed(0),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                textAlign: TextAlign.end),
          ),
          // 🚨 زرار الـ X للحذف 🚨
          SizedBox(
            width: 32.w,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Icon(Icons.close,
                  size: 16.r,
                  color: ColorsManager.errorText),
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedCell extends StatelessWidget {
  final String t;
  const _LockedCell(this.t);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70.w,
    child: Text(t,
        style: TextStyle(
            fontSize: 13.sp,
            color: ColorsManager.defaultTextSecondary),
        textAlign: TextAlign.center),
  );
}

class _EditableCell extends StatelessWidget {
  final TextEditingController ctrl;
  final bool allowDecimal;
  final String? suffix;
  final VoidCallback onChanged;
  final FormFieldValidator<String>? validator;

  const _EditableCell({
    required this.ctrl,
    this.allowDecimal = false,
    this.suffix,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70.w,
    child: TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13.sp,
          color: Theme.of(context).textTheme.bodyMedium?.color),
      onChanged: (_) => onChanged(),
      validator: validator,
      decoration: _cellDecoration(context),
    ),
  );
}

InputDecoration _cellDecoration(BuildContext context, {bool highlight = false}) {
  final theme = Theme.of(context);
  return InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
    filled: true,
    fillColor: highlight ? ColorsManager.warningSurface : theme.cardColor,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.r),
        borderSide: BorderSide(color: theme.dividerColor)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.r),
        borderSide: BorderSide(
            color: highlight ? ColorsManager.warningFill : theme.dividerColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.r),
        borderSide: BorderSide(color: ColorsManager.primaryColor)),
    errorStyle: TextStyle(fontSize: 9.sp, height: 0.8),
  );
}

// ─── New items section ────────────────────────────────────────────────────────

// ─── New items section ────────────────────────────────────────────────────────

class _NewItemsSection extends StatefulWidget {
  final List<_NewRow> rows;
  final void Function(ItemEntity) onAdd;
  final void Function(int) onRemove;
  final VoidCallback onChanged;
  final void Function(int, int)? onReorder;

  const _NewItemsSection({
    super.key,
    required this.rows,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
    this.onReorder,
  });

  @override
  State<_NewItemsSection> createState() => _NewItemsSectionState();
}

class _NewItemsSectionState extends State<_NewItemsSection> {
  ItemEntity? _pick;
  String? _selectedCategory;
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('invoices.add_new_items'.tr()),
        SizedBox(height: 10.h),
        BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            List<ItemEntity> allItems = [];
            List<String> categories = [];

            if (state is InventoryLoaded) {
              allItems = state.filtered.where((i) => i.availableQty > 0).toList();
              categories = allItems
                  .map((i) => i.category?.name ?? 'بدون فئة')
                  .toSet()
                  .toList();
            }

            final filteredItems = _selectedCategory == null
                ? allItems
                : allItems.where((i) => (i.category?.name ?? 'بدون فئة') == _selectedCategory).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Dropdown فلتر الفئات ───
                if (categories.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: AppDropdown<String?>(
                      title: '',
                      value: _selectedCategory,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('جميع الفئات', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: ColorsManager.primaryColor)),
                        ),
                        ...categories.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c, style: TextStyle(fontSize: 13.sp)),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _pick = null;
                          _searchCtrl.clear();
                          _focusNode.unfocus();
                        });
                      },
                    ),
                  ),

                // ─── حقل البحث وإضافة الصنف ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RawAutocomplete<ItemEntity>(
                        key: ValueKey(_selectedCategory),
                        textEditingController: _searchCtrl,
                        focusNode: _focusNode,
                        displayStringForOption: (item) => item.name,
                        optionsBuilder: (TextEditingValue v) {
                          final query = v.text.toLowerCase().trim();
                          if (query.isEmpty) return filteredItems;
                          return filteredItems.where((i) =>
                          i.name.toLowerCase().contains(query) ||
                              (i.model?.toLowerCase().contains(query) ?? false));
                        },
                        onSelected: (selection) {
                          setState(() => _pick = selection);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            onTap: () {
                              controller.notifyListeners();
                            },
                            style: TextStyle(fontSize: 13.sp),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'ابحث عن صنف لاختياره...',
                              hintStyle: TextStyle(
                                  fontSize: 12.sp,
                                  color: ColorsManager.defaultTextSecondary),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              filled: true,
                              fillColor: theme.cardColor,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  borderSide: BorderSide(color: theme.dividerColor)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  borderSide: BorderSide(color: theme.dividerColor)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                  borderSide: BorderSide(color: ColorsManager.primaryColor)),
                              prefixIcon: Icon(Icons.search,
                                  size: 18.r, color: ColorsManager.defaultTextSecondary),
                              suffixIcon: (_pick != null || controller.text.isNotEmpty)
                                  ? IconButton(
                                icon: Icon(Icons.close, size: 18.r, color: ColorsManager.errorText),
                                onPressed: () {
                                  setState(() {
                                    _pick = null;
                                    _searchCtrl.clear();
                                    _focusNode.unfocus();
                                  });
                                },
                              )
                                  : null,
                            ),
                            // 🚨 الفاليديشن: لو كتب أي حاجة بإيده نلغي الـ pick عشان الزرار يقفل
                            onChanged: (_) {
                              if (_pick != null) setState(() => _pick = null);
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Material(
                              elevation: 8,
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(8.r),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxHeight: 250.h, maxWidth: 300.w),
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) =>
                                      Divider(height: 1, color: theme.dividerColor),
                                  itemBuilder: (context, index) {
                                    final item = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(item),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.w, vertical: 10.h),
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(item.name,
                                                  style: TextStyle(
                                                      fontSize: 13.sp,
                                                      fontWeight: FontWeight.w500,
                                                      color: theme.textTheme.bodyMedium?.color),
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: ColorsManager.primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                'متوفر: ${item.availableQty}',
                                                style: TextStyle(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: ColorsManager.primaryColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _FlatBtn(
                      label: 'invoices.add_item_row'.tr(),
                      icon: Icons.add,
                      enabled: _pick != null, // 🚨 لا يمكن الضغط إلا إذا اختار من القائمة
                      onTap: _pick == null
                          ? () {}
                          : () {
                        widget.onAdd(_pick!);
                        setState(() {
                          _pick = null;
                          _searchCtrl.clear();
                          _focusNode.requestFocus();
                        });
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        if (widget.rows.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: ColorsManager.primaryColor.withOpacity(0.3))),
            child: Column(
              children: [
                _NewItemsHeader(),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: true,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    widget.onReorder?.call(oldIndex, newIndex);
                  },
                  itemCount: widget.rows.length,
                  itemBuilder: (context, index) {
                    final row = widget.rows[index];
                    return Column(
                      key: ValueKey(row),
                      children: [
                        Container(height: 1, color: theme.dividerColor),
                        _NewRowWidget(
                          row: row,
                          canRemove: true,
                          onRemove: () => widget.onRemove(index),
                          onChanged: widget.onChanged,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NewItemsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: ColorsManager.primaryColor);

    return Container(
      color: ColorsManager.primaryLight,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
              flex: 4, child: Text('invoices.col_item'.tr(), style: s)),
          _Hdr('invoices.col_qty'.tr(), s),
          _Hdr('invoices.col_days'.tr(), s),
          _Hdr('invoices.col_price'.tr(), s),
          _Hdr('invoices.col_disc_pct'.tr(), s),
          _Hdr('invoices.col_total'.tr(), s, end: true),
          SizedBox(width: 32.w),
        ],
      ),
    );
  }
}

class _NewRowWidget extends StatefulWidget {
  final _NewRow row;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _NewRowWidget(
      {super.key,
        required this.row,
        required this.canRemove,
        required this.onRemove,
        required this.onChanged});

  @override
  State<_NewRowWidget> createState() => _NewRowWidgetState();
}

class _NewRowWidgetState extends State<_NewRowWidget> {
  @override
  Widget build(BuildContext context) {
    final r = widget.row;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(r.item?.name ?? '—',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: ColorsManager.primaryColor),
                overflow: TextOverflow.ellipsis),
          ),
          _NumCell(
            ctrl: r.qtyCtrl,
            onChanged: () {
              setState(() {});
              widget.onChanged();
            },
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1) return '≥1';
              return null;
            },
          ),
          _NumCell(
            ctrl: r.daysCtrl,
            onChanged: () {
              setState(() {});
              widget.onChanged();
            },
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n < 1) return '≥1';
              return null;
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NumCell(
                  ctrl:         r.priceCtrl,
                  allowDecimal: true,
                  onChanged:    () { setState(() {}); widget.onChanged(); }
              ),
              if (r.item != null) ...[
                SizedBox(height: 4.h),
                PopupMenuButton<double>(
                  tooltip: 'اختر السعر',
                  padding: EdgeInsets.zero,
                  onSelected: (price) {
                    r.priceCtrl.text = price.toStringAsFixed(0);
                    setState(() {});
                    widget.onChanged();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: ColorsManager.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('الأسعار', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600, color: ColorsManager.primaryColor)),
                        Icon(Icons.arrow_drop_down, size: 12.r, color: ColorsManager.primaryColor),
                      ],
                    ),
                  ),
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: r.item!.defaultPrice,
                      child: Text('افتراضي: ${r.item!.defaultPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                    ),
                    PopupMenuItem(
                      value: r.item!.priceFilm,
                      child: Text('فيلم: ${r.item!.priceFilm.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                    ),
                    PopupMenuItem(
                      value: r.item!.priceSeries,
                      child: Text('مسلسل: ${r.item!.priceSeries.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                    ),
                    PopupMenuItem(
                      value: r.item!.priceAd,
                      child: Text('إعلان: ${r.item!.priceAd.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                    ),
                  ],
                ),
              ]
            ],
          ),
          _NumCell(
              ctrl: r.discCtrl,
              allowDecimal: true,
              suffix: '%',
              onChanged: () {
                setState(() {});
                widget.onChanged();
              }),
          SizedBox(
            width: 70.w,
            child: Text(r.lineNet.toStringAsFixed(0),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: ColorsManager.primaryColor),
                textAlign: TextAlign.end),
          ),
          SizedBox(
            width: 32.w,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Icon(Icons.close,
                  size: 16.r,
                  color: ColorsManager.defaultTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit footer ──────────────────────────────────────────────────────────────

class _EditFooter extends StatelessWidget {
  final double oldNet, newNet;
  final bool submitting;
  final double hPad;
  final VoidCallback onSubmit;
  final bool isDraft;
  final String invoiceId;
  final String customerId;

  const _EditFooter({
    required this.oldNet,
    required this.newNet,
    required this.submitting,
    required this.hPad,
    required this.onSubmit,
    required this.isDraft,
    required this.invoiceId,
    required this.customerId,
  });

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();

    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14.h),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TLine('invoices.old_net'.tr(),
                    '$cur ${oldNet.toStringAsFixed(0)}'),
                _TLine('invoices.new_net'.tr(),
                    '$cur ${newNet.toStringAsFixed(0)}',
                    bold: true),
              ],
            ),
            const Spacer(),

            _SubmitBtn(
              label: 'invoices.save_edit'.tr(),
              loading: submitting,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _Hdr extends StatelessWidget {
  final String t;
  final TextStyle s;
  final bool end;
  const _Hdr(this.t, this.s, {this.end = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70.w,
    child: Text(t,
        style: s,
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

class _NumCell extends StatelessWidget {
  final TextEditingController ctrl;
  final bool allowDecimal;
  final String? suffix;
  final VoidCallback? onChanged;
  final FormFieldValidator<String>? validator;

  const _NumCell(
      {required this.ctrl,
        this.allowDecimal = false,
        this.suffix,
        this.onChanged,
        this.validator});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 70.w,
      child: TextFormField(
        controller: ctrl,
        keyboardType:
        TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 13.sp, color: theme.textTheme.bodyMedium?.color),
        onChanged: (_) => onChanged?.call(),
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
          EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          suffixText: suffix,
          filled: true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: theme.dividerColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: ColorsManager.primaryColor)),
          errorStyle: TextStyle(fontSize: 9.sp, height: 0.8),
        ),
      ),
    );
  }
}

class _FlatBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _FlatBtn(
      {required this.label,
        required this.icon,
        required this.enabled,
        required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
          color: enabled
              ? ColorsManager.primaryColor
              : ColorsManager.backgroundSurface,
          borderRadius: BorderRadius.circular(6.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14.r,
              color: enabled
                  ? Colors.white
                  : ColorsManager.defaultTextSecondary),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? Colors.white
                      : ColorsManager.defaultTextSecondary)),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String t;
  const _SectionLabel(this.t);

  @override
  Widget build(BuildContext context) => Text(t,
      style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
          color: Theme.of(context).textTheme.titleSmall?.color));
}

class _TLine extends StatelessWidget {
  final String l, v;
  final bool bold;
  final Color? col;
  const _TLine(this.l, this.v, {this.bold = false, this.col});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l,
              style: TextStyle(
                  fontSize: bold ? 13.sp : 12.sp,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: theme.textTheme.bodyMedium?.color)),
          SizedBox(width: 16.w),
          Text(v,
              style: TextStyle(
                  fontSize: bold ? 15.sp : 13.sp,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: col ?? theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }
}

class _SubmitBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _SubmitBtn(
      {required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height: 42.h,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
          color: loading
              ? ColorsManager.primaryColor.withOpacity(0.6)
              : ColorsManager.primaryColor,
          borderRadius: BorderRadius.circular(8.r)),
      child: Center(
          child: loading
              ? SizedBox(
              width: 18.r,
              height: 18.r,
              child: const CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600))),
    ),
  );
}

// ─── Row data models ──────────────────────────────────────────────────────────

class _ExistingRow {
  final InvoiceItemEntity original;
  final TextEditingController daysCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  _ExistingRow(this.original)
      : daysCtrl  = TextEditingController(text: original.days.toString()),
        qtyCtrl   = TextEditingController(text: original.qty.toString()),
        priceCtrl = TextEditingController(
            text: original.pricePerDay.toStringAsFixed(0)),
        discCtrl  = TextEditingController(
            text: original.itemDiscountPercent.toStringAsFixed(1));

  int    get days         => int.tryParse(daysCtrl.text)     ?? original.days;
  int    get qty          => int.tryParse(qtyCtrl.text)      ?? original.qty;
  double get pricePerDay  => double.tryParse(priceCtrl.text) ?? original.pricePerDay;
  double get discPct      => (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
  double get flatDiscount => qty * days * pricePerDay * (discPct / 100);
  double get lineNet      =>
      (qty * days * pricePerDay - flatDiscount).clamp(0, double.infinity);

  void dispose() {
    daysCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }
}

class _NewRow {
  final ItemEntity? item;
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  _NewRow({this.item})
      : qtyCtrl = TextEditingController(text: '1'),
        daysCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(
            text: item != null ? item.defaultPrice.toStringAsFixed(0) : '0'),
        discCtrl = TextEditingController(text: '0');

  int get qty => int.tryParse(qtyCtrl.text) ?? 1;
  int get days => int.tryParse(daysCtrl.text) ?? 1;
  double get pricePerDay => double.tryParse(priceCtrl.text) ?? 0;
  double get discPct =>
      (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
  double get gross => qty * days * pricePerDay;
  double get flatDiscount => gross * (discPct / 100);
  double get lineNet => (gross - flatDiscount).clamp(0, double.infinity);

  void dispose() {
    qtyCtrl.dispose();
    daysCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }
}