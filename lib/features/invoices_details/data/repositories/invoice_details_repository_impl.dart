import 'package:invoflow/features/invoices_details/data/datasources/invoice_details_remote_data_source.dart';
import 'package:invoflow/features/invoices_details/domain/entities/invoice_details.dart';
import 'package:invoflow/features/invoices_details/domain/repositories/invoice_details_repository.dart';

class InvoiceDetailsRepositoryImpl implements InvoiceDetailsRepository {
  const InvoiceDetailsRepositoryImpl(this._remoteDataSource);

  final InvoiceDetailsRemoteDataSource _remoteDataSource;

  @override
  Future<InvoiceDetails> getInvoiceDetails(String invoiceId) {
    return _remoteDataSource.getInvoiceDetails(invoiceId);
  }
}
