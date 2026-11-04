import 'package:invoflow/features/add_invoice/presentation/cubit/add_invoice_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/add_invoice/data/datasources/add_invoice_remote_data_source.dart';
import 'package:invoflow/features/add_invoice/data/repositories/add_invoice_repository_impl.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/create_invoice_use_case.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/get_products_use_case.dart';
import 'package:invoflow/features/add_invoice/presentation/page/add_invoice_page.dart';
import 'package:invoflow/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:invoflow/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:invoflow/features/invoice/domain/usecases/delete_invoice_use_case.dart';
import 'package:invoflow/features/invoice/domain/usecases/get_invoices_use_case.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Owns the invoice Cubit for the lifetime of the invoice page.
class InvoiceDependencies extends StatelessWidget {
  const InvoiceDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceCubit>(
      create: (_) {
        final supabase = Supabase.instance.client;
        final repository = InvoiceRepositoryImpl(
          remoteDataSource: InvoiceRemoteDataSource(ApiClient(supabase)),
          supabaseClient: supabase,
        );
        return InvoiceCubit(
          getInvoices: GetInvoicesUseCase(repository),
          deleteInvoice: DeleteInvoiceUseCase(repository),
        )..loadInvoices();
      },
      child: child,
    );
  }
}

/// Composes the add-invoice route outside the invoice presentation layer.
Route<bool> createAddInvoiceRoute() {
  return MaterialPageRoute<bool>(
    builder: (_) {
      final repository = AddInvoiceRepositoryImpl(
        AddInvoiceRemoteDataSource(ApiClient(Supabase.instance.client)),
      );
      return BlocProvider<AddInvoiceCubit>(
        create: (_) => AddInvoiceCubit(
          getProducts: GetProductsUseCase(repository),
          createInvoice: CreateInvoiceUseCase(repository),
        )..loadProducts(),
        child: const AddInvoicePage(),
      );
    },
  );
}
