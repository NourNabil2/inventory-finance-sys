import 'package:bungee_manage_sys/features/alerts/domain/entities/alert_entity.dart';

class AlertModel extends AlertEntity {
  const AlertModel({
    required super.id,
    required super.invoiceId,
    required super.customerName,
    required super.itemName,
    required super.dueDate,
    required super.qty,
    required super.daysDiff,
    required super.alertType,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final String smartInvoiceNumber = json['invoice_number']?.toString() ??
        (json['invoice_id'] != null
            ? json['invoice_id'].toString().substring(0, 8).toUpperCase()
            : '');

    return AlertModel(
      id: json['id']?.toString() ?? '',
      invoiceId: smartInvoiceNumber,
      customerName: json['customer_name']?.toString() ?? 'غير معروف',
      itemName: json['item_name']?.toString() ?? 'غير معروف',
      dueDate: DateTime.parse(json['due_date']),
      daysDiff: (json['days_diff'] as num?)?.toInt() ?? 0,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      alertType: json['alert_type']?.toString() ?? 'overdue',
    );
  }
}