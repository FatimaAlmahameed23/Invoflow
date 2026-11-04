import 'package:invoflow/core/network/api_exception.dart';
import 'package:invoflow/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
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
    return _remoteDataSource.getInvoices();
  }

  @override
  Future<Invoice> deleteInvoice({
    required String invoiceId,
    required String idempotencyKey,
  }) {
    final accessToken = _supabaseClient.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_EXPIRED',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    return _remoteDataSource.deleteInvoice(
      invoiceId: invoiceId,
      idempotencyKey: idempotencyKey,
      accessToken: accessToken,
    );
  }
}
