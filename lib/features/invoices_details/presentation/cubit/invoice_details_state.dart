part of 'invoice_details_cubit.dart';

class InvoiceDetailsState {
  const InvoiceDetailsState({
    this.invoice,
    this.isLoading = false,
    this.errorMessage,
  });

  final InvoiceDetails? invoice;
  final bool isLoading;
  final String? errorMessage;
}
