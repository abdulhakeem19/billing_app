import 'package:billing_app/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../bloc/product_bloc.dart';
import '../../domain/entities/product.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_validators.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _barcode = '';
  double _price = 0.0;
  int _stock = 0;

  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() => _barcode = result);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final exists = context
          .read<ProductBloc>()
          .state
          .products
          .any((p) => p.barcode == _barcode);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Barcode "$_barcode" already exists!'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
        return;
      }

      context.read<ProductBloc>().add(AddProduct(Product(
            id: const Uuid().v4(),
            name: _name,
            barcode: _barcode,
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
        title: const Text('Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Barcode'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey(_barcode),
                        initialValue: _barcode,
                        decoration: const InputDecoration(
                            hintText: 'Enter or scan barcode'),
                        validator:
                            AppValidators.barcode,
                        onSaved: (v) => _barcode = v!.trim(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _scanButton(),
                  ],
                ),
                _hint('Tap the camera icon to scan'),
                const SizedBox(height: 20),
                _sectionLabel('Product Name'),
                TextFormField(
                  decoration: const InputDecoration(hintText: 'e.g. Basmati Rice'),
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.name(),
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                hintText: '0.00', prefixText: '₹ '),
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
                            keyboardType: TextInputType.number,
                            initialValue: '0',
                            decoration:
                                const InputDecoration(suffixText: 'units'),
                            validator: AppValidators.stock,
                            onSaved: (v) =>
                                _stock = int.tryParse(v!) ?? 0,
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
        icon: Icons.add_circle_outline,
        label: 'Add Product',
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

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary)),
    );
  }

  Widget _scanButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
        onPressed: _scanBarcode,
        tooltip: 'Scan barcode',
      ),
    );
  }
}
