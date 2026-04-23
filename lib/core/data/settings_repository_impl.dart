import 'hive_database.dart';
import 'settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _taxRateKey = 'tax_rate';
  static const String _invoiceNumberKey = 'next_invoice_number';

  @override
  double getTaxRate() {
    return HiveDatabase.settingsBox.get(_taxRateKey, defaultValue: 0.0)
        as double;
  }

  @override
  Future<void> saveTaxRate(double rate) {
    return HiveDatabase.settingsBox.put(_taxRateKey, rate);
  }

  @override
  Future<int> allocateInvoiceNumber() async {
    final box = HiveDatabase.settingsBox;
    final current =
        box.get(_invoiceNumberKey, defaultValue: 1) as int;
    await box.put(_invoiceNumberKey, current + 1);
    return current;
  }
}
