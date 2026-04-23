import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/features/billing/presentation/bloc/billing_bloc.dart';
import 'package:billing_app/features/invoice/domain/entities/invoice.dart';
import 'package:billing_app/features/invoice/domain/usecases/invoice_usecases.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import 'package:billing_app/core/data/settings_repository.dart';
import 'package:billing_app/features/settings/domain/repositories/printer_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGetProductByBarcodeUseCase extends Mock
    implements GetProductByBarcodeUseCase {}

class MockUpdateProductUseCase extends Mock implements UpdateProductUseCase {}

class MockSaveInvoiceUseCase extends Mock implements SaveInvoiceUseCase {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockPrinterRepository extends Mock implements PrinterRepository {}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _inStockProduct = Product(
  id: 'prod-1',
  name: 'Rice',
  barcode: '1234567890',
  price: 50.0,
  stock: 10,
);

const _outOfStockProduct = Product(
  id: 'prod-2',
  name: 'Sugar',
  barcode: '9876543210',
  price: 40.0,
  stock: 0,
);

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

BillingBloc _buildBloc({
  MockGetProductByBarcodeUseCase? barcodeUC,
  MockUpdateProductUseCase? updateUC,
  MockSaveInvoiceUseCase? saveUC,
  MockSettingsRepository? settingsRepo,
  MockPrinterRepository? printerRepo,
}) {
  final b = barcodeUC ?? MockGetProductByBarcodeUseCase();
  final u = updateUC ?? MockUpdateProductUseCase();
  final s = saveUC ?? MockSaveInvoiceUseCase();
  final sr = settingsRepo ?? MockSettingsRepository();
  final pr = printerRepo ?? MockPrinterRepository();

  when(() => sr.getTaxRate()).thenReturn(0.0);

  return BillingBloc(
    getProductByBarcodeUseCase: b,
    updateProductUseCase: u,
    saveInvoiceUseCase: s,
    settingsRepository: sr,
    printerRepository: pr,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Product(
        id: '', name: '', barcode: '', price: 0, stock: 0));
    registerFallbackValue(Invoice(
      id: '',
      invoiceNumber: 0,
      timestamp: DateTime(2024),
      items: const [],
      subtotal: 0,
      taxRate: 0,
      taxAmount: 0,
      discountAmount: 0,
      total: 0,
      paymentMode: 'Cash',
    ));
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------
  group('Initial state', () {
    test('has empty cart and zero totals', () {
      final bloc = _buildBloc();
      expect(bloc.state.cartItems, isEmpty);
      expect(bloc.state.taxRate, 0.0);
      expect(bloc.state.subtotal, 0.0);
      bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // AddProductToCartEvent
  // -------------------------------------------------------------------------
  group('AddProductToCartEvent', () {
    blocTest<BillingBloc, BillingState>(
      'adds an in-stock product to the cart',
      build: _buildBloc,
      act: (bloc) => bloc.add(const AddProductToCartEvent(_inStockProduct)),
      expect: () => [
        isA<BillingState>().having(
            (s) => s.cartItems.length, 'cart length', 1),
      ],
    );

    blocTest<BillingBloc, BillingState>(
      'increments quantity when same product is added twice',
      build: _buildBloc,
      act: (bloc) {
        bloc.add(const AddProductToCartEvent(_inStockProduct));
        bloc.add(const AddProductToCartEvent(_inStockProduct));
      },
      expect: () => [
        isA<BillingState>()
            .having((s) => s.cartItems.length, 'cart length', 1),
        isA<BillingState>()
            .having((s) => s.cartItems.first.quantity, 'quantity', 2),
      ],
    );

    blocTest<BillingBloc, BillingState>(
      'emits error for out-of-stock product',
      build: _buildBloc,
      act: (bloc) =>
          bloc.add(const AddProductToCartEvent(_outOfStockProduct)),
      expect: () => [
        isA<BillingState>().having((s) => s.error, 'error', isNotNull),
        isA<BillingState>().having((s) => s.error, 'error', isNull),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // RemoveProductFromCartEvent
  // -------------------------------------------------------------------------
  group('RemoveProductFromCartEvent', () {
    blocTest<BillingBloc, BillingState>(
      'removes a product from the cart',
      build: _buildBloc,
      seed: () => BillingState(
        taxRate: 0,
        cartItems: [const CartItem(product: _inStockProduct)],
      ),
      act: (bloc) =>
          bloc.add(const RemoveProductFromCartEvent('prod-1')),
      expect: () => [
        isA<BillingState>().having((s) => s.cartItems, 'cart', isEmpty),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // UpdateQuantityEvent
  // -------------------------------------------------------------------------
  group('UpdateQuantityEvent', () {
    blocTest<BillingBloc, BillingState>(
      'updates quantity for existing item',
      build: _buildBloc,
      seed: () => BillingState(
        taxRate: 0,
        cartItems: [const CartItem(product: _inStockProduct)],
      ),
      act: (bloc) => bloc.add(const UpdateQuantityEvent('prod-1', 5)),
      expect: () => [
        isA<BillingState>().having(
            (s) => s.cartItems.first.quantity, 'quantity', 5),
      ],
    );

    blocTest<BillingBloc, BillingState>(
      'removes item when quantity set to zero',
      build: _buildBloc,
      seed: () => BillingState(
        taxRate: 0,
        cartItems: [const CartItem(product: _inStockProduct)],
      ),
      act: (bloc) => bloc.add(const UpdateQuantityEvent('prod-1', 0)),
      expect: () => [
        isA<BillingState>().having((s) => s.cartItems, 'cart', isEmpty),
      ],
    );

    blocTest<BillingBloc, BillingState>(
      'emits error when quantity exceeds stock',
      build: _buildBloc,
      seed: () => BillingState(
        taxRate: 0,
        cartItems: [const CartItem(product: _inStockProduct)],
      ),
      // _inStockProduct has stock=10; requesting 99 should error
      act: (bloc) => bloc.add(const UpdateQuantityEvent('prod-1', 99)),
      expect: () => [
        isA<BillingState>().having((s) => s.error, 'error', isNotNull),
        isA<BillingState>().having((s) => s.error, 'error', isNull),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // ClearCartEvent
  // -------------------------------------------------------------------------
  blocTest<BillingBloc, BillingState>(
    'ClearCartEvent empties the cart',
    build: _buildBloc,
    seed: () => BillingState(
      taxRate: 5.0,
      cartItems: [const CartItem(product: _inStockProduct)],
    ),
    act: (bloc) => bloc.add(ClearCartEvent()),
    expect: () => [
      isA<BillingState>()
          .having((s) => s.cartItems, 'cart', isEmpty)
          .having((s) => s.taxRate, 'taxRate preserved', 5.0),
    ],
  );

  // -------------------------------------------------------------------------
  // SetTaxRateEvent
  // -------------------------------------------------------------------------
  blocTest<BillingBloc, BillingState>(
    'SetTaxRateEvent saves and emits new tax rate',
    build: () {
      final sr = MockSettingsRepository();
      when(() => sr.getTaxRate()).thenReturn(0.0);
      when(() => sr.saveTaxRate(any())).thenAnswer((_) async {});
      return _buildBloc(settingsRepo: sr);
    },
    act: (bloc) => bloc.add(const SetTaxRateEvent(12.0)),
    expect: () => [
      isA<BillingState>().having((s) => s.taxRate, 'taxRate', 12.0),
    ],
  );

  // -------------------------------------------------------------------------
  // ApplyDiscountEvent
  // -------------------------------------------------------------------------
  group('ApplyDiscountEvent', () {
    blocTest<BillingBloc, BillingState>(
      'applies flat discount',
      build: _buildBloc,
      act: (bloc) => bloc
          .add(const ApplyDiscountEvent(discountType: 'flat', value: 10.0)),
      expect: () => [
        isA<BillingState>()
            .having((s) => s.discountType, 'type', 'flat')
            .having((s) => s.discountValue, 'value', 10.0),
      ],
    );

    blocTest<BillingBloc, BillingState>(
      'applies percent discount',
      build: _buildBloc,
      act: (bloc) => bloc.add(
          const ApplyDiscountEvent(discountType: 'percent', value: 5.0)),
      expect: () => [
        isA<BillingState>()
            .having((s) => s.discountType, 'type', 'percent')
            .having((s) => s.discountValue, 'value', 5.0),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // SetPaymentModeEvent
  // -------------------------------------------------------------------------
  blocTest<BillingBloc, BillingState>(
    'SetPaymentModeEvent updates payment mode',
    build: _buildBloc,
    act: (bloc) => bloc.add(const SetPaymentModeEvent('UPI')),
    expect: () => [
      isA<BillingState>().having((s) => s.paymentMode, 'mode', 'UPI'),
    ],
  );

  // -------------------------------------------------------------------------
  // ScanBarcodeEvent
  // -------------------------------------------------------------------------
  group('ScanBarcodeEvent', () {
    blocTest<BillingBloc, BillingState>(
      'adds product to cart on successful barcode scan',
      build: () {
        final uc = MockGetProductByBarcodeUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right(_inStockProduct));
        return _buildBloc(barcodeUC: uc);
      },
      act: (bloc) =>
          bloc.add(const ScanBarcodeEvent('1234567890')),
      expect: () => [
        isA<BillingState>()
            .having((s) => s.cartItems.length, 'cart length', 1),
      ],
    );

    blocTest<BillingBloc, BillingState>(
      'emits error state when barcode is not found',
      build: () {
        final uc = MockGetProductByBarcodeUseCase();
        when(() => uc(any())).thenAnswer(
            (_) async => const Left(NotFoundFailure('Not found')));
        return _buildBloc(barcodeUC: uc);
      },
      act: (bloc) => bloc.add(const ScanBarcodeEvent('0000000000')),
      expect: () => [
        isA<BillingState>().having((s) => s.error, 'error', isNotNull),
        isA<BillingState>().having((s) => s.error, 'error', isNull),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // Computed properties
  // -------------------------------------------------------------------------
  group('BillingState computed properties', () {
    test('subtotal is sum of all item totals', () {
      // 2 × ₹50 = ₹100
      const item = CartItem(product: _inStockProduct, quantity: 2);
      final state = BillingState(taxRate: 0, cartItems: [item]);
      expect(state.subtotal, 100.0);
    });

    test('flat discount is clamped to subtotal', () {
      const item = CartItem(product: _inStockProduct, quantity: 1);
      final state = BillingState(
        taxRate: 0,
        cartItems: [item],
        discountType: 'flat',
        discountValue: 999.0, // larger than subtotal of ₹50
      );
      expect(state.discountAmount, 50.0); // clamped to subtotal
    });

    test('percent discount applies correctly', () {
      const item = CartItem(product: _inStockProduct, quantity: 2); // ₹100
      final state = BillingState(
        taxRate: 0,
        cartItems: [item],
        discountType: 'percent',
        discountValue: 10.0, // 10% of ₹100 = ₹10
      );
      expect(state.discountAmount, 10.0);
    });

    test('tax is applied after discount', () {
      const item = CartItem(product: _inStockProduct, quantity: 2); // ₹100
      final state = BillingState(
        taxRate: 10.0, // 10%
        cartItems: [item],
        discountType: 'flat',
        discountValue: 10.0, // taxable = ₹90
      );
      expect(state.taxAmount, 9.0); // 10% of ₹90
      expect(state.totalAmount, 99.0); // ₹90 + ₹9
    });
  });
}
