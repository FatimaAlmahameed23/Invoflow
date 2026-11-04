import 'package:invoflow/core/di/invoice_details_dependencies.dart';
import 'package:invoflow/core/widgets/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/invoices_details/presentation/cubit/invoice_details_cubit.dart';
import 'package:invoflow/features/invoices_details/presentation/widgets/invoice_details_information.dart';
import 'package:invoflow/features/invoices_details/presentation/widgets/invoice_details_items.dart';
import 'package:invoflow/features/invoices_details/presentation/widgets/invoice_details_totals.dart';

class InvoiceDetailsPage extends StatelessWidget {
  const InvoiceDetailsPage({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return InvoiceDetailsDependencies(
      invoiceId: invoiceId,
      child: _InvoiceDetailsView(invoiceId: invoiceId),
    );
  }
}

class _InvoiceDetailsView extends StatelessWidget {
  const _InvoiceDetailsView({required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8FB),
      appBar: const AppAppBar(title: 'Invoice Details'),
      body: BlocBuilder<InvoiceDetailsCubit, InvoiceDetailsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context
                          .read<InvoiceDetailsCubit>()
                          .loadInvoice(invoiceId),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final invoice = state.invoice;
          if (invoice == null) {
            return const Center(child: Text('Invoice details unavailable.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              InvoiceDetailsInformation(invoice: invoice),
              InvoiceDetailsItems(invoice: invoice),
              InvoiceDetailsTotals(invoice: invoice),
            ],
          );
        },
      ),
    );
  }
}
