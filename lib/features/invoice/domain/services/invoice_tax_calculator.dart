class InvoiceTaxCalculation {
  const InvoiceTaxCalculation._({
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int taxCents;
  final int totalCents;

  double get subtotal => subtotalCents / 100;
  double get tax => taxCents / 100;
  double get total => totalCents / 100;
}

class InvoiceTaxLine {
  const InvoiceTaxLine({
    required this.unitPrice,
    required this.quantity,
    required this.taxRate,
    required this.taxInclusive,
  });

  final double unitPrice;
  final double quantity;
  final double taxRate;
  final bool taxInclusive;
}

class InvoiceTaxTotals {
  const InvoiceTaxTotals({
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
  });

  final int subtotalCents;
  final int taxCents;
  final int totalCents;
}

class InvoiceTaxCalculator {
  InvoiceTaxCalculator._();

  static final BigInt _decimalScale = BigInt.from(1000000);
  static final BigInt _amountScale = _decimalScale * _decimalScale;
  static final BigInt _rateBase = BigInt.from(100) * _decimalScale;

  static InvoiceTaxCalculation calculate({
    required double unitPrice,
    required double quantity,
    required double taxRate,
    required bool taxInclusive,
  }) {
    if (!unitPrice.isFinite ||
        unitPrice < 0 ||
        !quantity.isFinite ||
        quantity <= 0 ||
        !taxRate.isFinite ||
        taxRate < 0 ||
        taxRate > 100) {
      throw ArgumentError(
        'Price must be non-negative, quantity must be positive, '
        'and tax rate must be between 0 and 100.',
      );
    }

    final unitPriceScaled = _toScaledDecimal(unitPrice);
    final quantityScaled = _toScaledDecimal(quantity);
    final taxRateScaled = _toScaledDecimal(taxRate);
    final amountScaled = unitPriceScaled * quantityScaled;
    final totalCents = _roundRatio(
      amountScaled * BigInt.from(100),
      _amountScale,
    );

    if (taxInclusive) {
      final subtotalCents = _roundRatio(
        amountScaled * _rateBase * BigInt.from(100),
        _amountScale * (_rateBase + taxRateScaled),
      );
      return InvoiceTaxCalculation._(
        subtotalCents: subtotalCents,
        taxCents: totalCents - subtotalCents,
        totalCents: totalCents,
      );
    }

    final subtotalCents = totalCents;
    final taxCents = _roundRatio(
      BigInt.from(subtotalCents) * taxRateScaled,
      _rateBase,
    );
    return InvoiceTaxCalculation._(
      subtotalCents: subtotalCents,
      taxCents: taxCents,
      totalCents: subtotalCents + taxCents,
    );
  }

  static InvoiceTaxTotals calculateInvoice(Iterable<InvoiceTaxLine> lines) {
    var subtotalCents = 0;
    var taxCents = 0;
    var totalCents = 0;

    for (final line in lines) {
      final calculation = calculate(
        unitPrice: line.unitPrice,
        quantity: line.quantity,
        taxRate: line.taxRate,
        taxInclusive: line.taxInclusive,
      );
      subtotalCents += calculation.subtotalCents;
      taxCents += calculation.taxCents;
      totalCents += calculation.totalCents;
    }

    return InvoiceTaxTotals(
      subtotalCents: subtotalCents,
      taxCents: taxCents,
      totalCents: totalCents,
    );
  }

  static BigInt _toScaledDecimal(double value) {
    final decimal = value.toStringAsFixed(6);
    final isNegative = decimal.startsWith('-');
    final unsignedDecimal = isNegative ? decimal.substring(1) : decimal;
    final parts = unsignedDecimal.split('.');
    final scaled = BigInt.parse('${parts[0]}${parts[1]}');
    return isNegative ? -scaled : scaled;
  }

  static int _roundRatio(BigInt numerator, BigInt denominator) {
    final rounded =
        (numerator * BigInt.from(2) + denominator) ~/
        (denominator * BigInt.from(2));
    return rounded.toInt();
  }
}
