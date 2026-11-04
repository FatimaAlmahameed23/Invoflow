class CreateInvoiceItemRequestModel {
  const CreateInvoiceItemRequestModel({
    required this.productId,
    required this.quantity,
  });

  final String productId;
  final double quantity;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
  };
}

class CreateInvoiceRequestModel {
  const CreateInvoiceRequestModel({
    required this.currency,
    required this.items,
  });

  final String currency;
  final List<CreateInvoiceItemRequestModel> items;

  Map<String, dynamic> toJson() => {
    'currency': currency,
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}
