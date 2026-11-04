import 'package:flutter/material.dart';

enum InvoiceStatus {
  draft('draft', 'Draft', Color(0xFF9A5A00)),
  approved('approved', 'Approved', Color(0xFF167A38)),
  deleted('deleted', 'Deleted', Color(0xFFC62828));

  final String apiValue;
  final String displayName;
  final Color color;

  const InvoiceStatus(this.apiValue, this.displayName, this.color);

  static InvoiceStatus fromApi(String value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.apiValue == value.toLowerCase(),
      orElse: () => throw FormatException('Unknown invoice status: $value'),
    );
  }
}
