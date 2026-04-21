import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/invoice.dart';
import '../repositories/invoice_repository.dart';

class SaveInvoiceUseCase implements UseCase<void, Invoice> {
  final InvoiceRepository repository;
  SaveInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Invoice params) {
    return repository.saveInvoice(params);
  }
}

class GetInvoicesUseCase implements UseCase<List<Invoice>, NoParams> {
  final InvoiceRepository repository;
  GetInvoicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(NoParams params) {
    return repository.getInvoices();
  }
}

class DeleteInvoiceUseCase implements UseCase<void, String> {
  final InvoiceRepository repository;
  DeleteInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteInvoice(params);
  }
}
