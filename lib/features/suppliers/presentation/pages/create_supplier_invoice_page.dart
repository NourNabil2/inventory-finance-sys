// lib/features/suppliers/presentation/pages/create_supplier_invoice_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/supplier_invoice_item_entity.dart';

// ── Invoice direction ─────────────────────────────────────────
enum _InvoiceType {
  purchase('فاتورة شراء منهم',  'نحن نشتري → يزيد balance علينا',  Icons.shopping_cart_outlined,   ColorsManager.errorText),
  service ('فاتورة خدمات عليهم','هم يأخذون منا → يزيد service_debt عليهم', Icons.receipt_long_outlined, ColorsManager.successText);

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _InvoiceType(this.label, this.subtitle, this.icon, this.color);
}

// ── Page ──────────────────────────────────────────────────────

class CreateSupplierInvoicePage extends StatefulWidget {
  final SupplierEntity supplier;
  /// Pass [initialType] to open directly on a specific tab (optional).
  final _InvoiceType initialType;

  const CreateSupplierInvoicePage({
    super.key,
    required this.supplier,
    this.initialType = _InvoiceType.purchase,
  });

  @override
  State<CreateSupplierInvoicePage> createState() =>
      _CreateSupplierInvoicePageState();
}

class _CreateSupplierInvoicePageState
    extends State<CreateSupplierInvoicePage> {
  late _InvoiceType _type;

  final _formKey   = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final List<_LineState> _lines = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  double get _subtotal  => _lines.fold(0.0, (s, l) => s + l.lineTotal);

  double get _hPad {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return (w - 920) / 2;
    if (w > 700)  return 40.w;
    return 16.w;
  }

  void _switchType(_InvoiceType t) {
    if (t == _type) return;
    setState(() {
      _type = t;
      // clear lines & notes when switching — avoids confusion
      for (final l in _lines) l.dispose();
      _lines.clear();
      _notesCtrl.clear();
    });
  }

  // ── Submit ────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lines.isEmpty) {
      context.showError('أضف صنفاً واحداً على الأقل');
      return;
    }
    setState(() => _submitting = true);

    final cubit = context.read<SuppliersCubit>();

    if (_type == _InvoiceType.purchase) {
      // ── Purchase invoice (supplier_invoices table) ────────
      final items = _lines.map((l) => SupplierInvoiceItemEntity(
        id:          '',
        invoiceId:   '',
        itemName:    l.nameCtrl.text.trim(),
        qty:         l.qty,
        days:        l.days,
        pricePerDay: l.pricePerDay,
      )).toList();

      await cubit.createInvoice(
        supplierId: widget.supplier.id,
        items:      items,
        notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      // ── Service invoice (invoices table → service_debt) ───
      await cubit.createServiceInvoiceForSupplier(
        supplierId:  widget.supplier.id,
        totalAmount: _subtotal,
        notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        // Pass item breakdown as a structured notes string so it's preserved
        // If you later add a full RPC, swap this call with createFullServiceInvoice
      );
    }

    if (!mounted) return;
    final st = cubit.state;
    if (st.hasError) {
      setState(() => _submitting = false);
      context.showError(st.errorMessage ?? 'حدث خطأ');
    } else {
      context.showSuccess(_type == _InvoiceType.purchase
          ? 'تم إنشاء فاتورة الشراء بنجاح'
          : 'تم إنشاء فاتورة الخدمات بنجاح');
      Navigator.of(context).pop();
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          // ── Type toggle bar ──────────────────────────────
          _TypeToggleBar(current: _type, onSelect: _switchType),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 20.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Supplier badge ─────────────────────
                    _SupplierBadge(supplier: widget.supplier, type: _type),
                    SizedBox(height: 16.h),

                    // ── Direction info banner ──────────────
                    _DirectionBanner(type: _type),
                    SizedBox(height: 16.h),

                    // ── Items table ────────────────────────
                    BlocBuilder<InventoryCubit, InventoryState>(
                      builder: (context, state) {
                        final items = state is InventoryLoaded
                            ? state.items
                            : <ItemEntity>[];
                        return _ItemsSection(
                          lines:          _lines,
                          inventoryItems: items,
                          type:           _type,
                          onAdd:    () => setState(() => _lines.add(_LineState())),
                          onRemove: (i)  => setState(() {
                            _lines[i].dispose();
                            _lines.removeAt(i);
                          }),
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),

                    SizedBox(height: 16.h),
                    // ── Notes ──────────────────────────────
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines:   2,
                      decoration: InputDecoration(
                        labelText:  'ملاحظات / البيان (اختياري)',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────
          _Footer(
            subtotal:   _subtotal,
            type:       _type,
            submitting: _submitting,
            hPad:       _hPad,
            onSubmit:   _submit,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) => AppBar(
    backgroundColor:  theme.cardColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: theme.dividerColor),
    ),
    leading: IconButton(
      icon:      Icon(Icons.arrow_back, size: 20.r),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('فاتورة جديدة',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color)),
        Text(widget.supplier.name,
            style: TextStyle(fontSize: 12.sp,
                color: ColorsManager.defaultTextSecondary)),
      ],
    ),
  );
}

