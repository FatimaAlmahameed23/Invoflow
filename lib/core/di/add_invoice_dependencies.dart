import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/add_invoice/data/datasources/add_invoice_remote_data_source.dart';
import 'package:invoflow/features/add_invoice/data/repositories/add_invoice_repository_impl.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/create_invoice_use_case.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/get_products_use_case.dart';
import 'package:invoflow/features/add_invoice/presentation/cubit/add_invoice_cubit.dart';
import 'package:invoflow/features/add_invoice/presentation/page/add_invoice_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddInvoiceDependencies extends StatelessWidget {
  const AddInvoiceDependencies({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddInvoiceCubit>(
      create: (_) {
        final repository = AddInvoiceRepositoryImpl(
          AddInvoiceRemoteDataSource(ApiClient(Supabase.instance.client)),
        );
        return AddInvoiceCubit(
          getProducts: GetProductsUseCase(repository),
          createInvoice: CreateInvoiceUseCase(repository),
        )..loadProducts();
      },
      child: child,
    );
  }
}

Route<bool> createAddInvoiceRoute() => MaterialPageRoute<bool>(
  builder: (_) => const AddInvoiceDependencies(child: AddInvoicePage()),
);
