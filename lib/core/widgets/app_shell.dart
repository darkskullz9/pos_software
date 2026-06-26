import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../data/services/barcode_service.dart';
import '../../data/services/product_service.dart';
import '../../data/services/settings_service.dart';
import '../../features/barcode/barcode_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/pos/pos_page.dart';
import '../../features/products/products_page.dart';
import '../../features/settings/settings_page.dart';
import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  final ProductService productService;
  final BarcodeService barcodeService;
  final SettingsService settingsService;

  const AppShell({
    super.key,
    required this.productService,
    required this.barcodeService,
    required this.settingsService,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;

  final List<String> _titles = const [
    'Tableau de bord',
    'Inventaire',
    'Caisse',
    'Codes-barres',
    'Paramètres',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),

          const VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Text(
                    _titles[selectedIndex],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: IndexedStack(
                      index: selectedIndex,
                      children: [
                        DashboardPage(productService: widget.productService),
                        ProductsPage(productService: widget.productService),
                        PosPage(
                          productService: widget.productService,
                          settingsService: widget.settingsService,
                        ),
                        BarcodePage(productService: widget.productService),
                        SettingsPage(
                          settingsService: widget.settingsService,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
