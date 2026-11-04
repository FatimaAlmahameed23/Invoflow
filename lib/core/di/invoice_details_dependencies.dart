import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/invoices_details/data/datasources/invoice_details_remote_data_source.dart';
import 'package:invoflow/features/invoices_details/data/repositories/invoice_details_repository_impl.dart';
import 'package:invoflow/features/invoices_details/domain/usecases/get_invoice_details_use_case.dart';
import 'package:invoflow/features/invoices_details/presentation/cubit/invoice_details_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoiceDetailsDependencies extends StatelessWidget {
  const InvoiceDetailsDependencies({
    super.key,
    required this.invoiceId,
    required this.child,
  });

  final String invoiceId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InvoiceDetailsCubit>(
      create: (_) => InvoiceDetailsCubit(
        GetInvoiceDetailsUseCase(
          InvoiceDetailsRepositoryImpl(
            InvoiceDetailsRemoteDataSource(ApiClient(Supabase.instance.client)),
          ),
        ),
      )..loadInvoice(invoiceId),
      child: child,
    );
  }
}
