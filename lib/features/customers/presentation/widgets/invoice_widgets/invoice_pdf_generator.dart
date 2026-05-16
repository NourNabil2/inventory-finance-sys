// lib/features/customers/presentation/utils/invoice_pdf_generator.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/assets.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:easy_localization/easy_localization.dart' as et;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ─── Brand colours ────────────────────────────────────────────────────────────
const _kPrimary   = PdfColor(0.10, 0.20, 0.50);
const _kPrimaryBg = PdfColor(0.95, 0.96, 0.99);
const _kSuccess   = PdfColor(0.06, 0.62, 0.35);
const _kSuccessBg = PdfColor(0.94, 1.00, 0.96);
const _kDanger    = PdfColor(0.80, 0.10, 0.10);
const _kGrey100   = PdfColor(0.97, 0.97, 0.97);
const _kGrey200   = PdfColor(0.90, 0.90, 0.90);
const _kGrey600   = PdfColor(0.45, 0.45, 0.45);
const _kText      = PdfColor(0.07, 0.07, 0.07);

// ─── Arabic detection ─────────────────────────────────────────────────────────

/// Returns true when [text] contains any Arabic/RTL Unicode character.
bool _isArabic(String text) => RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
).hasMatch(text);

/// Renders text correctly for both Latin and Arabic strings.
///
/// When Arabic is detected the widget is wrapped in [pw.Directionality] (RTL)
/// so the PDF renderer lays glyphs out right-to-left — eliminating the ▯ boxes.
///
/// Both [ltrStyle] and [arStyle] should already use Cairo TTF so the correct
/// glyph table is selected automatically.
pw.Widget _smartText(
    String text,
    pw.TextStyle ltrStyle,
    pw.TextStyle arStyle, {
      pw.TextAlign? align,
    }) {
  if (_isArabic(text)) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Text(
        text,
        style: arStyle,
        textAlign: align ?? pw.TextAlign.right,
      ),
    );
  }
  return pw.Text(
    text,
    style: ltrStyle,
    textAlign: align ?? pw.TextAlign.left,
  );
}

// ─── Generator ───────────────────────────────────────────────────────────────

class InvoicePdfGenerator {
  InvoicePdfGenerator._();

  // ── Public entry-point ────────────────────────────────────────────────────

