import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';

class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.status,
    required super.currency,
    required super.subtotal,
    required super.taxTotal,
    required super.grandTotal,
    required super.createdAt,
  });

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
      status: InvoiceStatus.fromApi(status),
      currency: currency,
      subtotal: subtotal.toDouble(),
      taxTotal: taxTotal.toDouble(),
      grandTotal: grandTotal.toDouble(),
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt),
    );
  }
}
