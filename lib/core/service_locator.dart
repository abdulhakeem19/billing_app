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
import 'data/settings_repository.dart';
import 'data/settings_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  _registerProductDependencies();
  _registerShopDependencies();
  _registerPrinterDependencies();
  _registerInvoiceDependencies();
  _registerLoyaltyDependencies();
  _registerSettingsDependencies();
  _registerBillingDependencies();
  _registerReportsDependencies();
}

// ---------------------------------------------------------------------------
// Product
// ---------------------------------------------------------------------------

void _registerProductDependencies() {
  sl.registerFactory(
    () => ProductBloc(
      getProductsUseCase: sl(),
      addProductUseCase: sl(),
      updateProductUseCase: sl(),
      deleteProductUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));

  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(),
  );
}

// ---------------------------------------------------------------------------
// Shop
// ---------------------------------------------------------------------------

void _registerShopDependencies() {
  sl.registerFactory(
    () => ShopBloc(
      getShopUseCase: sl(),
      updateShopUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(),
  );
}

// ---------------------------------------------------------------------------
// Printer / Settings page
// ---------------------------------------------------------------------------

void _registerPrinterDependencies() {
  sl.registerFactory(
    () => PrinterBloc(repository: sl()),
  );

  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(),
  );
}

// ---------------------------------------------------------------------------
// Invoice
// ---------------------------------------------------------------------------

void _registerInvoiceDependencies() {
  sl.registerLazySingleton(() => SaveInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoicesUseCase(sl()));
  sl.registerLazySingleton(() => DeleteInvoiceUseCase(sl()));

  sl.registerLazySingleton<InvoiceRepository>(
    () => InvoiceRepositoryImpl(),
  );
}

// ---------------------------------------------------------------------------
// Loyalty
// ---------------------------------------------------------------------------

void _registerLoyaltyDependencies() {
  sl.registerFactory(
    () => LoyaltyBloc(
      getCustomerByPhoneUseCase: sl(),
      createCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      getAllCustomersUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(() => GetCustomerByPhoneUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetAllCustomersUseCase(sl()));

  sl.registerLazySingleton<LoyaltyRepository>(
    () => LoyaltyRepositoryImpl(),
  );
}

// ---------------------------------------------------------------------------
// Settings (cross-cutting: tax rate, invoice counter)
// ---------------------------------------------------------------------------

void _registerSettingsDependencies() {
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(),
  );
}

// ---------------------------------------------------------------------------
// Billing
// ---------------------------------------------------------------------------

void _registerBillingDependencies() {
  sl.registerFactory(
    () => BillingBloc(
      getProductByBarcodeUseCase: sl(),
      updateProductUseCase: sl(),
      saveInvoiceUseCase: sl(),
      settingsRepository: sl(),
      printerRepository: sl(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Reports
// ---------------------------------------------------------------------------

void _registerReportsDependencies() {
  sl.registerFactory(
    () => ReportsBloc(
      getInvoicesUseCase: sl(),
      deleteInvoiceUseCase: sl(),
    ),
  );
}
