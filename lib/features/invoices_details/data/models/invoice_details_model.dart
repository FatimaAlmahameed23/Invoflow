import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';

class InvoiceDetailsModel extends InvoiceDetails {
  const InvoiceDetailsModel({
    required super.id,
    required super.invoiceNumber,
    required super.status,
    required super.currency,
    required super.subtotal,
    required super.taxTotal,
    required super.grandTotal,
    required super.createdAt,
    required super.customerName,
    required super.items,
  });

  factory InvoiceDetailsModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final invoiceNumber = json['invoice_number'];
    final status = json['status'];
    final currency = json['currency'];
    final subtotal = json['subtotal'];
    final taxTotal = json['tax_total'];
    final grandTotal = json['grand_total'];
    final createdAt = json['created_at'];
    final customerName =
        json['customer_name'] ?? json['client_name'] ?? json['customer'];
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
        (rawItems != null && rawItems is! List)) {
      throw const FormatException('The API returned invalid invoice details.');
    }

    final items = rawItems == null
        ? const <InvoiceDetailsItem>[]
        : (rawItems as List).map(_parseItem).toList(growable: false);

    return InvoiceDetailsModel(
      id: id,
      invoiceNumber: invoiceNumber as String?,
      status: InvoiceStatus.fromApi(status),
      currency: currency,
      subtotal: subtotal.toDouble(),
      taxTotal: taxTotal.toDouble(),
      grandTotal: grandTotal.toDouble(),
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt),
      customerName: customerName as String?,
      items: items,
    );
  }

  static InvoiceDetailsItem _parseItem(dynamic value) {
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

    return InvoiceDetailsItem(
      name: name,
      quantity: quantity.toDouble(),
      unitPrice: unitPrice.toDouble(),
      taxRate: taxRate.toDouble(),
      taxInclusive: taxInclusive,
      subtotal: subtotal.toDouble(),
      taxAmount: taxAmount.toDouble(),
      total: total.toDouble(),
    );
  }
}
