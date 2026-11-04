import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoices_details/data/datasources/invoice_details_remote_data_source.dart';
import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';
import 'package:invoflow/features/invoices_details/domain/repositories/invoice_details_repository.dart';

class InvoiceDetailsRepositoryImpl implements InvoiceDetailsRepository {
  const InvoiceDetailsRepositoryImpl(this._remoteDataSource);

  final InvoiceDetailsRemoteDataSource _remoteDataSource;

  @override
  Future<InvoiceDetails> getInvoiceDetails(String invoiceId) async {
    final response = await _remoteDataSource.getInvoiceDetails(invoiceId);
    return InvoiceDetails(
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
      customerName:
          response.customerName ?? response.clientName ?? response.customer,
      items: response.items
          .map(
            (item) => InvoiceDetailsItem(
              name: item.productName,
              quantity: item.quantity.toDouble(),
              unitPrice: item.unitPrice.toDouble(),
              taxRate: item.taxRate.toDouble(),
              taxInclusive: item.taxInclusive,
              subtotal: item.subtotal.toDouble(),
              taxAmount: item.taxAmount.toDouble(),
              total: item.lineTotal.toDouble(),
            ),
          )
          .toList(growable: false),
    );
  }
}
