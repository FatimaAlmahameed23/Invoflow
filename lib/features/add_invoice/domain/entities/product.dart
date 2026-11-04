class Product {
  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.unitPrice,
    required this.taxRate,
    required this.taxInclusive,
  });

  final String id;
  final String name;
  final String? barcode;
  final double unitPrice;
  final double taxRate;
  final bool taxInclusive;
}
