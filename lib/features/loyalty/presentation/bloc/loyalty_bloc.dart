import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/loyalty_usecases.dart';
import '../../../../core/usecase/usecase.dart';

part 'loyalty_event.dart';
part 'loyalty_state.dart';

class LoyaltyBloc extends Bloc<LoyaltyEvent, LoyaltyState> {
  final GetCustomerByPhoneUseCase getCustomerByPhoneUseCase;
  final CreateCustomerUseCase createCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final GetAllCustomersUseCase getAllCustomersUseCase;

  LoyaltyBloc({
    required this.getCustomerByPhoneUseCase,
    required this.createCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.getAllCustomersUseCase,
  }) : super(const LoyaltyState()) {
    on<LookupCustomerEvent>(_onLookupCustomer);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<SelectCustomerEvent>(_onSelectCustomer);
    on<ClearSelectedCustomerEvent>(_onClearSelectedCustomer);
    on<AwardPointsEvent>(_onAwardPoints);
    on<RedeemPointsEvent>(_onRedeemPoints);
    on<LoadAllCustomersEvent>(_onLoadAllCustomers);
  }

  Future<void> _onLookupCustomer(
      LookupCustomerEvent event, Emitter<LoyaltyState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final result = await getCustomerByPhoneUseCase(event.phone);
    result.fold(
      (failure) => emit(state.copyWith(
          isLoading: false, error: failure.message, lookupDone: true)),
      (customer) {
        if (customer == null) {
          // Not found – show "Register" prompt
          emit(state.copyWith(
              isLoading: false,
              clearSelectedCustomer: true,
              lookupDone: true,
              clearError: true));
        } else {
          emit(state.copyWith(
            isLoading: false,
            selectedCustomer: customer,
            lookupDone: true,
            clearError: true,
          ));
        }
      },
    );
  }

  Future<void> _onCreateCustomer(
      CreateCustomerEvent event, Emitter<LoyaltyState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    final newCustomer = Customer(
      id: const Uuid().v4(),
      name: event.name,
      phone: event.phone,
    );
    final result = await createCustomerUseCase(newCustomer);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.message)),
      (customer) => emit(state.copyWith(
        isLoading: false,
        selectedCustomer: customer,
        lookupDone: true,
        clearError: true,
      )),
    );
  }

  void _onSelectCustomer(
      SelectCustomerEvent event, Emitter<LoyaltyState> emit) {
    emit(state.copyWith(selectedCustomer: event.customer, lookupDone: true));
  }

  void _onClearSelectedCustomer(
      ClearSelectedCustomerEvent event, Emitter<LoyaltyState> emit) {
    emit(state.copyWith(
        clearSelectedCustomer: true,
        lookupDone: false,
        pointsToRedeem: 0));
  }

  Future<void> _onAwardPoints(
      AwardPointsEvent event, Emitter<LoyaltyState> emit) async {
    final customer = state.selectedCustomer;
    if (customer == null) return;
    final newPoints = (customer.points + event.points).clamp(0, kMaxLoyaltyPoints);
    final updated = customer.copyWith(points: newPoints);
    final result = await updateCustomerUseCase(updated);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (_) => emit(state.copyWith(selectedCustomer: updated, clearError: true)),
    );
  }

  void _onRedeemPoints(
      RedeemPointsEvent event, Emitter<LoyaltyState> emit) {
    final customer = state.selectedCustomer;
    if (customer == null) return;
    final redeemable = customer.points.clamp(0, event.maxPoints);
    emit(state.copyWith(pointsToRedeem: redeemable));
  }

  Future<void> _onLoadAllCustomers(
      LoadAllCustomersEvent event, Emitter<LoyaltyState> emit) async {
    final result = await getAllCustomersUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (customers) => emit(state.copyWith(allCustomers: customers)),
    );
  }
}
