import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/network/api_client.dart';
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
          InvoiceRemoteDataSource(ApiClient(supabase)),
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
