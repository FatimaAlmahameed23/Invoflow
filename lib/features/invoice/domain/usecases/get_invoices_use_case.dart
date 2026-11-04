import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/domain/repositories/invoice_repository.dart';

class GetInvoicesUseCase {
  const GetInvoicesUseCase(this._repository);

  final InvoiceRepository _repository;

  Future<List<Invoice>> call() => _repository.getInvoices();
}