// ── Type toggle bar ───────────────────────────────────────────

class _TypeToggleBar extends StatelessWidget {
  final _InvoiceType current;
  final void Function(_InvoiceType) onSelect;

  const _TypeToggleBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color:  theme.cardColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: _InvoiceType.values.map((t) {
          final sel = t == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(
                    left:  t == _InvoiceType.service ? 6.w : 0,
                    right: t == _InvoiceType.purchase ? 6.w : 0),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color: sel
                      ? t.color.withOpacity(0.1)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: sel ? t.color : theme.dividerColor,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(t.icon,
                        size:  16.r,
                        color: sel ? t.color : ColorsManager.defaultTextSecondary),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.label,
                              style: TextStyle(
                                  fontSize:   12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? t.color
                                      : Theme.of(context).textTheme.bodyMedium?.color)),
                          Text(t.subtitle,
                              style: TextStyle(
                                  fontSize: 9.sp,
                                  color: ColorsManager.defaultTextSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Direction banner ──────────────────────────────────────────

class _DirectionBanner extends StatelessWidget {
  final _InvoiceType type;
  const _DirectionBanner({required this.type});

  @override
  Widget build(BuildContext context) {
    final isPurchase = type == _InvoiceType.purchase;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color:        type.color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8.r),
        border:       Border.all(color: type.color.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(isPurchase ? Icons.arrow_circle_down_outlined
            : Icons.arrow_circle_up_outlined,
            size: 18.r, color: type.color),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            isPurchase
                ? 'ستُضاف قيمة الفاتورة إلى رصيد المورد (مديونيتنا له)'
                : 'ستُضاف قيمة الفاتورة إلى مديونية المورد علينا (service_debt)',
            style: TextStyle(fontSize: 11.sp, color: type.color,
                fontWeight: FontWeight.w600),
          ),
        ),
      ]),
    );
  }
}

// ── Supplier badge ────────────────────────────────────────────

