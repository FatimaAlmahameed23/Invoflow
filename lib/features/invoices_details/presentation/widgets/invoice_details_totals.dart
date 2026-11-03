import 'package:flutter/material.dart';
import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';

class InvoiceDetailsTotals extends StatelessWidget {
  const InvoiceDetailsTotals({super.key, required this.invoice});

  final InvoiceDetails invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: _money(invoice.subtotal)),
          const SizedBox(height: 10),
          _TotalRow(
            label: invoice.taxRateLabel,
            value: _money(invoice.taxTotal),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _TotalRow(
              label: 'Total',
              value: _money(invoice.grandTotal),
              emphasized: true,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double amount) =>
      '${invoice.currency} ${amount.toStringAsFixed(2)}';
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      color: emphasized ? const Color(0xFF92257E) : null,
      fontSize: emphasized ? 16 : 14,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}
