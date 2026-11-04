import 'package:invoflow/features/add_invoice/domain/entities/invoice_item.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';

abstract class AddInvoiceRepository {
  Future<List<Product>> getProducts({required String currency});
  Future<Invoice> createInvoice({
    required String currency,
    required List<InvoiceItem> items,
    required String idempotencyKey,
  });
}
