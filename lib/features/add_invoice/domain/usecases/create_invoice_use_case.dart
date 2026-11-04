import 'package:invoflow/features/add_invoice/domain/entities/invoice_item.dart';
import 'package:invoflow/features/add_invoice/domain/repositories/add_invoice_repository.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';

class CreateInvoiceUseCase {
  const CreateInvoiceUseCase(this._repository);
  final AddInvoiceRepository _repository;
  Future<Invoice> call({
    required String currency,
    required List<InvoiceItem> items,
    required String idempotencyKey,
  }) => _repository.createInvoice(
    currency: currency,
    items: items,
    idempotencyKey: idempotencyKey,
  );
}
