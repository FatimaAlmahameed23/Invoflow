import 'package:flutter/material.dart';
import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';
import 'package:invoflow/features/invoice/widgets/status_badge.dart';

class InvoiceDetailsInformation extends StatelessWidget {
  const InvoiceDetailsInformation({super.key, required this.invoice});

  final InvoiceDetails invoice;

  String get _formattedDate {
    final date = invoice.createdAt;
    if (date == null) return 'Date unavailable';
    return '${_month(date.month)} ${date.day}, ${date.year}';
  }

  String _month(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    return _DetailsCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, color: Color(0xFF92257E)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  invoice.invoiceNumber ?? 'Invoice',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              StatusBadge(status: invoice.status),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            label: 'Client',
            value: invoice.customerName?.isNotEmpty == true
                ? invoice.customerName!
                : 'Not specified',
          ),
          _InfoRow(label: 'Date', value: _formattedDate),
          _InfoRow(label: 'Currency', value: invoice.currency),
          _InfoRow(label: 'Tax Mode', value: invoice.taxMode),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}
