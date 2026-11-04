import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/get_products_use_case.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/create_invoice_use_case.dart';
import 'package:invoflow/features/add_invoice/presentation/widgets/product_picker_sheet.dart';
import 'barcode_scanner_page.dart';
import 'package:invoflow/core/widgets/app_app_bar.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/invoice/domain/services/invoice_tax_calculator.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({
    super.key,
    required this.getProducts,
    required this.createInvoice,
  });

  final GetProductsUseCase getProducts;
  final CreateInvoiceUseCase createInvoice;

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  static const _currencies = ['JOD', 'USD', 'EUR'];
  static const _purple = Color(0xFF92257E);

  String _currency = 'JOD';
  List<Product> _products = [];
  final Map<String, TextEditingController> _quantityControllers = {};
  bool _isLoadingProducts = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _pendingCreateSignature;
  String? _pendingIdempotencyKey;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _errorMessage = null;
    });

    try {
      final products = await widget.getProducts(currency: _currency);
      if (!mounted) return;
      final productIds = products.map((product) => product.id).toSet();
      for (final id in _quantityControllers.keys.toList()) {
        if (!productIds.contains(id)) {
          _quantityControllers.remove(id)?.dispose();
        }
      }
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoadingProducts = false;
      });
    }
  }

  void _addProduct(Product product) {
    final controller = _quantityControllers[product.id];
    if (controller == null) {
      _quantityControllers[product.id] = TextEditingController(text: '1');
    } else {
      final quantity = double.tryParse(controller.text) ?? 0;
      controller.text = _formatQuantity(quantity + 1);
    }
    setState(() {});
  }

  String _formatQuantity(double quantity) {
    return quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
  }

  InvoiceTaxTotals get _invoiceTotals => InvoiceTaxCalculator.calculateInvoice(
    _products
        .map((product) {
          final quantity = _quantityFor(product);
          return InvoiceTaxLine(
            unitPrice: product.unitPrice,
            quantity: quantity,
            taxRate: product.taxRate,
            taxInclusive: product.taxInclusive,
          );
        })
        .where((line) => line.quantity > 0),
  );

  bool get _hasInvoiceItems => _quantityControllers.values.any((controller) {
    final quantity = double.tryParse(controller.text);
    return quantity != null && quantity > 0;
  });

  double _quantityFor(Product product) {
    return double.tryParse(_quantityControllers[product.id]?.text ?? '') ?? 0;
  }

  InvoiceTaxCalculation _calculateLine(Product product, double quantity) {
    return InvoiceTaxCalculator.calculate(
      unitPrice: product.unitPrice,
      quantity: quantity,
      taxRate: product.taxRate,
      taxInclusive: product.taxInclusive,
    );
  }

  Future<void> _showProductPicker() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ProductPickerSheet(products: _products, currency: _currency),
    );
    if (product != null && mounted) _addProduct(product);
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (barcode == null || !mounted) return;

    Product? product;
    for (final candidate in _products) {
      if (candidate.barcode == barcode) {
        product = candidate;
        break;
      }
    }
    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No catalog product found for barcode $barcode.'),
        ),
      );
      return;
    }
    _addProduct(product);
  }

  Future<void> _createInvoice() async {
    final items = <Map<String, dynamic>>[];
    for (final product in _products) {
      final value = _quantityControllers[product.id]?.text.trim() ?? '';
      if (value.isEmpty) continue;

      final quantity = double.tryParse(value);
      if (quantity == null ||
          !quantity.isFinite ||
          quantity <= 0 ||
          quantity > 999999) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enter a valid quantity for ${product.name}.'),
          ),
        );
        return;
      }

      items.add({'product_id': product.id, 'quantity': quantity});
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to the invoice.')),
      );
      return;
    }

    final requestSignature = jsonEncode({
      'currency': _currency,
      'items': items,
    });
    if (_pendingCreateSignature != requestSignature ||
        _pendingIdempotencyKey == null) {
      _pendingCreateSignature = requestSignature;
      _pendingIdempotencyKey = _newIdempotencyKey();
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await widget.createInvoice(
        currency: _currency,
        items: items,
        idempotencyKey: _pendingIdempotencyKey!,
      );
      if (!mounted) return;
      _pendingCreateSignature = null;
      _pendingIdempotencyKey = null;
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isSaving = false;
      });
    }
  }

  String _newIdempotencyKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  String _moneyCents(int cents) =>
      '$_currency ${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final invoiceTotals = _invoiceTotals;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: const AppAppBar(title: 'Create Invoice'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _sectionLabel('Currency'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_currency),
            value: _currency,
            decoration: _fieldDecoration(),
            items: _currencies
                .map(
                  (currency) =>
                      DropdownMenuItem(value: currency, child: Text(currency)),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (currency) {
                    if (currency == null) return;
                    setState(() => _currency = currency);
                    _loadProducts();
                  },
          ),
          const SizedBox(height: 22),
          _sectionLabel('Tax Mode'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _purple, size: 20),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Tax is calculated using each product’s settings.',
                    style: TextStyle(color: _purple, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _sectionLabel('Items')),
              IconButton(
                tooltip: 'Scan barcode',
                onPressed: _isSaving || _isLoadingProducts
                    ? null
                    : _scanBarcode,
                icon: const Icon(
                  Icons.document_scanner_outlined,
                  color: _purple,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving || _isLoadingProducts
                  ? null
                  : _showProductPicker,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5E9F2),
                foregroundColor: _purple,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_isLoadingProducts)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null && _products.isEmpty) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: _isLoadingProducts ? null : _loadProducts,
              child: const Text('Try again'),
            ),
          ],
          if (!_isLoadingProducts && _errorMessage == null && _products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text('No products are available in your catalog.'),
            ),
          for (final product in _products)
            if (_quantityControllers.containsKey(product.id))
              _buildInvoiceItem(product),
          const SizedBox(height: 18),
          _summaryRow('Subtotal', _moneyCents(invoiceTotals.subtotalCents)),
          const SizedBox(height: 10),
          _summaryRow('Tax', _moneyCents(invoiceTotals.taxCents)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _summaryRow(
              'Total',
              _moneyCents(invoiceTotals.totalCents),
              emphasized: true,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Preview rounds each item to 2 decimals. The backend rounds saved item and invoice totals to 3 decimals; small differences are possible, and saved backend totals are authoritative.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          if (_errorMessage != null && _products.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0E5ED))),
          ),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving || _isLoadingProducts || !_hasInvoiceItems
                  ? null
                  : _createInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );
  }

  InputDecoration _fieldDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6D3E2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE6D3E2)),
    ),
  );

  Widget _buildInvoiceItem(Product product) {
    final controller = _quantityControllers[product.id]!;
    final quantity = double.tryParse(controller.text) ?? 0;
    final line = _calculateLine(product, quantity);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0E5ED)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                _moneyCents(line.totalCents),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              IconButton(
                tooltip: 'Remove item',
                visualDensity: VisualDensity.compact,
                onPressed: _isSaving
                    ? null
                    : () {
                        _quantityControllers.remove(product.id)?.dispose();
                        setState(() {});
                      },
                icon: const Icon(Icons.close, size: 19),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${product.taxInclusive ? 'Inclusive' : 'Exclusive'} tax · ${product.taxRate.toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ),
              SizedBox(
                width: 92,
                child: TextField(
                  controller: controller,
                  enabled: !_isSaving,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,3}'),
                    ),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration().copyWith(
                    labelText: 'Quantity',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 9,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Subtotal ${_moneyCents(line.subtotalCents)} · Tax ${_moneyCents(line.taxCents)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasized = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 16 : 14,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: emphasized ? _purple : null,
          ),
        ),
      ],
    );
  }
}
