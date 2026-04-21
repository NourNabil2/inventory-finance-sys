// lib/features/customers/presentation/widgets/invoice_items_table.dart
//
// Self-contained scrollable items table for the invoice details page.
//
// Layout strategy
// ───────────────
// • LayoutBuilder measures the available width.
// • If available > kTableMinWidth the table fills that width
//   (columns scale proportionally via the flexible item column).
// • If available < kTableMinWidth the table is exactly
//   kTableMinWidth wide and the outer SingleChildScrollView
//   lets the user scroll horizontally — overflow is impossible.
// ─────────────────────────────────────────────────────────────────
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:bungee_manage_sys/core/widgets/responsive_layout.dart';
import 'invoice_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceItemsTable extends StatelessWidget {
  final InvoiceEntity invoice;
  final Set<String> returningIds;
  final void Function(InvoiceItemEntity) onReturn;

  const InvoiceItemsTable({
    super.key,
    required this.invoice,
    required this.returningIds,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'invoices.items'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: theme.textTheme.titleSmall?.color,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LayoutBuilder(
              builder: (context, constraints) {
                /// Use all available space on wide screens; enforce a minimum
                /// on small screens so the scroll view takes over instead of
                /// columns compressing and overflowing.
                final tableWidth = constraints.maxWidth.clamp(
                  kTableMinWidth,
                  double.infinity,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: tableWidth > constraints.maxWidth
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TableHeader(tableWidth: tableWidth),
                        ...invoice.items.map(
                              (item) => _TableRow(
                            key: ValueKey(item.id),
                            item: item,
                            tableWidth: tableWidth,
                            canReturn: invoice.status != InvoiceStatus.canceled &&
                                item.remainingQty > 0,
                            isReturning: returningIds.contains(item.id),
                            onReturn: () => onReturn(item),
                            dividerColor: theme.dividerColor,
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Column-width registry
// ─────────────────────────────────────────────────────────────────────────────

/// Single source of truth for every column width.
///
/// All values are plain logical pixels — NOT scaled with `.w` — because
/// they are compared against [tableWidth] which also comes from
/// [LayoutBuilder] in logical pixels. Mixing `.w`-scaled values with
/// raw logical-pixel widths is the primary cause of overflow bugs.
abstract final class _Col {
  static const double hPad     = 16; // left + right padding inside each row
  static const double qty      = 52;
  static const double returned = 60;
  static const double days     = 52;
  static const double price    = 64;
  static const double total    = 64;
  static const double status   = 84;
  static const double action   = 92;

  /// Total width consumed by fixed columns + row horizontal padding.
  static const double _fixedSum =
      hPad * 2 + qty + returned + days + price + total + status + action;

  /// Width of the flexible item-name column given [tableWidth].
  /// Clamped to a minimum of 120 so it never disappears.
  static double item(double tableWidth) =>
      (tableWidth - _fixedSum).clamp(120.0, double.infinity);
}

// ─────────────────────────────────────────────────────────────────────────────
// Header row
// ─────────────────────────────────────────────────────────────────────────────

class TableHeader extends StatelessWidget {
  final double tableWidth;
  const TableHeader({required this.tableWidth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      color: ColorsManager.defaultTextSecondary,
      letterSpacing: 0.2,
    );

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: _Col.hPad, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: _Col.item(tableWidth),
            child: Text('invoices.col_item'.tr(), style: style),
          ),
          _Hdr('invoices.col_qty'.tr(),      style, w: _Col.qty,      align: TextAlign.center),
          _Hdr('invoices.col_returned'.tr(), style, w: _Col.returned,  align: TextAlign.center),
          _Hdr('invoices.col_days'.tr(),     style, w: _Col.days,     align: TextAlign.center),
          _Hdr('invoices.col_price'.tr(),    style, w: _Col.price,    align: TextAlign.center),
          _Hdr('invoices.col_total'.tr(),    style, w: _Col.total,    align: TextAlign.end),
          _Hdr('invoices.col_status'.tr(),   style, w: _Col.status,   align: TextAlign.center),
          SizedBox(width: _Col.action),
        ],
      ),
    );
  }
}

class _Hdr extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double w;
  final TextAlign align;

  const _Hdr(this.text, this.style, {required this.w, required this.align});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: w, child: Text(text, style: style, textAlign: align));
}

// ─────────────────────────────────────────────────────────────────────────────
// Data row
// ─────────────────────────────────────────────────────────────────────────────

class _TableRow extends StatelessWidget {
  final InvoiceItemEntity item;
  final double tableWidth;
  final bool canReturn;
  final bool isReturning;
  final VoidCallback onReturn;
  final Color dividerColor;

  const _TableRow({
    super.key,
    required this.item,
    required this.tableWidth,
    required this.canReturn,
    required this.isReturning,
    required this.onReturn,
    required this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullyReturned = item.isFullyReturned;
    final partial = item.isPartiallyReturned;

    final rowColor = fullyReturned
        ? ColorsManager.successSurface
        : partial
        ? ColorsManager.warningSurface
        : theme.cardColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(height: 1, color: dividerColor),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          color: rowColor,
          padding: const EdgeInsets.symmetric(horizontal: _Col.hPad, vertical: 12),
          child: Row(
            children: [
              // ── Name + sub-rented badge ──
              SizedBox(
                width: _Col.item(tableWidth),
                child: _ItemNameCell(item: item, dimmed: fullyReturned),
              ),
              // ── Fixed data cells ──
              _Cell('${item.qty}',                              w: _Col.qty),
              _Cell(
                item.returnedQty > 0 ? '${item.returnedQty}' : '—',
                w: _Col.returned,
                color: item.returnedQty > 0 ? ColorsManager.successText : null,
              ),
              _Cell('${item.days}',                            w: _Col.days),
              _Cell(item.pricePerDay.toStringAsFixed(0),       w: _Col.price),
              // ── Line total (end-aligned) ──
              SizedBox(
                width: _Col.total,
                child: Text(
                  item.lineTotalAfterDiscount.toStringAsFixed(0),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: fullyReturned
                        ? ColorsManager.defaultTextSecondary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              // ── Status chip ──
              SizedBox(
                width: _Col.status,
                child: Center(child: _StatusChip(item: item)),
              ),
              // ── Return / loading button ──
              SizedBox(
                width: _Col.action,
                child: canReturn
                    ? _ReturnButton(
                  isLoading: isReturning,
                  remainingQty: item.remainingQty,
                  onTap: onReturn,
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ItemNameCell extends StatelessWidget {
  final InvoiceItemEntity item;
  final bool dimmed;

  const _ItemNameCell({required this.item, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.itemName ?? item.itemId.substring(0, 8),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.sp,
            color: dimmed
                ? ColorsManager.defaultTextSecondary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
        if (item.isSubRented)
          Text(
            'invoices.sub_rented'.tr(),
            style: TextStyle(fontSize: 10.sp, color: ColorsManager.warningText),
          ),
      ],
    );
  }
}

/// Generic centred data cell.
class _Cell extends StatelessWidget {
  final String text;
  final double w;
  final Color? color;

  const _Cell(this.text, {required this.w, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: w,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13.sp,
        color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final InvoiceItemEntity item;
  const _StatusChip({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isFullyReturned) {
      return StatusChip(
        label: 'invoices.item_status_returned'.tr(),
        status: ChipStatus.completed,
      );
    }
    if (item.isPartiallyReturned) {
      return StatusChip(
        label: 'invoices.item_status_partial'.tr(
          namedArgs: {'rem': '${item.remainingQty}'},
        ),
        status: ChipStatus.pending,
      );
    }
    return StatusChip(
      label: 'invoices.item_status_out'.tr(),
      status: ChipStatus.active,
    );
  }
}

class _ReturnButton extends StatelessWidget {
  final bool isLoading;
  final int remainingQty;
  final VoidCallback onTap;

  const _ReturnButton({
    required this.isLoading,
    required this.remainingQty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isLoading
                ? theme.scaffoldBackgroundColor
                : ColorsManager.infoSurface,
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
              color: isLoading
                  ? theme.dividerColor
                  : ColorsManager.infoFill.withOpacity(0.4),
            ),
          ),
          child: isLoading
              ? SizedBox(
            width: 12.r,
            height: 12.r,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: ColorsManager.primaryColor,
            ),
          )
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.assignment_return_outlined,
                size: 11.r,
                color: ColorsManager.primaryColor,
              ),
              SizedBox(width: 3.w),
              Flexible(
                child: Text(
                  'invoices.return_item_qty'.tr(
                    namedArgs: {'qty': '$remainingQty'},
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.primaryColor,
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