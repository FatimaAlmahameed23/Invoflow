import 'dart:convert';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/create_invoice_use_case.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/get_products_use_case.dart';
import 'package:invoflow/features/invoice/domain/services/invoice_tax_calculator.dart';

part 'add_invoice_state.dart';

class AddInvoiceCubit extends Cubit<AddInvoiceState> {
  AddInvoiceCubit({
    required GetProductsUseCase getProducts,
    required CreateInvoiceUseCase createInvoice,
  }) : _getProducts = getProducts,
       _createInvoice = createInvoice,
       super(const AddInvoiceState());

  final GetProductsUseCase _getProducts;
  final CreateInvoiceUseCase _createInvoice;
  int _loadVersion = 0;
  String? _pendingSignature;
  String? _pendingKey;

  Future<void> loadProducts() async {
    if (state.isSaving || state.isCreated) return;
    final version = ++_loadVersion;
    final currency = state.currency;
    emit(state.copyWith(isLoadingProducts: true));
    try {
      final products = await _getProducts(currency: currency);
      if (isClosed || version != _loadVersion) return;
      final ids = products.map((product) => product.id).toSet();
      emit(
        state.copyWith(
          products: List.unmodifiable(products),
          quantities: Map.unmodifiable(
            Map.of(state.quantities)..removeWhere((id, _) => !ids.contains(id)),
          ),
          isLoadingProducts: false,
        ),
      );
    } catch (error) {
      if (isClosed || version != _loadVersion) return;
      // Do not display prices from a different currency after a failed reload.
      emit(
        state.copyWith(
          products: const [],
          isLoadingProducts: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> changeCurrency(String currency) async {
    if (state.isSaving ||
        state.isCreated ||
        currency == state.currency ||
        !['JOD', 'USD', 'EUR'].contains(currency)) {
      return;
    }
    emit(
      state.copyWith(
        currency: currency,
        products: const [],
        isLoadingProducts: true,
      ),
    );
    await loadProducts();
  }

  void addProduct(Product product) {
    if (state.isSaving ||
        state.isLoadingProducts ||
        state.isCreated ||
        !state.products.any((item) => item.id == product.id)) {
      return;
    }
    final quantity = state.quantityFor(product) + 1;
    final text = quantity == quantity.truncateToDouble()
        ? quantity.toInt().toString()
        : quantity.toString();
    emit(
      state.copyWith(
        quantities: Map.unmodifiable({...state.quantities, product.id: text}),
      ),
    );
  }

  void updateQuantity(String productId, String value) {
    if (state.isSaving ||
        state.isLoadingProducts ||
        state.isCreated ||
        !state.quantities.containsKey(productId)) {
      return;
    }
    emit(
      state.copyWith(
        quantities: Map.unmodifiable({...state.quantities, productId: value}),
      ),
    );
  }

  void removeProduct(String productId) {
    if (state.isSaving || state.isLoadingProducts || state.isCreated) return;
    emit(
      state.copyWith(
        quantities: Map.unmodifiable(
          Map.of(state.quantities)..remove(productId),
        ),
      ),
    );
  }

  void addBarcode(String barcode) {
    if (state.isSaving || state.isLoadingProducts || state.isCreated) return;
    for (final product in state.products) {
      if (product.barcode == barcode) {
        addProduct(product);
        return;
      }
    }
    emit(
      state.copyWith(message: 'No catalog product found for barcode $barcode.'),
    );
  }

  Future<void> saveInvoice() async {
    if (state.isSaving || state.isLoadingProducts || state.isCreated) return;
    final items = <Map<String, dynamic>>[];
    for (final product in state.products) {
      final value = state.quantities[product.id]?.trim() ?? '';
      if (value.isEmpty) continue;
      final quantity = double.tryParse(value);
      if (quantity == null ||
          !quantity.isFinite ||
          quantity <= 0 ||
          quantity > 999999 ||
          !RegExp(r'^\d+(?:\.\d{0,3})?$').hasMatch(value)) {
        emit(
          state.copyWith(
            message: 'Enter a valid quantity for ${product.name}.',
          ),
        );
        return;
      }
      items.add({'product_id': product.id, 'quantity': quantity});
    }
    if (items.isEmpty) {
      emit(state.copyWith(message: 'Add at least one item to the invoice.'));
      return;
    }
    final signature = jsonEncode({'currency': state.currency, 'items': items});
    if (_pendingSignature != signature || _pendingKey == null) {
      _pendingSignature = signature;
      final random = Random.secure();
      _pendingKey = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    }
    emit(state.copyWith(isSaving: true));
    try {
      await _createInvoice(
        currency: state.currency,
        items: items,
        idempotencyKey: _pendingKey!,
      );
      if (isClosed) return;
      _pendingSignature = null;
      _pendingKey = null;
      emit(state.copyWith(isSaving: false, isCreated: true));
    } catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isSaving: false, errorMessage: error.toString()));
    }
  }
}
