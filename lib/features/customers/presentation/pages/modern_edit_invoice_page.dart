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
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _discCtrl = TextEditingController(
        text: widget.invoice.discountPercent.toStringAsFixed(1));
    _existing = widget.invoice.items
        .where((i) => i.isOut)
        .map(_ExistingRow.new)
        .toList();
  }

  @override
  void dispose() {
    _discCtrl.dispose();
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

  double _existingSubtotal() =>
      _existing.fold(0.0, (s, r) => s + r.lineNet);

  double _newSubtotal() => _newRows.fold(0.0, (s, r) => s + r.lineNet);

  double _newInvDiscount() {
    final pct = (double.tryParse(_discCtrl.text) ?? 0).clamp(0, 100);
    return (_existingSubtotal() + _newSubtotal()) * (pct / 100);
  }

  double get _newNet =>
      (_existingSubtotal() + _newSubtotal() - _newInvDiscount())
          .clamp(0, double.infinity);

  double get _additionalDebt => (_newNet - _oldNet).clamp(0, double.infinity);

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isAdmin = context.read<UserCubit>().isAdmin;

    final modifiedItems = <String, Map<String, dynamic>>{};
    for (final r in _existing) {
      final daysChanged  = r.days != r.original.days;
      final qtyChanged   = isAdmin && r.qty != r.original.qty;
      final priceChanged = isAdmin && r.pricePerDay != r.original.pricePerDay;
      final discChanged  = isAdmin && r.flatDiscount != r.original.itemDiscount;

      if (daysChanged || qtyChanged || priceChanged || discChanged) {
        modifiedItems[r.original.id] = {
          'days':         r.days,
          'qty':          isAdmin ? r.qty          : r.original.qty,
          'pricePerDay':  isAdmin ? r.pricePerDay  : r.original.pricePerDay,
          'flatDiscount': isAdmin ? r.flatDiscount : r.original.itemDiscount,
        };
      }
    }

    final newItemEntities = _newRows
        .map((r) => InvoiceItemEntity(
      id:           '',
      invoiceId:    widget.invoice.id,
      itemId:       r.item!.id,
      itemName:     r.item!.name,
      qty:          r.qty,
      days:         r.days,
      pricePerDay:  r.pricePerDay,
      itemDiscount: r.flatDiscount,
      status:       InvoiceItemStatus.out,
    ))
        .toList();

    final pct         = (double.tryParse(_discCtrl.text) ?? 0).clamp(0, 100);
    final newDiscFlat = (_existingSubtotal() + _newSubtotal()) * (pct / 100);

    setState(() => _submitting = true);
    if (!mounted) return;

    context.read<InvoicesCubit>().editInvoice(
      invoiceId:       widget.invoice.id,
      originalInvoice: widget.invoice,
      newItems:        newItemEntities,
      modifiedItems:   modifiedItems,
      newDiscountFlat: newDiscFlat,
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  padding: EdgeInsets.symmetric(
                      horizontal: _hPad, vertical: 24.h),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExistingItemsSection(
                          rows: _existing,
                          onChanged: () => setState(() {}),
                        ),
                        SizedBox(height: 20.h),
                        _NewItemsSection(
                          rows: _newRows,
                          onAdd: (item) =>
                              setState(() => _newRows.add(_NewRow(item: item))),
                          onRemove: (i) => setState(() {
                            _newRows[i].dispose();
                            _newRows.removeAt(i);
                          }),
                          onChanged: () => setState(() {}),
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
                additionalDebt: _additionalDebt,
                submitting: _submitting,
                hPad: _hPad,
                onSubmit: _submit,
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

// ─── Existing items section ───────────────────────────────────────────────────

class _ExistingItemsSection extends StatelessWidget {
  final List<_ExistingRow> rows;
  final VoidCallback onChanged;

  const _ExistingItemsSection(
      {required this.rows, required this.onChanged});

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
                ...rows.asMap().entries.map((e) => Column(children: [
                  Container(height: 1, color: theme.dividerColor),
                  _ExistingRowWidget(
                      row: e.value, onChanged: onChanged),
                ])),
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
          Expanded(
              flex: 4, child: Text('invoices.col_item'.tr(), style: s)),
          _Hdr('invoices.col_qty'.tr(), s),
          _Hdr('invoices.col_days'.tr(), s),
          _Hdr('invoices.col_price'.tr(), s),
          _Hdr('invoices.col_disc_pct'.tr(), s),
          _Hdr('invoices.col_total'.tr(), s, end: true),
          _Hdr('invoices.col_status'.tr(), s),
        ],
      ),
    );
  }
}

class _ExistingRowWidget extends StatefulWidget {
  final _ExistingRow row;
  final VoidCallback onChanged;
  const _ExistingRowWidget({required this.row, required this.onChanged});

