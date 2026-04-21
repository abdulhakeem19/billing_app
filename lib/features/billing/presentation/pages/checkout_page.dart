import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../loyalty/presentation/bloc/loyalty_bloc.dart';
import '../bloc/billing_bloc.dart';

/// Number of currency units (₹) per loyalty point redeemed.
const double kPointsToRupeeRate = 1.0;

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _discountController = TextEditingController();
  bool _isPercentDiscount = false;
  final _loyaltyPhoneController = TextEditingController();
  bool _redeemPoints = false;

  @override
  void dispose() {
    _discountController.dispose();
    _loyaltyPhoneController.dispose();
    super.dispose();
  }

  void _applyDiscount(BillingBloc bloc) {
    final val = double.tryParse(_discountController.text) ?? 0;
    bloc.add(ApplyDiscountEvent(
        discountType: _isPercentDiscount ? 'percent' : 'flat', value: val));
  }

  Future<void> _shareWhatsApp(
      BillingState billing, ShopState shopState) async {
    final shopName =
        shopState is ShopLoaded ? shopState.shop.name : 'Shop';
    final sb = StringBuffer();
    sb.writeln('*$shopName — Receipt*');
    sb.writeln('');
    for (final item in billing.cartItems) {
      sb.writeln(
          '${item.quantity} x ${item.product.name}  ₹${item.total.toStringAsFixed(2)}');
    }
    sb.writeln('');
    if (billing.discountAmount > 0) {
      sb.writeln('Discount: -₹${billing.discountAmount.toStringAsFixed(2)}');
    }
    if (billing.taxAmount > 0) {
      sb.writeln(
          'Tax (${billing.taxRate.toStringAsFixed(1)}%): ₹${billing.taxAmount.toStringAsFixed(2)}');
    }
    sb.writeln('*Total: ₹${billing.totalAmount.toStringAsFixed(2)}*');
    sb.writeln('Payment: ${billing.paymentMode}');
    sb.writeln('');
    sb.writeln('Thank you!');

    final encoded = Uri.encodeComponent(sb.toString());
    final url = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          context.read<BillingBloc>().add(ClearCartEvent());
          context.read<LoyaltyBloc>().add(ClearSelectedCustomerEvent());
          context.go('/');
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Checkout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              onPressed: () {
                context.read<BillingBloc>().add(ClearCartEvent());
                context.read<LoyaltyBloc>().add(ClearSelectedCustomerEvent());
                context.go('/');
              },
            ),
          ),
          body: BlocConsumer<BillingBloc, BillingState>(
            listener: (context, state) {
              if (state.printSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Printed successfully'),
                    backgroundColor: Colors.green));
              }
              if (state.checkoutSuccess) {
                final loyaltyState = context.read<LoyaltyBloc>().state;
                if (loyaltyState.selectedCustomer != null) {
                  final pointsEarned = state.totalAmount.toInt();
                  final pointsRedeemed = loyaltyState.pointsToRedeem;
                  final netPoints = pointsEarned - pointsRedeemed;
                  context.read<LoyaltyBloc>().add(AwardPointsEvent(netPoints));
                }
                context.read<LoyaltyBloc>().add(ClearSelectedCustomerEvent());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sale completed!'),
                    backgroundColor: Colors.green));
                context.read<BillingBloc>().add(ClearCartEvent());
                context.go('/');
              }
            },
            builder: (context, billingState) {
              return BlocBuilder<ShopBloc, ShopState>(
                  builder: (context, shopState) {
                String upiId = '';
                String shopName = 'Shop';

                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            // Items Table
                            _buildItemsTable(billingState, borderColor),
                            const SizedBox(height: 16),

                            // Discount & Tax Row
                            _buildDiscountAndTaxSection(context, billingState),
                            const SizedBox(height: 16),

                            // Payment Mode
                            _buildPaymentModeSection(context, billingState),
                            const SizedBox(height: 16),

                            // Loyalty Points Section
                            _buildLoyaltySection(context, billingState),
                            const SizedBox(height: 16),

                            // Total Summary
                            _buildTotalSummary(billingState),
                            const SizedBox(height: 16),

                            // UPI QR
                            if (upiId.isNotEmpty)
                              _buildUpiQr(upiId, shopName, billingState),

                            const SizedBox(height: 120),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Action Bar
                    _buildBottomBar(
                        context, billingState, shopState, upiId, shopName),
                  ],
                );
              });
            },
          ),
        ));
  }

  Widget _buildItemsTable(BillingState state, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE5E5EA)),
            bottom: BorderSide(color: Color(0xFFE5E5EA)),
          ),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _buildHeaderCell('Product Name', TextAlign.left),
                _buildHeaderCell('Price', TextAlign.right),
                _buildHeaderCell('Total', TextAlign.right),
              ],
            ),
            ...state.cartItems.map((item) => TableRow(
                  children: [
                    _buildDataCell(
                        '${item.quantity} x ${item.product.name}',
                        TextAlign.left),
                    _buildDataCell(
                        '₹${item.product.price.toStringAsFixed(2)}',
                        TextAlign.right,
                        isSubtitle: true),
                    _buildDataCell('₹${item.total.toStringAsFixed(2)}',
                        TextAlign.right,
                        isBold: true),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountAndTaxSection(
      BuildContext context, BillingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Discount',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _discountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: _isPercentDiscount ? 'Enter %' : 'Enter ₹',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _applyDiscount(context.read<BillingBloc>()),
                ),
              ),
              const SizedBox(width: 8),
              ToggleButtons(
                isSelected: [!_isPercentDiscount, _isPercentDiscount],
                onPressed: (index) {
                  setState(() => _isPercentDiscount = index == 1);
                  _applyDiscount(context.read<BillingBloc>());
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: Theme.of(context).primaryColor,
                selectedBorderColor: Theme.of(context).primaryColor,
                fillColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                constraints:
                    const BoxConstraints(minWidth: 48, minHeight: 44),
                children: const [Text('₹'), Text('%')],
              ),
            ],
          ),
          if (state.taxRate > 0) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tax (${state.taxRate.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontSize: 13)),
                Text('₹${state.taxAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentModeSection(BuildContext context, BillingState state) {
    const modes = ['Cash', 'Card', 'UPI'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Mode',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: modes.map((mode) {
              final selected = state.paymentMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => context
                        .read<BillingBloc>()
                        .add(SetPaymentModeEvent(mode)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(mode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[700])),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltySection(BuildContext context, BillingState billing) {
    return BlocBuilder<LoyaltyBloc, LoyaltyState>(
      builder: (context, loyaltyState) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  const Text('Loyalty Points',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              if (loyaltyState.selectedCustomer == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _loyaltyPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Customer phone number',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: loyaltyState.isLoading
                          ? null
                          : () {
                              final phone =
                                  _loyaltyPhoneController.text.trim();
                              if (phone.isNotEmpty) {
                                context
                                    .read<LoyaltyBloc>()
                                    .add(LookupCustomerEvent(phone));
                              }
                            },
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14)),
                      child: loyaltyState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Find'),
                    ),
                  ],
                ),
                if (loyaltyState.lookupDone &&
                    loyaltyState.selectedCustomer == null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('New customer? ',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          final phone =
                              _loyaltyPhoneController.text.trim();
                          if (phone.isNotEmpty) {
                            context.read<LoyaltyBloc>().add(
                                CreateCustomerEvent(
                                    name: 'Customer', phone: phone));
                          }
                        },
                        child: Text('Register',
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loyaltyState.selectedCustomer!.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(loyaltyState.selectedCustomer!.phone,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                              '${loyaltyState.selectedCustomer!.points} pts',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (loyaltyState.selectedCustomer!.points > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Redeem ${loyaltyState.selectedCustomer!.points} pts = ₹${(loyaltyState.selectedCustomer!.points * kPointsToRupeeRate).toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Switch(
                        value: _redeemPoints,
                        onChanged: (val) {
                          setState(() => _redeemPoints = val);
                          if (val) {
                            context.read<LoyaltyBloc>().add(RedeemPointsEvent(
                                loyaltyState.selectedCustomer!.points));
                            final discount = loyaltyState
                                .selectedCustomer!.points
                                .toDouble() *
                                kPointsToRupeeRate;
                            context.read<BillingBloc>().add(ApplyDiscountEvent(
                                discountType: 'flat', value: discount));
                            _discountController.text =
                                discount.toStringAsFixed(0);
                            _isPercentDiscount = false;
                          } else {
                            context.read<LoyaltyBloc>().add(
                                const RedeemPointsEvent(0));
                            context.read<BillingBloc>().add(
                                const ApplyDiscountEvent(
                                    discountType: 'flat', value: 0));
                            _discountController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ],
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<LoyaltyBloc>()
                        .add(ClearSelectedCustomerEvent());
                    setState(() => _redeemPoints = false);
                  },
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Remove Customer'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[500]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSummary(BillingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', '₹${state.subtotal.toStringAsFixed(2)}'),
          if (state.discountAmount > 0) ...[
            const SizedBox(height: 6),
            _totalRow('Discount',
                '-₹${state.discountAmount.toStringAsFixed(2)}',
                valueColor: Colors.red),
          ],
          if (state.taxAmount > 0) ...[
            const SizedBox(height: 6),
            _totalRow(
                'Tax (${state.taxRate.toStringAsFixed(1)}%)',
                '+₹${state.taxAmount.toStringAsFixed(2)}'),
          ],
          const Divider(height: 20),
          _totalRow(
              'GRAND TOTAL', '₹${state.totalAmount.toStringAsFixed(2)}',
              bold: true, large: true),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool bold = false, bool large = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: large ? 13 : 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[600],
                letterSpacing: bold ? 1.1 : 0)),
        Text(value,
            style: TextStyle(
                fontSize: large ? 22 : 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? (large ? const Color(0xFF0F172A) : null),
                letterSpacing: large ? -0.5 : 0)),
      ],
    );
  }

  Widget _buildUpiQr(
      String upiId, String shopName, BillingState billingState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          const Text('Scan to Pay',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.1)),
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            height: 180,
            child: PrettyQrView.data(
              data:
                  'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BillingState billingState,
      ShopState shopState, String upiId, String shopName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(24), right: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // WhatsApp share button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.share, color: Color(0xFF25D366)),
              onPressed: () =>
                  _shareWhatsApp(billingState, shopState),
              tooltip: 'Share via WhatsApp',
            ),
          ),
          const SizedBox(width: 8),
          // Print button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.print,
                  color: Theme.of(context).primaryColor),
              onPressed: billingState.isPrinting
                  ? null
                  : () {
                      if (shopState is ShopLoaded) {
                        context.read<BillingBloc>().add(PrintReceiptEvent(
                            shopName: shopState.shop.name,
                            address1: shopState.shop.addressLine1,
                            address2: shopState.shop.addressLine2,
                            phone: shopState.shop.phoneNumber,
                            footer: shopState.shop.footerText));
                      }
                    },
              tooltip: 'Print Receipt',
            ),
          ),
          const SizedBox(width: 8),
          // Complete Sale button
          Expanded(
            child: BlocBuilder<LoyaltyBloc, LoyaltyState>(
              builder: (context, loyaltyState) {
                return ElevatedButton.icon(
                  onPressed: billingState.isCheckingOut
                      ? null
                      : () {
                          context.read<BillingBloc>().add(
                                CompleteCheckoutEvent(
                                  customerId:
                                      loyaltyState.selectedCustomer?.id,
                                  pointsEarned:
                                      billingState.totalAmount.toInt(),
                                  pointsRedeemed:
                                      loyaltyState.pointsToRedeem,
                                ),
                              );
                        },
                  icon: billingState.isCheckingOut
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Sale'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}
