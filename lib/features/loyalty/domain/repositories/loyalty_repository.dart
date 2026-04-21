import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer.dart';

abstract class LoyaltyRepository {
  Future<Either<Failure, Customer?>> getCustomerByPhone(String phone);
  Future<Either<Failure, Customer>> createCustomer(Customer customer);
  Future<Either<Failure, void>> updateCustomer(Customer customer);
  Future<Either<Failure, List<Customer>>> getAllCustomers();
}