  @override
  State<_ExistingRowWidget> createState() => _ExistingRowWidgetState();
}

class _ExistingRowWidgetState extends State<_ExistingRowWidget> {
  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final r       = widget.row;
    final isAdmin = context.read<UserCubit>().isAdmin;
    final isExtended = r.days > r.original.days;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: theme.cardColor,
      child: Row(
        children: [
          // اسم الصنف — مش بيتغير
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.original.itemName ?? '—',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                    overflow: TextOverflow.ellipsis),
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

          // ── الكمية: أدمن = editable, غيره = locked ──
          isAdmin
              ? _EditableCell(ctrl: r.qtyCtrl, onChanged: widget.onChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1) ? '≥1' : null;
              })
              : _LockedCell('${r.original.qty}'),

          // ── الأيام: للكل editable (الحالي) ──
          SizedBox(
            width: 70.w,
            child: TextFormField(
              controller: r.daysCtrl,
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

          // ── السعر: أدمن = editable ──
          isAdmin
              ? _EditableCell(ctrl: r.priceCtrl, allowDecimal: true, onChanged: widget.onChanged)
              : _LockedCell(r.original.pricePerDay.toStringAsFixed(0)),

          // ── الخصم: أدمن = editable ──
          isAdmin
              ? _EditableCell(ctrl: r.discCtrl, allowDecimal: true, suffix: '%', onChanged: widget.onChanged,
              validator: (v) {
                final n = double.tryParse(v ?? '');
                return (n == null || n < 0 || n > 100) ? '0–100' : null;
              })
              : _LockedCell(r.original.itemDiscount > 0
              ? '${r.original.itemDiscountPercent.toStringAsFixed(1)}%'
              : '—'),

          // الإجمالي
          SizedBox(
            width: 70.w,
            child: Text(r.lineNet.toStringAsFixed(0),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                textAlign: TextAlign.end),
          ),

          // Status badge
          SizedBox(
            width: 70.w,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                    color: ColorsManager.warningSurface,
                    borderRadius: BorderRadius.circular(4.r)),
                child: Text('invoices.item_status_out'.tr(),
                    style: TextStyle(fontSize: 10.sp,
                        color: ColorsManager.warningText, fontWeight: FontWeight.w600)),
              ),
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

class _NewItemsSection extends StatefulWidget {
  final List<_NewRow> rows;
  final void Function(ItemEntity) onAdd;
  final void Function(int) onRemove;
  final VoidCallback onChanged;

  const _NewItemsSection(
      {required this.rows,
        required this.onAdd,
        required this.onRemove,
        required this.onChanged});

  @override
  State<_NewItemsSection> createState() => _NewItemsSectionState();
}

class _NewItemsSectionState extends State<_NewItemsSection> {
  ItemEntity? _pick;

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
            final items = state is InventoryLoaded
                ? state.filtered.where((i) => i.availableQty > 0).toList()
                : <ItemEntity>[];

            return Row(
              children: [
                Expanded(
                  child: AppDropdown<ItemEntity?>(
                    title: '',
                    value: _pick,
                    enabled: items.isNotEmpty,
                    onChanged: (v) => setState(() => _pick = v),
                    items: items
                        .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text('${i.name} (×${i.availableQty})',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.sp)),
                    ))
                        .toList(),
                  ),
                ),
                SizedBox(width: 10.w),
                _FlatBtn(
                  label: 'invoices.add_item_row'.tr(),
                  icon: Icons.add,
                  enabled: _pick != null,
                  onTap: _pick == null
                      ? () {}
                      : () {
                    widget.onAdd(_pick!);
                    setState(() => _pick = null);
                  },
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
                ...widget.rows.asMap().entries.map((e) => Column(children: [
                  Container(height: 1, color: theme.dividerColor),
                  _NewRowWidget(
                    key: ValueKey(e.key),
                    row: e.value,
                    canRemove: true,
                    onRemove: () => widget.onRemove(e.key),
                    onChanged: widget.onChanged,
                  ),
                ])),
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
    final theme = Theme.of(context);
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
          _NumCell(ctrl: r.priceCtrl, allowDecimal: true, onChanged: () {
            setState(() {});
            widget.onChanged();
          }),
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
  final double oldNet, newNet, additionalDebt;
  final bool submitting;
  final double hPad;
  final VoidCallback onSubmit;

  const _EditFooter(
      {required this.oldNet,
        required this.newNet,
        required this.additionalDebt,
        required this.submitting,
        required this.hPad,
        required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur = 'dashboard.currency'.tr();

    return Container(
      decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor))),
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
                if (additionalDebt > 0)
                  _TLine('invoices.additional_debt'.tr(),
                      '+$cur ${additionalDebt.toStringAsFixed(0)}',
                      col: ColorsManager.errorText),
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