import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;
  late int _stock;

  @override
  void initState() {
    super.initState();
    _name = widget.product.name;
    _price = widget.product.price;
    _stock = widget.product.stock;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      context.read<ProductBloc>().add(UpdateProduct(Product(
            id: widget.product.id,
            name: _name,
            barcode: widget.product.barcode,
            price: _price,
            stock: _stock,
          )));
      context.pop();
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
        title: const Text('Edit Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immutable barcode display
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_scanner,
                          color: AppTheme.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BARCODE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text(widget.product.barcode,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace')),
                        ],
                      ),
                    ],
                  ),
                ),

                _sectionLabel('Product Name'),
                TextFormField(
                  initialValue: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.required('Please enter a name'),
                  onSaved: (v) => _name = v!.trim(),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Price (₹)'),
                          TextFormField(
                            initialValue: _price.toStringAsFixed(2),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            decoration:
                                const InputDecoration(prefixText: '₹ '),
                            validator: AppValidators.price,
                            onSaved: (v) => _price = double.parse(v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Stock'),
                          TextFormField(
                            initialValue: '${widget.product.stock}',
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(suffixText: 'units'),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              final n = int.tryParse(v);
                              if (n == null || n < 0) return 'Invalid';
                              return null;
                            },
                            onSaved: (v) => _stock = int.tryParse(v!) ?? 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: PrimaryButton(
        onPressed: _submit,
        icon: Icons.save_outlined,
        label: 'Save Changes',
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary)),
    );
  }
}
