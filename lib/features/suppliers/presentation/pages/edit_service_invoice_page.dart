import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditServiceInvoicePage extends StatefulWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;

  const EditServiceInvoicePage({
    super.key,
    required this.invoice,
    required this.supplierId,
  });

  @override
  State<EditServiceInvoicePage> createState() => _EditServiceInvoicePageState();
}

class _EditServiceInvoicePageState extends State<EditServiceInvoicePage> {
  final List<_ExistingServiceLineState> _existingLines = [];
  final List<_NewServiceLineState> _newLines = [];
  final List<String> _deletedItemIds = [];

  late final TextEditingController _globalDiscPctCtrl;
  late final TextEditingController _globalDiscFlatCtrl;
  late final TextEditingController _notesCtrl;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    context.read<InventoryCubit>().fetchItems();

    _globalDiscPctCtrl = TextEditingController(text: '0');
    _globalDiscFlatCtrl = TextEditingController(text: widget.invoice.discount.toStringAsFixed(0));
    _notesCtrl = TextEditingController(text: widget.invoice.notes ?? '');

    for (var item in widget.invoice.items) {
      _existingLines.add(_ExistingServiceLineState(item));
    }
    _updateGlobalDiscountPct();
  }

  @override
  void dispose() {
    for (var el in _existingLines) { el.dispose(); }
    for (var nl in _newLines) { nl.dispose(); }
    _globalDiscPctCtrl.dispose();
    _globalDiscFlatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _grossTotal {
    double t = 0;
    for (var l in _existingLines) { t += l.lineNet; }
    for (var l in _newLines) { t += l.lineNet; }
    return t;
  }

  double get _globalFlatDiscount => double.tryParse(_globalDiscFlatCtrl.text) ?? 0;
  double get _globalDiscPct      => double.tryParse(_globalDiscPctCtrl.text) ?? 0;
  double get _netTotal           => (_grossTotal - _globalFlatDiscount).clamp(0, double.infinity);

  double get _hPad {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return (w - 920) / 2;
    if (w > 700)  return 40.w;
    return 16.w;
  }

  void _updateGlobalDiscountPct() {
    final g = _grossTotal;
    final flat = _globalFlatDiscount;
    if (g > 0) {
      final pct = (flat / g) * 100;
      _globalDiscPctCtrl.text = pct.toStringAsFixed(1);
    } else {
      _globalDiscPctCtrl.text = '0';
    }
  }

  void _onGlobalDiscPctChanged(String val) {
    final pct = double.tryParse(val) ?? 0;
    if (pct > 100) return;
    final flat = _grossTotal * (pct / 100);
    _globalDiscFlatCtrl.text = flat.toStringAsFixed(0);
    setState(() {});
  }

  void _onGlobalDiscFlatChanged(String val) {
    final flat = double.tryParse(val) ?? 0;
    if (_grossTotal > 0) {
      final pct = (flat / _grossTotal) * 100;
      _globalDiscPctCtrl.text = pct.toStringAsFixed(1);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (_netTotal < widget.invoice.paidAmount) {
      context.showError('الصافي (${_netTotal.toStringAsFixed(0)}) أقل من المبلغ المدفوع مسبقاً (${widget.invoice.paidAmount})');
      return;
    }
    setState(() => _submitting = true);

    final existingUpdates = _existingLines.map((l) => {
      'id': l.original.id,
      'qty': l.qty,
      'days': l.days,
      'price_per_day': l.pricePerDay,
      'item_discount': l.flatDiscount,
    }).toList();

    final newItems = _newLines.map((l) => {
      'item_id': l.item.id,
      'qty': l.qty,
      'days': l.days,
      'price_per_day': l.pricePerDay,
      'item_discount': l.flatDiscount,
    }).toList();

    await context.read<SuppliersCubit>().editServiceInvoice(
      invoiceId: widget.invoice.id,
      supplierId: widget.supplierId,
      discount: _globalFlatDiscount,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      deletedItemIds: _deletedItemIds,
      existingUpdates: existingUpdates,
      newItems: newItems,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) => p.serviceInvoiceEditStatus != c.serviceInvoiceEditStatus,
      listener: (context, state) {
        if (state.serviceInvoiceEditStatus == ServiceInvoiceEditStatus.success) {
          context.showSuccess('تم تعديل الفاتورة بنجاح!');
          Navigator.pop(context);
        } else if (state.serviceInvoiceEditStatus == ServiceInvoiceEditStatus.failure) {
          context.showError(state.errorMessage ?? 'حدث خطأ');
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: _hPad, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<InventoryCubit, InventoryState>(
                      builder: (ctx, invState) {
                        final allItems = invState is InventoryLoaded ? invState.filtered : <ItemEntity>[];
                        final categories = invState is InventoryLoaded ? invState.categories : <ItemCategoryEntity>[];
                        return _ItemPickerSection(
                          existingLines: _existingLines,
                          newLines:      _newLines,
                          allItems:      allItems,
                          categories:    categories,
                          onAdd:         (item) => setState(() {
                            _newLines.add(_NewServiceLineState(item: item));
                            _updateGlobalDiscountPct();
                          }),
                          onRemoveExisting: (i) {
                            final line = _existingLines[i];
                            setState(() {
                              _deletedItemIds.add(line.original.id);
                              _existingLines.removeAt(i);
                              _updateGlobalDiscountPct();
                            });
                            Future.microtask(() => line.dispose());
                          },
                          onRemoveNew: (i) {
                            final line = _newLines[i];
                            setState(() {
                              _newLines.removeAt(i);
                              _updateGlobalDiscountPct();
                            });
                            Future.microtask(() => line.dispose());
                          },
                          onChanged: () => setState(() => _updateGlobalDiscountPct()),
                        );
                      },
                    ),

                    SizedBox(height: 16.h),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines:   2,
                      decoration: InputDecoration(
                        labelText:  'ملاحظات الفاتورة',
                        prefixIcon: const Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            _Footer(
              subtotal:    _grossTotal,
              invDiscPct:  _globalDiscPct,
              invDiscFlat: _globalFlatDiscount,
              netTotal:    _netTotal,
              invDiscPctCtrl: _globalDiscPctCtrl,
              invDiscFlatCtrl: _globalDiscFlatCtrl,
              submitting:  _submitting,
              hPad:        _hPad,
              onPctChanged:  _onGlobalDiscPctChanged,
              onFlatChanged: _onGlobalDiscFlatChanged,
              onSubmit:    _submit,
            ),
          ],
        ),
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
    title: Text('تعديل فاتورة الخدمات',
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700,
            color: theme.textTheme.titleLarge?.color)),
  );
}

// ══════════════════════════════════════════════════════════════════════════════════════════
// Item picker & Table section
// ══════════════════════════════════════════════════════════════════════════════════════════

class _ItemPickerSection extends StatefulWidget {
  final List<_ExistingServiceLineState> existingLines;
  final List<_NewServiceLineState>      newLines;
  final List<ItemEntity>                allItems;
  final List<ItemCategoryEntity>        categories;
  final void Function(ItemEntity)       onAdd;
  final void Function(int)              onRemoveExisting;
  final void Function(int)              onRemoveNew;
  final VoidCallback                    onChanged;

  const _ItemPickerSection({
    required this.existingLines, required this.newLines, required this.allItems, required this.categories,
    required this.onAdd, required this.onRemoveExisting, required this.onRemoveNew, required this.onChanged,
  });

  @override
  State<_ItemPickerSection> createState() => _ItemPickerSectionState();
}

class _ItemPickerSectionState extends State<_ItemPickerSection> {
  ItemEntity? _pick;
  final _ctrl = TextEditingController();
  final _fn   = FocusNode();
  String? _selectedCategoryId;

  @override
  void dispose() { _ctrl.dispose(); _fn.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalLines = widget.existingLines.length + widget.newLines.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('الأصناف', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: theme.textTheme.titleSmall?.color)),
        if (totalLines > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(color: ColorsManager.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
            child: Text('$totalLines صنف', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: ColorsManager.primaryColor)),
          ),
      ]),
      SizedBox(height: 10.h),

      // Category filter dropdown
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(6.r), border: Border.all(color: theme.dividerColor)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: _selectedCategoryId,
            isExpanded: true,
            hint: Text('كل التصنيفات', style: TextStyle(fontSize: 13.sp)),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text('كل التصنيفات', style: TextStyle(fontSize: 13.sp))),
              ...widget.categories.map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name, style: TextStyle(fontSize: 13.sp)))),
            ],
            onChanged: (val) {
              setState(() => _selectedCategoryId = val);
              context.read<InventoryCubit>().filterByCategory(val);
              setState(() { _pick = null; _ctrl.clear(); });
            },
          ),
        ),
      ),
      SizedBox(height: 10.h),

      // Search + Add
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: RawAutocomplete<ItemEntity>(
            textEditingController:  _ctrl,
            focusNode:              _fn,
            displayStringForOption: (item) => item.name,
            optionsBuilder: (v) {
              final q = v.text.toLowerCase().trim();
              if (q.isEmpty) return widget.allItems;
              return widget.allItems.where((i) => i.name.toLowerCase().contains(q) || (i.model?.toLowerCase().contains(q) ?? false));
            },
            onSelected: (sel) => setState(() => _pick = sel),
            fieldViewBuilder: (ctx, ctrl, fn, _) => TextField(
              controller: ctrl, focusNode: fn, onTap: () => ctrl.notifyListeners(),
              onChanged: (_) { if (_pick != null) setState(() => _pick = null); },
              style: TextStyle(fontSize: 13.sp),
              decoration: InputDecoration(
                isDense: true, hintText: 'ابحث عن صنف لإضافته...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                filled: true, fillColor: theme.cardColor,
                prefixIcon: Icon(Icons.search, size: 18.r, color: ColorsManager.defaultTextSecondary),
                suffixIcon: (_pick != null || ctrl.text.isNotEmpty)
                    ? IconButton(icon: Icon(Icons.close, size: 18.r, color: ColorsManager.errorText), onPressed: () => setState(() { _pick = null; _ctrl.clear(); _fn.unfocus(); }))
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: theme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: theme.dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: ColorsManager.primaryColor)),
              ),
            ),
            optionsViewBuilder: (ctx, onSel, opts) => Align(
              alignment: AlignmentDirectional.topStart,
              child: Material(
                elevation: 8, color: theme.cardColor, borderRadius: BorderRadius.circular(8.r),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 250.h, maxWidth: 300.w),
                  child: ListView.separated(
                    padding: EdgeInsets.zero, shrinkWrap: true, itemCount: opts.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (_, i) {
                      final item = opts.elementAt(i);
                      return InkWell(
                        onTap: () => onSel(item),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color), overflow: TextOverflow.ellipsis),
                                if (item.model != null || item.category != null)
                                  Text([item.model, item.category?.name].where((e) => e != null).join(' - '), style: TextStyle(fontSize: 10.sp, color: ColorsManager.defaultTextSecondary)),
                              ],
                            )),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(color: ColorsManager.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4.r)),
                              child: Text('${item.availableQty} متاح', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: ColorsManager.primaryColor)),
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
        GestureDetector(
          onTap: _pick == null ? null : () {
            widget.onAdd(_pick!);
            setState(() { _pick = null; _ctrl.clear(); _fn.requestFocus(); });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(color: _pick != null ? ColorsManager.primaryColor : ColorsManager.backgroundSurface, borderRadius: BorderRadius.circular(6.r)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, size: 14.r, color: _pick != null ? Colors.white : ColorsManager.defaultTextSecondary),
              SizedBox(width: 4.w),
              Text('إضافة', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _pick != null ? Colors.white : ColorsManager.defaultTextSecondary)),
            ]),
          ),
        ),
      ]),

      SizedBox(height: 14.h),

      // Table
      Container(
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(8.r), border: Border.all(color: theme.dividerColor)),
        child: totalLines == 0
            ? Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(child: Column(children: [
            Icon(Icons.shopping_cart_outlined, size: 32.r, color: ColorsManager.inputBorder),
            SizedBox(height: 8.h),
            Text('الفاتورة فارغة حالياً', style: TextStyle(fontSize: 13.sp, color: ColorsManager.defaultTextSecondary)),
          ])),
        )
            : Column(children: [
          _TableHead(),
          ...widget.existingLines.asMap().entries.map((e) => Column(children: [
            Container(height: 1, color: theme.dividerColor),
            _LineRow(
              line: e.value,
              isNew: false,
              onRemove: () => widget.onRemoveExisting(e.key),
              onChanged: widget.onChanged,
            ),
          ])),
          ...widget.newLines.asMap().entries.map((e) => Column(children: [
            Container(height: 1, color: theme.dividerColor),
            _LineRow(
              line: e.value,
              isNew: true,
              onRemove: () => widget.onRemoveNew(e.key),
              onChanged: widget.onChanged,
            ),
          ])),
        ]),
      ),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════════════════
