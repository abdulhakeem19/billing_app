part of 'billing_bloc.dart';

/// Maximum stock quantity that can be set for a product.
const int kMaxStock = 999999;

abstract class BillingEvent extends Equatable {
  const BillingEvent();
  @override
  List<Object> get props => [];
}

class ScanBarcodeEvent extends BillingEvent {
  final String barcode;
  const ScanBarcodeEvent(this.barcode);
  @override
  List<Object> get props => [barcode];
}

class AddProductToCartEvent extends BillingEvent {
  final Product product;
  const AddProductToCartEvent(this.product);
  @override
  List<Object> get props => [product];
}

class RemoveProductFromCartEvent extends BillingEvent {
  final String productId;
  const RemoveProductFromCartEvent(this.productId);
  @override
  List<Object> get props => [productId];
}

class UpdateQuantityEvent extends BillingEvent {
  final String productId;
  final int quantity;
  const UpdateQuantityEvent(this.productId, this.quantity);
  @override
  List<Object> get props => [productId, quantity];
}

class ClearCartEvent extends BillingEvent {}

class SetTaxRateEvent extends BillingEvent {
  final double taxRate;
  const SetTaxRateEvent(this.taxRate);
  @override
  List<Object> get props => [taxRate];
}

class ApplyDiscountEvent extends BillingEvent {
  final String discountType; // 'flat' or 'percent'
  final double value;
  const ApplyDiscountEvent({required this.discountType, required this.value});
  @override
  List<Object> get props => [discountType, value];
}

class SetPaymentModeEvent extends BillingEvent {
  final String mode; // 'Cash', 'Card', 'UPI'
  const SetPaymentModeEvent(this.mode);
  @override
  List<Object> get props => [mode];
}

class CompleteCheckoutEvent extends BillingEvent {
  final String? customerId;
  final int pointsEarned;
  final int pointsRedeemed;

  const CompleteCheckoutEvent({
    this.customerId,
    this.pointsEarned = 0,
    this.pointsRedeemed = 0,
  });

  @override
  List<Object> get props => [pointsEarned, pointsRedeemed];
}

class PrintReceiptEvent extends BillingEvent {
  final String shopName;
  final String address1;
  final String address2;
  final String phone;
  final String footer;

  const PrintReceiptEvent({
    required this.shopName,
    required this.address1,
    required this.address2,
    required this.phone,
    required this.footer,
  });

  @override
  List<Object> get props => [shopName, address1, address2, phone, footer];
}
