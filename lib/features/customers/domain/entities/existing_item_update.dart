class ExistingItemUpdate {
  final String id;
  final String itemId;
  final int newDays;
  final int newQty;

  ExistingItemUpdate({
    required this.id,
    required this.itemId,
    required this.newDays,
    required this.newQty,
  });

  // تحويل البيانات لـ JSON عشان الـ Data layer يبعتها للـ API/DB
  Map<String, dynamic> toJson() => {
    'id': id,
    'item_id': itemId,
    'new_days': newDays,
    'new_qty': newQty,
  };
}