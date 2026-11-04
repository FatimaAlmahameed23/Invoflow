part of 'add_invoice_cubit.dart';

class AddInvoiceState {
  const AddInvoiceState({
    this.currency = 'JOD',
    this.products = const [],
    this.quantities = const {},
    this.isLoadingProducts = true,
    this.isSaving = false,
    this.isCreated = false,
    this.errorMessage,
    this.message,
  });

  final String currency;
  final List<Product> products;
  final Map<String, String> quantities;
  final bool isLoadingProducts;
  final bool isSaving;
  final bool isCreated;
  final String? errorMessage;
  final String? message;

  double quantityFor(Product product) {
    final value = double.tryParse(quantities[product.id] ?? '');
    return value != null && value.isFinite && value > 0 ? value : 0;
  }

  bool get hasInvoiceItems =>
      products.any((product) => quantityFor(product) > 0);

  InvoiceTaxCalculation lineFor(Product product) =>
      InvoiceTaxCalculator.calculate(
        unitPrice: quantityFor(product) > 0 ? product.unitPrice : 0,
        quantity: quantityFor(product) > 0 ? quantityFor(product) : 1,
        taxRate: product.taxRate,
        taxInclusive: product.taxInclusive,
      );

  InvoiceTaxTotals get totals => InvoiceTaxCalculator.calculateInvoice(
    products
        .where((product) => quantityFor(product) > 0)
        .map(
          (product) => InvoiceTaxLine(
            unitPrice: product.unitPrice,
            quantity: quantityFor(product),
            taxRate: product.taxRate,
            taxInclusive: product.taxInclusive,
          ),
        ),
  );

  AddInvoiceState copyWith({
    String? currency,
    List<Product>? products,
    Map<String, String>? quantities,
    bool? isLoadingProducts,
    bool? isSaving,
    bool? isCreated,
    String? errorMessage,
    String? message,
  }) => AddInvoiceState(
    currency: currency ?? this.currency,
    products: products ?? this.products,
    quantities: quantities ?? this.quantities,
    isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
    isSaving: isSaving ?? this.isSaving,
    isCreated: isCreated ?? this.isCreated,
    errorMessage: errorMessage,
    message: message,
  );
}
