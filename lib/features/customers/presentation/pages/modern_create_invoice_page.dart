// lib/features/customers/presentation/pages/modern_create_invoice_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import 'package:bungee_manage_sys/core/widgets/app_dropdown.dart';

class ModernCreateInvoicePage extends StatefulWidget {
  final CustomerEntity customer;
  const ModernCreateInvoicePage({super.key, required this.customer});

  @override
  State<ModernCreateInvoicePage> createState() =>
      _ModernCreateInvoicePageState();
}

class _ModernCreateInvoicePageState extends State<ModernCreateInvoicePage> {
  final _formKey        = GlobalKey<FormState>();
  final List<_LineState> _lines = [];
  final _invDiscCtrl    = TextEditingController(text: '0');
  final _amtPaidCtrl    = TextEditingController(text: '0');

  final _jobNameCtrl    = TextEditingController();
  final _productionCtrl = TextEditingController();

  DateTime _invoiceDate = DateTime.now();

  String _payMethod = 'safe';
  bool   _submitting = false;

  @override
  void dispose() {
    for (final l in _lines) l.dispose();
    _invDiscCtrl.dispose();
    _amtPaidCtrl.dispose();
    _jobNameCtrl.dispose();
    _productionCtrl.dispose();
    super.dispose();
  }

  double get _subtotal    => _lines.fold(0.0, (s, l) => s + l.lineNet);
  double get _invDiscPct  => (double.tryParse(_invDiscCtrl.text) ?? 0).clamp(0, 100);
  double get _invDiscFlat => _subtotal * (_invDiscPct / 100);
  double get _netTotal    => (_subtotal - _invDiscFlat).clamp(0, double.infinity);
  double get _amtPaid     => (double.tryParse(_amtPaidCtrl.text) ?? 0).clamp(0, _netTotal);
  double get _remaining   => _netTotal - _amtPaid;


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: ColorsManager.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }


  Future<void> _submit({bool isDraft = false}) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lines.isEmpty) {
      context.showError('invoices.error_no_items'.tr());
      return;
    }
    for (int i = 0; i < _lines.length; i++) {
      if (_lines[i].item == null) {
        context.showError(
            'invoices.error_row_no_item'.tr(namedArgs: {'row': '${i + 1}'}));
        return;
      }
    }

    setState(() => _submitting = true);

    final resolvedItems = _lines.map((l) => InvoiceItemEntity(
      id:           '',
      invoiceId:    '',
      itemId:       l.item!.id,
      itemName:     l.item!.name,
      qty:          l.qty,
      days:         l.days,
      pricePerDay:  l.pricePerDay,
      itemDiscount: l.flatDiscount,
      isSubRented:  l.isSubRented,
      status:       InvoiceItemStatus.out,
    )).toList();

    final jobName    = _jobNameCtrl.text.trim().isEmpty    ? null : _jobNameCtrl.text.trim();
    final production = _productionCtrl.text.trim().isEmpty ? null : _productionCtrl.text.trim();

    final invoice = InvoiceEntity(
      id:           const Uuid().v4(),
      customerId:   widget.customer.id,
      totalAmount:  _subtotal,
      discount:     _invDiscFlat,
      status:       isDraft ? InvoiceStatus.draft : InvoiceStatus.active,
      createdAt:    _invoiceDate,
      invoiceNumber: '',
      jobName:      jobName,
      production:   production,
    );

    if (!mounted) return;
    context.read<InvoicesCubit>().createInvoiceWithPayment(
      invoice:     invoice,
      items:       resolvedItems,
      amountPaid:  isDraft ? 0.0 : _amtPaid,
      method:      _payMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<InvoicesCubit, InvoicesState>(
      listener: (context, state) {
        if (state is InvoiceCreated) {
          context.showSuccess('invoices.created_success'.tr());
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
                    horizontal: _hPad(context), vertical: 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CustomerBadge(customer: widget.customer),
                      SizedBox(height: 16.h),

                      _JobProductionRow(
                        jobNameCtrl:    _jobNameCtrl,
                        productionCtrl: _productionCtrl,
                      ),
                      SizedBox(height: 20.h),

                      _ItemPickerSection(
                        lines:     _lines,
                        onAdd:     (item) => setState(() => _lines.add(_LineState(item: item))),
                        onRemove:  (i) => setState(() {
                          _lines[i].dispose();
                          _lines.removeAt(i);
                        }),
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _Footer(
              subtotal:        _subtotal,
              invDiscPct:      _invDiscPct,
              invDiscFlat:     _invDiscFlat,
              netTotal:        _netTotal,
              amtPaid:         _amtPaid,
              remaining:       _remaining,
              invDiscCtrl:     _invDiscCtrl,
              amtPaidCtrl:     _amtPaidCtrl,
              payMethod:       _payMethod,
              submitting:      _submitting,
              hPad:            _hPad(context),
              onMethodChanged: (v) => setState(() => _payMethod = v),
              onChanged:       () => setState(() {}),
              onSubmit:        (isDraft) => _submit(isDraft: isDraft), // 👈
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) => AppBar(
    backgroundColor:    theme.cardColor,
    surfaceTintColor:   Colors.transparent,
    elevation:          0,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: theme.dividerColor),
    ),
    leading: IconButton(
        icon: Icon(Icons.arrow_back, size: 20.r),
        onPressed: () => Navigator.of(context).pop()),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('invoices.create_invoice'.tr(),
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color)),
        Text(widget.customer.name,
            style: TextStyle(
                fontSize: 12.sp,
                color: ColorsManager.defaultTextSecondary)),
      ],
    ),
  );

  double _hPad(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w > 1200) return (w - 920) / 2;
    if (w > 700)  return 40.w;
    return 16.w;
  }
}

