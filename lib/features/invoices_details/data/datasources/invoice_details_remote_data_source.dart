import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/invoices_details/data/models/invoice_details_model.dart';

class InvoiceDetailsRemoteDataSource {
  const InvoiceDetailsRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<InvoiceDetailsModel> getInvoiceDetails(String invoiceId) async {
    final response = await _apiClient.get('invoices/$invoiceId');
    if (response is! Map || response['data'] is! Map) {
      throw const FormatException(
        'The API returned an invalid invoice details response.',
      );
    }

    return InvoiceDetailsModel.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}
