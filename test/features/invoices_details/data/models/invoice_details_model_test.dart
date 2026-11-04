import 'package:flutter_test/flutter_test.dart';
import 'package:invoflow/features/invoices_details/data/models/response/invoice_details_model.dart';

void main() {
  test(
    'parses invoice details including deleted status and item tax settings',
    () {
      final invoice = InvoiceDetailsModel.fromJson({
        'id': 'invoice-uuid',
        'invoice_number': 'INV-0014',
        'status': 'deleted',
        'currency': 'JOD',
        'subtotal': 850,
        'tax_total': 127.5,
        'grand_total': 977.5,
        'created_at': '2025-01-28T12:00:00Z',
        'client_name': 'Smart Solutions',
        'items': [
          {
            'product_name': 'Website Design',
            'quantity': 1,
            'unit_price': 700,
            'tax_rate': 15,
            'tax_inclusive': false,
            'subtotal': 700,
            'tax_amount': 105,
            'line_total': 805,
          },
          {
            'product_name': 'Maintenance',
            'quantity': 1,
            'unit_price': 150,
            'tax_rate': 15,
            'tax_inclusive': false,
            'subtotal': 150,
            'tax_amount': 22.5,
            'line_total': 172.5,
          },
        ],
      });

      expect(invoice.id, 'invoice-uuid');
      expect(invoice.status, 'deleted');
      expect(invoice.clientName, 'Smart Solutions');
      expect(invoice.customerName, isNull);
      expect(invoice.createdAt, '2025-01-28T12:00:00Z');
      expect(invoice.items, hasLength(2));
      expect(invoice.items.first.lineTotal, 805);
      expect(invoice.grandTotal, 977.5);
    },
  );
}
