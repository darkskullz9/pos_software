import 'package:flutter/material.dart';

import '../../data/models/app_settings_model.dart';
import '../../data/services/settings_service.dart';

import 'widgets/string_list_editor.dart';

class SettingsPage extends StatefulWidget {
  final SettingsService settingsService;

  const SettingsPage({super.key, required this.settingsService});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _storeCodeController = TextEditingController();
  final _labelQuantityController = TextEditingController();
  final _receiptFooterController = TextEditingController();

  late String _currency;
  late String _defaultPaymentMethod;
  late String _barcodeFormat;
  late ThemeMode _themeMode;

  late bool _confirmBeforeCheckout;
  late bool _preventNegativeStock;
  late bool _autoGenerateBarcode;

  late List<String> _productTypes;
  late List<String> _subCategories;
  late List<String> _brands;
  late List<String> _colors;
  late List<String> _sizes;
  late List<String> _locations;

  @override
  void initState() {
    super.initState();
    widget.settingsService.addListener(_loadFromService);
    _loadFromService();
  }

  @override
  void dispose() {
    widget.settingsService.removeListener(_loadFromService);

    _storeNameController.dispose();
    _taxRateController.dispose();
    _lowStockController.dispose();
    _storeCodeController.dispose();
    _labelQuantityController.dispose();
    _receiptFooterController.dispose();

    super.dispose();
  }

