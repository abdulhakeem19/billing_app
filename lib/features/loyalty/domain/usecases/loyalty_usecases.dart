import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../repositories/loyalty_repository.dart';

class GetCustomerByPhoneUseCase implements UseCase<Customer?, String> {
  final LoyaltyRepository repository;
  GetCustomerByPhoneUseCase(this.repository);

  @override
  Future<Either<Failure, Customer?>> call(String params) {
    return repository.getCustomerByPhone(params);
  }
}

class CreateCustomerUseCase implements UseCase<Customer, Customer> {
  final LoyaltyRepository repository;
  CreateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, Customer>> call(Customer params) {
    return repository.createCustomer(params);
  }
}

class UpdateCustomerUseCase implements UseCase<void, Customer> {
  final LoyaltyRepository repository;
  UpdateCustomerUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Customer params) {
    return repository.updateCustomer(params);
  }
}

class GetAllCustomersUseCase implements UseCase<List<Customer>, NoParams> {
  final LoyaltyRepository repository;
  GetAllCustomersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(NoParams params) {
    return repository.getAllCustomers();
  }
}
