import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:invoflow/features/invoice/presentation/widgets/invoice_card.dart';
import 'package:invoflow/features/invoices_details/presentation/page/invoice_details_page.dart';

class InvoiceList extends StatelessWidget {
  const InvoiceList({
    super.key,
    required this.state,
    required this.onAddInvoice,
  });

  final InvoiceState state;
  final VoidCallback onAddInvoice;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<InvoiceCubit>().loadInvoices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAddInvoice,
              icon: const Icon(Icons.add),
              label: const Text('Add Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5E9F2),
                foregroundColor: const Color(0xFF92257E),
                elevation: 0,
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.isLoading && state.invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (state.errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: context.read<InvoiceCubit>().loadInvoices,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ],
          if (!state.isLoading &&
              state.errorMessage == null &&
              state.invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No invoices yet. Add your first one.'),
              ),
            ),
          for (final invoice in state.invoices)
            InvoiceCard(
              invoice: invoice,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InvoiceDetailsPage(invoiceId: invoice.id),
                ),
              ),
              onDelete: invoice.status == InvoiceStatus.approved
                  ? () => context.read<InvoiceCubit>().deleteInvoice(invoice.id)
                  : null,
              onRetryDelete: invoice.status == InvoiceStatus.approved
                  ? () => context.read<InvoiceCubit>().deleteInvoice(invoice.id)
                  : null,
              isDeleting: state.deletingInvoiceIds.contains(invoice.id),
              deleteError: state.deleteErrors[invoice.id],
            ),
        ],
      ),
    );
  }
}
