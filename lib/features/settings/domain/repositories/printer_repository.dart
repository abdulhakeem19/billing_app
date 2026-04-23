import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

abstract class PrinterRepository {
  Future<List<BluetoothInfo>> scanDevices();
  Future<bool> connect(String macAddress);
  Future<bool> disconnect();
  bool get isConnected;
  String? getSavedPrinterMac();
  String? getSavedPrinterName();
  Future<void> savePrinterData(String mac, String name);
  Future<void> clearPrinterData();
  Future<void> testPrint(String shopName);

  /// Formats and sends a receipt to the connected thermal printer.
  Future<void> printReceipt({
    required String shopName,
    required String address1,
    required String address2,
    required String phone,
    required List<Map<String, dynamic>> items,
    required double total,
    required String footer,
  });
}
