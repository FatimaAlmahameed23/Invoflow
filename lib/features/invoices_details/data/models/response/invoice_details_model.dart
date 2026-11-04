class InvoiceDetailsModel {
  const InvoiceDetailsModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.createdAt,
    required this.customerName,
    this.clientName,
    this.customer,
    required this.items,
  });

  final String id;
  final String? invoiceNumber;
  final String status;
  final String currency;
  final num subtotal;
  final num taxTotal;
  final num grandTotal;
  final String? createdAt;
  final String? customerName;
  final String? clientName;
  final String? customer;
  final List<InvoiceDetailsItemModel> items;

  factory InvoiceDetailsModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final invoiceNumber = json['invoice_number'];
    final status = json['status'];
    final currency = json['currency'];
    final subtotal = json['subtotal'];
    final taxTotal = json['tax_total'];
    final grandTotal = json['grand_total'];
    final createdAt = json['created_at'];
    final customerName = json['customer_name'];
    final clientName = json['client_name'];
    final customer = json['customer'];
    final rawItems = json['items'];

    if (id is! String ||
        status is! String ||
        currency is! String ||
        subtotal is! num ||
        taxTotal is! num ||
        grandTotal is! num ||
        (invoiceNumber != null && invoiceNumber is! String) ||
        (createdAt != null && createdAt is! String) ||
        (customerName != null && customerName is! String) ||
        (clientName != null && clientName is! String) ||
        (customer != null && customer is! String) ||
        (rawItems != null && rawItems is! List)) {
      throw const FormatException('The API returned invalid invoice details.');
    }

    final items = rawItems == null
        ? const <InvoiceDetailsItemModel>[]
        : (rawItems as List).map(_parseItem).toList(growable: false);

    return InvoiceDetailsModel(
      id: id,
      invoiceNumber: invoiceNumber as String?,
      status: status,
      currency: currency,
      subtotal: subtotal,
      taxTotal: taxTotal,
      grandTotal: grandTotal,
      createdAt: createdAt as String?,
      customerName: customerName as String?,
      clientName: clientName as String?,
      customer: customer as String?,
      items: items,
    );
  }

  static InvoiceDetailsItemModel _parseItem(dynamic value) {
    if (value is! Map) {
      throw const FormatException('The API returned an invalid invoice item.');
    }
    final json = Map<String, dynamic>.from(value);
    final name = json['product_name'];
    final quantity = json['quantity'];
    final unitPrice = json['unit_price'];
    final taxRate = json['tax_rate'];
    final taxInclusive = json['tax_inclusive'];
    final subtotal = json['subtotal'];
    final taxAmount = json['tax_amount'];
    final total = json['line_total'];

    if (name is! String ||
        quantity is! num ||
        unitPrice is! num ||
        taxRate is! num ||
        taxInclusive is! bool ||
        subtotal is! num ||
        taxAmount is! num ||
        total is! num) {
      throw const FormatException('The API returned an invalid invoice item.');
    }

    return InvoiceDetailsItemModel(
      productName: name,
      quantity: quantity,
      unitPrice: unitPrice,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
      subtotal: subtotal,
      taxAmount: taxAmount,
      lineTotal: total,
    );
  }
}

class InvoiceDetailsItemModel {
  const InvoiceDetailsItemModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.taxInclusive,
    required this.subtotal,
    required this.taxAmount,
    required this.lineTotal,
  });

  final String productName;
  final num quantity;
  final num unitPrice;
  final num taxRate;
  final bool taxInclusive;
  final num subtotal;
  final num taxAmount;
  final num lineTotal;
}
