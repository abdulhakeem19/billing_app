part of 'loyalty_bloc.dart';

class LoyaltyState extends Equatable {
  final Customer? selectedCustomer;
  final bool lookupDone;
  final bool isLoading;
  final String? error;
  final int pointsToRedeem;
  final List<Customer> allCustomers;

  const LoyaltyState({
    this.selectedCustomer,
    this.lookupDone = false,
    this.isLoading = false,
    this.error,
    this.pointsToRedeem = 0,
    this.allCustomers = const [],
  });

  // 1 point = ₹1 discount
  double get redemptionValue => pointsToRedeem.toDouble();

  LoyaltyState copyWith({
    Customer? selectedCustomer,
    bool clearSelectedCustomer = false,
    bool? lookupDone,
    bool? isLoading,
    String? error,
    int? pointsToRedeem,
    List<Customer>? allCustomers,
  }) {
    return LoyaltyState(
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      lookupDone: lookupDone ?? this.lookupDone,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      pointsToRedeem: pointsToRedeem ?? this.pointsToRedeem,
      allCustomers: allCustomers ?? this.allCustomers,
    );
  }

  @override
  List<Object?> get props =>
      [selectedCustomer, lookupDone, isLoading, error, pointsToRedeem];
}
