import 'package:invoflow/core/di/add_invoice_dependencies.dart';
import 'package:invoflow/core/di/invoice_dependencies.dart';
import 'package:invoflow/core/widgets/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/features/invoice/presentation/cubit/invoice_cubit.dart';
import 'package:invoflow/features/invoice/presentation/widgets/invoice_list.dart';
import 'package:invoflow/features/settings/presentation/page/settings_page.dart';

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const InvoiceDependencies(child: _InvoiceView());
  }
}

class _InvoiceView extends StatefulWidget {
  const _InvoiceView();

  @override
  State<_InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<_InvoiceView> {
  int _selectedDestination = 0;

  Future<void> _openAddInvoicePage() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(createAddInvoiceRoute());
    if (!mounted) return;
    if (created == true) {
      await context.read<InvoiceCubit>().loadInvoices();
    }
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
              builder: (context, state) =>
                  InvoiceList(state: state, onAddInvoice: _openAddInvoicePage),
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
