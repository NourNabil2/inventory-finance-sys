// lib/features/suppliers/presentation/pages/create_supplier_invoice_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_dropdown.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart'; // 🚨 ضروري توليد ID للبنود

// ── Invoice direction ──────────────────────────────────────────────────────────

enum _InvoiceType {
  purchase(
    'فاتورة شراء منهم',
    'نحن نشتري → يزيد balance علينا',
    Icons.shopping_cart_outlined,
    ColorsManager.errorText,
  ),
  service(
    'فاتورة خدمات عليهم',
    'هم يأخذون منا → يزيد service_debt عليهم',
    Icons.receipt_long_outlined,
    ColorsManager.successText,
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _InvoiceType(this.label, this.subtitle, this.icon, this.color);
}

// ══════════════════════════════════════════════════════════════════════════════
// Page
// ══════════════════════════════════════════════════════════════════════════════

class CreateSupplierInvoicePage extends StatefulWidget {
  final SupplierEntity supplier;
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

  final _formKey     = GlobalKey<FormState>();
  final _notesCtrl   = TextEditingController();
  final _invDiscCtrl = TextEditingController(text: '0');
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
    _invDiscCtrl.dispose();
    for (final l in _lines) { l.dispose(); }
    super.dispose();
  }

  // ── Calculations ────────────────────────────────────────────────────────────