class _SupplierBadge extends StatelessWidget {
  final SupplierEntity supplier;
  final _InvoiceType   type;
  const _SupplierBadge({required this.supplier, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final cur    = 'dashboard.currency'.tr();
    final letter = supplier.name.trim().isEmpty
        ? '?' : supplier.name.trim()[0].toUpperCase();
    final isPurchase = type == _InvoiceType.purchase;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(8.r),
        border:       Border.all(color: theme.dividerColor),
      ),
      child: Row(children: [
        CircleAvatar(
          radius:          18.r,
          backgroundColor: ColorsManager.primaryColor.withOpacity(0.12),
          child: Text(letter,
              style: TextStyle(color: ColorsManager.primaryColor,
                  fontWeight: FontWeight.w700, fontSize: 13.sp)),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(supplier.name,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                    color: theme.textTheme.titleSmall?.color)),
            if (supplier.phone != null)
              Text(supplier.phone!,
                  style: TextStyle(fontSize: 12.sp,
                      color: ColorsManager.defaultTextSecondary)),
          ]),
        ),
        // Show relevant balance
        if (isPurchase && supplier.balance > 0)
          _Badge(
            label:  'مديونيتنا له',
            value:  '$cur ${supplier.balance.toStringAsFixed(0)}',
            color:  ColorsManager.errorText,
            bgColor: ColorsManager.errorSurface,
          ),
        if (!isPurchase && supplier.serviceDebt > 0)
          _Badge(
            label:  'مديونيته لنا',
            value:  '$cur ${supplier.serviceDebt.toStringAsFixed(0)}',
            color:  ColorsManager.successText,
            bgColor: ColorsManager.successFill.withOpacity(0.15),
          ),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;
  final Color  bgColor;
  const _Badge({required this.label, required this.value,
    required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(color: bgColor,
        borderRadius: BorderRadius.circular(6.r)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label,
          style: TextStyle(fontSize: 10.sp, color: color)),
      Text(value,
          style: TextStyle(fontSize: 12.sp,
              fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ── Items section ─────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final List<_LineState>  lines;
  final List<ItemEntity>  inventoryItems;
  final _InvoiceType      type;
  final VoidCallback      onAdd;
  final void Function(int) onRemove;
  final VoidCallback      onChanged;

  const _ItemsSection({
    required this.lines,
    required this.inventoryItems,
    required this.type,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('الأصناف',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                    color: theme.textTheme.titleSmall?.color)),
            _FlatBtn(
                label: 'إضافة صنف',
                icon:  Icons.add,
                color: type.color,
                onTap: onAdd),
          ],
        ),
        SizedBox(height: 10.h),
        if (lines.isEmpty)
          _EmptyPlaceholder(type: type)
        else
          Container(
            decoration: BoxDecoration(
                color:        theme.cardColor,
                borderRadius: BorderRadius.circular(8.r),
                border:       Border.all(color: theme.dividerColor)),
            child: Column(children: [
              _TableHead(),
              ...lines.asMap().entries.map((e) => Column(children: [
                Container(height: 1, color: theme.dividerColor),
                _LineRow(
                  key:            ValueKey(e.key),
                  line:           e.value,
                  inventoryItems: inventoryItems,
                  onRemove:       () => onRemove(e.key),
                  onChanged:      onChanged,
                ),
              ])),
            ]),
          ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final _InvoiceType type;
  const _EmptyPlaceholder({required this.type});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 40.h),
    decoration: BoxDecoration(
      color:        Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8.r),
      border:       Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Center(
      child: Column(children: [
        Icon(type.icon, size: 32.r, color: ColorsManager.inputBorder),
        SizedBox(height: 8.h),
        Text('لا توجد أصناف بعد',
            style: TextStyle(fontSize: 13.sp,
                color: ColorsManager.defaultTextSecondary)),
      ]),
    ),
  );
}

class _TableHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600,
        color: ColorsManager.defaultTextSecondary);
    return Container(
      color:   theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(children: [
        Expanded(flex: 4, child: Text('اسم الصنف', style: s)),
        _Hdr('الكمية', s),
        _Hdr('الأيام', s),
        _Hdr('السعر/يوم', s),
        _Hdr('الإجمالي', s, end: true),
        SizedBox(width: 28.w),
      ]),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String t; final TextStyle s; final bool end;
  const _Hdr(this.t, this.s, {this.end = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62.w,
    child: Text(t, style: s,
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

// ── Line row ──────────────────────────────────────────────────

class _LineRow extends StatefulWidget {
  final _LineState       line;
  final List<ItemEntity> inventoryItems;
  final VoidCallback     onRemove;
  final VoidCallback     onChanged;

  const _LineRow({
    super.key,
    required this.line,
    required this.inventoryItems,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l     = widget.line;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _ItemAutocomplete(
              line:      l,
              items:     widget.inventoryItems,
              onChanged: widget.onChanged,
            ),
          ),
          SizedBox(width: 6.w),
          _NumCell(ctrl: l.qtyCtrl, onChanged: widget.onChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1) ? '≥1' : null;
              }),
          SizedBox(width: 4.w),
          _NumCell(ctrl: l.daysCtrl, onChanged: widget.onChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n == null || n < 1) ? '≥1' : null;
              }),
          SizedBox(width: 4.w),
          _NumCell(ctrl: l.priceCtrl, allowDecimal: true,
              onChanged: widget.onChanged),
          SizedBox(width: 4.w),
          SizedBox(
            width: 62.w,
            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(l.lineTotal.toStringAsFixed(0),
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp,
                      color: theme.textTheme.bodyMedium?.color),
                  textAlign: TextAlign.end),
            ),
          ),
          SizedBox(width: 4.w),
          SizedBox(
            width: 24.w,
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close, size: 16.r,
                    color: ColorsManager.defaultTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Autocomplete ──────────────────────────────────────────────

class _ItemAutocomplete extends StatelessWidget {
  final _LineState       line;
  final List<ItemEntity> items;
  final VoidCallback     onChanged;

  const _ItemAutocomplete({
    required this.line,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawAutocomplete<ItemEntity>(
      textEditingController: line.nameCtrl,
      focusNode:             line.focusNode,
      displayStringForOption: (item) => item.name,
      optionsBuilder: (v) {
        final q = v.text.toLowerCase().trim();
        if (q.isEmpty) return items;
        return items.where((i) => i.name.toLowerCase().contains(q));
      },
      onSelected: (sel) {
        line.nameCtrl.text  = sel.name;
        line.priceCtrl.text = sel.defaultPrice.toStringAsFixed(0);
        onChanged();
      },
      fieldViewBuilder: (ctx, ctrl, fn, _) => TextFormField(
        controller:  ctrl,
        focusNode:   fn,
        style:       TextStyle(fontSize: 13.sp),
        decoration:  InputDecoration(
          isDense:  true,
          hintText: 'اختر أو اكتب...',
          hintStyle: TextStyle(fontSize: 11.sp,
              color: ColorsManager.defaultTextSecondary),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          filled:     true,
          fillColor:  theme.cardColor,
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: theme.dividerColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: ColorsManager.primaryColor)),
          errorStyle: TextStyle(fontSize: 9.sp, height: 0.8),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
        onChanged: (_) => onChanged(),
      ),
      optionsViewBuilder: (ctx, onSel, opts) => Align(
        alignment: AlignmentDirectional.topStart,
        child: Material(
          elevation:    8,
          color:        theme.cardColor,
          borderRadius: BorderRadius.circular(8.r),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 280.w),
            child: ListView.separated(
              padding:          EdgeInsets.zero,
              shrinkWrap:       true,
              itemCount:        opts.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (_, i) {
                final item = opts.elementAt(i);
                return InkWell(
                  onTap: () => onSel(item),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(item.name,
                              style: TextStyle(fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: theme.textTheme.bodyMedium?.color),
                              overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color:        ColorsManager.primaryColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text('متوفر: ${item.availableQty}',
                              style: TextStyle(fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: ColorsManager.primaryColor)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Num cell ──────────────────────────────────────────────────

class _NumCell extends StatelessWidget {
  final TextEditingController      ctrl;
  final bool                       allowDecimal;
  final VoidCallback               onChanged;
  final FormFieldValidator<String>? validator;

  const _NumCell({
    required this.ctrl,
    required this.onChanged,
    this.allowDecimal = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 62.w,
      child: TextFormField(
        controller:  ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign:   TextAlign.center,
        style:       TextStyle(fontSize: 13.sp),
        onChanged:   (_) => onChanged(),
        validator:   validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          filled:     true,
          fillColor:  theme.cardColor,
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: theme.dividerColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
              borderSide: BorderSide(color: ColorsManager.primaryColor)),
          errorStyle: TextStyle(fontSize: 9.sp, height: 0.8),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final double       subtotal;
  final _InvoiceType type;
  final bool         submitting;
  final double       hPad;
  final VoidCallback onSubmit;

  const _Footer({
    required this.subtotal,
    required this.type,
    required this.submitting,
    required this.hPad,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();
    return Container(
      decoration: BoxDecoration(
          color:  theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor))),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14.h),
      child: SafeArea(
        child: Row(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الإجمالي',
                  style: TextStyle(fontSize: 12.sp,
                      color: ColorsManager.defaultTextSecondary)),
              Text('$cur ${subtotal.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w800,
                      color: type.color)),
            ],
          ),
          const Spacer(),
          _SubmitBtn(
            label:   type == _InvoiceType.purchase
                ? 'تأكيد فاتورة الشراء'
                : 'تأكيد فاتورة الخدمات',
            color:   type.color,
            loading: submitting,
            onTap:   onSubmit,
          ),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _FlatBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;
  const _FlatBtn({required this.label, required this.icon,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(6.r)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14.r, color: Colors.white),
        SizedBox(width: 4.w),
        Text(label, style: TextStyle(fontSize: 12.sp,
            fontWeight: FontWeight.w600, color: Colors.white)),
      ]),
    ),
  );
}

class _SubmitBtn extends StatelessWidget {
  final String   label;
  final Color    color;
  final bool     loading;
  final VoidCallback onTap;
  const _SubmitBtn({required this.label, required this.color,
    required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height:  44.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
          color:        loading ? color.withOpacity(0.6) : color,
          borderRadius: BorderRadius.circular(8.r)),
      child: Center(
        child: loading
            ? SizedBox(width: 20.r, height: 20.r,
            child: const CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : Text(label, style: TextStyle(color: Colors.white,
            fontSize: 13.sp, fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

// ── Line state ────────────────────────────────────────────────

class _LineState {
  final TextEditingController nameCtrl;
  final FocusNode             focusNode;
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;

  _LineState()
      : nameCtrl  = TextEditingController(),
        focusNode  = FocusNode(),
        qtyCtrl   = TextEditingController(text: '1'),
        daysCtrl  = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(text: '0');

  int    get qty        => int.tryParse(qtyCtrl.text)      ?? 1;
  int    get days       => int.tryParse(daysCtrl.text)     ?? 1;
  double get pricePerDay => double.tryParse(priceCtrl.text) ?? 0;
  double get lineTotal  => qty * days * pricePerDay;

  void dispose() {
    nameCtrl.dispose(); focusNode.dispose();
    qtyCtrl.dispose();  daysCtrl.dispose(); priceCtrl.dispose();
  }
}