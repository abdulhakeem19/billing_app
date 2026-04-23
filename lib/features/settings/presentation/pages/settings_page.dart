import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:app_settings/app_settings.dart';

import '../../../../core/data/hive_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/printer_bloc.dart';
import '../bloc/printer_event.dart';
import '../bloc/printer_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PrinterBloc>().add(InitPrinterEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile card
            _buildProfileSection(),
            const SizedBox(height: 24),

            // Management
            _sectionHeader('Management'),
            _buildGroup(children: [
              _item(
                icon: Icons.inventory_2_outlined,
                title: 'Products',
                subtitle: 'Manage stock and barcodes',
                onTap: () => context.push('/products'),
              ),
              _divider(),
              _item(
                icon: Icons.storefront_outlined,
                title: 'Shop Details',
                subtitle: 'Edit business info & address',
                onTap: () => context.push('/shop'),
              ),
              _divider(),
              _item(
                icon: Icons.bar_chart_rounded,
                title: 'Reports & Analytics',
                subtitle: 'Sales history and trends',
                onTap: () => context.push('/reports'),
              ),
              _divider(),
              _item(
                icon: Icons.qr_code_2_rounded,
                title: 'Digital QR Menu',
                subtitle: 'Generate QR codes for your menu',
                onTap: () => context.push('/qr-menu'),
              ),
            ]),
            const SizedBox(height: 24),

            // Billing
            _sectionHeader('Billing'),
            _buildGroup(children: [_buildTaxItem()]),
            const SizedBox(height: 24),

            // Hardware
            _sectionHeader('Hardware'),
            BlocConsumer<PrinterBloc, PrinterState>(
              listener: (context, state) {
                if (state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(12),
                  ));
                } else if (state.status == PrinterStatus.connected) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Printer connected'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              builder: (context, state) => _buildGroup(children: [
                _item(
                  icon: Icons.print_outlined,
                  title: 'Print Device',
                  subtitleWidget: Row(
                    children: [
                      Flexible(
                        child: Text(
                          state.connectedMac != null
                              ? (state.connectedName ?? 'Printer connected')
                              : 'No printer connected',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (state.connectedMac != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Text('CONNECTED',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.teal.shade700)),
                        ),
                      ],
                    ],
                  ),
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.status == PrinterStatus.scanning ||
                          state.status == PrinterStatus.connecting)
                        const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor))
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppTheme.primaryColor, size: 20),
                          onPressed: () => context
                              .read<PrinterBloc>()
                              .add(RefreshPrinterEvent()),
                        ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: AppTheme.textSecondary, size: 20),
                        onPressed: () => AppSettings.openAppSettings(
                            type: AppSettingsType.bluetooth),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'To connect a new device, tap ⚙ to pair via Bluetooth settings, then return and tap ↺ to refresh.',
                style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      color: AppTheme.surfaceColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: BlocBuilder<ShopBloc, ShopState>(builder: (context, state) {
        String shopName = 'My Shop';
        String initials = 'MS';
        if (state.shop != null && state.shop!.name.isNotEmpty) {
          shopName = state.shop!.name;
          final parts = shopName.trim().split(' ');
          initials = parts
              .take(2)
              .map((p) => p.isNotEmpty ? p[0].toUpperCase() : '')
              .join('');
          if (initials.isEmpty) initials = 'S';
        }

        return Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shopName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => context.push('/shop'),
                    child: const Text('Edit shop details →',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return const Divider(
        height: 1, thickness: 1, color: AppTheme.dividerColor, indent: 60);
  }

  Widget _buildTaxItem() {
    final taxRate = _getTaxRate();
    return _item(
      icon: Icons.percent_rounded,
      title: 'Tax Rate',
      subtitle: taxRate > 0
          ? '${taxRate.toStringAsFixed(1)}% applied on orders'
          : 'No tax configured',
      onTap: () => _showTaxDialog(context),
    );
  }

  double _getTaxRate() {
    try {
      return HiveDatabase.settingsBox.get('tax_rate', defaultValue: 0.0)
          as double;
    } catch (_) {
      return 0.0;
    }
  }

  void _showTaxDialog(BuildContext context) {
    final taxRate = _getTaxRate();
    final controller =
        TextEditingController(text: taxRate > 0 ? taxRate.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tax Rate',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter tax percentage (e.g. 5 for 5%)',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                hintText: '0.0',
                suffixText: '%',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 0;
              HiveDatabase.settingsBox.put('tax_rate', val);
              context.read<BillingBloc>().add(SetTaxRateEvent(val));
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Tax rate set to ${val.toStringAsFixed(1)}%'),
                backgroundColor: AppTheme.successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.all(12),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    IconData? trailingIcon = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child:
                  Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 3),
                    subtitleWidget,
                  ],
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailingIcon != null)
              Icon(trailingIcon,
                  color: AppTheme.dividerColor, size: 18),
          ],
        ),
      ),
    );
  }
}
