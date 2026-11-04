enum InvoiceStatus {
  approved('approved', 'Approved'),
  deleted('deleted', 'Deleted');

  final String apiValue;
  final String displayName;

  const InvoiceStatus(this.apiValue, this.displayName);

  static InvoiceStatus fromApi(String value) {
    return InvoiceStatus.values.firstWhere(
      (status) => status.apiValue == value.toLowerCase(),
      orElse: () => throw FormatException('Unknown invoice status: $value'),
    );
  }
}
