import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';

abstract class InvoiceDetailsRepository {
  Future<InvoiceDetails> getInvoiceDetails(String invoiceId);
}