  static Future<void> shareInvoice({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required InvoicePaymentSummary paymentSummary,
    required String currencyLabel,
    required String appName,
  }) async {
    final pdf = await _buildPdf(
      invoice: invoice,
      customer: customer,
      paymentSummary: paymentSummary,
      currencyLabel: currencyLabel,
      appName: appName,
    );

    final ref = invoice.invoiceNumber.isNotEmpty
        ? invoice.invoiceNumber
        : invoice.id.substring(0, 8).toUpperCase();

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_$ref.pdf',
    );
  }

  // ── Builder ───────────────────────────────────────────────────────────────

  static Future<pw.Document> _buildPdf({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required InvoicePaymentSummary paymentSummary,
    required String currencyLabel,
    required String appName,
  }) async {
    final doc = pw.Document();

    // ── Fonts ──────────────────────────────────────────────────────────────
    // Cairo TTF contains both Latin AND Arabic glyph tables.
    // Using it for every style guarantees Arabic characters render correctly.
    pw.Font? regular;
    pw.Font? bold;
    try {
      regular = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
      bold = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
    } catch (_) {
      debugPrint('Cairo font not found — Arabic text may show boxes.');
    }

    // ── Logo ───────────────────────────────────────────────────────────────
    pw.ImageProvider? logo;
    try {
      final bytes = await rootBundle.load(Assets.logoApp);
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      debugPrint('Logo not found at assets/images/logo.png — using text fallback.');
    }

    // ── Style factory ──────────────────────────────────────────────────────
    pw.TextStyle mk(double size, {bool b = false, PdfColor? c}) =>
        pw.TextStyle(
          font: b ? bold : regular,
          fontBold: bold,
          fontSize: size,
          color: c ?? _kText,
          fontWeight: b ? pw.FontWeight.bold : pw.FontWeight.normal,
        );

    // LTR styles
    final sBase  = mk(8.5);
    final sSm    = mk(7.5,  c: _kGrey600);
    final sBold  = mk(8.5,  b: true);
    final sTitle = mk(17,   b: true, c: _kPrimary);
    final sTotal = mk(11,   b: true, c: _kPrimary);

    // Arabic variants — slightly larger for readability at same font size
    final sBaseAr = mk(9.5);
    final sSmAr   = mk(8.5,  c: _kGrey600);
    final sBoldAr = mk(10,  b: true);

    final ref     = invoice.invoiceNumber.isNotEmpty
        ? invoice.invoiceNumber
        : invoice.id.substring(0, 8).toUpperCase();
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.createdAt);
    final cur     = currencyLabel;

    // ── Page ──────────────────────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.ltr, // page LTR; Arabic cells flip locally
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        footer: (ctx) => _footer(sSm, appName, ctx),
        build: (ctx) => [
          _header(logo, sTitle, sSm, sBase, sBaseAr, sSmAr, sBoldAr,
              appName, ref, dateStr, customer, invoice),
          pw.SizedBox(height: 6),
          pw.Divider(color: _kGrey200, thickness: 0.6),
          pw.SizedBox(height: 6),
          _itemsTable(invoice, sBase, sBaseAr, sBold, cur),
          pw.SizedBox(height: 8),
          _totalsAndPayment(
              invoice, paymentSummary, sBase, sBold, sTotal, sSm, cur),
          pw.SizedBox(height: 6),
        ],
      ),
    );

    return doc;
  }

  // ── Section builders ──────────────────────────────────────────────────────

  static pw.Widget _header(
      pw.ImageProvider? logo,
      pw.TextStyle sTitle,
      pw.TextStyle sSm,
      pw.TextStyle sBase,
      pw.TextStyle sBaseAr,
      pw.TextStyle sSmAr,
      pw.TextStyle sBoldAr,
      String appName,
      String ref,
      String dateStr,
      CustomerEntity customer,
      InvoiceEntity invoice,
      ) {
    final hasJob = invoice.jobName != null && invoice.jobName!.isNotEmpty;
    final hasProd = invoice.production != null && invoice.production!.isNotEmpty;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left — logo only (no text)
        if (logo != null)
          pw.Image(logo, width: 52, height: 52, fit: pw.BoxFit.contain)
        else
          pw.Text(appName, style: sTitle),

        // Center — Job Name + Production (if present)
        if (hasJob || hasProd)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              if (hasJob)
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'Job Name: ',
                      style: sBase.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 9),
                    ),
                    _smartText(
                      invoice.jobName!,
                      sBase.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 9),
                      sBoldAr.copyWith(fontSize: 10),
                    ),
                  ],
                ),

              if (hasProd) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'Production: ',
                      style: sSm,
                    ),
                    _smartText(
                      invoice.production!,
                      sSm,
                      sSmAr,
                    ),
                  ],
                ),
              ],
            ],
          ),

        // Right — invoice badge + meta + customer (compact horizontal)
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Customer info (name + phone)
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _smartText(
                  customer.name,
                  sBase.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                  sBoldAr.copyWith(fontSize: 10),
                ),
                if (customer.phone != null)
                  pw.Text(customer.phone!, style: sSm),
              ],
            ),

            pw.SizedBox(width: 12),
            pw.Container(width: 0.6, height: 36, color: _kGrey200),
            pw.SizedBox(width: 12),

            // Invoice # and date
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _metaRow('Invoice #', ref, sBase),
                pw.SizedBox(height: 2),
                _metaRow('Date', dateStr, sBase),
              ],
            ),

            pw.SizedBox(width: 12),

            // INVOICE badge
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: pw.BoxDecoration(
                color: _kPrimaryBg,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Text('INVOICE',
                  style: sTitle.copyWith(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _itemsTable(
      InvoiceEntity invoice,
      pw.TextStyle cell,
      pw.TextStyle cellAr,
      pw.TextStyle hdrStyle,
      String cur,
      ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _kGrey200, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),    // Item name
        1: const pw.FixedColumnWidth(36),  // Qty
        2: const pw.FixedColumnWidth(36),  // Days
        3: const pw.FixedColumnWidth(58),  // Price/Day
        4: const pw.FixedColumnWidth(48),  // Discount %
        5: const pw.FixedColumnWidth(64),  // Line Total
      },
      children: [
        // ── Header ──
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _kPrimaryBg),
          children: [
            _th('Item Name', hdrStyle),
            _th('Qty', hdrStyle, center: true),
            _th('Days', hdrStyle, center: true),
            _th('Price/Day', hdrStyle, center: true),
            _th('Discount %', hdrStyle, center: true), // 🆕 Header الخصم
            _th('Line Total', hdrStyle, end: true),
          ],
        ),

        // ── Items ──
        ...invoice.items.asMap().entries.map((e) {
          final item = e.value;
          final alt  = e.key.isOdd;
          final name = item.itemName ?? '—';

          // 🆕 حساب الخصم %
          final lineTotal = item.qty * item.days * item.pricePerDay;
          final discountPercent = lineTotal > 0
              ? ((item.itemDiscount ?? 0) / lineTotal * 100).toStringAsFixed(1)
              : '0.0';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: alt ? _kGrey100 : PdfColors.white,
            ),
            children: [
              // ★ Item name — Arabic-safe ★
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5, vertical: 4),
                child: _smartText(name, cell, cellAr),
              ),
              _td('${item.qty}',  cell, center: true),
              _td('${item.days}', cell, center: true),
              _td('${_f(item.pricePerDay)} $cur', cell, center: true),
              // 🆕 Discount column
              _td('$discountPercent%', cell, center: true),
              _td(
                '${_f(item.lineTotalAfterDiscount)} $cur',
                cell.copyWith(fontWeight: pw.FontWeight.bold),
                end: true,
              ),
            ],
          );
        }),
      ],
    );
  }


  static pw.Widget _totalsAndPayment(
      InvoiceEntity invoice,
      InvoicePaymentSummary summary,
      pw.TextStyle sBase,
      pw.TextStyle sBold,
      pw.TextStyle sTotal,
      pw.TextStyle sSm,
      String cur,
      ) {
    // Subtotal should be the gross total (before ANY discounts)
    final subtotal = invoice.grossTotal;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kGrey200, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
        // اللون أخضر لو مدفوعة، رمادي لو عليها فلوس (عشان نشيل الألوان التحذيرية المزعجة)
        color: summary.isFullyPaid ? _kSuccessBg : _kGrey100,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Status badge - Show ONLY if paid. Hide if unpaid to remove "PENDING"
          if (summary.isFullyPaid)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _kSuccess,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                '✓ PAID',
                style: sBold.copyWith(color: PdfColors.white, fontSize: 7.5),
              ),
            )
          else
          // Spacer if no badge
            pw.SizedBox(width: 40),

          // Subtotal (Gross before item and invoice discounts)
          _compactStat('Subtotal', '${_f(subtotal)} $cur', sBase, sSm),

          // Show Item Discounts if exist
          if (invoice.totalItemDiscounts > 0)
            _compactStat('Item Disc.', '− ${_f(invoice.totalItemDiscounts)} $cur',
                sBase.copyWith(color: _kDanger), sSm),

          // Show Invoice Discount if exist
          if (invoice.discount > 0)
            _compactStat(
              'Inv. Disc. (${invoice.discountPercent.toStringAsFixed(1)}%)',
              '− ${_f(invoice.discount)} $cur',
              sBase.copyWith(color: _kDanger), sSm,
            ),

          // Divider
          pw.Container(width: 0.6, height: 28, color: _kGrey200),

          // Net Total (Gross - Item Disc - Inv Disc)
          _compactStat('Net Total', '${_f(invoice.netTotal)} $cur', sBase, sSm),

          // Divider
          pw.Container(width: 0.6, height: 28, color: _kGrey200),

          // Paid
          _compactStat('Amount Paid', '${_f(summary.totalPaid)} $cur',
              sBase.copyWith(color: _kSuccess), sSm),

          // Remaining
          if (summary.remaining > 0)
            _compactStat('Balance Due', '${_f(summary.remaining)} $cur',
                sBold.copyWith(color: _kDanger), sSm),
        ],
      ),
    );
  }

  static pw.Widget _footer(
      pw.TextStyle sm, String appName, pw.Context ctx) {
    return pw.Column(children: [
      pw.Divider(color: _kGrey200, thickness: 0.6),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by $appName', style: sm),
          pw.Text('Thank you for your business!', style: sm),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: sm),
        ],
      ),
    ]);
  }

  // ── Cell helpers ──────────────────────────────────────────────────────────

  static pw.Widget _th(String t, pw.TextStyle s,
      {bool center = false, bool end = false}) =>
      pw.Padding(
        padding:
        const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: pw.Text(t,
            style: s,
            textAlign: end
                ? pw.TextAlign.right
                : center
                ? pw.TextAlign.center
                : pw.TextAlign.left),
      );

  static pw.Widget _td(String t, pw.TextStyle s,
      {bool center = false, bool end = false}) =>
      pw.Padding(
        padding:
        const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(t,
            style: s,
            textAlign: end
                ? pw.TextAlign.right
                : center
                ? pw.TextAlign.center
                : pw.TextAlign.left),
      );

  static pw.Widget _compactStat(
      String label, String value, pw.TextStyle valStyle, pw.TextStyle lblStyle) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(label, style: lblStyle),
          pw.SizedBox(height: 2),
          pw.Text(value, style: valStyle),
        ],
      );

  static pw.Widget _metaRow(
      String label, String value, pw.TextStyle s) =>
      pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text('$label  ', style: s.copyWith(color: _kGrey600)),
        pw.Text(value,
            style: s.copyWith(fontWeight: pw.FontWeight.bold)),
      ]);

  static pw.Widget _tRow(
      String label, String value, pw.TextStyle s) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: s),
          pw.Text(value, style: s),
        ],
      );

  static pw.Widget _pRow(
      String label, String value, pw.TextStyle s) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: s),
          pw.Text(value,
              style: s.copyWith(fontWeight: pw.FontWeight.bold)),
        ],
      );

  static String _f(double v) => v.toStringAsFixed(0);
}

