import 'package:fpdart/fpdart.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../models/invoice_model.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  @override
  Future<Either<Failure, void>> saveInvoice(Invoice invoice) async {
    try {
      final box = HiveDatabase.invoiceBox;
      final model = _toModel(invoice);
      await box.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoices() async {
    try {
      final box = HiveDatabase.invoiceBox;
      final invoices = box.values.map(_fromModel).toList();
      invoices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      await HiveDatabase.invoiceBox.delete(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  InvoiceModel _toModel(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      timestamp: invoice.timestamp,
      items: invoice.items
          .map((i) => InvoiceItemModel(
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                price: i.price,
              ))
          .toList(),
      subtotal: invoice.subtotal,
      taxRate: invoice.taxRate,
      taxAmount: invoice.taxAmount,
      discountAmount: invoice.discountAmount,
      total: invoice.total,
      paymentMode: invoice.paymentMode,
      customerId: invoice.customerId,
      loyaltyPointsEarned: invoice.loyaltyPointsEarned,
      loyaltyPointsRedeemed: invoice.loyaltyPointsRedeemed,
    );
  }

  Invoice _fromModel(InvoiceModel model) {
    return Invoice(
      id: model.id,
      invoiceNumber: model.invoiceNumber,
      timestamp: model.timestamp,
      items: model.items
          .map((i) => InvoiceItem(
                productId: i.productId,
                productName: i.productName,
                quantity: i.quantity,
                price: i.price,
              ))
          .toList(),
      subtotal: model.subtotal,
      taxRate: model.taxRate,
      taxAmount: model.taxAmount,
      discountAmount: model.discountAmount,
      total: model.total,
      paymentMode: model.paymentMode,
      customerId: model.customerId,
      loyaltyPointsEarned: model.loyaltyPointsEarned,
      loyaltyPointsRedeemed: model.loyaltyPointsRedeemed,
    );
  }
}