// ─── ويدجت اختيار التاريخ ─────────────────────────────────────────────────────

class _InvoiceDateRow extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _InvoiceDateRow({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEEE, d MMMM yyyy', 'ar'); // صيغة التاريخ

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: ColorsManager.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Icon(Icons.calendar_month_rounded, size: 20.r, color: ColorsManager.primaryColor),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تاريخ الفاتورة', style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary, fontWeight: FontWeight.w600)),
                SizedBox(height: 2.h),
                Text(fmt.format(date), style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700, color: theme.textTheme.bodyMedium?.color)),
              ],
            ),
            const Spacer(),
            Text('تعديل', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: ColorsManager.primaryColor)),
          ],
        ),
      ),
    );
  }
}

// ─── Job Name + Production row ────────────────────────────────────────────────

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
      fontSize:    11.sp,
      fontWeight:  FontWeight.w600,
      color:       ColorsManager.defaultTextSecondary,
      letterSpacing: 0.2,
    );

    InputDecoration fieldDeco(String hint) => InputDecoration(
      isDense:  true,
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      filled:    true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: theme.dividerColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: theme.dividerColor)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: ColorsManager.primaryColor, width: 1.5)),
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
                style:      TextStyle(fontSize: 13.sp),
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
                style:      TextStyle(fontSize: 13.sp),
                decoration: fieldDeco('invoices.production_hint'.tr()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Customer badge ───────────────────────────────────────────────────────────

class _CustomerBadge extends StatelessWidget {
  final CustomerEntity customer;
  const _CustomerBadge({required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final letter = customer.name.trim().isEmpty
        ? '?'
        : customer.name.trim()[0].toUpperCase();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color:        theme.cardColor,
        borderRadius: BorderRadius.circular(8.r),
        border:       Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius:          18.r,
            backgroundColor: ColorsManager.primaryColor.withOpacity(0.12),
            child: Text(letter,
                style: TextStyle(
                    color:      ColorsManager.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize:   13.sp)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:   14.sp,
                        color:      theme.textTheme.titleSmall?.color)),
                if (customer.phone != null)
                  Text(customer.phone!,
                      style: TextStyle(
                          fontSize: 12.sp,
                          color:    ColorsManager.defaultTextSecondary)),
              ],
            ),
          ),
          if (customer.totalDebt > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                  color:        ColorsManager.errorSurface,
                  borderRadius: BorderRadius.circular(6.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('invoices.existing_debt'.tr(),
                      style: TextStyle(
                          fontSize: 10.sp, color: ColorsManager.errorText)),
                  Text(
                      '${'dashboard.currency'.tr()} ${customer.totalDebt.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize:   12.sp,
                          fontWeight: FontWeight.w700,
                          color:      ColorsManager.errorText)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Items section ────────────────────────────────────────────────────────────

class _ItemPickerSection extends StatefulWidget {
  final List<_LineState>       lines;
  final void Function(ItemEntity) onAdd;
  final void Function(int)     onRemove;
  final VoidCallback           onChanged;

  const _ItemPickerSection({
    required this.lines,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ItemPickerSection> createState() => _ItemPickerSectionState();
}

class _ItemPickerSectionState extends State<_ItemPickerSection> {
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
        _SectionTitle(label: 'invoices.section_items'.tr()),
        SizedBox(height: 10.h),
        BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) {
            if (state is InventoryLoading || state is InventoryInitial) {
              return const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2));
            }

            final allItems = state is InventoryLoaded
                ? state.filtered.where((i) => i.availableQty > 0).toList()
                : <ItemEntity>[];

            final categories = allItems
                .map((i) => i.category?.name ?? 'بدون فئة')
                .toSet()
                .toList();

            final filteredItems = _selectedCategory == null
                ? allItems
                : allItems.where((i) => (i.category?.name ?? 'بدون فئة') == _selectedCategory).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RawAutocomplete<ItemEntity>(
                        key: ValueKey(_selectedCategory),
                        textEditingController: _searchCtrl,
                        focusNode:             _focusNode,
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
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode:  focusNode,
                            onTap: () {
                              controller.notifyListeners();
                            },
                            style: TextStyle(fontSize: 13.sp),
                            decoration: InputDecoration(
                              isDense:   true,
                              hintText:  'ابحث عن صنف لاختياره...',
                              hintStyle: TextStyle(
                                  fontSize: 12.sp,
                                  color:    ColorsManager.defaultTextSecondary),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              filled:    true,
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
                                  size:  18.r,
                                  color: ColorsManager.defaultTextSecondary),
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
                            onChanged: (_) {
                              if (_pick != null) setState(() => _pick = null);
                            },
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: AlignmentDirectional.topStart,
                            child: Material(
                              elevation:    8,
                              color:        theme.cardColor,
                              borderRadius: BorderRadius.circular(8.r),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxHeight: 250.h, maxWidth: 300.w),
                                child: ListView.separated(
                                  padding:      EdgeInsets.zero,
                                  shrinkWrap:   true,
                                  itemCount:    options.length,
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
                                                      fontSize:   13.sp,
                                                      fontWeight: FontWeight.w500,
                                                      color:      theme.textTheme
                                                          .bodyMedium?.color),
                                                  overflow: TextOverflow.ellipsis),
                                            ),
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6.w, vertical: 2.h),
                                              decoration: BoxDecoration(
                                                color: ColorsManager.primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                BorderRadius.circular(4.r),
                                              ),
                                              child: Text(
                                                'متوفر: ${item.availableQty}',
                                                style: TextStyle(
                                                    fontSize:   11.sp,
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
                      label:   'invoices.add_item_row'.tr(),
                      icon:    Icons.add,
                      enabled: _pick != null,
                      onTap:   _pick == null
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
        SizedBox(height: 14.h),
        Container(
          decoration: BoxDecoration(
              color:        theme.cardColor,
              borderRadius: BorderRadius.circular(8.r),
              border:       Border.all(color: theme.dividerColor)),
          child: widget.lines.isEmpty
              ? _EmptyPlaceholder()
              : Column(children: [
            _TableHead(),
            ...widget.lines.asMap().entries.map((e) => Column(children: [
              Container(height: 1, color: theme.dividerColor),
              _LineRow(
                key:       ValueKey(e.key),
                line:      e.value,
                canRemove: true,
                onRemove:  () => widget.onRemove(e.key),
                onChanged: widget.onChanged,
              ),
            ])),
          ]),
        ),
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 40.h),
    child: Center(
        child: Column(children: [
          Icon(Icons.inventory_2_outlined,
              size: 32.r, color: ColorsManager.inputBorder),
          SizedBox(height: 8.h),
          Text('invoices.no_items_yet'.tr(),
              style: TextStyle(
                  fontSize: 13.sp,
                  color:    ColorsManager.defaultTextSecondary)),
        ])),
  );
}

