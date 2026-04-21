// lib/features/suppliers/presentation/pages/create_supplier_invoice_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateSupplierInvoicePage extends StatefulWidget {
  final SupplierEntity supplier;
  const CreateSupplierInvoicePage({super.key, required this.supplier});

  @override
  State<CreateSupplierInvoicePage> createState() =>
      _CreateSupplierInvoicePageState();
}

class _CreateSupplierInvoicePageState
    extends State<CreateSupplierInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final List<_LineState> _lines = [];
  bool _submitting = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    for (final l in _lines) l.dispose();
    super.dispose();
  }

  double get _total => _lines.fold(0.0, (s, l) => s + l.lineTotal);

  double get _hPad {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return (w - 920) / 2;
    if (w > 700) return 40.w;
    return 16.w;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lines.isEmpty) {
      context.showError('أضف صنفاً واحداً على الأقل');
      return;
    }

    setState(() => _submitting = true);

    final items = _lines.map((l) => SupplierInvoiceItemEntity(
      id: '', invoiceId: '', itemName: l.nameCtrl.text.trim(),
      qty: l.qty, days: l.days, pricePerDay: l.pricePerDay,
    )).toList();

    final cubit = context.read<SuppliersCubit>();
    await cubit.createInvoice(
      supplierId: widget.supplier.id,
      items: items,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    final state = cubit.state;
    // 🚨 تأكدنا إننا بنقفل لو مفيش إيرور، لأن الـ Cubit بيعمل loading -> success 🚨
    if (state.hasError) {
      setState(() => _submitting = false);
      context.showError(state.errorMessage ?? 'حدث خطأ');
    } else {
      context.showSuccess('تم إنشاء الفاتورة بنجاح');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
                    _SupplierBadge(supplier: widget.supplier),
                    SizedBox(height: 20.h),

                    // 🚨 التعديل السحري: تمرير InventoryCubit للمنتجات 🚨
                    BlocBuilder<InventoryCubit, InventoryState>(
                      builder: (context, state) {
                        List<ItemEntity> inventoryItems = [];
                        if (state is InventoryLoaded) {
                          inventoryItems = state.items;
                        }

                        return _ItemsSection(
                          lines: _lines,
                          inventoryItems: inventoryItems,
                          onAdd: () => setState(() => _lines.add(_LineState())),
                          onRemove: (i) => setState(() {
                            _lines[i].dispose();
                            _lines.removeAt(i);
                          }),
                          onChanged: () => setState(() {}),
                        );
                      },
                    ),

                    SizedBox(height: 16.h),
                    // Notes field
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
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
            total: _total,
            submitting: _submitting,
            hPad: _hPad,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) => AppBar(
    backgroundColor: theme.cardColor,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: theme.dividerColor),
    ),
    leading: IconButton(
      icon: Icon(Icons.arrow_back, size: 20.r),
      onPressed: () => Navigator.of(context).pop(),
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('فاتورة مورد جديدة',
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color)),
        Text(widget.supplier.name,
            style: TextStyle(
                fontSize: 12.sp,
                color: ColorsManager.defaultTextSecondary)),
      ],
    ),
  );
}

// ─── Supplier badge ──────────────────────────────────────────────────────────

class _SupplierBadge extends StatelessWidget {
  final SupplierEntity supplier;
  const _SupplierBadge({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur = 'dashboard.currency'.tr();
    final letter = supplier.name.trim().isEmpty
        ? '?'
        : supplier.name.trim()[0].toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: ColorsManager.primaryColor.withOpacity(0.12),
            child: Text(letter,
                style: TextStyle(
                    color: ColorsManager.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: theme.textTheme.titleSmall?.color)),
                if (supplier.phone != null)
                  Text(supplier.phone!,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: ColorsManager.defaultTextSecondary)),
              ],
            ),
          ),
          if (supplier.balance > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                  color: ColorsManager.errorSurface,
                  borderRadius: BorderRadius.circular(6.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('المديونية الحالية',
                      style: TextStyle(
                          fontSize: 10.sp, color: ColorsManager.errorText)),
                  Text('$cur ${supplier.balance.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.errorText)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Items section ────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final List<_LineState> lines;
  final List<ItemEntity> inventoryItems;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final VoidCallback onChanged;

  const _ItemsSection({
    required this.lines,
    required this.inventoryItems,
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
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: theme.textTheme.titleSmall?.color)),
            _FlatBtn(label: 'إضافة صنف', icon: Icons.add, onTap: onAdd),
          ],
        ),
        SizedBox(height: 10.h),
        if (lines.isEmpty)
          _EmptyPlaceholder()
        else
          Container(
            decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: theme.dividerColor)),
            child: Column(
              children: [
                _TableHead(),
                ...lines.asMap().entries.map((e) => Column(children: [
                  Container(height: 1, color: theme.dividerColor),
                  _LineRow(
                    key: ValueKey(e.key),
                    line: e.value,
                    inventoryItems: inventoryItems, // 👈 باصينا المنتجات هنا
                    onRemove: () => onRemove(e.key),
                    onChanged: onChanged,
                  ),
                ])),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: 40.h),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8.r),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 32.r, color: ColorsManager.inputBorder),
          SizedBox(height: 8.h),
          Text('لا توجد أصناف بعد',
              style: TextStyle(
                  fontSize: 13.sp,
                  color: ColorsManager.defaultTextSecondary)),
        ],
      ),
    ),
  );
}

