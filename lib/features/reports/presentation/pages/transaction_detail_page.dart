import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../invoice/domain/entities/invoice.dart';

class TransactionDetailPage extends StatelessWidget {
  final Invoice invoice;
  const TransactionDetailPage({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        leading: IconButton(
          icon:
              Icon(Icons.chevron_left, size: 28, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  _row('Date',
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(invoice.timestamp)),
                  _divider(),
                  _row('Payment', invoice.paymentMode),
                  _divider(),
                  _row('Invoice #', '#${invoice.invoiceNumber}'),
                  if (invoice.loyaltyPointsEarned > 0) ...[
                    _divider(),
                    _row('Points Earned',
                        '+${invoice.loyaltyPointsEarned} pts',
                        valueColor: Colors.green),
                  ],
                  if (invoice.loyaltyPointsRedeemed > 0) ...[
                    _divider(),
                    _row('Points Redeemed',
                        '-${invoice.loyaltyPointsRedeemed} pts',
                        valueColor: Colors.orange),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: borderColor),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration:
                          const BoxDecoration(color: Color(0xFFF8FAFC)),
                      children: [
                        _headerCell('Item'),
                        _headerCell('Qty'),
                        _headerCell('Total', align: TextAlign.right),
                      ],
                    ),
                    ...invoice.items.map((item) => TableRow(
                          children: [
                            _dataCell(item.productName),
                            _dataCell('${item.quantity}'),
                            _dataCell(
                                '₹${item.total.toStringAsFixed(2)}',
                                align: TextAlign.right,
                                bold: true),
                          ],
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Totals card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                children: [
                  _row('Subtotal',
                      '₹${invoice.subtotal.toStringAsFixed(2)}'),
                  if (invoice.discountAmount > 0) ...[
                    _divider(),
                    _row('Discount',
                        '-₹${invoice.discountAmount.toStringAsFixed(2)}',
                        valueColor: Colors.red),
                  ],
                  if (invoice.taxAmount > 0) ...[
                    _divider(),
                    _row('Tax (${invoice.taxRate.toStringAsFixed(1)}%)',
                        '+₹${invoice.taxAmount.toStringAsFixed(2)}'),
                  ],
                  _divider(),
                  _row('TOTAL',
                      '₹${invoice.total.toStringAsFixed(2)}',
                      bold: true,
                      valueColor: AppTheme.primaryColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 1, color: Colors.grey[100]);

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text,
          textAlign: align,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5)),
    );
  }

  Widget _dataCell(String text,
      {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(text,
          textAlign: align,
          style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87)),
    );
  }
}
