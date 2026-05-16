// lib/features/customers/presentation/widgets/invoice_form_widgets.dart
//
// Item-table widgets shared between ModernCreateInvoicePage and
// ModernEditInvoicePage.
// ────────────────────────────────────────────────────────────────
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_dropdown.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bungee_manage_sys/core/widgets/responsive_layout.dart';
import 'invoice_widgets.dart';

// ─── Customer badge ───────────────────────────────────────────

class InvoiceCustomerBadge extends StatelessWidget {
  final CustomerEntity customer;
  const InvoiceCustomerBadge({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter =
    customer.name.trim().isEmpty ? '?' : customer.name.trim()[0].toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
            child: Text(
              letter,
              style: TextStyle(
                color: ColorsManager.primaryColor,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: theme.textTheme.titleSmall?.color,
                  ),
                ),
                if (customer.phone != null)
                  Text(
                    customer.phone!,
                    style: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
                  ),
              ],
            ),
          ),
          if (customer.totalDebt > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: ColorsManager.errorSurface,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'invoices.existing_debt'.tr(),
                    style: TextStyle(fontSize: 10.sp, color: ColorsManager.errorText),
                  ),
                  Text(
                    '${'dashboard.currency'.tr()} ${customer.totalDebt.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: ColorsManager.errorText,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Table header ─────────────────────────────────────────────

/// Table header for the create/edit form.
/// Wrapped in a horizontal scroll view so it always aligns
/// with [InvoiceLineRow] which uses the same [kTableMinWidth].
class InvoiceCreateTableHead extends StatelessWidget {
  const InvoiceCreateTableHead({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      color: ColorsManager.defaultTextSecondary,
      letterSpacing: 0.3,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: kTableMinWidth),
        child: Container(
          color: theme.scaffoldBackgroundColor,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text('invoices.col_item'.tr(), style: s)),
              InvoiceColHdr('invoices.col_qty'.tr(), s),
              InvoiceColHdr('invoices.col_days'.tr(), s),
              InvoiceColHdr('invoices.col_price'.tr(), s),
              InvoiceColHdr('invoices.col_disc_pct'.tr(), s), // 🆕 الخصم موجود بالفعل
              InvoiceColHdr('invoices.col_total'.tr(), s, end: true),
              SizedBox(width: 32.w),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Item picker ──────────────────────────────────────────────

class InvoiceItemPickerRow extends StatefulWidget {
  final void Function(ItemEntity) onAdd;
  const InvoiceItemPickerRow({super.key, required this.onAdd});

  @override
  State<InvoiceItemPickerRow> createState() => _InvoiceItemPickerRowState();
}

class _InvoiceItemPickerRowState extends State<InvoiceItemPickerRow> {
  ItemEntity? _pick;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading || state is InventoryInitial) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

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
                    .map(
                      (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      '${i.name}  (×${i.availableQty})',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
            SizedBox(width: 10.w),
            InvoiceAddItemBtn(
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
    );
  }
}

// ─── Line row ─────────────────────────────────────────────────

/// A single editable item row.
///
/// Uses [kTableMinWidth] as a hard minimum so that the row
/// never collapses below the width of [InvoiceCreateTableHead],
/// keeping both in perfect alignment inside the same outer scroll.
class InvoiceLineRow extends StatefulWidget {
  final InvoiceLineState line;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const InvoiceLineRow({
    super.key,
    required this.line,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<InvoiceLineRow> createState() => _InvoiceLineRowState();
}

class _InvoiceLineRowState extends State<InvoiceLineRow> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = widget.line;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: kTableMinWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Item name + available qty ──
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.item?.name ?? '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (l.item != null)
                      Text(
                        '×${l.item!.availableQty} ${'invoices.available'.tr()}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: ColorsManager.defaultTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // ── Qty ──
              InvoiceNumCell(
                ctrl: l.qtyCtrl,
                onChanged: () {
                  setState(() {});
                  widget.onChanged();
                },
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return '≥1';
                  if (l.item != null && n > l.item!.availableQty) {
                    return '≤${l.item!.availableQty}';
                  }
                  return null;
                },
              ),
              // ── Days ──
              InvoiceNumCell(
                ctrl: l.daysCtrl,
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
              // ── Price ──
              InvoiceNumCell(
                ctrl: l.priceCtrl,
                allowDecimal: true,
                onChanged: () {
                  setState(() {});
                  widget.onChanged();
                },
              ),
              // ── Discount % ──
              InvoiceNumCell(
                ctrl: l.discCtrl,
                allowDecimal: true,
                suffix: '%',
                onChanged: () {
                  setState(() {});
                  widget.onChanged();
                },
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n < 0 || n > 100) return '0–100';
                  return null;
                },
              ),
              // ── Line net ──
              SizedBox(
                width: 70.w,
                child: Text(
                  l.lineNet.toStringAsFixed(0),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
              // ── Remove ──
              SizedBox(
                width: 32.w,
                child: widget.canRemove
                    ? GestureDetector(
                  onTap: widget.onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.r,
                    color: ColorsManager.errorFill,
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Two free-text fields shown above the items table:
/// "Job Name" and "Production".
/// Pass the two controllers from the page's state.
class InvoiceJobFields extends StatelessWidget {
  final TextEditingController jobNameCtrl;
  final TextEditingController productionCtrl;

  const InvoiceJobFields({
    super.key,
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
    final fieldDeco = InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
        borderSide: BorderSide(color: ColorsManager.primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: theme.cardColor,
    );

    return Row(
      children: [
        // ── Job Name ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('invoices.job_name'.tr(), style: labelStyle),
              SizedBox(height: 4.h),
              TextField(
                controller: jobNameCtrl,
                style: TextStyle(fontSize: 13.sp),
                decoration: fieldDeco.copyWith(
                  hintText: 'invoices.job_name_hint'.tr(),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // ── Production ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('invoices.production'.tr(), style: labelStyle),
              SizedBox(height: 4.h),
              TextField(
                controller: productionCtrl,
                style: TextStyle(fontSize: 13.sp),
                decoration: fieldDeco.copyWith(
                  hintText: 'invoices.production_hint'.tr(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Footer field ─────────────────────────────────────────────

class InvoiceFooterField extends StatelessWidget {
  final String label;
  final Widget child;
  final double width;

  const InvoiceFooterField({
    super.key,
    required this.label,
    required this.child,
    this.width = 110,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width.w,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: ColorsManager.defaultTextSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        child,
      ],
    ),
  );
}

// ─── Line state model ─────────────────────────────────────────

/// Mutable state for a single invoice line; owns its controllers.
/// Callers must call [dispose] when removing a line.
class InvoiceLineState {
  final ItemEntity? item;
  final TextEditingController qtyCtrl;
  final TextEditingController daysCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController discCtrl;

  InvoiceLineState({this.item})
      : qtyCtrl = TextEditingController(text: '1'),
        daysCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(
          text: item != null ? item.defaultPrice.toStringAsFixed(0) : '0',
        ),
        discCtrl = TextEditingController(text: '0');

  int get qty => int.tryParse(qtyCtrl.text) ?? 1;
  int get days => int.tryParse(daysCtrl.text) ?? 1;
  double get pricePerDay => double.tryParse(priceCtrl.text) ?? 0;
  double get discPct => (double.tryParse(discCtrl.text) ?? 0).clamp(0, 100);
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