import 'package:invoflow/features/add_invoice/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.barcode,
    required super.unitPrice,
    required super.taxRate,
    required super.taxInclusive,
  });

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
      unitPrice: unitPrice.toDouble(),
      taxRate: taxRate.toDouble(),
      taxInclusive: taxInclusive,
    );
  }
}
