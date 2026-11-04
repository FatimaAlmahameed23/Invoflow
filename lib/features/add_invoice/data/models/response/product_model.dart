class ProductModel {
  const ProductModel({
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
  final num unitPrice;
  final num taxRate;
  final bool taxInclusive;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final barcode = json['barcode'];
    final unitPrice = json['unit_price'];
    final taxRate = json['tax_rate'];
    final taxInclusive = json['tax_inclusive'];

    if (id is! String ||
        name is! String ||
        (barcode != null && barcode is! String) ||
        unitPrice is! num ||
        taxRate is! num ||
        taxInclusive is! bool) {
      throw const FormatException('The API returned an invalid product.');
    }

    return ProductModel(
      id: id,
      name: name,
      barcode: barcode as String?,
      unitPrice: unitPrice,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
    );
  }
}
