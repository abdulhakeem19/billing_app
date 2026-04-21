import 'package:equatable/equatable.dart';

class InvoiceItem extends Equatable {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  const InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;

  @override
  List<Object> get props => [productId, productName, quantity, price];
}

class Invoice extends Equatable {
  final String id;
  final int invoiceNumber;
  final DateTime timestamp;
  final List<InvoiceItem> items;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double discountAmount;
  final double total;
  final String paymentMode;
  final String? customerId;
  final int loyaltyPointsEarned;
  final int loyaltyPointsRedeemed;

  const Invoice({
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

  @override
  List<Object?> get props => [id, invoiceNumber, timestamp, total];
}
