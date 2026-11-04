import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/core/network/api_exception.dart';
import 'package:invoflow/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/data/models/invoice_model.dart';
import 'package:invoflow/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  const InvoiceRepositoryImpl({
    required InvoiceRemoteDataSource remoteDataSource,
    required SupabaseClient supabaseClient,
  }) : _remoteDataSource = remoteDataSource,
       _supabaseClient = supabaseClient;

  final InvoiceRemoteDataSource _remoteDataSource;
  final SupabaseClient _supabaseClient;

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
    final accessToken = _supabaseClient.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_EXPIRED',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final response = await _remoteDataSource.deleteInvoice(
      invoiceId: invoiceId,
      idempotencyKey: idempotencyKey,
      accessToken: accessToken,
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
