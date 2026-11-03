import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';

class Invoice {
  const Invoice({
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
  final InvoiceStatus status;
  final String currency;
  final double subtotal;
  final double taxTotal;
  final double grandTotal;
  final DateTime? createdAt;
}
