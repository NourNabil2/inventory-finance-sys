import 'package:equatable/equatable.dart';

class AlertEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String customerName;
  final String itemName;
  final DateTime dueDate;
  final int daysDiff;
  final int qty;
  final String alertType;

  const AlertEntity({
    required this.id,
    required this.invoiceId,
    required this.customerName,
    required this.itemName,
    required this.dueDate,
    required this.daysDiff,
    required this.qty,
    required this.alertType,
  });

  bool get isOverdue => alertType == 'overdue';

  @override
  List<Object?> get props => [id, invoiceId, alertType];
}