class _TableHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        color: ColorsManager.defaultTextSecondary);

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('اسم الصنف', style: s)),
          _Hdr('الكمية', s),
          _Hdr('الأيام', s),
          _Hdr('السعر/يوم', s),
          _Hdr('الإجمالي', s, end: true),
          SizedBox(width: 28.w),
        ],
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String t;
  final TextStyle s;
  final bool end;
  const _Hdr(this.t, this.s, {this.end = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 62.w,
    child: Text(t,
        style: s, textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

// ─── Line row ─────────────────────────────────────────────────────────────────

class _LineRow extends StatefulWidget {
  final _LineState line;
  final List<ItemEntity> inventoryItems;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

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
    final l = widget.line;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚨 حقل اسم الصنف الذكي (بحث أو كتابة حرة) 🚨
          Expanded(
            flex: 4,
            child: _ItemAutocomplete(
              line: l,
              items: widget.inventoryItems,
              onChanged: widget.onChanged,
            ),
          ),
          SizedBox(width: 6.w),
          _NumCell(
              ctrl: l.qtyCtrl,
              onChanged: widget.onChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return '≥1';
                return null;
              }),
          SizedBox(width: 4.w),
          _NumCell(
              ctrl: l.daysCtrl,
              onChanged: widget.onChanged,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return '≥1';
                return null;
              }),
          SizedBox(width: 4.w),
          _NumCell(
              ctrl: l.priceCtrl,
              allowDecimal: true,
              onChanged: widget.onChanged),
          SizedBox(width: 4.w),
          // Total — locked display
          SizedBox(
            width: 62.w,
            child: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Text(
                l.lineTotal.toStringAsFixed(0),
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: theme.textTheme.bodyMedium?.color),
                textAlign: TextAlign.end,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          SizedBox(
            width: 24.w,
            child: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Icon(Icons.close,
                    size: 16.r,
                    color: ColorsManager.defaultTextSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Autocomplete Widget (السحر هنا) ──────────────────────────────────────────

// ─── Autocomplete Widget (السحر هنا) ──────────────────────────────────────────

class _ItemAutocomplete extends StatelessWidget {
  final _LineState line;
  final List<ItemEntity> items;
  final VoidCallback onChanged;

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
      focusNode: line.focusNode,
      // 🚨 الاسم اللي هينزل في الحقل بعد الاختيار (الاسم فقط)
      displayStringForOption: (item) => item.name,
      optionsBuilder: (TextEditingValue v) {
        final query = v.text.toLowerCase().trim();
        if (query.isEmpty) return items;
        return items.where((i) => i.name.toLowerCase().contains(query));
      },
      onSelected: (selection) {
        line.nameCtrl.text = selection.name;
        line.priceCtrl.text = selection.defaultPrice.toStringAsFixed(0); // سحب السعر أوتوماتيك
        onChanged();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(fontSize: 13.sp),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'اختر من المخزن أو اكتب...',
            hintStyle: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
            contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
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
          validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
          onChanged: (_) => onChanged(),
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
              // 🚨 كبرنا العرض شوية عشان يكفي الاسم + الكمية
              constraints: BoxConstraints(maxHeight: 200.h, maxWidth: 280.w),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(item),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      // 🚨 التعديل السحري هنا: إظهار الاسم والكمية المتوفرة بشكل أنيق 🚨
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: ColorsManager.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'متوفر: ${item.availableQty}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: ColorsManager.primaryColor,
                              ),
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
    );
  }
}
// ───────────────────────────────────────────────────────────────────────────────

class _NumCell extends StatelessWidget {
  final TextEditingController ctrl;
  final bool allowDecimal;
  final VoidCallback onChanged;
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
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13.sp),
        onChanged: (_) => onChanged(),
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
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

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final double total;
  final bool submitting;
  final double hPad;
  final VoidCallback onSubmit;

  const _Footer({
    required this.total,
    required this.submitting,
    required this.hPad,
    required this.onSubmit,
  });

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
                Text('الإجمالي',
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.defaultTextSecondary)),
                Text(
                  '$cur ${total.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: ColorsManager.primaryColor),
                ),
              ],
            ),
            const Spacer(),
            _SubmitBtn(
                label: 'تأكيد الفاتورة', loading: submitting, onTap: onSubmit),
          ],
        ),
      ),
    );
  }
}

class _FlatBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _FlatBtn(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
          color: ColorsManager.primaryColor,
          borderRadius: BorderRadius.circular(6.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.r, color: Colors.white),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      ),
    ),
  );
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
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      decoration: BoxDecoration(
          color: loading
              ? ColorsManager.primaryColor.withOpacity(0.6)
              : ColorsManager.primaryColor,
          borderRadius: BorderRadius.circular(8.r)),
      child: Center(
        child: loading
            ? SizedBox(
            width: 20.r,
            height: 20.r,
            child: const CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : Text(label,
            style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

// ─── Line state ───────────────────────────────────────────────────────────────

class _LineState {
  final TextEditingController nameCtrl;
  final FocusNode focusNode; // 👈 ضفنا FocusNode عشان الـ Autocomplete
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;

  _LineState()
      : nameCtrl = TextEditingController(),
        focusNode = FocusNode(),
        qtyCtrl = TextEditingController(text: '1'),
        daysCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(text: '0');

  int get qty => int.tryParse(qtyCtrl.text) ?? 1;
  int get days => int.tryParse(daysCtrl.text) ?? 1;
  double get pricePerDay => double.tryParse(priceCtrl.text) ?? 0;
  double get lineTotal => qty * days * pricePerDay;

  void dispose() {
    nameCtrl.dispose();
    focusNode.dispose();
    qtyCtrl.dispose();
    daysCtrl.dispose();
    priceCtrl.dispose();
  }
}