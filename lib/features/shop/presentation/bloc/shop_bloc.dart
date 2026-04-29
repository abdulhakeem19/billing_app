import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/shop.dart';
import '../../domain/usecases/shop_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'shop_event.dart';
part 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final GetShopUseCase getShopUseCase;
  final UpdateShopUseCase updateShopUseCase;

  ShopBloc({
    required this.getShopUseCase,
    required this.updateShopUseCase,
  }) : super(const ShopState()) {
    on<LoadShopEvent>(_onLoadShop);
    on<UpdateShopEvent>(_onUpdateShop);
  }

  Future<void> _onLoadShop(LoadShopEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(status: ShopStatus.loading, clearMessage: true));
    final result = await getShopUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
          status: ShopStatus.error, message: failure.message)),
      (shop) => emit(state.copyWith(status: ShopStatus.loaded, shop: shop)),
    );
  }

  Future<void> _onUpdateShop(
      UpdateShopEvent event, Emitter<ShopState> emit) async {
    emit(state.copyWith(status: ShopStatus.loading, clearMessage: true));
    final result = await updateShopUseCase(event.shop);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ShopStatus.error, message: failure.message)),
      (_) => emit(state.copyWith(
          status: ShopStatus.success, shop: event.shop, clearMessage: true)),
    );
  }
}