  double get _subtotal    => _lines.fold(0.0, (s, l) => s + l.lineNet);
  double get _invDiscPct  => (double.tryParse(_invDiscCtrl.text) ?? 0).clamp(0, 100);
  double get _invDiscFlat => _subtotal * (_invDiscPct / 100);
  double get _netTotal    => (_subtotal - _invDiscFlat).clamp(0, double.infinity);

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
      for (final l in _lines) { l.dispose(); }
      _lines.clear();
      _notesCtrl.clear();
      _invDiscCtrl.text = '0';
    });
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lines.isEmpty) {
      context.showError('أضف صنفاً واحداً على الأقل');
      return;
    }
    setState(() => _submitting = true);

    final cubit = context.read<SuppliersCubit>();

    if (_type == _InvoiceType.purchase) {
      final items = _lines.map((l) => SupplierInvoiceItemEntity(
        id:          const Uuid().v4(), // 🚨 إعطاء ID افتراضي
        invoiceId:   '',
        itemName:    l.itemName,
        qty:         l.qty,
        days:        l.days,
        pricePerDay: l.pricePerDay,
        itemDiscount: l.flatDiscount, // 🚨 التعديل السحري: تمرير الخصم الفعلي
      )).toList();

      await cubit.createInvoice(
        supplierId: widget.supplier.id,
        items:      items,
        discount:   _invDiscFlat,
        notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      final invoiceData = {
        'total_amount': _subtotal,
        'discount': _invDiscFlat,
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      };
      
      final itemsData = _lines.map((l) => {
        'item_id': l.item?.id,
        'qty': l.qty,
        'days': l.days,
        'price_per_day': l.pricePerDay,
        'item_discount': l.flatDiscount,
      }).toList();

      await cubit.createFullServiceInvoiceForSupplier(
        supplierId:  widget.supplier.id,
        invoiceData: invoiceData,
        itemsData:   itemsData,
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

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _TypeToggleBar(current: _type, onSelect: _switchType),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 20.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SupplierBadge(supplier: widget.supplier, type: _type),
                    SizedBox(height: 16.h),
                    _DirectionBanner(type: _type),
                    SizedBox(height: 16.h),

                    BlocBuilder<InventoryCubit, InventoryState>(
                      builder: (ctx, invState) {
                        final allItems = invState is InventoryLoaded
                            ? invState.filtered
                            : <ItemEntity>[];
                        return _ItemPickerSection(
                          lines:    _lines,
                          allItems: allItems,
                          type:     _type,
                          onAdd:    (item) => setState(() => _lines.add(_LineState(item: item))),
                          onRemove: (i) {
                            final line = _lines[i];
                            setState(() => _lines.removeAt(i));
                            Future.microtask(() => line.dispose()); // 🚨 تنظيف آمن للذاكرة
                          },
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),

                    SizedBox(height: 16.h),
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

          _Footer(
            subtotal:    _subtotal,
            invDiscPct:  _invDiscPct,
            invDiscFlat: _invDiscFlat,
            netTotal:    _netTotal,
            invDiscCtrl: _invDiscCtrl,
            type:        _type,
            submitting:  _submitting,
            hPad:        _hPad,
            onChanged:   () => setState(() {}),
            onSubmit:    _submit,
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
        child: Container(height: 1, color: theme.dividerColor)),
    leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 20.r),
        onPressed: () => Navigator.of(context).pop()),
    title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('فاتورة جديدة',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700,
              color: theme.textTheme.titleLarge?.color)),
      Text(widget.supplier.name,
          style: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Type toggle bar
// ══════════════════════════════════════════════════════════════════════════════

class _TypeToggleBar extends StatelessWidget {
  final _InvoiceType current;
  final void Function(_InvoiceType) onSelect;
  const _TypeToggleBar({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color:   theme.cardColor,
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
                    left:  t == _InvoiceType.service  ? 6.w : 0,
                    right: t == _InvoiceType.purchase ? 6.w : 0),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                decoration: BoxDecoration(
                  color:        sel ? t.color.withOpacity(0.1) : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border:       Border.all(color: sel ? t.color : theme.dividerColor,
                      width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(t.icon, size: 16.r,
                      color: sel ? t.color : ColorsManager.defaultTextSecondary),
                  SizedBox(width: 8.w),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.label,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700,
                            color: sel ? t.color : theme.textTheme.bodyMedium?.color)),
                    Text(t.subtitle,
                        style: TextStyle(fontSize: 9.sp, color: ColorsManager.defaultTextSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Direction banner
// ══════════════════════════════════════════════════════════════════════════════

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
        Icon(isPurchase ? Icons.arrow_circle_down_outlined : Icons.arrow_circle_up_outlined,
            size: 18.r, color: type.color),
        SizedBox(width: 10.w),
        Expanded(child: Text(
          isPurchase
              ? 'ستُضاف قيمة الفاتورة إلى رصيد المورد (مديونيتنا له)'
              : 'ستُضاف قيمة الفاتورة إلى مديونية المورد علينا (service_debt)',
          style: TextStyle(fontSize: 11.sp, color: type.color, fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Supplier badge
// ══════════════════════════════════════════════════════════════════════════════

class _SupplierBadge extends StatelessWidget {
  final SupplierEntity supplier;
  final _InvoiceType   type;
  const _SupplierBadge({required this.supplier, required this.type});

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final cur        = 'dashboard.currency'.tr();
    final letter     = supplier.name.trim().isEmpty ? '?' : supplier.name.trim()[0].toUpperCase();
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
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(supplier.name,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                  color: theme.textTheme.titleSmall?.color)),
          if (supplier.phone != null)
            Text(supplier.phone!,
                style: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary)),
        ])),
        if (isPurchase && supplier.balance > 0)
          _Chip(label: 'مديونيتنا له',
              value: '$cur ${supplier.balance.toStringAsFixed(0)}',
              color: ColorsManager.errorText, bg: ColorsManager.errorSurface),
        if (!isPurchase && supplier.serviceDebt > 0)
          _Chip(label: 'مديونيته لنا',
              value: '$cur ${supplier.serviceDebt.toStringAsFixed(0)}',
              color: ColorsManager.successText,
              bg: ColorsManager.successFill.withOpacity(0.15)),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final Color  color, bg;
  const _Chip({required this.label, required this.value, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6.r)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label, style: TextStyle(fontSize: 10.sp, color: color)),
      Text(value, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Item picker section
// ══════════════════════════════════════════════════════════════════════════════

class _ItemPickerSection extends StatefulWidget {
  final List<_LineState>          lines;
  final List<ItemEntity>          allItems;
  final _InvoiceType              type;
  final void Function(ItemEntity) onAdd;
  final void Function(int)        onRemove;
  final VoidCallback              onChanged;

  const _ItemPickerSection({
    required this.lines, required this.allItems, required this.type,
    required this.onAdd, required this.onRemove, required this.onChanged,
  });

  @override
  State<_ItemPickerSection> createState() => _ItemPickerSectionState();
}

class _ItemPickerSectionState extends State<_ItemPickerSection> {
  ItemEntity? _pick;
  String?     _cat;
  final _ctrl = TextEditingController();
  final _fn   = FocusNode();

  @override
  void dispose() { _ctrl.dispose(); _fn.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cats = widget.allItems
        .map((i) => i.category?.name ?? 'بدون فئة').toSet().toList();

    final filtered = _cat == null
        ? widget.allItems
        : widget.allItems.where((i) => (i.category?.name ?? 'بدون فئة') == _cat).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('الأصناف',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp,
                color: theme.textTheme.titleSmall?.color)),
        if (widget.lines.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color:        widget.type.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text('${widget.lines.length} صنف',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700,
                    color: widget.type.color)),
          ),
      ]),
      SizedBox(height: 10.h),

      // Category filter
      if (cats.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: AppDropdown<String?>(
            title: '',
            value: _cat,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text('جميع الفئات',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700,
                        color: ColorsManager.primaryColor)),
              ),
              ...cats.map((c) => DropdownMenuItem(value: c,
                  child: Text(c, style: TextStyle(fontSize: 13.sp)))),
            ],
            onChanged: (v) => setState(() { _cat = v; _pick = null; _ctrl.clear(); }),
          ),
        ),

      // Search + Add
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: RawAutocomplete<ItemEntity>(
            key:                    ValueKey(_cat),
            textEditingController:  _ctrl,
            focusNode:              _fn,
            displayStringForOption: (item) => item.name,
            optionsBuilder: (v) {
              final q = v.text.toLowerCase().trim();
              if (q.isEmpty) return filtered;
              return filtered.where((i) =>
              i.name.toLowerCase().contains(q) ||
                  (i.model?.toLowerCase().contains(q) ?? false));
            },
            onSelected: (sel) => setState(() => _pick = sel),
            fieldViewBuilder: (ctx, ctrl, fn, _) => TextField(
              controller: ctrl, focusNode: fn,
              onTap:      () => ctrl.notifyListeners(),
              onChanged:  (_) { if (_pick != null) setState(() => _pick = null); },
              style:      TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                isDense:   true,
                hintText:  'ابحث عن صنف لاختياره...',
                hintStyle: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                filled:     true, fillColor: theme.cardColor,
                prefixIcon: Icon(Icons.search, size: 18.r, color: ColorsManager.defaultTextSecondary),
                suffixIcon: (_pick != null || ctrl.text.isNotEmpty)
                    ? IconButton(
                  icon: Icon(Icons.close, size: 18.r, color: ColorsManager.errorText),
                  onPressed: () => setState(() {
                    _pick = null; _ctrl.clear(); _fn.unfocus();
                  }),
                )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
                    borderSide: BorderSide(color: theme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
                    borderSide: BorderSide(color: theme.dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
                    borderSide: BorderSide(color: ColorsManager.primaryColor)),
              ),
            ),
            optionsViewBuilder: (ctx, onSel, opts) => Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 8, color: theme.cardColor,
                borderRadius: BorderRadius.circular(8.r),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 250.h, maxWidth: 300.w),
                  child: ListView.separated(
                    padding: EdgeInsets.zero, shrinkWrap: true,
                    itemCount: opts.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (_, i) {
                      final item = opts.elementAt(i);
                      return InkWell(
                        onTap: () => onSel(item),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Text(item.name,
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500,
                                    color: theme.textTheme.bodyMedium?.color),
                                overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color:        ColorsManager.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text('${item.availableQty} متاح',
                                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600,
                                      color: ColorsManager.primaryColor)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        _AddBtn(
          enabled: _pick != null,
          onTap:   _pick == null ? () {} : () {
            widget.onAdd(_pick!);
            setState(() { _pick = null; _ctrl.clear(); _fn.requestFocus(); });
          },
        ),
      ]),

      SizedBox(height: 14.h),

      // Table
      Container(
        decoration: BoxDecoration(
            color:        theme.cardColor,
            borderRadius: BorderRadius.circular(8.r),
            border:       Border.all(color: theme.dividerColor)),
        child: widget.lines.isEmpty
            ? _EmptyPlaceholder(type: widget.type)
            : Column(children: [
          _TableHead(),
          ...widget.lines.asMap().entries.map((e) => Column(children: [
            Container(height: 1, color: theme.dividerColor),
            _LineRow(
              key:       ValueKey(e.key),
              line:      e.value,
              onRemove:  () => widget.onRemove(e.key),
              onChanged: widget.onChanged,
            ),
          ])),
        ]),
      ),
    ]);
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final _InvoiceType type;
  const _EmptyPlaceholder({required this.type});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 40.h),
    child: Center(child: Column(children: [
      Icon(type.icon, size: 32.r, color: ColorsManager.inputBorder),
      SizedBox(height: 8.h),
      Text('ابحث عن صنف وأضفه من الأعلى',
          style: TextStyle(fontSize: 13.sp, color: ColorsManager.defaultTextSecondary)),
    ])),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Table header