// Table UI Components
// ══════════════════════════════════════════════════════════════════════════════════════════

class _TableHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: ColorsManager.defaultTextSecondary, letterSpacing: 0.2);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(children: [
        Expanded(flex: 4, child: Text('الصنف', style: s)),
        _H('الكمية', s), _H('الأيام', s), _H('سعر/يوم', s),
        _H('خصم %', s), _H('الخصم', s), _H('الإجمالي', s, end: true),
        SizedBox(width: 28.w),
      ]),
    );
  }
}

class _H extends StatelessWidget {
  final String t; final TextStyle s; final bool end;
  const _H(this.t, this.s, {this.end = false});
  @override
  Widget build(BuildContext context) => SizedBox(width: 58.w, child: Text(t, style: s, textAlign: end ? TextAlign.end : TextAlign.center));
}

class _LineRow extends StatefulWidget {
  final dynamic      line; // accepts both _ExistingServiceLineState and _NewServiceLineState
  final bool         isNew;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _LineRow({required this.line, required this.isNew, required this.onRemove, required this.onChanged});
  @override
  State<_LineRow> createState() => _LineRowState();
}

class _LineRowState extends State<_LineRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.line;

    return Container(
      color: widget.isNew ? ColorsManager.primaryColor.withOpacity(0.02) : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.itemName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: theme.textTheme.bodyMedium?.color), overflow: TextOverflow.ellipsis),
          if (l.itemModel != null)
            Text(l.itemModel!, style: TextStyle(fontSize: 10.sp, color: ColorsManager.defaultTextSecondary)),
          if (widget.isNew) Text('مضاف حديثاً', style: TextStyle(fontSize: 10.sp, color: ColorsManager.primaryColor))
          else Text('موجود', style: TextStyle(fontSize: 10.sp, color: ColorsManager.successText)),
        ])),
        _NumCell(ctrl: l.qtyCtrl, onChanged: () { setState(() {}); widget.onChanged(); }),
        _NumCell(ctrl: l.daysCtrl, onChanged: () { setState(() {}); widget.onChanged(); }),
        _NumCell(ctrl: l.priceCtrl, allowDecimal: true, onChanged: () { setState(() {}); widget.onChanged(); }),
        _NumCell(ctrl: l.discCtrl, allowDecimal: true, suffix: '%', onChanged: () { setState(() {}); widget.onChanged(); }),
        SizedBox(
          width: 58.w,
          child: Padding(
            padding: EdgeInsets.only(top: 8.h),
            child: Text(
              l.flatDiscount.toStringAsFixed(0),
              style: TextStyle(fontSize: 12.sp, color: ColorsManager.errorText, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ),
        SizedBox(width: 58.w, child: Padding(padding: EdgeInsets.only(top: 8.h), child: Text(l.lineNet.toStringAsFixed(0), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp, color: theme.textTheme.bodyMedium?.color), textAlign: TextAlign.end))),
        SizedBox(width: 28.w, child: Padding(padding: EdgeInsets.only(top: 6.h), child: GestureDetector(onTap: widget.onRemove, child: Icon(Icons.close, size: 16.r, color: ColorsManager.errorText)))),
      ]),
    );
  }
}

