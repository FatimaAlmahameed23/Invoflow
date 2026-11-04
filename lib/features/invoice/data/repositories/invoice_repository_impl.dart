import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/data/models/response/invoice_model.dart';
import 'package:invoflow/features/invoice/domain/repositories/invoice_repository.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  const InvoiceRepositoryImpl(this._remoteDataSource);

  final InvoiceRemoteDataSource _remoteDataSource;

  @override
  Future<List<Invoice>> getInvoices() async {
    final response = await _remoteDataSource.getInvoices();
    return response.map(_toInvoice).toList(growable: false);
  }

  @override
  Future<Invoice> deleteInvoice({
    required String invoiceId,
    required String idempotencyKey,
  }) async {
    final response = await _remoteDataSource.deleteInvoice(
      invoiceId: invoiceId,
      idempotencyKey: idempotencyKey,
    );
    final invoice = _toInvoice(response);
    if (invoice.status != InvoiceStatus.deleted) {
      throw const FormatException(
        'The API did not mark the invoice as deleted.',
      );
    }
    return invoice;
  }

  Invoice _toInvoice(InvoiceModel response) {
    return Invoice(
      id: response.id,
      invoiceNumber: response.invoiceNumber,
      status: InvoiceStatus.fromApi(response.status),
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
