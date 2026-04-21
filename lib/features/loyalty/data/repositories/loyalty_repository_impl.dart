import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../models/customer_model.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  Customer _fromModel(CustomerModel m) =>
      Customer(id: m.id, name: m.name, phone: m.phone, points: m.points);

  CustomerModel _toModel(Customer c) =>
      CustomerModel(id: c.id, name: c.name, phone: c.phone, points: c.points);

  @override
  Future<Either<Failure, Customer?>> getCustomerByPhone(String phone) async {
    try {
      final box = HiveDatabase.customerBox;
      final match = box.values
          .where((m) => m.phone == phone)
          .map(_fromModel)
          .firstOrNull;
      return Right(match);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Customer>> createCustomer(Customer customer) async {
    try {
      final box = HiveDatabase.customerBox;
      final id = customer.id.isEmpty ? const Uuid().v4() : customer.id;
      final model = CustomerModel(
          id: id,
          name: customer.name,
          phone: customer.phone,
          points: customer.points);
      await box.put(id, model);
      return Right(_fromModel(model));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomer(Customer customer) async {
    try {
      await HiveDatabase.customerBox.put(customer.id, _toModel(customer));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> getAllCustomers() async {
    try {
      final customers =
          HiveDatabase.customerBox.values.map(_fromModel).toList();
      return Right(customers);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
