import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/add_invoice/presentation/cubit/add_invoice_cubit.dart';
import 'package:invoflow/features/add_invoice/presentation/widgets/product_picker_sheet.dart';
import 'barcode_scanner_page.dart';
import 'package:invoflow/core/widgets/app_app_bar.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  static const _currencies = ['JOD', 'USD', 'EUR'];
  static const _purple = Color(0xFF92257E);

  final Map<String, TextEditingController> _quantityControllers = {};

  AddInvoiceCubit get _cubit => context.read<AddInvoiceCubit>();
  String get _currency => _cubit.state.currency;
  bool get _isSaving => _cubit.state.isSaving;
  bool get _isLoadingProducts => _cubit.state.isLoadingProducts;

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _showProductPicker() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductPickerSheet(
        products: _cubit.state.products,
        currency: _currency,
      ),
    );
    if (product != null && mounted) _cubit.addProduct(product);
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );
    if (barcode == null || !mounted) return;

    _cubit.addBarcode(barcode);
  }

  String _moneyCents(int cents) =>
      '$_currency ${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddInvoiceCubit, AddInvoiceState>(
      listener: (context, state) {
        if (state.isCreated) {
          Navigator.of(context).pop(true);
        } else if (state.message != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        final invoiceTotals = state.totals;
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
                      (currency) => DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      ),
                    )
                    .toList(),
                onChanged: _isSaving
                    ? null
                    : (currency) {
                        if (currency == null) return;
                        _cubit.changeCurrency(currency);
                      },
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
              if (state.errorMessage != null && state.products.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
                TextButton(
                  onPressed: _isLoadingProducts ? null : _cubit.loadProducts,
                  child: const Text('Try again'),
                ),
              ],
              if (!_isLoadingProducts &&
                  state.errorMessage == null &&
                  state.products.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('No products are available in your catalog.'),
                ),
              for (final product in state.products)
                if (state.quantities.containsKey(product.id))
                  _buildInvoiceItem(product),
              const SizedBox(height: 18),
              _summaryRow('Subtotal', _moneyCents(invoiceTotals.subtotalCents)),
              const SizedBox(height: 10),
              _summaryRow('Tax', _moneyCents(invoiceTotals.taxCents)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
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
              if (state.errorMessage != null && state.products.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
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
                  onPressed:
                      _isSaving || _isLoadingProducts || !state.hasInvoiceItems
                      ? null
                      : _cubit.saveInvoice,
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
      },
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
    final value = _cubit.state.quantities[product.id]!;
    final controller = _quantityControllers.putIfAbsent(
      product.id,
      () => TextEditingController(text: value),
    );
    if (controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    final line = _cubit.state.lineFor(product);

    return Container(
      key: ValueKey(product.id),
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
                    : () => _cubit.removeProduct(product.id),
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
                  onChanged: (value) =>
                      _cubit.updateQuantity(product.id, value),
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
