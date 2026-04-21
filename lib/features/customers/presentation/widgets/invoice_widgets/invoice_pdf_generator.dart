// lib/features/customers/presentation/utils/invoice_pdf_generator.dart

import 'dart:io';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:easy_localization/easy_localization.dart' as et;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePdfGenerator {
  InvoicePdfGenerator._();

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

    // 🚨 استخدام السيريال الذكي في اسم الملف 🚨
    final fileNameNum = invoice.invoiceNumber.isNotEmpty
        ? invoice.invoiceNumber
        : invoice.id.substring(0, 8).toUpperCase();

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Invoice_$fileNameNum.pdf',
    );
  }

  static Future<pw.Document> _buildPdf({
    required InvoiceEntity invoice,
    required CustomerEntity customer,
    required InvoicePaymentSummary paymentSummary,
    required String currencyLabel,
    required String appName,
  }) async {
    final doc = pw.Document();

    // 🚨 تحميل خط Cairo لدعم اللغة العربية 🚨
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      regularFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
      boldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
    } catch (_) {
      debugPrint("لم يتم العثور على خط Cairo، سيتم استخدام الخط الافتراضي");
    }

    final baseStyle = pw.TextStyle(font: regularFont, fontSize: 12, color: PdfColors.grey800);
    final boldStyle = pw.TextStyle(font: boldFont, fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black);
    final titleStyle = pw.TextStyle(font: boldFont, fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor(0.1, 0.2, 0.5)); // لون أزرق شيك
    final subtitleStyle = pw.TextStyle(font: regularFont, fontSize: 11, color: PdfColors.grey600);
    final smallStyle = pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey600);

    final currency = currencyLabel;
    final fmt = DateFormat('yyyy-MM-dd');

    // 🚨 استخدام السيريال الذكي في عرض الفاتورة 🚨
    final invoiceNum = invoice.invoiceNumber.isNotEmpty
        ? invoice.invoiceNumber
        : invoice.id.substring(0, 8).toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl, // 🚨 تفعيل اتجاه اليمين لليسار لدعم العربي 🚨
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // ── Header ────────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // اليمين (الشركة)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(appName, style: titleStyle),
                  pw.SizedBox(height: 4),
                  pw.Text('تأجير معدات سينمائية وتصوير', style: subtitleStyle),
                ],
              ),
              // اليسار (بيانات الفاتورة والعميل)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('فاتورة رقم: $invoiceNum', style: boldStyle.copyWith(fontSize: 14, color: const PdfColor(0.1, 0.2, 0.5))),
                  pw.SizedBox(height: 4),
                  pw.Text('التاريخ: ${fmt.format(invoice.createdAt)}', style: baseStyle),
                  pw.SizedBox(height: 10),
                  pw.Text('مطلوب من السيد/ة:', style: smallStyle),
                  pw.Text(customer.name, style: boldStyle.copyWith(fontSize: 14)),
                  if (customer.phone != null)
                    pw.Text(customer.phone!, style: baseStyle),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // ── Items table ───────────────────────────────────────────────────
          pw.Container(
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
            ),
            child: pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(4),  // الصنف
                1: const pw.FixedColumnWidth(50), // الكمية
                2: const pw.FixedColumnWidth(50), // الأيام
                3: const pw.FixedColumnWidth(80), // السعر
                4: const pw.FixedColumnWidth(90), // الإجمالي
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor(0.95, 0.96, 0.98), // لون خلفية هادي للهيدر
                    borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(7)),
                  ),
                  children: [
                    _cell('الصنف', boldStyle, align: pw.Alignment.centerRight),
                    _cell('الكمية', boldStyle),
                    _cell('الأيام', boldStyle),
                    _cell('السعر/يوم', boldStyle),
                    _cell('الإجمالي', boldStyle, align: pw.Alignment.centerLeft),
                  ],
                ),
                // Item rows
                ...invoice.items.map((item) => pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey200, width: 1))
                    ),
                    children: [
                      _cell(item.itemName ?? '—', baseStyle, align: pw.Alignment.centerRight),
                      _cell('${item.qty}', baseStyle),
                      _cell('${item.days}', baseStyle),
                      _cell('${item.pricePerDay.toStringAsFixed(0)} $currency', baseStyle),
                      _cell(
                          '${item.lineTotalAfterDiscount.toStringAsFixed(0)} $currency',
                          boldStyle.copyWith(fontSize: 11),
                          align: pw.Alignment.centerLeft
                      ),
                    ])),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── Totals & Payment ──────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // ملخص الدفع (على اليمين)
              pw.Container(
                width: 220,
                decoration: pw.BoxDecoration(
                  color: paymentSummary.isFullyPaid
                      ? const PdfColor(0.94, 1.0, 0.96)
                      : const PdfColor(1.0, 0.98, 0.93),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(
                    color: paymentSummary.isFullyPaid ? PdfColors.green300 : PdfColors.orange300,
                  ),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                        paymentSummary.isFullyPaid ? 'خالصة (مدفوعة بالكامل) ✓' : 'ملخص الدفع',
                        style: boldStyle.copyWith(
                          color: paymentSummary.isFullyPaid ? PdfColors.green700 : PdfColors.orange700,
                        )),
                    pw.SizedBox(height: 8),
                    _totalsRow('المدفوع', '${paymentSummary.totalPaid.toStringAsFixed(0)} $currency', baseStyle.copyWith(color: PdfColors.green700)),
                    if (paymentSummary.remaining > 0)
                      _totalsRow('المتبقي (المديونية)', '${paymentSummary.remaining.toStringAsFixed(0)} $currency', boldStyle.copyWith(color: PdfColors.red700)),
                  ],
                ),
              ),

              // الإجماليات (على اليسار)
              pw.Container(
                width: 240,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey200),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                padding: const pw.EdgeInsets.all(12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _totalsRow('المجموع الفرعي', '${invoice.totalAmount.toStringAsFixed(0)} $currency', baseStyle),
                    if (invoice.discount > 0) ...[
                      pw.SizedBox(height: 4),
                      _totalsRow(
                        'الخصم (${invoice.discountPercent.toStringAsFixed(1)}%)',
                        '− ${invoice.discount.toStringAsFixed(0)} $currency',
                        baseStyle.copyWith(color: PdfColors.red),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    _totalsRow(
                      'الصافي المستحق',
                      '${invoice.netTotal.toStringAsFixed(0)} $currency',
                      boldStyle.copyWith(fontSize: 16, color: const PdfColor(0.1, 0.2, 0.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),

          // ── Footer ────────────────────────────────────────────────────────
          pw.Divider(color: PdfColors.grey200),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text('تم إصدار هذه الفاتورة بواسطة نظام $appName', style: smallStyle),
          ),
          pw.Center(
            child: pw.Text('شكراً لتعاملكم معنا', style: boldStyle.copyWith(color: PdfColors.grey500)),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _cell(String text, pw.TextStyle style, {pw.Alignment align = pw.Alignment.center}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text, style: style),
      ),
    );
  }

  static pw.Widget _totalsRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}

// ─── Share button widget ─────────────────────────────────────────────────────

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
  State<ShareInvoicePdfButton> createState() => _ShareInvoicePdfButtonState();
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
        currencyLabel: 'dashboard.currency'.tr(), // 🚨 تم ربط العملة بملف الترجمة
        appName: 'app.name'.tr(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invoices.pdf_error'.tr())),
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: ColorsManager.primaryColor))
            else
              Icon(Icons.picture_as_pdf_outlined, size: 15.r, color: ColorsManager.primaryColor),
            SizedBox(width: 6.w),
            Text('invoices.share_pdf'.tr(),
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: ColorsManager.primaryColor)),
          ],
        ),
      ),
    );
  }
}