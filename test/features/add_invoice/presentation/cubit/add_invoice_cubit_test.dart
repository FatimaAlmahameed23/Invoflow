import 'package:invoflow/features/add_invoice/domain/entities/invoice_item.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/add_invoice/domain/repositories/add_invoice_repository.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/create_invoice_use_case.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/get_products_use_case.dart';
import 'package:invoflow/features/add_invoice/presentation/cubit/add_invoice_cubit.dart';
import 'package:invoflow/features/invoice/domain/entities/invoice.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';

const product = Product(
  id: 'p1',
  name: 'Product',
  barcode: '123',
  unitPrice: 100,
  taxRate: 16,
  taxInclusive: false,
);

void main() {
  late FakeRepository repository;
  late AddInvoiceCubit cubit;
  setUp(() {
    repository = FakeRepository();
    cubit = AddInvoiceCubit(
      getProducts: GetProductsUseCase(repository),
      createInvoice: CreateInvoiceUseCase(repository),
    );
  });
  tearDown(() => cubit.close());

  test('adds scanned products, updates totals, and removes items', () async {
    await cubit.loadProducts();
    cubit.addBarcode('123');
    cubit.addProduct(product);
    expect(cubit.state.quantities['p1'], '2');
    expect(cubit.state.totals.totalCents, 23200);
    cubit.updateQuantity('p1', '');
    expect(cubit.state.lineFor(product).totalCents, 0);
    cubit.updateQuantity('p1', '1.5');
    expect(cubit.state.totals.totalCents, 17400);
    cubit.removeProduct('p1');
    expect(cubit.state.hasInvoiceItems, false);
    cubit.addBarcode('missing');
    expect(cubit.state.message, contains('missing'));
  });

  test('validates quantities before saving', () async {
    await cubit.loadProducts();
    cubit.addProduct(product);
    cubit.updateQuantity('p1', '1000000');
    await cubit.saveInvoice();
    expect(cubit.state.message, contains('valid quantity'));
    expect(repository.keys, isEmpty);
  });

  test(
    'retries unchanged requests with the same key and creates once',
    () async {
      await cubit.loadProducts();
      cubit.addProduct(product);
      repository.failSave = true;
      await cubit.saveInvoice();
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.isSaving, false);
      await cubit.saveInvoice();
      expect(repository.keys[0], repository.keys[1]);
      expect(cubit.state.isCreated, true);
      await cubit.saveInvoice();
      expect(repository.keys.length, 2);
    },
  );

  test('ignores an old currency response', () async {
    final old = Completer<List<Product>>();
    repository.delayedJod = old;
    final loading = cubit.loadProducts();
    await cubit.changeCurrency('USD');
    old.complete(const []);
    await loading;
    expect(cubit.state.currency, 'USD');
    expect(cubit.state.products, [product]);
    expect(cubit.state.isLoadingProducts, false);
  });
}

class FakeRepository implements AddInvoiceRepository {
  final keys = <String>[];
  bool failSave = false;
  Completer<List<Product>>? delayedJod;

  @override
  Future<List<Product>> getProducts({required String currency}) async {
    if (currency == 'JOD' && delayedJod != null) return delayedJod!.future;
    return [product];
  }

  @override
  Future<Invoice> createInvoice({
    required String currency,
    required List<InvoiceItem> items,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    if (failSave) {
      failSave = false;
      throw StateError('Network failure');
    }
    return Invoice(
      id: 'i1',
      invoiceNumber: 'INV-1',
      status: InvoiceStatus.approved,
      currency: currency,
      subtotal: 100,
      taxTotal: 16,
      grandTotal: 116,
      createdAt: null,
    );
  }
}
