import 'package:get_it/get_it.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/product_usecases.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/domain/usecases/shop_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../features/settings/data/repositories/printer_repository_impl.dart';
import '../../features/settings/domain/repositories/printer_repository.dart';
import '../../features/settings/presentation/bloc/printer_bloc.dart';
import '../../features/invoice/data/repositories/invoice_repository_impl.dart';
import '../../features/invoice/domain/repositories/invoice_repository.dart';
import '../../features/invoice/domain/usecases/invoice_usecases.dart';
import '../../features/loyalty/data/repositories/loyalty_repository_impl.dart';
import '../../features/loyalty/domain/repositories/loyalty_repository.dart';
import '../../features/loyalty/domain/usecases/loyalty_usecases.dart';
import '../../features/loyalty/presentation/bloc/loyalty_bloc.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';
import '../../features/billing/presentation/bloc/billing_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Features - Product
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => ShopBloc(
      getShopUseCase: sl(),
      updateShopUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PrinterBloc(
      repository: sl(),
    ),
  );

  // BillingBloc now needs updateProductUseCase and saveInvoiceUseCase
  sl.registerFactory(
    () => BillingBloc(
      getProductByBarcodeUseCase: sl(),
      updateProductUseCase: sl(),
      saveInvoiceUseCase: sl(),
    ),
  );

  // ReportsBloc
  sl.registerFactory(
    () => ReportsBloc(
      getInvoicesUseCase: sl(),
      deleteInvoiceUseCase: sl(),
    ),
  );

  // LoyaltyBloc
  sl.registerFactory(
    () => LoyaltyBloc(
      getCustomerByPhoneUseCase: sl(),
      createCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      getAllCustomersUseCase: sl(),
    ),
  );

  // Use cases - Product
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));

  // Repository - Product
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(),
  );

  // Use cases - Shop
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  // Repository - Shop
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(),
  );

  // Features - Settings / Printer
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(),
  );

  // Use cases - Invoice
  sl.registerLazySingleton(() => SaveInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteInvoiceUseCase(sl()));

  // Repository - Invoice
  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(),
  );

  // Use cases - Loyalty
  sl.registerLazySingleton(() => GetCustomerByPhoneUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetAllCustomersUseCase(sl()));

  // Repository - Loyalty
  sl.registerLazySingleton<LoyaltyRepository>(
    () => LoyaltyRepositoryImpl(),
  );
}
