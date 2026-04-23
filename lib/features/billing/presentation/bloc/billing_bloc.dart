import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/cart_item.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import 'package:billing_app/features/invoice/domain/entities/invoice.dart';
import 'package:billing_app/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:billing_app/core/data/settings_repository.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';

part 'billing_event.dart';
part 'billing_state.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final SaveInvoiceUseCase saveInvoiceUseCase;
  final SettingsRepository settingsRepository;
  final PrinterRepository printerRepository;

  BillingBloc({
    required this.getProductByBarcodeUseCase,
    required this.updateProductUseCase,
    required this.saveInvoiceUseCase,
    required this.settingsRepository,
    required this.printerRepository,
  }) : super(BillingState(
          taxRate: settingsRepository.getTaxRate(),
        )) {
    on<ScanBarcodeEvent>(_onScanBarcode);
    on<AddProductToCartEvent>(_onAddProductToCart);
    on<RemoveProductFromCartEvent>(_onRemoveProductFromCart);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<PrintReceiptEvent>(_onPrintReceipt);
    on<SetTaxRateEvent>(_onSetTaxRate);
    on<ApplyDiscountEvent>(_onApplyDiscount);
    on<SetPaymentModeEvent>(_onSetPaymentMode);
    on<CompleteCheckoutEvent>(_onCompleteCheckout);
  }

  Future<void> _onScanBarcode(
      ScanBarcodeEvent event, Emitter<BillingState> emit) async {
    final result = await getProductByBarcodeUseCase(event.barcode);
    result.fold(
      (failure) {
        emit(state.copyWith(error: 'Product not found: ${event.barcode}'));
        emit(state.copyWith(clearError: true));
      },
      (product) {
        if (product.stock <= 0) {
          emit(state.copyWith(
              error: '${product.name} is out of stock!'));
          emit(state.copyWith(clearError: true));
          return;
        }
        add(AddProductToCartEvent(product));
      },
    );
  }

  void _onAddProductToCart(
      AddProductToCartEvent event, Emitter<BillingState> emit) {
    if (event.product.stock <= 0) {
      emit(state.copyWith(
          error: '${event.product.name} is out of stock!', clearError: false));
      emit(state.copyWith(clearError: true));
      return;
    }

    final cleanState = state.copyWith(clearError: true);
    final existingIndex = cleanState.cartItems
        .indexWhere((item) => item.product.id == event.product.id);

    if (existingIndex >= 0) {
      final existing = cleanState.cartItems[existingIndex];
      final newQty = existing.quantity + 1;
      if (newQty > event.product.stock) {
        emit(state.copyWith(
            error: 'Not enough stock for ${event.product.name}',
            clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
      final backendItems = List<CartItem>.from(cleanState.cartItems);
      backendItems[existingIndex] = existing.copyWith(quantity: newQty);
      emit(cleanState.copyWith(cartItems: backendItems));
    } else {
      emit(cleanState.copyWith(
          cartItems: [
            ...cleanState.cartItems,
            CartItem(product: event.product)
          ]));
    }
  }

  void _onRemoveProductFromCart(
      RemoveProductFromCartEvent event, Emitter<BillingState> emit) {
    final updatedList = state.cartItems
        .where((item) => item.product.id != event.productId)
        .toList();
    emit(state.copyWith(cartItems: updatedList));
  }

  void _onUpdateQuantity(
      UpdateQuantityEvent event, Emitter<BillingState> emit) {
    if (event.quantity <= 0) {
      add(RemoveProductFromCartEvent(event.productId));
      return;
    }
    final index = state.cartItems
        .indexWhere((item) => item.product.id == event.productId);
    if (index >= 0) {
      final product = state.cartItems[index].product;
      if (event.quantity > product.stock) {
        emit(state.copyWith(
            error: 'Not enough stock for ${product.name}', clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
      final items = List<CartItem>.from(state.cartItems);
      items[index] = items[index].copyWith(quantity: event.quantity);
      emit(state.copyWith(cartItems: items));
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<BillingState> emit) {
    emit(BillingState(taxRate: state.taxRate));
  }

  Future<void> _onSetTaxRate(
      SetTaxRateEvent event, Emitter<BillingState> emit) async {
    await settingsRepository.saveTaxRate(event.taxRate);
    emit(state.copyWith(taxRate: event.taxRate));
  }

  void _onApplyDiscount(
      ApplyDiscountEvent event, Emitter<BillingState> emit) {
    emit(state.copyWith(
      discountType: event.discountType,
      discountValue: event.value,
    ));
  }

  void _onSetPaymentMode(
      SetPaymentModeEvent event, Emitter<BillingState> emit) {
    emit(state.copyWith(paymentMode: event.mode));
  }

  Future<void> _onCompleteCheckout(
      CompleteCheckoutEvent event, Emitter<BillingState> emit) async {
    emit(state.copyWith(isCheckingOut: true, error: null));

    // Deduct stock for each cart item
    for (final item in state.cartItems) {
      final updated = Product(
        id: item.product.id,
        name: item.product.name,
        barcode: item.product.barcode,
        price: item.product.price,
        stock: (item.product.stock - item.quantity).clamp(0, kMaxStock),
      );
      await updateProductUseCase(updated);
    }

    // Atomically obtain the next invoice number
    final invoiceNumber = await settingsRepository.allocateInvoiceNumber();

    final invoice = Invoice(
      id: const Uuid().v4(),
      invoiceNumber: invoiceNumber,
      timestamp: DateTime.now(),
      items: state.cartItems
          .map((i) => InvoiceItem(
                productId: i.product.id,
                productName: i.product.name,
                quantity: i.quantity,
                price: i.product.price,
              ))
          .toList(),
      subtotal: state.subtotal,
      taxRate: state.taxRate,
      taxAmount: state.taxAmount,
      discountAmount: state.discountAmount,
      total: state.totalAmount,
      paymentMode: state.paymentMode,
      customerId: event.customerId,
      loyaltyPointsEarned: event.pointsEarned,
      loyaltyPointsRedeemed: event.pointsRedeemed,
    );

    await saveInvoiceUseCase(invoice);

    emit(state.copyWith(
      isCheckingOut: false,
      checkoutSuccess: true,
      completedInvoice: invoice,
      isPrinting: false,
      printSuccess: false,
    ));
  }

  Future<void> _onPrintReceipt(
      PrintReceiptEvent event, Emitter<BillingState> emit) async {
    if (!printerRepository.isConnected) {
      final savedMac = printerRepository.getSavedPrinterMac();
      if (savedMac != null) {
        final connected = await printerRepository.connect(savedMac);
        if (!connected) {
          emit(state.copyWith(
              error: 'Failed to auto-connect to printer!', clearError: false));
          emit(state.copyWith(clearError: true));
          return;
        }
      } else {
        emit(state.copyWith(
            error: 'Printer not connected & no saved printer found!',
            clearError: false));
        emit(state.copyWith(clearError: true));
        return;
      }
    }

    emit(state.copyWith(
        isPrinting: true, printSuccess: false, clearError: true));

    try {
      final items = state.cartItems
          .map((item) => {
                'name': item.product.name,
                'qty': item.quantity,
                'price': item.product.price,
                'total': item.total,
              })
          .toList();

      await printerRepository.printReceipt(
          shopName: event.shopName,
          address1: event.address1,
          address2: event.address2,
          phone: event.phone,
          items: items,
          total: state.totalAmount,
          footer: event.footer);

      emit(state.copyWith(isPrinting: false, printSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isPrinting: false, error: 'Print failed: $e', clearError: false));
      emit(state.copyWith(clearError: true));
    }
  }
}
