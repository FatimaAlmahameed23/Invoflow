import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';
import 'package:invoflow/features/invoices_details/domain/repositories/invoice_details_repository.dart';

class GetInvoiceDetailsUseCase {
  const GetInvoiceDetailsUseCase(this._repository);

  final InvoiceDetailsRepository _repository;

  Future<InvoiceDetails> call(String invoiceId) {
    return _repository.getInvoiceDetails(invoiceId);
  }
}
