import '../models/request/create_invoice_request_model.dart';
import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/add_invoice/data/models/response/product_model.dart';
import 'package:invoflow/features/invoice/data/models/response/invoice_model.dart';

class AddInvoiceRemoteDataSource {
  const AddInvoiceRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<List<ProductModel>> getProducts({required String currency}) async {
    final response = await _apiClient.get(
      'products',
      queryParameters: {'limit': '100', 'offset': '0', 'currency': currency},
    );
    final records = _readDataList(response, 'products');
    return records.map(ProductModel.fromJson).toList(growable: false);
  }

  Future<InvoiceModel> createInvoice({
    required CreateInvoiceRequestModel request,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post(
      'invoices',
      body: request.toJson(),
      headers: {'Idempotency-Key': idempotencyKey},
    );

    if (response is! Map || response['data'] is! Map) {
      throw const FormatException('The API returned an invalid invoice.');
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
