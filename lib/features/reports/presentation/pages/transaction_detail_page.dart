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
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #${invoice.invoiceNumber}'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meta card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  _row('Date',
                      DateFormat('dd MMM yyyy, h:mm a')
                          .format(invoice.timestamp)),
                  _divider(),
                  _row('Payment', invoice.paymentMode),
                  _divider(),
                  _row('Invoice #', '#${invoice.invoiceNumber}'),
                  if (invoice.loyaltyPointsEarned > 0) ...[
                    _divider(),
                    _row('Points Earned',
                        '+${invoice.loyaltyPointsEarned} pts',
                        valueColor: AppTheme.successColor),
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
            const SizedBox(height: 12),

            // Items table
            Container(
              decoration: AppTheme.cardDecoration(withBorder: true),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(
                        color: AppTheme.dividerColor, width: 1),
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                          color: AppTheme.backgroundColor),
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
            const SizedBox(height: 12),

            // Totals
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                children: [
                  _row('Subtotal',
                      '₹${invoice.subtotal.toStringAsFixed(2)}'),
                  if (invoice.discountAmount > 0) ...[
                    _divider(),
                    _row('Discount',
                        '-₹${invoice.discountAmount.toStringAsFixed(2)}',
                        valueColor: AppTheme.errorColor),
                  ],
                  if (invoice.taxAmount > 0) ...[
                    _divider(),
                    _row(
                        'Tax (${invoice.taxRate.toStringAsFixed(1)}%)',
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w500,
                  color: valueColor ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppTheme.dividerColor);

  Widget _headerCell(String text, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(text,
          textAlign: align,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3)),
    );
  }

  Widget _dataCell(String text,
      {TextAlign align = TextAlign.left, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Text(text,
          textAlign: align,
          style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: AppTheme.textPrimary)),
    );
  }
}