// ══════════════════════════════════════════════════════════════════════════════

class _TableHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600,
        color: ColorsManager.defaultTextSecondary, letterSpacing: 0.2);
    return Container(
      color:   theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(children: [
        Expanded(flex: 4, child: Text('الصنف', style: s)),
        _H('الكمية',    s),
        _H('الأيام',    s),
        _H('سعر/يوم',  s),
        _H('خصم %',    s),
        _H('الإجمالي', s, end: true),
        SizedBox(width: 28.w),
      ]),
    );
  }
}

class _H extends StatelessWidget {
  final String t; final TextStyle s; final bool end;
  const _H(this.t, this.s, {this.end = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 58.w,
    child: Text(t, style: s, textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Line row
// ══════════════════════════════════════════════════════════════════════════════

class _LineRow extends StatefulWidget {
  final _LineState   line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _LineRow({super.key, required this.line, required this.onRemove, required this.onChanged});
  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.line;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // اسم الصنف
        Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.itemName,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp,
                  color: theme.textTheme.bodyMedium?.color),
              overflow: TextOverflow.ellipsis),
          if (l.item != null)
            Text('${l.item!.availableQty} متاح',
                style: TextStyle(fontSize: 10.sp, color: ColorsManager.defaultTextSecondary)),
        ])),

        // الكمية
        _NumCell(ctrl: l.qtyCtrl, onChanged: () { setState(() {}); widget.onChanged(); },
            validator: (v) { final n = int.tryParse(v ?? ''); return (n == null || n < 1) ? '≥1' : null; }),

        // الأيام
        _NumCell(ctrl: l.daysCtrl, onChanged: () { setState(() {}); widget.onChanged(); },
            validator: (v) { final n = int.tryParse(v ?? ''); return (n == null || n < 1) ? '≥1' : null; }),

        // السعر + قائمة الأسعار
        SizedBox(width: 58.w, child: Column(mainAxisSize: MainAxisSize.min, children: [
          _NumCell(ctrl: l.priceCtrl, allowDecimal: true,
              onChanged: () { setState(() {}); widget.onChanged(); }),
          if (l.item != null) ...[
            SizedBox(height: 3.h),
            PopupMenuButton<double>(
              tooltip: 'اختر السعر', padding: EdgeInsets.zero,
              onSelected: (price) {
                l.priceCtrl.text = price.toStringAsFixed(0);
                setState(() {}); widget.onChanged();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: ColorsManager.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('الأسعار', style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w600,
                      color: ColorsManager.primaryColor)),
                  Icon(Icons.arrow_drop_down, size: 12.r, color: ColorsManager.primaryColor),
                ]),
              ),
              itemBuilder: (ctx) => [
                PopupMenuItem(value: l.item!.defaultPrice,
                    child: Text('افتراضي: ${l.item!.defaultPrice.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600))),
                PopupMenuItem(value: l.item!.priceFilm,
                    child: Text('فيلم: ${l.item!.priceFilm.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.sp))),
                PopupMenuItem(value: l.item!.priceSeries,
                    child: Text('مسلسل: ${l.item!.priceSeries.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.sp))),
                PopupMenuItem(value: l.item!.priceAd,
                    child: Text('إعلان: ${l.item!.priceAd.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 11.sp))),
              ],
            ),
          ],
        ])),

        // خصم %
        _NumCell(ctrl: l.discCtrl, allowDecimal: true, suffix: '%',
            onChanged: () { setState(() {}); widget.onChanged(); }),

        // إجمالي السطر
        SizedBox(width: 58.w, child: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Text(l.lineNet.toStringAsFixed(0),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp,
                  color: theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.end),
        )),

        // حذف
        SizedBox(width: 28.w, child: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: GestureDetector(
            onTap: widget.onRemove,
            child: Icon(Icons.close, size: 16.r, color: ColorsManager.errorText),
          ),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Num cell
// ══════════════════════════════════════════════════════════════════════════════

class _NumCell extends StatelessWidget {
  final TextEditingController       ctrl;
  final bool                        allowDecimal;
  final String?                     suffix;
  final VoidCallback?               onChanged;
  final FormFieldValidator<String>?  validator;

  const _NumCell({
    required this.ctrl,
    this.allowDecimal = false,
    this.suffix,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 58.w,
      child: TextFormField(
        controller:   ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign:    TextAlign.center,
        style:        TextStyle(fontSize: 12.sp),
        onChanged:    (_) => onChanged?.call(),
        validator:    validator,
        decoration: InputDecoration(
          isDense:        true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          suffixText:     suffix,
          suffixStyle:    TextStyle(fontSize: 10.sp, color: ColorsManager.defaultTextSecondary),
          filled:         true, fillColor: theme.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r),
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

// ══════════════════════════════════════════════════════════════════════════════
// Footer
// ══════════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  final double       subtotal, invDiscPct, invDiscFlat, netTotal;
  final TextEditingController invDiscCtrl;
  final _InvoiceType type;
  final bool         submitting;
  final double       hPad;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _Footer({
    required this.subtotal, required this.invDiscPct,
    required this.invDiscFlat, required this.netTotal,
    required this.invDiscCtrl, required this.type,
    required this.submitting, required this.hPad,
    required this.onChanged, required this.onSubmit,
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // خصم الفاتورة %
            SizedBox(
              width: 110.w,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('خصم الفاتورة %',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500,
                        color: ColorsManager.defaultTextSecondary)),
                SizedBox(height: 4.h),
                _NumCell(
                  ctrl:         invDiscCtrl,
                  allowDecimal: true,
                  suffix:       '%',
                  onChanged:    onChanged,
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n < 0 || n > 100) return '0–100';
                    return null;
                  },
                ),
              ]),
            ),

            const Spacer(),

            // ملخص الأرقام
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _TLine('الإجمالي قبل الخصم', '$cur ${subtotal.toStringAsFixed(0)}'),
              if (invDiscFlat > 0)
                _TLine('خصم الفاتورة (${invDiscPct.toStringAsFixed(1)}%)',
                    '− $cur ${invDiscFlat.toStringAsFixed(0)}',
                    col: ColorsManager.warningFill),
              Container(height: 1, width: 240.w, color: theme.dividerColor,
                  margin: EdgeInsets.symmetric(vertical: 4.h)),
              _TLine(
                type == _InvoiceType.purchase
                    ? 'الصافي (يُضاف لمديونيتنا للمورد)'
                    : 'الصافي (يُضاف لمديونية المورد علينا)',
                '$cur ${netTotal.toStringAsFixed(0)}',
                bold: true, col: type.color,
              ),
            ]),
          ]),

          SizedBox(height: 12.h),

          SizedBox(
            width: double.infinity, height: 46.h,
            child: GestureDetector(
              onTap: submitting ? null : onSubmit,
              child: Container(
                decoration: BoxDecoration(
                  color:        submitting ? type.color.withOpacity(0.6) : type.color,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: submitting
                      ? SizedBox(width: 20.r, height: 20.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(type.icon, size: 18.r, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      type == _InvoiceType.purchase
                          ? 'تأكيد فاتورة الشراء'
                          : 'تأكيد فاتورة الخدمات',
                      style: TextStyle(color: Colors.white,
                          fontSize: 14.sp, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TLine extends StatelessWidget {
  final String label, value;
  final bool   bold;
  final Color? col;
  const _TLine(this.label, this.value, {this.bold = false, this.col});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: bold ? 13.sp : 12.sp,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: theme.textTheme.bodyMedium?.color)),
        SizedBox(width: 16.w),
        Text(value, style: TextStyle(fontSize: bold ? 15.sp : 13.sp,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: col ?? theme.textTheme.bodyMedium?.color)),
      ]),
    );
  }
}

class _AddBtn extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _AddBtn({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color:        enabled ? ColorsManager.primaryColor : ColorsManager.backgroundSurface,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add, size: 14.r,
            color: enabled ? Colors.white : ColorsManager.defaultTextSecondary),
        SizedBox(width: 4.w),
        Text('إضافة', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
            color: enabled ? Colors.white : ColorsManager.defaultTextSecondary)),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Line state
// ══════════════════════════════════════════════════════════════════════════════

class _LineState {
  final ItemEntity? item;   // للعرض فقط — مش بيأثر على المخزن

  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  _LineState({this.item})
      : qtyCtrl   = TextEditingController(text: '1'),
        daysCtrl  = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(
            text: item != null ? item.defaultPrice.toStringAsFixed(0) : '0'),
        discCtrl  = TextEditingController(text: '0');

  String get itemName     => item?.name ?? '';
  int    get qty          => int.tryParse(qtyCtrl.text)      ?? 1;
  int    get days         => int.tryParse(daysCtrl.text)     ?? 1;
  double get pricePerDay  => double.tryParse(priceCtrl.text) ?? 0;
  double get discPct      => (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
  double get gross        => qty * days * pricePerDay;
  double get flatDiscount => gross * (discPct / 100);
  double get lineNet      => (gross - flatDiscount).clamp(0, double.infinity);

  void dispose() {
    qtyCtrl.dispose();
    daysCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }
}