// ─── Share button widget ──────────────────────────────────────────────────────

class ShareInvoicePdfButton extends StatefulWidget {
  final InvoiceEntity invoice;
  final CustomerEntity customer;
  final InvoicePaymentSummary paymentSummary;

  const ShareInvoicePdfButton({
    super.key,
    required this.invoice,
    required this.customer,
    required this.paymentSummary,
  });

  @override
  State<ShareInvoicePdfButton> createState() =>
      _ShareInvoicePdfButtonState();
}

class _ShareInvoicePdfButtonState extends State<ShareInvoicePdfButton> {
  bool _generating = false;

  Future<void> _share() async {
    setState(() => _generating = true);
    try {
      await InvoicePdfGenerator.shareInvoice(
        invoice: widget.invoice,
        customer: widget.customer,
        paymentSummary: widget.paymentSummary,
        currencyLabel: et.tr('dashboard.currency'),
        appName: et.tr('app.name'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(et.tr('invoices.pdf_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _generating ? null : _share,
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9FF),
          borderRadius: BorderRadius.circular(7.r),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_generating)
              SizedBox(
                width: 14.r,
                height: 14.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorsManager.primaryColor,
                ),
              )
            else
              Icon(Icons.picture_as_pdf_outlined,
                  size: 15.r, color: ColorsManager.primaryColor),
            SizedBox(width: 6.w),
            Text(
              et.tr('invoices.share_pdf'),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: ColorsManager.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}