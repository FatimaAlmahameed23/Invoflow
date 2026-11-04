class InvoiceModel {
  const InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.createdAt,
  });

  final String id;
  final String? invoiceNumber;
  final String status;
  final String currency;
  final num subtotal;
  final num taxTotal;
  final num grandTotal;
  final String? createdAt;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final status = json['status'];
    final currency = json['currency'];
    final subtotal = json['subtotal'];
    final taxTotal = json['tax_total'];
    final grandTotal = json['grand_total'];
    final invoiceNumber = json['invoice_number'];
    final createdAt = json['created_at'];

    if (id is! String ||
        status is! String ||
        currency is! String ||
        subtotal is! num ||
        taxTotal is! num ||
        grandTotal is! num ||
        (invoiceNumber != null && invoiceNumber is! String) ||
        (createdAt != null && createdAt is! String)) {
      throw const FormatException('The API returned an invalid invoice.');
    }

    return InvoiceModel(
      id: id,
      invoiceNumber: invoiceNumber as String?,
      status: status,
      currency: currency,
      subtotal: subtotal,
      taxTotal: taxTotal,
      grandTotal: grandTotal,
      createdAt: createdAt as String?,
    );
  }
}
