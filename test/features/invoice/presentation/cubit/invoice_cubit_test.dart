import 'package:flutter_test/flutter_test.dart';
import 'package:invoflow/core/network/api_exception.dart';
import 'package:invoflow/features/invoice/data/models/invoice_model.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:invoflow/features/invoice/domain/usecases/delete_invoice_use_case.dart';
import 'package:invoflow/features/invoice/domain/usecases/get_invoices_use_case.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_cubit.dart';

void main() {
  test('retries a soft delete with the same idempotency UUID', () async {
    final repository = _FakeInvoiceRepository();
    final cubit = InvoiceCubit(
      getInvoices: GetInvoicesUseCase(repository),
      deleteInvoice: DeleteInvoiceUseCase(repository),
    );
    addTearDown(cubit.close);

    await cubit.loadInvoices();
    await cubit.deleteInvoice('invoice-1');

    final firstKey = repository.idempotencyKeys.single;
    expect(
      firstKey,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(
      cubit.state.deleteErrors['invoice-1'],
      'This invoice can no longer be deleted because its status changed.',
    );

    await cubit.deleteInvoice('invoice-1');

    expect(repository.idempotencyKeys, [firstKey, firstKey]);
    expect(cubit.state.invoices.single.status, InvoiceStatus.deleted);
    expect(cubit.state.deleteErrors, isEmpty);
    expect(cubit.state.deletingInvoiceIds, isEmpty);
  });

  test('maps expired-session and missing-invoice errors for the UI', () async {
    final repository = _FakeInvoiceRepository()
      ..deleteFailure = const ApiException(
        statusCode: 401,
        code: 'UNAUTHORIZED',
        message: 'Unauthorized',
      );
    final cubit = InvoiceCubit(
      getInvoices: GetInvoicesUseCase(repository),
      deleteInvoice: DeleteInvoiceUseCase(repository),
    );
    addTearDown(cubit.close);

    await cubit.loadInvoices();
    await cubit.deleteInvoice('invoice-1');

    expect(
      cubit.state.deleteErrors['invoice-1'],
      'Your session has expired. Please sign in again.',
    );
  });

  test('maps a missing invoice response to a refresh prompt', () async {
    final repository = _FakeInvoiceRepository()
      ..deleteFailure = const ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'Not found',
      );
    final cubit = InvoiceCubit(
      getInvoices: GetInvoicesUseCase(repository),
      deleteInvoice: DeleteInvoiceUseCase(repository),
    );
    addTearDown(cubit.close);

    await cubit.loadInvoices();
    await cubit.deleteInvoice('invoice-1');

    expect(
      cubit.state.deleteErrors['invoice-1'],
      'Invoice not found. Refresh the invoice list and try again.',
    );
  });
}

class _FakeInvoiceRepository implements InvoiceRepository {
  final List<String> idempotencyKeys = [];
  Object? deleteFailure = const ApiException(
    statusCode: 409,
    code: 'CONFLICT',
    message: 'Conflict',
  );

  final InvoiceModel _approvedInvoice = const InvoiceModel(
    id: 'invoice-1',
    invoiceNumber: 'INV-0001',
    status: InvoiceStatus.approved,
    currency: 'JOD',
    subtotal: 100,
    taxTotal: 16,
    grandTotal: 116,
    createdAt: null,
  );

  @override
  Future<List<Invoice>> getInvoices() async => [_approvedInvoice];

  @override
  Future<Invoice> deleteInvoice({
    required String invoiceId,
    required String idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey);
    final failure = deleteFailure;
    if (failure != null) {
      deleteFailure = null;
      throw failure;
    }

    return InvoiceModel(
      id: _approvedInvoice.id,
      invoiceNumber: _approvedInvoice.invoiceNumber,
      status: InvoiceStatus.deleted,
      currency: _approvedInvoice.currency,
      subtotal: _approvedInvoice.subtotal,
      taxTotal: _approvedInvoice.taxTotal,
      grandTotal: _approvedInvoice.grandTotal,
      createdAt: _approvedInvoice.createdAt,
    );
  }
}
