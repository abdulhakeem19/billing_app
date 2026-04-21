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
          icon:
              Icon(Icons.chevron_left, size: 28, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Full Menu QR'),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Shop info header
                  Text(shopName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${products.length} items',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  const SizedBox(height: 24),

                  // QR code
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: products.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No products yet. Add products first.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey)),
                          )
                        : SizedBox(
                            width: 220,
                            height: 220,
                            child: PrettyQrView.data(data: menuData),
                          ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppTheme.primaryColor, size: 18),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Customers can scan this QR to view the full menu with prices.',
                            style: TextStyle(fontSize: 13),
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
          return const Center(
              child: Text('No products yet.',
                  style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = state.products[index];
            return _buildProductQrCard(context, product);
          },
        );
      },
    );
  }

  Widget _buildProductQrCard(BuildContext context, Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 4),
                Text('Barcode: ${product.barcode}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showProductQrDialog(context, product),
            child: SizedBox(
              width: 80,
              height: 80,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text('₹${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                height: 200,
                child: PrettyQrView.data(data: qrData),
              ),
              const SizedBox(height: 16),
              Text('Scan to add to order',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500])),
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