  void _loadFromService() {
    final settings = widget.settingsService.settings;

    _productTypes = List<String>.from(settings.productTypes);
    _subCategories = List<String>.from(settings.subCategories);
    _brands = List<String>.from(settings.brands);
    _colors = List<String>.from(settings.colors);
    _sizes = List<String>.from(settings.sizes);
    _locations = List<String>.from(settings.locations);

    _storeNameController.text = settings.storeName;
    _taxRateController.text = settings.defaultTaxRate.toString();
    _lowStockController.text = settings.lowStockThreshold.toString();
    _storeCodeController.text = settings.storeCode.toString();
    _labelQuantityController.text = settings.defaultLabelQuantity.toString();
    _receiptFooterController.text = settings.receiptFooter;

    _currency = settings.currency;
    _defaultPaymentMethod = settings.defaultPaymentMethod;
    _barcodeFormat = settings.barcodeFormat;
    _themeMode = settings.themeMode;

    _confirmBeforeCheckout = settings.confirmBeforeCheckout;
    _preventNegativeStock = settings.preventNegativeStock;
    _autoGenerateBarcode = settings.autoGenerateBarcode;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = AppSettingsModel(
      storeName: _storeNameController.text.trim(),
      currency: _currency,
      defaultTaxRate: double.parse(
        _taxRateController.text.trim().replaceAll(',', '.'),
      ),
      defaultPaymentMethod: _defaultPaymentMethod,
      confirmBeforeCheckout: _confirmBeforeCheckout,
      preventNegativeStock: _preventNegativeStock,
      lowStockThreshold: int.parse(_lowStockController.text.trim()),
      autoGenerateBarcode: _autoGenerateBarcode,
      storeCode: int.parse(_storeCodeController.text.trim()),
      defaultLabelQuantity: int.parse(_labelQuantityController.text.trim()),
      receiptFooter: _receiptFooterController.text.trim(),
      barcodeFormat: _barcodeFormat,
      themeMode: _themeMode,
      productTypes: _productTypes,
      subCategories: _subCategories,
      brands: _brands,
      colors: _colors,
      sizes: _sizes,
      locations: _locations,
    );

    await widget.settingsService.saveSettings(settings);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paramètres enregistrés'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Réinitialiser les paramètres'),
          content: const Text(
            'Voulez-vous vraiment restaurer les paramètres par défaut ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Réinitialiser'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await widget.settingsService.resetSettings();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Paramètres réinitialisés')));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.settingsService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        children: [
          _section(
            title: 'Magasin',
            children: [
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Nom du magasin'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom du magasin est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Devise'),
                items: const [
                  DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                  DropdownMenuItem(value: 'USD', child: Text('USD - Dollar')),
                  DropdownMenuItem(value: 'GBP', child: Text('GBP - Livre')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _currency = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxRateController,
                decoration: const InputDecoration(
                  labelText: 'TVA par défaut (%)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final parsed = double.tryParse(
                    value?.trim().replaceAll(',', '.') ?? '',
                  );

                  if (parsed == null) return 'TVA invalide';
                  if (parsed < 0 || parsed > 100) {
                    return 'La TVA doit être entre 0 et 100';
                  }

                  return null;
                },
              ),
            ],
          ),
          _section(
            title: 'Caisse',
            children: [
              DropdownButtonFormField<String>(
                initialValue: _defaultPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Moyen de paiement par défaut',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Carte bancaire',
                    child: Text('Carte bancaire'),
                  ),
                  DropdownMenuItem(value: 'Espèces', child: Text('Espèces')),
                  DropdownMenuItem(value: 'Virement', child: Text('Virement')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _defaultPaymentMethod = value);
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Demander confirmation avant encaissement'),
                value: _confirmBeforeCheckout,
                onChanged: (value) {
                  setState(() => _confirmBeforeCheckout = value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bloquer les ventes si stock insuffisant'),
                value: _preventNegativeStock,
                onChanged: (value) {
                  setState(() => _preventNegativeStock = value);
                },
              ),
            ],
          ),
          _section(
            title: 'Produits & stock',
            children: [
              TextFormField(
                controller: _lowStockController,
                decoration: const InputDecoration(
                  labelText: 'Seuil stock faible',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');

                  if (parsed == null) return 'Seuil invalide';
                  if (parsed < 0) return 'Le seuil doit être positif';

                  return null;
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Générer les codes-barres automatiquement'),
                value: _autoGenerateBarcode,
                onChanged: (value) {
                  setState(() => _autoGenerateBarcode = value);
                },
              ),
              TextFormField(
                controller: _storeCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code magasin',
                  helperText: 'Utilisé pour générer les codes-barres internes',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');

                  if (parsed == null) return 'Code magasin invalide';
                  if (parsed < 0 || parsed > 99) {
                    return 'Le code magasin doit être entre 0 et 99';
                  }

                  return null;
                },
              ),
            ],
          ),

          _section(
            title: 'Catalogue',
            children: [
              StringListEditor(
                title: 'Types de produits',
                values: _productTypes,
                hintText: 'Ex : Blazer, Legging, Sac...',
                onChanged: (values) {
                  setState(() => _productTypes = values);
                },
              ),

              const SizedBox(height: 20),
              StringListEditor(
                title: 'Sous-catégories',
                values: _subCategories,
                hintText: 'Ex : Chaussures, Accessoires cheveux...',
                onChanged: (values) {
                  setState(() => _subCategories = values);
                },
              ),

              const SizedBox(height: 20),
              StringListEditor(
                title: 'Marques',
                values: _brands,
                hintText: 'Ex : Nike, Levi\'s, Mango...',
                onChanged: (values) {
                  setState(() => _brands = values);
                },
              ),

              const SizedBox(height: 20),
              StringListEditor(
                title: 'Couleurs',
                values: _colors,
                hintText: 'Ex : kaki, doré, argenté...',
                onChanged: (values) {
                  setState(() => _colors = values);
                },
              ),

              const SizedBox(height: 20),
              StringListEditor(
                title: 'Tailles',
                values: _sizes,
                hintText: 'Ex : 50, 52, 54...',
                onChanged: (values) {
                  setState(() => _sizes = values);
                },
              ),

              const SizedBox(height: 20),
              StringListEditor(
                title: 'Emplacements',
                values: _locations,
                hintText: 'Ex : Bac 1, Portant gauche...',
                onChanged: (values) {
                  setState(() => _locations = values);
                },
              ),
            ],
          ),

          _section(
            title: 'Tickets & étiquettes',
            children: [
              TextFormField(
                controller: _labelQuantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité d’étiquettes par défaut',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');

                  if (parsed == null) return 'Quantité invalide';
                  if (parsed <= 0) {
                    return 'La quantité doit être supérieure à 0';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _barcodeFormat,
                decoration: const InputDecoration(
                  labelText: 'Format code-barres',
                ),
                items: const [
                  DropdownMenuItem(value: 'EAN-13', child: Text('EAN-13')),
                  DropdownMenuItem(value: 'Code128', child: Text('Code128')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _barcodeFormat = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _receiptFooterController,
                decoration: const InputDecoration(
                  labelText: 'Message bas de ticket',
                ),
                maxLines: 2,
              ),
            ],
          ),
          _section(
            title: 'Apparence',
            children: [
              DropdownButtonFormField<ThemeMode>(
                initialValue: _themeMode,
                decoration: const InputDecoration(labelText: 'Thème'),
                items: const [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text('Système'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text('Clair'),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text('Sombre'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _themeMode = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetSettings,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Réinitialiser'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
