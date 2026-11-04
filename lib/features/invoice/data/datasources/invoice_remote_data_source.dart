import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/invoice/data/models/invoice_model.dart';

class InvoiceRemoteDataSource {
  const InvoiceRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InvoiceModel>> getInvoices() async {
    final response = await _apiClient.get(
      'invoices',
      queryParameters: {'limit': '100', 'offset': '0'},
    );
    final records = _readDataList(response, 'invoices');
    return records.map(InvoiceModel.fromJson).toList(growable: false);
  }

  Future<InvoiceModel> deleteInvoice({
    required String invoiceId,
    required String idempotencyKey,
    required String accessToken,
  }) async {
    final response = await _apiClient.delete(
      'invoices/$invoiceId',
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Idempotency-Key': idempotencyKey,
      },
    );

    if (response is! Map || response['data'] is! Map) {
      throw const FormatException(
        'The API returned an invalid deleted invoice response.',
      );
    }

    final invoice = InvoiceModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
    return invoice;
  }

  List<Map<String, dynamic>> _readDataList(dynamic response, String resource) {
    if (response is! Map || response['data'] is! List) {
      throw FormatException('The API returned an invalid $resource response.');
    }

    return (response['data'] as List)
        .map((record) {
          if (record is! Map) {
            throw FormatException(
              'The API returned an invalid $resource record.',
            );
          }
          return Map<String, dynamic>.from(record);
        })
        .toList(growable: false);
  }
}
