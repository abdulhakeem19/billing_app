import 'package:billing_app/features/reports/presentation/pages/transaction_detail_page.dart';
import 'package:billing_app/features/invoice/domain/entities/invoice.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/reports_bloc.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(LoadReportsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reports & Analytics'),
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(
                child: Text('Error: ${state.error}',
                    style: const TextStyle(color: AppTheme.textSecondary)));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<ReportsBloc>().add(LoadReportsEvent()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildFilterRow(context, state),
                const SizedBox(height: 16),
                _buildSummaryCards(state),
                const SizedBox(height: 16),
                _buildSalesChart(state),
                if (state.topProducts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTopProducts(state),
                ],
                const SizedBox(height: 16),
                _buildTransactionList(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context, ReportsState state) {
    const filters = ['today', 'week', 'month', 'all'];
    const labels = ['Today', 'Week', 'Month', 'All'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = state.filter == filters[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              child: GestureDetector(
                onTap: () => context
                    .read<ReportsBloc>()
                    .add(SetReportFilterEvent(filters[i])),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]
                        : null,
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards(ReportsState state) {
    return Row(
      children: [
        Expanded(
            child: _summaryCard(
          icon: Icons.currency_rupee_rounded,
          label: 'Revenue',
          value: '₹${state.totalRevenue.toStringAsFixed(0)}',
          color: AppTheme.successColor,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _summaryCard(
          icon: Icons.receipt_long_rounded,
          label: 'Orders',
          value: '${state.totalTransactions}',
          color: AppTheme.primaryColor,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _summaryCard(
          icon: Icons.trending_up_rounded,
          label: 'Avg',
          value: '₹${state.averageOrderValue.toStringAsFixed(0)}',
          color: Colors.orange,
        )),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSalesChart(ReportsState state) {
    final data = state.dailyRevenue;
    if (data.isEmpty || data.every((e) => e.value == 0)) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          children: [
            const Text('Sales – Last 7 Days',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 20),
            const Icon(Icons.bar_chart_rounded,
                size: 48, color: AppTheme.dividerColor),
            const SizedBox(height: 8),
            const Text('No sales data yet',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sales – Last 7 Days',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.primaryColor,
                    getTooltipItem: (_, __, rod, ___) => BarTooltipItem(
                      '₹${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('dd/M').format(data[idx].key),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        color: AppTheme.primaryColor,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.25,
                          color: AppTheme.backgroundColor,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(ReportsState state) {
    final top = state.topProducts;
    final maxQty = top.first.value.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Selling',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          ...top.map((entry) {
            final pct = maxQty == 0 ? 0.0 : entry.value / maxQty;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${entry.value} sold',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppTheme.backgroundColor,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, ReportsState state) {
    final invoices = state.filteredInvoices;

    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transactions',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${invoices.length}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.dividerColor),
          if (invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No transactions in this period',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ),
            )
          else
            ...invoices
                .take(50)
                .map((inv) => _buildTransactionTile(context, inv)),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, Invoice invoice) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(invoice: invoice),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(_paymentIcon(invoice.paymentMode),
                  color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice #${invoice.invoiceNumber}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy • h:mm a')
                        .format(invoice.timestamp),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${invoice.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(invoice.paymentMode,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppTheme.dividerColor),
          ],
        ),
      ),
    );
  }

  IconData _paymentIcon(String mode) {
    switch (mode) {
      case 'Card':
        return Icons.credit_card_rounded;
      case 'UPI':
        return Icons.qr_code_rounded;
      default:
        return Icons.payments_outlined;
    }
  }
}
