import 'package:flutter_test/flutter_test.dart';
import 'package:invoflow/features/invoice/data/models/invoice_model.dart';
import 'package:invoflow/features/invoice/domain/services/invoice_tax_calculator.dart';

void main() {
  group('InvoiceTaxCalculator', () {
    test('extracts tax from an inclusive unit price', () {
      final result = InvoiceTaxCalculator.calculate(
        unitPrice: 116,
        quantity: 1,
        taxRate: 16,
        taxInclusive: true,
      );

      expect(result.subtotal, 100);
      expect(result.tax, 16);
      expect(result.total, 116);
    });

    test('adds tax to an exclusive unit price', () {
      final result = InvoiceTaxCalculator.calculate(
        unitPrice: 100,
        quantity: 1,
        taxRate: 16,
        taxInclusive: false,
      );

      expect(result.subtotal, 100);
      expect(result.tax, 16);
      expect(result.total, 116);
    });

    test('supports multiple quantities', () {
      final result = InvoiceTaxCalculator.calculate(
        unitPrice: 116,
        quantity: 2.5,
        taxRate: 16,
        taxInclusive: true,
      );

      expect(result.subtotal, 250);
      expect(result.tax, 40);
      expect(result.total, 290);
    });

    test('handles zero tax', () {
      final inclusive = InvoiceTaxCalculator.calculate(
        unitPrice: 19.99,
        quantity: 1.5,
        taxRate: 0,
        taxInclusive: true,
      );
      final exclusive = InvoiceTaxCalculator.calculate(
        unitPrice: 19.99,
        quantity: 1.5,
        taxRate: 0,
        taxInclusive: false,
      );

      expect(inclusive.subtotal, 29.99);
      expect(inclusive.tax, 0);
      expect(inclusive.total, 29.99);
      expect(exclusive.subtotal, 29.99);
      expect(exclusive.tax, 0);
      expect(exclusive.total, 29.99);
    });

    test('rounds decimal prices and calculated totals to two decimals', () {
      final exclusive = InvoiceTaxCalculator.calculate(
        unitPrice: 19.99,
        quantity: 1.5,
        taxRate: 16,
        taxInclusive: false,
      );
      final inclusive = InvoiceTaxCalculator.calculate(
        unitPrice: 19.99,
        quantity: 1.5,
        taxRate: 16,
        taxInclusive: true,
      );

      expect(exclusive.subtotal, 29.99);
      expect(exclusive.tax, 4.80);
      expect(exclusive.total, 34.79);
      expect(inclusive.subtotal, 25.85);
      expect(inclusive.tax, 4.14);
      expect(inclusive.total, 29.99);
    });

    test('aggregates products with different tax rates and tax types', () {
      final totals = InvoiceTaxCalculator.calculateInvoice([
        const InvoiceTaxLine(
          unitPrice: 116,
          quantity: 1,
          taxRate: 16,
          taxInclusive: true,
        ),
        const InvoiceTaxLine(
          unitPrice: 100,
          quantity: 2,
          taxRate: 10,
          taxInclusive: false,
        ),
        const InvoiceTaxLine(
          unitPrice: 5.555,
          quantity: 2,
          taxRate: 0,
          taxInclusive: false,
        ),
      ]);

      expect(totals.subtotalCents, 31111);
      expect(totals.taxCents, 3600);
      expect(totals.totalCents, 34711);
    });
  });

  test('InvoiceModel keeps backend totals as returned', () {
    final invoice = InvoiceModel.fromJson({
      'id': 'invoice-id',
      'invoice_number': 'INV-0001',
      'status': 'approved',
      'currency': 'JOD',
      'subtotal': 100.123,
      'tax_total': 16.02,
      'grand_total': 116.143,
      'created_at': '2025-01-28T12:00:00Z',
    });

    expect(invoice.createdAt, '2025-01-28T12:00:00Z');
    expect(invoice.subtotal, 100.123);
    expect(invoice.taxTotal, 16.02);
    expect(invoice.grandTotal, 116.143);
  });

  test('InvoiceModel preserves backend status strings', () {
    final approvedInvoice = InvoiceModel.fromJson({
      'id': 'approved-id',
      'invoice_number': 'INV-0002',
      'status': 'approved',
      'currency': 'JOD',
      'subtotal': 100,
      'tax_total': 16,
      'grand_total': 116,
    });
    final deletedInvoice = InvoiceModel.fromJson({
      'id': 'deleted-id',
      'invoice_number': 'INV-0003',
      'status': 'deleted',
      'currency': 'JOD',
      'subtotal': 100,
      'tax_total': 16,
      'grand_total': 116,
    });

    expect(approvedInvoice.status, 'approved');
    expect(deletedInvoice.status, 'deleted');
  });
}
