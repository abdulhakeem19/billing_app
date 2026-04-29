import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  /// In-memory barcode→product index for O(1) lookups.
  /// Populated lazily on first use and kept in sync on every write.
  Map<String, ProductModel>? _barcodeIndex;

  Map<String, ProductModel> _getOrBuildIndex() {
    if (_barcodeIndex == null) {
      _barcodeIndex = {};
      for (final model in HiveDatabase.productBox.values) {
        _barcodeIndex![model.barcode] = model;
      }
    }
    return _barcodeIndex!;
  }

  void _invalidateIndex() => _barcodeIndex = null;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final products = HiveDatabase.productBox.values.toList();
      return Right(products);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductByBarcode(String barcode) async {
    try {
      final index = _getOrBuildIndex();
      final model = index[barcode];
      if (model == null) {
        return const Left(NotFoundFailure('Product not found'));
      }
      return Right(model);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Product product) async {
    try {
      final model = ProductModel.fromEntity(product);
      await HiveDatabase.productBox.put(model.id, model);
      _invalidateIndex();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Product product) async {
    try {
      final model = ProductModel.fromEntity(product);
      await HiveDatabase.productBox.put(model.id, model);
      _invalidateIndex();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      await HiveDatabase.productBox.delete(id);
      _invalidateIndex();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
