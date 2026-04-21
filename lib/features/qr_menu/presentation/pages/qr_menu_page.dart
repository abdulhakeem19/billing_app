import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';

class QrMenuPage extends StatefulWidget {
  const QrMenuPage({super.key});

  @override
  State<QrMenuPage> createState() => _QrMenuPageState();
}

class _QrMenuPageState extends State<QrMenuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital QR Menu'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Full Menu'),
            Tab(text: 'Per Product'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFullMenuTab(),
          _buildPerProductTab(),
        ],
      ),
    );
  }

  Widget _buildFullMenuTab() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, productState) {
        return BlocBuilder<ShopBloc, ShopState>(
          builder: (context, shopState) {
            final shopName = shopState is ShopLoaded
                ? shopState.shop.name
                : 'Shop Menu';
            final products = productState.products;

            final menuData = jsonEncode({
              'shop': shopName,
              'menu': products
                  .map((p) => {
                        'name': p.name,
                        'price': p.price,
                        'barcode': p.barcode,
                      })
                  .toList(),
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(
                children: [
                  Text(shopName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text(
                    products.isEmpty
                        ? 'No items in menu'
                        : '${products.length} item${products.length == 1 ? '' : 's'} in menu',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 28),

                  // QR container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.cardDecoration(),
                    child: products.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(Icons.qr_code_2,
                                    size: 60,
                                    color: AppTheme.dividerColor),
                                SizedBox(height: 12),
                                Text(
                                  'Add products to generate menu QR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(
                            width: 220,
                            height: 220,
                            child: PrettyQrView.data(data: menuData),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.primaryColor, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Customers can scan this QR code to view the full menu with prices.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPerProductTab() {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      size: 30, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                const Text('No products yet',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 6),
                const Text('Add products to see their QR codes',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _buildProductQrCard(context, state.products[index]),
        );
      },
    );
  }

  Widget _buildProductQrCard(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text('₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor)),
                const SizedBox(height: 4),
                Text(product.barcode,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontFamily: 'monospace')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showProductQrDialog(context, product),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 76,
                height: 76,
                child: PrettyQrView.data(
                  data: jsonEncode({
                    'id': product.id,
                    'name': product.name,
                    'price': product.price,
                    'barcode': product.barcode,
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductQrDialog(BuildContext context, Product product) {
    final qrData = jsonEncode({
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'barcode': product.barcode,
    });

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('₹${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                  width: 200,
                  height: 200,
                  child: PrettyQrView.data(data: qrData)),
              const SizedBox(height: 12),
              const Text('Scan to add to order',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
