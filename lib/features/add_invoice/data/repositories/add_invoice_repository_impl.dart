import 'package:invoflow/features/add_invoice/data/datasources/add_invoice_remote_data_source.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/add_invoice/domain/repositories/add_invoice_repository.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';

class AddInvoiceRepositoryImpl implements AddInvoiceRepository {
  const AddInvoiceRepositoryImpl(this._dataSource);
  final AddInvoiceRemoteDataSource _dataSource;
  @override
  Future<List<Product>> getProducts({required String currency}) =>
      _dataSource.getProducts(currency: currency);
  @override
  Future<Invoice> createInvoice({
    required String currency,
    required List<Map<String, dynamic>> items,
    required String idempotencyKey,
  }) => _dataSource.createInvoice(
    currency: currency,
    items: items,
    idempotencyKey: idempotencyKey,
  );
}
