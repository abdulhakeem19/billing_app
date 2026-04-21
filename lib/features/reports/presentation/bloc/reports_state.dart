part of 'reports_bloc.dart';

class ReportsState extends Equatable {
  final List<Invoice> allInvoices;
  final String filter; // 'today', 'week', 'month', 'all'
  final bool isLoading;
  final String? error;

  const ReportsState({
    this.allInvoices = const [],
    this.filter = 'week',
    this.isLoading = false,
    this.error,
  });

  List<Invoice> get filteredInvoices {
    final now = DateTime.now();
    return allInvoices.where((inv) {
      switch (filter) {
        case 'today':
          return inv.timestamp.year == now.year &&
              inv.timestamp.month == now.month &&
              inv.timestamp.day == now.day;
        case 'week':
          return inv.timestamp.isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return inv.timestamp.year == now.year &&
              inv.timestamp.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  double get totalRevenue =>
      filteredInvoices.fold(0, (sum, inv) => sum + inv.total);

  int get totalTransactions => filteredInvoices.length;

  double get averageOrderValue =>
      totalTransactions == 0 ? 0 : totalRevenue / totalTransactions;

  /// Returns top 5 products by quantity sold
  List<MapEntry<String, int>> get topProducts {
    final Map<String, int> counts = {};
    for (final inv in filteredInvoices) {
      for (final item in inv.items) {
        counts[item.productName] =
            (counts[item.productName] ?? 0) + item.quantity;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  /// Revenue per day for the last 7 days
  List<MapEntry<DateTime, double>> get dailyRevenue {
    final Map<String, double> byDay = {};
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final key = '${day.year}-${day.month}-${day.day}';
      byDay[key] = 0;
    }
    for (final inv in allInvoices) {
      final key =
          '${inv.timestamp.year}-${inv.timestamp.month}-${inv.timestamp.day}';
      if (byDay.containsKey(key)) {
        byDay[key] = (byDay[key] ?? 0) + inv.total;
      }
    }
    return byDay.entries
        .map((e) {
          final parts = e.key.split('-').map(int.parse).toList();
          return MapEntry(DateTime(parts[0], parts[1], parts[2]), e.value);
        })
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  ReportsState copyWith({
    List<Invoice>? allInvoices,
    String? filter,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ReportsState(
      allInvoices: allInvoices ?? this.allInvoices,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [allInvoices, filter, isLoading, error];
}
