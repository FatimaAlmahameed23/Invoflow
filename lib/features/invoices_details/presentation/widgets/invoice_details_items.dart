import 'package:flutter/material.dart';
import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';

class InvoiceDetailsItems extends StatelessWidget {
  const InvoiceDetailsItems({super.key, required this.invoice});

  final InvoiceDetails invoice;

  String _quantity(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Text(
            'Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
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
          child: invoice.items.isEmpty
              ? const Text('No item details available.')
              : Column(
                  children: [
                    for (var index = 0; index < invoice.items.length; index++)
                      _buildItem(invoice.items[index], index),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildItem(InvoiceDetailsItem item, int index) {
    return Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index > 0) const Divider(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_quantity(item.quantity)} × ${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.taxInclusive ? 'Inclusive' : 'Exclusive'} tax · ${item.taxRate.toStringAsFixed(item.taxRate % 1 == 0 ? 0 : 2)}%',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${invoice.currency} ${item.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Subtotal ${invoice.currency} ${item.subtotal.toStringAsFixed(2)} · Tax ${invoice.currency} ${item.taxAmount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
