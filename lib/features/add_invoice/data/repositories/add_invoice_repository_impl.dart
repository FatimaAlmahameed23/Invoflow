import '../models/request/create_invoice_request_model.dart';
import 'package:invoflow/features/add_invoice/domain/entities/invoice_item.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/add_invoice/data/datasources/add_invoice_remote_data_source.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/add_invoice/domain/repositories/add_invoice_repository.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';

class AddInvoiceRepositoryImpl implements AddInvoiceRepository {
  const AddInvoiceRepositoryImpl(this._dataSource);
  final AddInvoiceRemoteDataSource _dataSource;
  @override
  Future<List<Product>> getProducts({required String currency}) async {
    final response = await _dataSource.getProducts(currency: currency);
    return response
        .map(
          (product) => Product(
            id: product.id,
            name: product.name,
            barcode: product.barcode,
            unitPrice: product.unitPrice.toDouble(),
            taxRate: product.taxRate.toDouble(),
            taxInclusive: product.taxInclusive,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Invoice> createInvoice({
    required String currency,
    required List<InvoiceItem> items,
    required String idempotencyKey,
  }) async {
    final response = await _dataSource.createInvoice(
      request: CreateInvoiceRequestModel(
        currency: currency,
        items: items
            .map(
              (item) => CreateInvoiceItemRequestModel(
                productId: item.productId,
                quantity: item.quantity,
              ),
            )
            .toList(growable: false),
      ),
      idempotencyKey: idempotencyKey,
    );
    final status = InvoiceStatus.fromApi(response.status);
    if (status != InvoiceStatus.approved) {
      throw const FormatException(
        'The API created an invoice with an unexpected status.',
      );
    }
    return Invoice(
      id: response.id,
      invoiceNumber: response.invoiceNumber,
      status: status,
      currency: response.currency,
      subtotal: response.subtotal.toDouble(),
      taxTotal: response.taxTotal.toDouble(),
      grandTotal: response.grandTotal.toDouble(),
      createdAt: response.createdAt == null
          ? null
          : DateTime.tryParse(response.createdAt!),
    );
  }
}
