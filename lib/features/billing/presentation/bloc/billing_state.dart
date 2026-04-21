part of 'billing_bloc.dart';

class BillingState extends Equatable {
  final List<CartItem> cartItems;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;
  final double taxRate; // percentage e.g. 5.0 = 5%
  final String discountType; // 'flat' or 'percent'
  final double discountValue;
  final String paymentMode; // 'Cash', 'Card', 'UPI'
  final bool isCheckingOut;
  final bool checkoutSuccess;
  final Invoice? completedInvoice;

  const BillingState({
    this.cartItems = const [],
    this.error,
    this.isPrinting = false,
    this.printSuccess = false,
    this.taxRate = 0.0,
    this.discountType = 'flat',
    this.discountValue = 0.0,
    this.paymentMode = 'Cash',
    this.isCheckingOut = false,
    this.checkoutSuccess = false,
    this.completedInvoice,
  });

  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.total);

  double get discountAmount {
    if (discountType == 'percent') {
      return (subtotal * discountValue / 100).clamp(0, subtotal);
    }
    return discountValue.clamp(0, subtotal);
  }

  double get taxableAmount => subtotal - discountAmount;

  double get taxAmount => taxableAmount * taxRate / 100;

  double get totalAmount => taxableAmount + taxAmount;

  BillingState copyWith({
    List<CartItem>? cartItems,
    String? error,
    bool clearError = false,
    bool? isPrinting,
    bool? printSuccess,
    double? taxRate,
    String? discountType,
    double? discountValue,
    String? paymentMode,
    bool? isCheckingOut,
    bool? checkoutSuccess,
    Invoice? completedInvoice,
  }) {
    return BillingState(
      cartItems: cartItems ?? this.cartItems,
      error: clearError ? null : (error ?? this.error),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
      taxRate: taxRate ?? this.taxRate,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      paymentMode: paymentMode ?? this.paymentMode,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      checkoutSuccess: checkoutSuccess ?? this.checkoutSuccess,
      completedInvoice: completedInvoice ?? this.completedInvoice,
    );
  }

  @override
  List<Object?> get props => [
        cartItems,
        error,
        isPrinting,
        printSuccess,
        taxRate,
        discountType,
        discountValue,
        paymentMode,
        isCheckingOut,
        checkoutSuccess,
      ];
}
