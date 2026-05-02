// lib/features/customers/presentation/utils/invoice_pdf_generator.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
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
const _kWarning   = PdfColor(0.60, 0.30, 0.00);
const _kWarningBg = PdfColor(1.00, 0.97, 0.88);
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
      final bytes = await rootBundle.load('assets/images/logo.png');
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
    final sBase  = mk(11);
    final sSm    = mk(9.5,  c: _kGrey600);
    final sBold  = mk(11,   b: true);
    final sTitle = mk(22,   b: true, c: _kPrimary);
    final sTotal = mk(15,   b: true, c: _kPrimary);

    // Arabic variants — slightly larger for readability at same font size
    final sBaseAr = mk(12);
    final sSmAr   = mk(10,  c: _kGrey600);
    final sBoldAr = mk(13,  b: true);

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
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        footer: (ctx) => _footer(sSm, appName, ctx),
        build: (ctx) => [
          _header(logo, sTitle, sSm, sBase, sBaseAr, sSmAr, sBoldAr,
              appName, ref, dateStr, customer),
          pw.SizedBox(height: 24),
          pw.Divider(color: _kGrey200, thickness: 0.8),
          pw.SizedBox(height: 20),
          _itemsTable(invoice, sBase, sBold, sBaseAr, sBoldAr, cur),
          pw.SizedBox(height: 24),
          _totalsAndPayment(
              invoice, paymentSummary, sBase, sBold, sTotal, sSm, cur),
          pw.SizedBox(height: 32),
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
      ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Left — logo / company name
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Image(logo, width: 90, height: 90, fit: pw.BoxFit.contain)
            else
              pw.Text(appName, style: sTitle),
            pw.SizedBox(height: 6),
            if (logo != null)
              pw.Text(appName, style: sTitle.copyWith(fontSize: 16)),
            pw.Text('Professional Rental Management', style: sSm),
          ],
        ),

        // Right — invoice meta + client
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding:
              const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _kPrimaryBg,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('INVOICE',
                  style: sTitle.copyWith(fontSize: 20)),
            ),
            pw.SizedBox(height: 10),
            _metaRow('Invoice #', ref, sBase),
            pw.SizedBox(height: 3),
            _metaRow('Date', dateStr, sBase),
            pw.SizedBox(height: 12),
            pw.Text('Bill To:', style: sSm),
            pw.SizedBox(height: 4),

            // ★ Customer name — Arabic-safe ★
            _smartText(
              customer.name,
              sBase.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 13),
              sBoldAr.copyWith(fontSize: 14),
            ),

            if (customer.phone != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(customer.phone!, style: sSm),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _itemsTable(
      InvoiceEntity invoice,
      pw.TextStyle sBase,
      pw.TextStyle sBold,
      pw.TextStyle sBaseAr,
      pw.TextStyle sBoldAr,
      String cur,
      ) {
    final hdr    = sBold.copyWith(color: _kPrimary, fontSize: 10.5);
    final cell   = sBase.copyWith(fontSize: 10.5);
    final cellAr = sBaseAr.copyWith(fontSize: 10.5);

    return pw.Table(
      border: pw.TableBorder(
        top:              pw.BorderSide(color: _kGrey200, width: 0.6),
        bottom:           pw.BorderSide(color: _kGrey200, width: 0.6),
        left:             pw.BorderSide(color: _kGrey200, width: 0.6),
        right:            pw.BorderSide(color: _kGrey200, width: 0.6),
        horizontalInside: pw.BorderSide(color: _kGrey200, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FixedColumnWidth(42),
        2: pw.FixedColumnWidth(42),
        3: pw.FixedColumnWidth(76),
        4: pw.FixedColumnWidth(82),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kPrimaryBg),
          children: [
            _th('Item / Description', hdr),
            _th('Qty',        hdr, center: true),
            _th('Days',       hdr, center: true),
            _th('Unit Price', hdr, center: true),
            _th('Amount',     hdr, end: true),
          ],
        ),
        // Data rows
        ...invoice.items.asMap().entries.map((e) {
          final item = e.value;
          final alt  = e.key.isOdd;
          final name = item.itemName ?? '—';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: alt ? _kGrey100 : PdfColors.white,
            ),
            children: [
              // ★ Item name — Arabic-safe ★
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8, vertical: 7),
                child: _smartText(name, cell, cellAr),
              ),
              _td('${item.qty}',  cell, center: true),
              _td('${item.days}', cell, center: true),
              _td('${_f(item.pricePerDay)} $cur', cell, center: true),
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
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Payment card
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: summary.isFullyPaid ? _kSuccessBg : _kWarningBg,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                color: summary.isFullyPaid ? _kSuccess : _kWarning,
                width: 0.8,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  summary.isFullyPaid ? 'PAID IN FULL  ✓' : 'PAYMENT SUMMARY',
                  style: sBold.copyWith(
                    color: summary.isFullyPaid ? _kSuccess : _kWarning,
                    fontSize: 11.5,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pRow('Total Due',
                    '${_f(summary.totalDue)} $cur', sBase),
                pw.SizedBox(height: 4),
                _pRow('Amount Paid',
                    '${_f(summary.totalPaid)} $cur',
                    sBase.copyWith(color: _kSuccess)),
                if (summary.remaining > 0) ...[
                  pw.SizedBox(height: 4),
                  _pRow('Balance Due',
                      '${_f(summary.remaining)} $cur',
                      sBold.copyWith(color: _kDanger)),
                ],
              ],
            ),
          ),
        ),

        pw.SizedBox(width: 20),

        // Totals breakdown
        pw.SizedBox(
          width: 232,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _kGrey200, width: 0.8),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _tRow('Subtotal',
                    '${_f(invoice.totalAmount)} $cur', sBase),
                if (invoice.totalItemDiscounts > 0) ...[
                  pw.SizedBox(height: 4),
                  _tRow('Item Discounts',
                      '− ${_f(invoice.totalItemDiscounts)} $cur',
                      sBase.copyWith(color: _kDanger)),
                ],
                if (invoice.discount > 0) ...[
                  pw.SizedBox(height: 4),
                  _tRow(
                    'Invoice Discount '
                        '(${invoice.discountPercent.toStringAsFixed(1)}%)',
                    '− ${_f(invoice.discount)} $cur',
                    sBase.copyWith(color: _kDanger),
                  ),
                ],
                pw.SizedBox(height: 8),
                pw.Divider(color: _kGrey200, thickness: 0.8),
                pw.SizedBox(height: 8),
                _tRow('Net Total',
                    '${_f(invoice.netTotal)} $cur', sTotal),
              ],
            ),
          ),
        ),
      ],
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
        const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
        const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Text(t,
            style: s,
            textAlign: end
                ? pw.TextAlign.right
                : center
                ? pw.TextAlign.center
                : pw.TextAlign.left),
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