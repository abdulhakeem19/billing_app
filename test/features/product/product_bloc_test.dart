import 'package:billing_app/core/error/failure.dart';
import 'package:billing_app/core/usecase/usecase.dart';
import 'package:billing_app/features/product/domain/entities/product.dart';
import 'package:billing_app/features/product/domain/usecases/product_usecases.dart';
import 'package:billing_app/features/product/presentation/bloc/product_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockGetProductsUseCase extends Mock implements GetProductsUseCase {}

class MockAddProductUseCase extends Mock implements AddProductUseCase {}

class MockUpdateProductUseCase extends Mock implements UpdateProductUseCase {}

class MockDeleteProductUseCase extends Mock implements DeleteProductUseCase {}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _product = Product(
  id: 'prod-1',
  name: 'Rice',
  barcode: '1234567890',
  price: 50.0,
  stock: 10,
);

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

ProductBloc _buildBloc({
  MockGetProductsUseCase? getUC,
  MockAddProductUseCase? addUC,
  MockUpdateProductUseCase? updateUC,
  MockDeleteProductUseCase? deleteUC,
}) {
  return ProductBloc(
    getProductsUseCase: getUC ?? MockGetProductsUseCase(),
    addProductUseCase: addUC ?? MockAddProductUseCase(),
    updateProductUseCase: updateUC ?? MockUpdateProductUseCase(),
    deleteProductUseCase: deleteUC ?? MockDeleteProductUseCase(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Product(
        id: '', name: '', barcode: '', price: 0, stock: 0));
    registerFallbackValue(NoParams());
  });

  // -------------------------------------------------------------------------
  // LoadProducts
  // -------------------------------------------------------------------------
  group('LoadProducts', () {
    blocTest<ProductBloc, ProductState>(
      'emits loading then loaded with products on success',
      build: () {
        final uc = MockGetProductsUseCase();
        when(() => uc(any()))
            .thenAnswer((_) async => const Right([_product]));
        return _buildBloc(getUC: uc);
      },
      act: (bloc) => bloc.add(LoadProducts()),
      expect: () => [
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loaded)
            .having((s) => s.products, 'products', [_product]),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'emits loading then error on failure',
      build: () {
        final uc = MockGetProductsUseCase();
        when(() => uc(any())).thenAnswer(
            (_) async => const Left(CacheFailure('DB error')));
        return _buildBloc(getUC: uc);
      },
      act: (bloc) => bloc.add(LoadProducts()),
      expect: () => [
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.error)
            .having((s) => s.message, 'message', 'DB error'),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // AddProduct
  // -------------------------------------------------------------------------
  group('AddProduct', () {
    blocTest<ProductBloc, ProductState>(
      'emits success then reloads products',
      build: () {
        final addUC = MockAddProductUseCase();
        final getUC = MockGetProductsUseCase();
        when(() => addUC(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getUC(any()))
            .thenAnswer((_) async => const Right([_product]));
        return _buildBloc(addUC: addUC, getUC: getUC);
      },
      act: (bloc) => bloc.add(const AddProduct(_product)),
      expect: () => [
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.success),
        // Reload triggered internally
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loaded),
      ],
    );

    blocTest<ProductBloc, ProductState>(
      'emits error on add failure',
      build: () {
        final addUC = MockAddProductUseCase();
        when(() => addUC(any())).thenAnswer(
            (_) async => const Left(CacheFailure('write error')));
        return _buildBloc(addUC: addUC);
      },
      act: (bloc) => bloc.add(const AddProduct(_product)),
      expect: () => [
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.error),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // UpdateProduct
  // -------------------------------------------------------------------------
  group('UpdateProduct', () {
    blocTest<ProductBloc, ProductState>(
      'emits success then reloads on update',
      build: () {
        final updateUC = MockUpdateProductUseCase();
        final getUC = MockGetProductsUseCase();
        when(() => updateUC(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getUC(any()))
            .thenAnswer((_) async => const Right([_product]));
        return _buildBloc(updateUC: updateUC, getUC: getUC);
      },
      act: (bloc) => bloc.add(const UpdateProduct(_product)),
      expect: () => [
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.success),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loaded),
      ],
    );
  });

  // -------------------------------------------------------------------------
  // DeleteProduct
  // -------------------------------------------------------------------------
  group('DeleteProduct', () {
    blocTest<ProductBloc, ProductState>(
      'emits success then reloads on delete',
      build: () {
        final deleteUC = MockDeleteProductUseCase();
        final getUC = MockGetProductsUseCase();
        when(() => deleteUC(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getUC(any()))
            .thenAnswer((_) async => const Right([]));
        return _buildBloc(deleteUC: deleteUC, getUC: getUC);
      },
      act: (bloc) => bloc.add(const DeleteProduct('prod-1')),
      expect: () => [
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.success),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loading),
        isA<ProductState>()
            .having((s) => s.status, 'status', ProductStatus.loaded)
            .having((s) => s.products, 'products', isEmpty),
      ],
    );
  });
}
