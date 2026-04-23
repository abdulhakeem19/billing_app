part of 'shop_bloc.dart';

enum ShopStatus { initial, loading, loaded, error, success }

class ShopState extends Equatable {
  final ShopStatus status;
  final Shop? shop;
  final String? message;

  const ShopState({
    this.status = ShopStatus.initial,
    this.shop,
    this.message,
  });

  ShopState copyWith({
    ShopStatus? status,
    Shop? shop,
    String? message,
    bool clearMessage = false,
  }) {
    return ShopState(
      status: status ?? this.status,
      shop: shop ?? this.shop,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [status, shop, message];
}
