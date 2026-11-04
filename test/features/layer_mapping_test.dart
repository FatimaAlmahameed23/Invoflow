import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/add_invoice/data/datasources/add_invoice_remote_data_source.dart';
import 'package:invoflow/features/add_invoice/data/repositories/add_invoice_repository_impl.dart';
import 'package:invoflow/features/add_invoice/domain/entities/invoice_item.dart';
import 'package:invoflow/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:invoflow/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoices_details/data/datasources/invoice_details_remote_data_source.dart';
import 'package:invoflow/features/invoices_details/data/repositories/invoice_details_repository_impl.dart';

Map<String, dynamic> invoiceJson({String status = 'approved'}) => {
  'id': 'invoice-1',
  'invoice_number': 'INV-1',
  'status': status,
  'currency': 'JOD',
  'subtotal': 100,
  'tax_total': 16,
  'grand_total': 116,
  'created_at': '2026-11-04T12:00:00Z',
};

void main() {
  late SupabaseClient supabase;
  late FakeApiClient api;
  setUp(() {
    supabase = SupabaseClient('https://example.supabase.co', 'test-key');
    api = FakeApiClient(supabase);
  });
  tearDown(() => supabase.dispose());

  test('invoice repository converts backend fields to app types', () async {
    api.response = {
      'data': [invoiceJson()],
    };
    final repository = InvoiceRepositoryImpl(InvoiceRemoteDataSource(api));
    final invoice = (await repository.getInvoices()).single;
    expect(invoice.status, InvoiceStatus.approved);
    expect(invoice.createdAt, DateTime.utc(2026, 11, 4, 12));
    expect(invoice.subtotal, isA<double>());
    api.response = {'data': invoiceJson(status: 'deleted')};
    expect(
      (await repository.deleteInvoice(
        invoiceId: 'invoice-1',
        idempotencyKey: 'request-1',
      )).status,
      InvoiceStatus.deleted,
    );
    expect(api.lastHeaders?['Authorization'], 'Bearer test-token');
    api.response = {'data': invoiceJson()};
    await expectLater(
      repository.deleteInvoice(
        invoiceId: 'invoice-1',
        idempotencyKey: 'request-2',
      ),
      throwsFormatException,
    );
  });

  test(
    'product models become entities and invoice requests serialize only in data',
    () async {
      final repository = AddInvoiceRepositoryImpl(
        AddInvoiceRemoteDataSource(api),
      );
      api.response = {
        'data': [
          {
            'id': 'p1',
            'name': 'Product',
            'barcode': null,
            'unit_price': 100,
            'tax_rate': 16,
            'tax_inclusive': false,
          },
        ],
      };
      final product = (await repository.getProducts(currency: 'JOD')).single;
      expect(product.unitPrice, isA<double>());
      api.response = {'data': invoiceJson()};
      final invoice = await repository.createInvoice(
        currency: 'JOD',
        items: const [InvoiceItem(productId: 'p1', quantity: 1)],
        idempotencyKey: 'create-1',
      );
      expect(invoice.status, InvoiceStatus.approved);
      expect(api.lastBody, {
        'currency': 'JOD',
        'items': [
          {'product_id': 'p1', 'quantity': 1.0},
        ],
      });
      expect(api.lastHeaders?['Idempotency-Key'], 'create-1');
    },
  );

  test('detail repository maps nested items and customer aliases', () async {
    api.response = {
      'data': {
        ...invoiceJson(status: 'deleted'),
        'client_name': 'Client',
        'items': [
          {
            'product_name': 'Product',
            'quantity': 1,
            'unit_price': 100,
            'tax_rate': 16,
            'tax_inclusive': false,
            'subtotal': 100,
            'tax_amount': 16,
            'line_total': 116,
          },
        ],
      },
    };
    final repository = InvoiceDetailsRepositoryImpl(
      InvoiceDetailsRemoteDataSource(api),
    );
    final invoice = await repository.getInvoiceDetails('invoice-1');
    expect(invoice.status, InvoiceStatus.deleted);
    expect(invoice.customerName, 'Client');
    expect(invoice.createdAt, DateTime.utc(2026, 11, 4, 12));
    expect(invoice.items.single.name, 'Product');
    expect(invoice.items.single.total, 116.0);
    expect(invoice.taxRateLabel, 'Tax (16%)');
  });
}

class FakeApiClient extends ApiClient {
  FakeApiClient(super.supabase);
  dynamic response;
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastHeaders;

  @override
  String requireAccessToken() => 'test-token';

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async => response;

  @override
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastBody = body;
    lastHeaders = headers;
    return response;
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    required Map<String, String> headers,
  }) async {
    lastHeaders = headers;
    return response;
  }
}
