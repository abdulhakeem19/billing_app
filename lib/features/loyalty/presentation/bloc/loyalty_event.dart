part of 'loyalty_bloc.dart';

abstract class LoyaltyEvent extends Equatable {
  const LoyaltyEvent();
  @override
  List<Object> get props => [];
}

class LookupCustomerEvent extends LoyaltyEvent {
  final String phone;
  const LookupCustomerEvent(this.phone);
  @override
  List<Object> get props => [phone];
}

class CreateCustomerEvent extends LoyaltyEvent {
  final String name;
  final String phone;
  const CreateCustomerEvent({required this.name, required this.phone});
  @override
  List<Object> get props => [name, phone];
}

class SelectCustomerEvent extends LoyaltyEvent {
  final Customer customer;
  const SelectCustomerEvent(this.customer);
  @override
  List<Object> get props => [customer];
}

class ClearSelectedCustomerEvent extends LoyaltyEvent {}

class AwardPointsEvent extends LoyaltyEvent {
  final int points;
  const AwardPointsEvent(this.points);
  @override
  List<Object> get props => [points];
}

class RedeemPointsEvent extends LoyaltyEvent {
  final int maxPoints;
  const RedeemPointsEvent(this.maxPoints);
  @override
  List<Object> get props => [maxPoints];
}

class LoadAllCustomersEvent extends LoyaltyEvent {}
