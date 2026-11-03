import 'package:flutter/material.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