class _NumCell extends StatelessWidget {
  final TextEditingController ctrl;
  final bool allowDecimal;
  final String? suffix;
  final VoidCallback? onChanged;

  const _NumCell({required this.ctrl, this.allowDecimal = false, this.suffix, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 58.w,
      child: TextFormField(
        controller: ctrl, keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp), onChanged: (_) => onChanged?.call(),
        decoration: InputDecoration(
          isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          suffixText: suffix, suffixStyle: TextStyle(fontSize: 10.sp, color: ColorsManager.defaultTextSecondary),
          filled: true, fillColor: theme.cardColor,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: theme.dividerColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: ColorsManager.primaryColor)),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════════════════
// Footer
// ══════════════════════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  final double       subtotal, invDiscPct, invDiscFlat, netTotal;
  final TextEditingController invDiscPctCtrl;
  final TextEditingController invDiscFlatCtrl;
  final bool         submitting;
  final double       hPad;
  final void Function(String) onPctChanged;
  final void Function(String) onFlatChanged;
  final VoidCallback onSubmit;

  const _Footer({
    required this.subtotal, required this.invDiscPct, required this.invDiscFlat, required this.netTotal,
    required this.invDiscPctCtrl, required this.invDiscFlatCtrl, required this.submitting, required this.hPad,
    required this.onPctChanged, required this.onFlatChanged, required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return Container(
      decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14.h),
      child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 110.w,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('خصم الفاتورة %', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: ColorsManager.defaultTextSecondary)),
                SizedBox(height: 4.h),
                _NumCell(ctrl: invDiscPctCtrl, allowDecimal: true, suffix: '%', onChanged: () => onPctChanged(invDiscPctCtrl.text)),
              ]),
            ),
            SizedBox(width: 16.w),
            SizedBox(
              width: 110.w,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('خصم الفاتورة (مبلغ)', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: ColorsManager.defaultTextSecondary)),
                SizedBox(height: 4.h),
                _NumCell(ctrl: invDiscFlatCtrl, allowDecimal: true, suffix: cur, onChanged: () => onFlatChanged(invDiscFlatCtrl.text)),
              ]),
            ),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _TLine('الإجمالي قبل الخصم', '$cur ${subtotal.toStringAsFixed(0)}'),
              if (invDiscFlat > 0)
                _TLine('خصم الفاتورة (${invDiscPct.toStringAsFixed(1)}%)', '− $cur ${invDiscFlat.toStringAsFixed(0)}', col: ColorsManager.warningFill),
              Container(height: 1, width: 240.w, color: theme.dividerColor, margin: EdgeInsets.symmetric(vertical: 4.h)),
              _TLine('الصافي النهائي', '$cur ${netTotal.toStringAsFixed(0)}', bold: true, col: ColorsManager.primaryColor),
            ]),
          ]),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity, height: 46.h,
            child: GestureDetector(
              onTap: submitting ? null : onSubmit,
              child: Container(
                decoration: BoxDecoration(color: submitting ? ColorsManager.primaryColor.withOpacity(0.6) : ColorsManager.primaryColor, borderRadius: BorderRadius.circular(10.r)),
                child: Center(
                  child: submitting
                      ? SizedBox(width: 20.r, height: 20.r, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.save_outlined, size: 18.r, color: Colors.white), SizedBox(width: 8.w),
                    Text('حفظ التعديلات', style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700)),
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
  final String label, value; final bool bold; final Color? col;
  const _TLine(this.label, this.value, {this.bold = false, this.col});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontSize: bold ? 13.sp : 12.sp, fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: theme.textTheme.bodyMedium?.color)),
        SizedBox(width: 16.w),
        Text(value, style: TextStyle(fontSize: bold ? 15.sp : 13.sp, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: col ?? theme.textTheme.bodyMedium?.color)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════════════════
// Classes For Edit
// ══════════════════════════════════════════════════════════════════════════════════════════

class _ExistingServiceLineState {
  final ServiceInvoiceItemEntity original;
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  _ExistingServiceLineState(this.original)
      : qtyCtrl = TextEditingController(text: original.qty.toString()),
        daysCtrl = TextEditingController(text: original.days.toString()),
        priceCtrl = TextEditingController(text: original.pricePerDay.toStringAsFixed(0)),
        discCtrl = TextEditingController(text: _calcPct(original));

  static String _calcPct(ServiceInvoiceItemEntity orig) {
    double gross = orig.qty * orig.days * orig.pricePerDay;
    if (gross == 0) return '0';
    double pct = (orig.itemDiscount / gross) * 100;
    return pct == 0 ? '0' : pct.toStringAsFixed(1);
  }

  String get itemName     => original.itemName ?? '';
  String? get itemModel   => original.itemModel;
  int    get qty          => int.tryParse(qtyCtrl.text)      ?? 1;
  int    get days         => int.tryParse(daysCtrl.text)     ?? 1;
  double get pricePerDay  => double.tryParse(priceCtrl.text) ?? 0;
  double get discPct      => (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
  double get gross        => qty * days * pricePerDay;
  double get flatDiscount => gross * (discPct / 100);
  double get lineNet      => (gross - flatDiscount).clamp(0, double.infinity);

  void dispose() {
    qtyCtrl.dispose(); daysCtrl.dispose(); priceCtrl.dispose();
    discCtrl.dispose();
  }
}

class _NewServiceLineState {
  final ItemEntity item;
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  _NewServiceLineState({required this.item})
      : qtyCtrl   = TextEditingController(text: '1'),
        daysCtrl  = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(text: item.defaultPrice.toStringAsFixed(0)),
        discCtrl  = TextEditingController(text: '0');

  String get itemName     => item.name;
  String? get itemModel   => item.model;
  int    get qty          => int.tryParse(qtyCtrl.text)      ?? 1;
  int    get days         => int.tryParse(daysCtrl.text)     ?? 1;
  double get pricePerDay  => double.tryParse(priceCtrl.text) ?? 0;
  double get discPct      => (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
  double get gross        => qty * days * pricePerDay;
  double get flatDiscount => gross * (discPct / 100);
  double get lineNet      => (gross - flatDiscount).clamp(0, double.infinity);

  void dispose() {
    qtyCtrl.dispose(); daysCtrl.dispose(); priceCtrl.dispose();
    discCtrl.dispose();
  }
}
