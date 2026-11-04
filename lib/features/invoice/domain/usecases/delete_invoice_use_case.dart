import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/domain/repositories/invoice_repository.dart';

class DeleteInvoiceUseCase {
  const DeleteInvoiceUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<Invoice> call({
    required String invoiceId,
    required String idempotencyKey,
  }) {
    return _repository.deleteInvoice(
      invoiceId: invoiceId,
      idempotencyKey: idempotencyKey,
    );
  }
}
