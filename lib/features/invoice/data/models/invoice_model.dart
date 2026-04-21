import 'package:hive/hive.dart';

part 'invoice_model.g.dart';

@HiveType(typeId: 2)
class InvoiceItemModel {
  @HiveField(0)
  final String productId;
  @HiveField(1)
  final String productName;
  @HiveField(2)
  final int quantity;
  @HiveField(3)
  final double price;

  const InvoiceItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;
}

@HiveType(typeId: 3)
class InvoiceModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final int invoiceNumber;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final List<InvoiceItemModel> items;
  @HiveField(4)
  final double subtotal;
  @HiveField(5)
  final double taxRate;
  @HiveField(6)
  final double taxAmount;
  @HiveField(7)
  final double discountAmount;
  @HiveField(8)
  final double total;
  @HiveField(9)
  final String paymentMode;
  @HiveField(10)
  final String? customerId;
  @HiveField(11)
  final int loyaltyPointsEarned;
  @HiveField(12)
  final int loyaltyPointsRedeemed;

  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.timestamp,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.paymentMode,
    this.customerId,
    this.loyaltyPointsEarned = 0,
    this.loyaltyPointsRedeemed = 0,
  });
}
