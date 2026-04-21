import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scanQR(List<Product> products) async {
    final barcode = await context.push<String>('/scanner');
    if (barcode != null && barcode.isNotEmpty) {
      final match = products.where((p) => p.barcode == barcode).firstOrNull;
      _searchController.text = match?.name ?? barcode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('Products'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products…',
                        prefixIcon: const Icon(Icons.search,
                            color: AppTheme.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: AppTheme.textSecondary, size: 18),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner,
                          color: AppTheme.primaryColor, size: 22),
                      onPressed: () => _scanQR(state.products),
                      tooltip: 'Scan barcode',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product list
          Expanded(
            child: BlocConsumer<ProductBloc, ProductState>(
              listener: (context, state) {
                if (state.status == ProductStatus.success &&
                    state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message!),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                } else if (state.status == ProductStatus.error &&
                    state.message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.message!),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                }
              },
              builder: (context, state) {
                if (state.status == ProductStatus.loading &&
                    state.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.products.isEmpty) {
                  return _buildEmptyState(state.status == ProductStatus.error
                      ? (state.message ?? 'An error occurred')
                      : null);
                }

                final filtered = state.products
                    .where((p) =>
                        p.name.toLowerCase().contains(_searchQuery) ||
                        p.barcode.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState('No products match "$_searchQuery"');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _buildProductCard(context, filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/products/add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('Add Product',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildEmptyState(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 32, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
                message != null
                    ? message
                    : 'No products yet',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.center),
            if (message == null) ...[
              const SizedBox(height: 6),
              const Text('Tap + to add your first product',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: InkWell(
        onTap: () => context.push('/products/edit/${product.id}', extra: product),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  product.name.isNotEmpty
                      ? product.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text('₹${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primaryColor)),
                        const SizedBox(width: 8),
                        _buildStockBadge(product.stock),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(product.barcode,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.textSecondary, size: 20),
                onPressed: () => _confirmDelete(context, product),
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock) {
    final Color bg;
    final Color fg;
    final String label;
    if (stock <= 0) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade600;
      label = 'Out of stock';
    } else if (stock <= 5) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade700;
      label = 'Low: $stock';
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      label = '$stock in stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content:
            Text('Remove "${product.name}" from your catalog?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<ProductBloc>().add(DeleteProduct(product.id));
              Navigator.pop(ctx);
            },
            child: Text('Delete',
                style: TextStyle(color: Colors.red.shade600,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
