import 'package:invoflow/features/add_invoice/domain/entities/product.dart';
import 'package:invoflow/features/add_invoice/domain/repositories/add_invoice_repository.dart';

class GetProductsUseCase {
  const GetProductsUseCase(this._repository);
  final AddInvoiceRepository _repository;
  Future<List<Product>> call({required String currency}) =>
      _repository.getProducts(currency: currency);
}
