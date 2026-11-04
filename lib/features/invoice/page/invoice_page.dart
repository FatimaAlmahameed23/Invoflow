import 'package:invoflow/core/widgets/app_app_bar.dart';
import 'package:invoflow/features/add_invoice/data/datasources/add_invoice_remote_data_source.dart';
import 'package:invoflow/features/add_invoice/data/repositories/add_invoice_repository_impl.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/get_products_use_case.dart';
import 'package:invoflow/features/add_invoice/domain/usecases/create_invoice_use_case.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/network/api_client.dart';
import 'package:invoflow/features/invoice/data/datasources/invoice_remote_data_source.dart';
import 'package:invoflow/features/invoice/data/repositories/invoice_repository_impl.dart';
import 'package:invoflow/features/invoice/domain/enum/status_enum.dart';
import 'package:invoflow/features/invoice/domain/usecases/delete_invoice_use_case.dart';
import 'package:invoflow/features/invoice/domain/usecases/get_invoices_use_case.dart';
import 'package:invoflow/features/add_invoice/presentation/page/add_invoice_page.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_state.dart';
import 'package:invoflow/features/invoice/widgets/invoice_card.dart';
import 'package:invoflow/features/invoices_details/presentation/page/invoice_details_page.dart';
import 'package:invoflow/features/settings/presentation/page/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late final InvoiceRemoteDataSource _dataSource;
  late final InvoiceCubit _invoiceCubit;

  _InvoicePageState() {
    final supabase = Supabase.instance.client;
    _dataSource = InvoiceRemoteDataSource(ApiClient(supabase));
    final repository = InvoiceRepositoryImpl(
      remoteDataSource: _dataSource,
      supabaseClient: supabase,
    );
    _invoiceCubit = InvoiceCubit(
      getInvoices: GetInvoicesUseCase(repository),
      deleteInvoice: DeleteInvoiceUseCase(repository),
    );
  }

  int _selectedDestination = 0;

  @override
  void initState() {
    super.initState();
    _invoiceCubit.loadInvoices();
  }

  @override
  void dispose() {
    unawaited(_invoiceCubit.close());
    super.dispose();
  }

  Future<void> _openAddInvoicePage() async {
    final repository = AddInvoiceRepositoryImpl(
      AddInvoiceRemoteDataSource(ApiClient(Supabase.instance.client)),
    );
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddInvoicePage(
          getProducts: GetProductsUseCase(repository),
          createInvoice: CreateInvoiceUseCase(repository),
        ),
      ),
    );
    if (created == true) _invoiceCubit.loadInvoices();
  }

  Widget _buildInvoiceList(InvoiceState state) {
    return RefreshIndicator(
      onRefresh: _invoiceCubit.loadInvoices,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openAddInvoicePage,
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
                    onPressed: _invoiceCubit.loadInvoices,
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
                  ? () => _invoiceCubit.deleteInvoice(invoice.id)
                  : null,
              onRetryDelete: invoice.status == InvoiceStatus.approved
                  ? () => _invoiceCubit.deleteInvoice(invoice.id)
                  : null,
              isDeleting: state.deletingInvoiceIds.contains(invoice.id),
              deleteError: state.deleteErrors[invoice.id],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInvoicesSelected = _selectedDestination == 0;

    return Scaffold(
      appBar: isInvoicesSelected
          ? const AppAppBar(title: 'Invoices', backButton: false)
          : null,
      body: isInvoicesSelected
          ? BlocBuilder<InvoiceCubit, InvoiceState>(
              bloc: _invoiceCubit,
              builder: (context, state) => _buildInvoiceList(state),
            )
          : const SettingsPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (index) {
          setState(() => _selectedDestination = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
