import 'package:flutter/material.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final InvoiceStatus status;

  Color get _color => switch (status) {
    InvoiceStatus.approved => const Color(0xFF167A38),
    InvoiceStatus.deleted => const Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
