import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';

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
