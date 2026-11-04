import 'package:invoflow/features/invoice/domain/entities/invoice.dart';

abstract class InvoiceRepository {
  Future<List<Invoice>> getInvoices();

  Future<Invoice> deleteInvoice({
    required String invoiceId,
    required String idempotencyKey,
  });
}
