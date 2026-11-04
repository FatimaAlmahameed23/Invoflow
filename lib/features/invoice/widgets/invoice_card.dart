import 'package:flutter/material.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/widgets/status_badge.dart';

class InvoiceCard extends StatefulWidget {
  const InvoiceCard({
    super.key,
    required this.invoice,
    this.onTap,
    this.onDelete,
    this.onRetryDelete,
    this.isDeleting = false,
    this.deleteError,
  });

  final Invoice invoice;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onRetryDelete;
  final bool isDeleting;
  final String? deleteError;

  @override
  State<InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<InvoiceCard> {
  bool _isExpanded = false;
  bool _isConfirmingDelete = false;

  String get _formattedDate {
    final date = widget.invoice.createdAt;
    if (date == null) return 'Date unavailable';

    const months = [
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
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _confirmDelete() async {
    if (_isConfirmingDelete || widget.isDeleting) return;
    setState(() => _isConfirmingDelete = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete invoice?'),
          content: const Text(
            'This invoice will be marked as deleted. Its record and items will be kept.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted && widget.onDelete != null) {
        await widget.onDelete!();
      }
    } finally {
      if (mounted) setState(() => _isConfirmingDelete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.invoice.invoiceNumber ?? 'Draft invoice',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: widget.invoice.status),
                      const SizedBox(height: 6),
                      Text(
                        '${widget.invoice.currency} ${widget.invoice.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: _isExpanded
                        ? 'Hide invoice totals'
                        : 'Show invoice totals',
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      tooltip: 'Delete invoice',
                      onPressed: widget.isDeleting || _isConfirmingDelete
                          ? null
                          : _confirmDelete,
                      visualDensity: VisualDensity.compact,
                      color: Colors.red.shade700,
                      icon: widget.isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              if (_isExpanded) ...[
                const Divider(height: 20),
                _totalRow('Subtotal', widget.invoice.subtotal),
                const SizedBox(height: 6),
                _totalRow('Tax', widget.invoice.taxTotal),
                const SizedBox(height: 6),
                _totalRow('Total', widget.invoice.grandTotal, emphasized: true),
              ],
              if (widget.deleteError != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.deleteError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.isDeleting
                          ? null
                          : widget.onRetryDelete,
                      child: widget.isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount, {bool emphasized = false}) {
    final style = TextStyle(
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      color: emphasized ? const Color(0xFF92257E) : null,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(
          '${widget.invoice.currency} ${amount.toStringAsFixed(2)}',
          style: style,
        ),
      ],
    );
  }
}
