import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';

class InvoiceDetailsItem {
  const InvoiceDetailsItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.taxRate,
    required this.taxInclusive,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double taxRate;
  final bool taxInclusive;
  final double subtotal;
  final double taxAmount;
  final double total;
}

class InvoiceDetails {
  const InvoiceDetails({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.currency,
    required this.subtotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.createdAt,
    required this.customerName,
    required this.items,
  });

  final String id;
  final String? invoiceNumber;
  final InvoiceStatus status;
  final String currency;
  final double subtotal;
  final double taxTotal;
  final double grandTotal;
  final DateTime? createdAt;
  final String? customerName;
  final List<InvoiceDetailsItem> items;

  String get taxMode {
    final modes = items.map((item) => item.taxInclusive).toSet();
    if (modes.length > 1) return 'Mixed';
    if (modes.isEmpty) return 'Not available';
    return modes.single ? 'Inclusive' : 'Exclusive';
  }

  String get taxRateLabel {
    final rates = items.map((item) => item.taxRate).toSet();
    if (rates.isEmpty) return 'Tax';
    if (rates.length > 1) return 'Tax';
    return 'Tax (${rates.single.toStringAsFixed(rates.single % 1 == 0 ? 0 : 2)}%)';
  }
}
