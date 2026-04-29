/// Abstraction over the untyped settings Hive box.
///
/// Centralises all reads/writes of app-wide settings (tax rate, invoice
/// counter, etc.) so that BLoCs no longer need to access [HiveDatabase]
/// directly and can remain testable via mock implementations.
abstract class SettingsRepository {
  /// Returns the currently configured tax rate (percentage, e.g. 5.0 = 5 %).
  double getTaxRate();

  /// Persists a new [rate] value.
  Future<void> saveTaxRate(double rate);

  /// Atomically reads the current invoice number, increments the stored
  /// counter, and returns the value that should be used for the new invoice.
  ///
  /// Hive's single-isolate model guarantees that reads and writes on the same
  /// box are serialised within the same Flutter isolate, making this safe
  /// for typical single-user POS usage.
  Future<int> allocateInvoiceNumber();
}