// ─── Table header ─────────────────────────────────────────────────────────────

class _TableHead extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
        fontSize:     11.sp,
        fontWeight:   FontWeight.w600,
        color:        ColorsManager.defaultTextSecondary,
        letterSpacing: 0.3);

    return Container(
      color:   theme.scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('invoices.col_item'.tr(), style: style)),
          _Hdr('invoices.col_qty'.tr(),      style),
          _Hdr('invoices.col_days'.tr(),     style),
          _Hdr('invoices.col_price'.tr(),    style),
          _Hdr('invoices.col_disc_pct'.tr(), style),
          _Hdr('invoices.col_total'.tr(),    style, end: true),
          SizedBox(width: 32.w),
        ],
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String    t;
  final TextStyle s;
  final bool      end;
  const _Hdr(this.t, this.s, {this.end = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70.w,
    child: Text(t,
        style:     s,
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

// ─── Line row ─────────────────────────────────────────────────────────────────

class _LineRow extends StatefulWidget {
  final _LineState   line;
  final bool         canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineRow({
    super.key,
    required this.line,
    required this.canRemove,
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
    final l     = widget.line; // أو r لو إنت في صفحة التعديل
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        // 🚨 دي مهمة جداً عشان الخلايا تفضل متساوية من فوق 🚨
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.item?.name ?? '—',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:   13.sp,
                        color:      theme.textTheme.bodyMedium?.color),
                    overflow: TextOverflow.ellipsis),
                if (l.item != null)
                  Row(
                    children: [
                      Text('×${l.item!.availableQty} ${'invoices.available'.tr()}',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color:    ColorsManager.defaultTextSecondary)),
                      SizedBox(width: 8.w),
                      // زرار التكملة من الخارج... (نفس الكود بتاعك)
                    ],
                  ),
              ],
            ),
          ),

          // 1. ─── خلية الكمية (Qty) ───
          _NumCell(
              ctrl:      l.qtyCtrl,
              onChanged: () { setState(() {}); widget.onChanged(); },
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return '≥1';
                return null;
              }),

          // 2. ─── خلية الأيام (Days) ───
          _NumCell(
              ctrl:      l.daysCtrl,
              onChanged: () { setState(() {}); widget.onChanged(); },
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return '≥1';
                return null;
              }),

          // 3. ─── 🚨 خلية السعر (Price) + قائمة الأسعار تحتها 🚨 ───
          SizedBox(
            width: 70.w, // نفس عرض باقي الخلايا
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NumCell(
                    ctrl:         l.priceCtrl,
                    allowDecimal: true,
                    onChanged:    () { setState(() {}); widget.onChanged(); }),
                if (l.item != null) ...[
                  SizedBox(height: 4.h),
                  PopupMenuButton<double>(
                    tooltip: 'اختر السعر',
                    padding: EdgeInsets.zero,
                    onSelected: (price) {
                      l.priceCtrl.text = price.toStringAsFixed(0);
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
                        value: l.item!.defaultPrice,
                        child: Text('افتراضي: ${l.item!.defaultPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600)),
                      ),
                      PopupMenuItem(
                        value: l.item!.priceFilm,
                        child: Text('فيلم: ${l.item!.priceFilm.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                      ),
                      PopupMenuItem(
                        value: l.item!.priceSeries,
                        child: Text('مسلسل: ${l.item!.priceSeries.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                      ),
                      PopupMenuItem(
                        value: l.item!.priceAd,
                        child: Text('إعلان: ${l.item!.priceAd.toStringAsFixed(0)}', style: TextStyle(fontSize: 11.sp)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),

          // 4. ─── 🚨 خلية الخصم (Discount) رجعت لمكانها الصحيح 🚨 ───
          _NumCell(
              ctrl:         l.discCtrl,
              allowDecimal: true,
              suffix:       '%',
              onChanged:    () { setState(() {}); widget.onChanged(); }),

          // 5. ─── الإجمالي (Net Total) ───
          SizedBox(
            width: 70.w,
            child: Text(
              l.lineNet.toStringAsFixed(0),
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   13.sp,
                  color:      theme.textTheme.bodyMedium?.color),
              textAlign: TextAlign.end,
            ),
          ),

          // 6. ─── زرار الحذف (Remove) ───
          SizedBox(
            width: 32.w,
            child: widget.canRemove
                ? GestureDetector(
              onTap:  widget.onRemove,
              child:  Icon(Icons.close,
                  size:  16.r,
                  color: ColorsManager.errorText),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _NumCell extends StatelessWidget {
  final TextEditingController     ctrl;
  final bool                      allowDecimal;
  final String?                   suffix;
  final VoidCallback?             onChanged;
  final FormFieldValidator<String>? validator;

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
      width: 70.w,
      child: TextFormField(
        controller:   ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign:    TextAlign.center,
        style: TextStyle(
            fontSize: 13.sp, color: theme.textTheme.bodyMedium?.color),
        onChanged: (_) => onChanged?.call(),
        validator:    validator,
        decoration: InputDecoration(
          isDense:        true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          suffixText:     suffix,
          suffixStyle:    TextStyle(
              fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
          filled:    true,
          fillColor: theme.cardColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide:   BorderSide(color: theme.dividerColor)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide:   BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide:   BorderSide(color: ColorsManager.primaryColor)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6.r),
              borderSide:   BorderSide(color: ColorsManager.errorFill)),
          errorStyle: TextStyle(fontSize: 9.sp, height: 0.8),
        ),
      ),
    );
  }
}

// ─── Sticky footer ────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  final double subtotal, invDiscPct, invDiscFlat, netTotal, amtPaid, remaining;
  final TextEditingController invDiscCtrl, amtPaidCtrl;
  final String   payMethod;
  final bool     submitting;
  final double   hPad;
  final void Function(String) onMethodChanged;
  final VoidCallback onChanged;
  final void Function(bool) onSubmit; // 🚨 تستقبل boolean عشان تحدد مسودة ولا تأكيد

  const _Footer({
    required this.subtotal,
    required this.invDiscPct,
    required this.invDiscFlat,
    required this.netTotal,
    required this.amtPaid,
    required this.remaining,
    required this.invDiscCtrl,
    required this.amtPaidCtrl,
    required this.payMethod,
    required this.submitting,
    required this.hPad,
    required this.onMethodChanged,
    required this.onChanged,
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
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16.h),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FooterField(
                    label: 'invoices.invoice_disc_pct'.tr(),
                    child: _NumCell(
                        ctrl:         invDiscCtrl,
                        allowDecimal: true,
                        suffix:       '%',
                        onChanged:    onChanged,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 0 || n > 100) return '0–100';
                          return null;
                        })),
                SizedBox(width: 16.w),
                _FooterField(
                    label: 'invoices.amount_paid'.tr(),
                    child: _NumCell(
                        ctrl:         amtPaidCtrl,
                        allowDecimal: true,
                        onChanged:    onChanged)),
                SizedBox(width: 12.w),
                SizedBox(
                  width: 130.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('invoices.method'.tr(),
                          style: TextStyle(
                              fontSize:   11.sp,
                              fontWeight: FontWeight.w500,
                              color:      ColorsManager.defaultTextSecondary)),
                      SizedBox(height: 4.h),
                      AppDropdown<String>(
                        title:     '',
                        value:     payMethod,
                        onChanged: (v) => onMethodChanged(v!),
                        items: [
                          DropdownMenuItem(
                              value: 'safe',
                              child: Text('invoices.method_safe'.tr())),
                          DropdownMenuItem(
                              value: 'bank',
                              child: Text('invoices.method_bank'.tr())),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _TLine('invoices.subtotal'.tr(),
                        '$cur ${subtotal.toStringAsFixed(0)}'),
                    if (invDiscFlat > 0)
                      _TLine(
                        '${'invoices.discount'.tr()} (${invDiscPct.toStringAsFixed(1)}%)',
                        '−$cur ${invDiscFlat.toStringAsFixed(0)}',
                        col: ColorsManager.errorText,
                      ),
                    Container(
                        height: 1,
                        width:  260.w,
                        color:  theme.dividerColor,
                        margin: EdgeInsets.symmetric(vertical: 4.h)),
                    _TLine('invoices.net_total'.tr(),
                        '$cur ${netTotal.toStringAsFixed(0)}',
                        bold: true),
                    if (amtPaid > 0) ...[
                      _TLine('invoices.amount_paid'.tr(),
                          '−$cur ${amtPaid.toStringAsFixed(0)}',
                          col: ColorsManager.successText),
                      _TLine(
                        'invoices.remaining_debt'.tr(),
                        '$cur ${remaining.toStringAsFixed(0)}',
                        bold: true,
                        col:  remaining > 0
                            ? ColorsManager.errorText
                            : ColorsManager.successText,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 14.h),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _SubmitBtn(
                    label:   'invoices.draft_invoice'.tr(),
                    loading: submitting,
                    isOutlined: true,
                    onTap:   () => onSubmit(true),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: _SubmitBtn(
                    label:   'invoices.confirm_invoice'.tr(),
                    loading: submitting,
                    isOutlined: false,
                    onTap:   () => onSubmit(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FooterField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 110.w,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize:   11.sp,
                fontWeight: FontWeight.w500,
                color:      ColorsManager.defaultTextSecondary)),
        SizedBox(height: 4.h),
        child,
      ],
    ),
  );
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize:   bold ? 13.sp : 12.sp,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color:      theme.textTheme.bodyMedium?.color)),
          SizedBox(width: 20.w),
          Text(value,
              style: TextStyle(
                  fontSize:   bold ? 15.sp : 13.sp,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color:      col ?? theme.textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }
}

// 🚨 تحديث زرار الـ Submit عشان يدعم ستايل الـ Outlined للمسودة 🚨
class _SubmitBtn extends StatelessWidget {
  final String   label;
  final bool     loading;
  final bool     isOutlined;
  final VoidCallback onTap;

  const _SubmitBtn({
    required this.label,
    required this.loading,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height: 44.h,
      decoration: BoxDecoration(
          color: isOutlined
              ? Colors.transparent
              : (loading ? ColorsManager.primaryColor.withOpacity(0.6) : ColorsManager.primaryColor),
          border: isOutlined ? Border.all(color: ColorsManager.primaryColor, width: 1.5) : null,
          borderRadius: BorderRadius.circular(8.r)),
      child: Center(
          child: loading && !isOutlined
              ? SizedBox(
              width:  20.r,
              height: 20.r,
              child: const CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
              : Text(label,
              style: TextStyle(
                  color:      isOutlined ? ColorsManager.primaryColor : Colors.white,
                  fontSize:   14.sp,
                  fontWeight: FontWeight.w600))),
    ),
  );
}

class _FlatBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;
  const _FlatBtn({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
          color:        enabled
              ? ColorsManager.primaryColor
              : ColorsManager.backgroundSurface,
          borderRadius: BorderRadius.circular(6.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size:  14.r,
              color: enabled ? Colors.white : ColorsManager.defaultTextSecondary),
          SizedBox(width: 4.w),
          Text(label,
              style: TextStyle(
                  fontSize:   12.sp,
                  fontWeight: FontWeight.w600,
                  color:      enabled
                      ? Colors.white
                      : ColorsManager.defaultTextSecondary)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize:   14.sp,
          color:      Theme.of(context).textTheme.titleSmall?.color));
}

// ─── Line state ───────────────────────────────────────────────────────────────

class _LineState {
  final ItemEntity? item;
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;
  bool isSubRented = false;

  _LineState({this.item})
      : qtyCtrl   = TextEditingController(text: '1'),
        daysCtrl   = TextEditingController(text: '1'),
        priceCtrl  = TextEditingController(
            text: item != null ? item.defaultPrice.toStringAsFixed(0) : '0'),
        discCtrl   = TextEditingController(text: '0');

  int    get qty        => int.tryParse(qtyCtrl.text)    ?? 1;
  int    get days       => int.tryParse(daysCtrl.text)   ?? 1;
  double get pricePerDay => double.tryParse(priceCtrl.text) ?? 0;
  double get discPct    => (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
  double get gross      => qty * days * pricePerDay;
  double get flatDiscount => gross * (discPct / 100);
  double get lineNet    => (gross - flatDiscount).clamp(0, double.infinity);

  void dispose() {
    qtyCtrl.dispose();
    daysCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }
}