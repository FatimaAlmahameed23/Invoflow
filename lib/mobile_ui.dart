import 'package:flutter/material.dart';

const ink = Color(0xFF18352F);
const green = Color(0xFF16755D);
const paper = Color(0xFFF5F7F5);

class Invoice {
  Invoice(
    this.number,
    this.customer,
    this.currency,
    this.lines, {
    this.status = 'Draft',
    this.inclusive = false,
  });
  final String number;
  String customer, currency, status;
  bool inclusive;
  List<InvoiceLine> lines;
  double get subtotal => lines.fold(0, (sum, l) => sum + l.price * l.quantity);
  double get tax => inclusive ? subtotal - subtotal / 1.16 : subtotal * .16;
  double get total => inclusive ? subtotal : subtotal + tax;
}

class InvoiceLine {
  InvoiceLine(this.name, this.price, {this.quantity = 1});
  final String name;
  final double price;
  int quantity;
  InvoiceLine copy() => InvoiceLine(name, price, quantity: quantity);
}

class InvoFlowPreview extends StatelessWidget {
  const InvoFlowPreview({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'InvoFlow',
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.light,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
      ).copyWith(primary: green, surface: Colors.white, onSurface: ink),
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.all(16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ),
    home: const LoginScreen(),
  );
}

Widget pageBody(List<Widget> children) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: children,
    ),
  ),
);

Widget heading(String title, [String? subtitle]) => Padding(
  padding: const EdgeInsets.only(bottom: 22),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF657871), height: 1.5),
        ),
      ],
    ],
  ),
);

Widget panel(Widget child) => Container(
  margin: const EdgeInsets.only(bottom: 16),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: const Color(0xFFE2E8E4)),
    borderRadius: BorderRadius.circular(20),
  ),
  child: child,
);

Widget badge(String status) {
  final color = status == 'Approved'
      ? green
      : status == 'Draft'
      ? const Color(0xFF936316)
      : const Color(0xFF9C4949);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: pageBody([
        const SizedBox(height: 55),
        const Align(
          alignment: Alignment.centerLeft,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: green,
            child: Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 28),
        heading(
          'InvoFlow',
          'Less paperwork. More flow.\nYour invoices, neatly in one place.',
        ),
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              const Text(
                'Explore the mobile experience with sample invoices.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const InvoiceHome()),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Explore demo'),
              ),
            ],
          ),
        ),
        const Text(
          'INTERACTIVE PREVIEW',
          style: TextStyle(fontSize: 11, letterSpacing: 2, color: green),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sample data only. Sign-in and live account connections will be added during integration.',
          style: TextStyle(color: Color(0xFF657871), height: 1.5),
        ),
      ]),
    ),
  );
}

class InvoiceHome extends StatefulWidget {
  const InvoiceHome({super.key});
  @override
  State<InvoiceHome> createState() => _InvoiceHomeState();
}

class _InvoiceHomeState extends State<InvoiceHome> {
  final invoices = [
    Invoice('INV-00024', 'Olive Studio', 'JOD', [
      InvoiceLine('Wireless keyboard', 28, quantity: 2),
    ], status: 'Approved'),
    Invoice('INV-00025', 'Amman Creative', 'JOD', [
      InvoiceLine('USB-C hub', 35),
    ]),
    Invoice('INV-00026', 'North Design', 'USD', [
      InvoiceLine('Desk stand', 24),
    ], status: 'Cancelled'),
  ];
  String filter = 'All', query = '', currency = 'JOD';
  bool inclusive = false;
  int tab = 0, nextNumber = 27;

  Future<void> edit([Invoice? invoice]) async {
    final result = await Navigator.of(context).push<Invoice>(
      MaterialPageRoute(
        builder: (_) => InvoiceEditor(
          invoice: invoice,
          currency: currency,
          inclusive: inclusive,
          number: 'INV-${nextNumber.toString().padLeft(5, '0')}',
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (invoice == null) {
          invoices.insert(0, result);
          nextNumber++;
        } else {
          invoices[invoices.indexOf(invoice)] = result;
        }
      });
    }
  }

  Future<void> details(Invoice invoice) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => InvoiceDetails(
          invoice: invoice,
          onEdit: () => edit(invoice),
          onDelete: () => invoices.remove(invoice),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visible = invoices
        .where(
          (i) =>
              (filter == 'All' || i.status == filter) &&
              '${i.customer} ${i.number}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'invoflow',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: CircleAvatar(
              backgroundColor: Color(0xFFE3EDE7),
              child: Text('FA', style: TextStyle(color: green, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: tab == 0
            ? pageBody([
                heading('Your invoices', 'A clear view of every sale.'),
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'APPROVED SALES · JOD',
                        style: TextStyle(
                          color: Color(0xFFBBD4CA),
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        invoices
                            .where(
                              (i) =>
                                  i.status == 'Approved' && i.currency == 'JOD',
                            )
                            .fold<double>(0, (s, i) => s + i.total)
                            .toStringAsFixed(3),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${invoices.where((i) => i.status == 'Draft').length} drafts ready for your next step',
                        style: const TextStyle(color: Color(0xFFBBD4CA)),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: edit,
                  icon: const Icon(Icons.add),
                  label: const Text('Create invoice'),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  decoration: const InputDecoration(
                    hintText: 'Search customer or invoice',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Draft', 'Approved', 'Cancelled']
                      .map(
                        (s) => ChoiceChip(
                          label: Text(s),
                          selected: filter == s,
                          onSelected: (_) => setState(() => filter = s),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  '${visible.length} INVOICES',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    color: Color(0xFF657871),
                  ),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  panel(
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No invoices found. Try another search or create your first invoice.',
                      ),
                    ),
                  ),
                ...visible.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => details(i),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      i.number,
                                      style: const TextStyle(
                                        color: Color(0xFF657871),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  badge(i.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                i.customer,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${i.currency} ${i.total.toStringAsFixed(i.currency == 'JOD' ? 3 : 2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Demo workspace · Changes last until the app restarts',
                  style: TextStyle(fontSize: 12, color: Color(0xFF657871)),
                ),
              ])
            : pageBody([
                heading('Settings', 'Make InvoFlow feel like your workspace.'),
                panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice defaults',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: currency,
                        decoration: const InputDecoration(
                          labelText: 'Default currency',
                        ),
                        items: ['JOD', 'USD', 'EUR']
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => currency = v!),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tax-inclusive prices'),
                        subtitle: const Text(
                          'Include 16% sample tax in item prices',
                        ),
                        value: inclusive,
                        onChanged: (v) => setState(() => inclusive = v),
                      ),
                      const Text(
                        'Defaults apply to new invoices. Sample prices are for interface exploration.',
                        style: TextStyle(color: Color(0xFF657871), height: 1.5),
                      ),
                    ],
                  ),
                ),
                panel(
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.light_mode_outlined, color: green),
                    title: Text('Light appearance'),
                    subtitle: Text('Simple, clear, and easy on the eyes'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave demo'),
                ),
              ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class InvoiceEditor extends StatefulWidget {
  const InvoiceEditor({
    super.key,
    this.invoice,
    required this.currency,
    required this.inclusive,
    required this.number,
  });
  final Invoice? invoice;
  final String currency, number;
  final bool inclusive;
  @override
  State<InvoiceEditor> createState() => _InvoiceEditorState();
}

class _InvoiceEditorState extends State<InvoiceEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController customer;
  late String currency;
  late bool inclusive;
  late List<InvoiceLine> lines;
  @override
  void initState() {
    super.initState();
    customer = TextEditingController(text: widget.invoice?.customer ?? '');
    currency = widget.invoice?.currency ?? widget.currency;
    inclusive = widget.invoice?.inclusive ?? widget.inclusive;
    lines = widget.invoice?.lines.map((l) => l.copy()).toList() ?? [];
  }

  @override
  void dispose() {
    customer.dispose();
    super.dispose();
  }

  Future<void> addProduct() async {
    final product = await showModalBottomSheet<InvoiceLine>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading(
                  'Add a product',
                  'Sample catalog · prices shown in $currency',
                ),
                ...[
                  InvoiceLine('Wireless keyboard', 28),
                  InvoiceLine('USB-C hub', 35),
                  InvoiceLine('Desk stand', 24),
                ].map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: paper,
                      child: Icon(Icons.inventory_2_outlined, color: green),
                    ),
                    title: Text(p.name),
                    subtitle: Text('$currency ${p.price.toStringAsFixed(3)}'),
                    trailing: const Icon(
                      Icons.add_circle_outline,
                      color: green,
                    ),
                    onTap: () => Navigator.pop(ctx, p),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (product == null || !mounted) {
      return;
    }
    setState(() {
      final existing = lines.indexWhere((l) => l.name == product.name);
      if (existing < 0) {
        lines.add(product);
      } else {
        lines[existing].quantity++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = Invoice(
      widget.invoice?.number ?? widget.number,
      customer.text,
      currency,
      lines,
      inclusive: inclusive,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'New invoice' : 'Edit invoice'),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: pageBody([
            heading(
              'Start with the details',
              'Save a draft, then review it before approval.',
            ),
            TextFormField(
              controller: customer,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Customer name',
                hintText: 'e.g. Olive Studio',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter a customer name'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: currency,
              decoration: const InputDecoration(labelText: 'Invoice currency'),
              items: [
                'JOD',
                'USD',
                'EUR',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => currency = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tax-inclusive prices'),
              subtitle: const Text('Sample tax rate: 16%'),
              value: inclusive,
              onChanged: (v) => setState(() => inclusive = v),
            ),
            const SizedBox(height: 18),
            const Text(
              'ITEMS',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (lines.isEmpty)
              panel(
                const Text(
                  'Add a product to start your invoice. You can adjust quantities below.',
                ),
              ),
            ...lines.map(
              (l) => panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text('$currency ${l.price.toStringAsFixed(3)} ×'),
                        IconButton(
                          tooltip: 'Decrease quantity',
                          onPressed: () => setState(() {
                            if (l.quantity > 1) {
                              l.quantity--;
                            } else {
                              lines.remove(l);
                            }
                          }),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('${l.quantity}'),
                        IconButton(
                          tooltip: 'Increase quantity',
                          onPressed: () => setState(() => l.quantity++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'Remove item',
                          onPressed: () => setState(() => lines.remove(l)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            ),
            const SizedBox(height: 20),
            totals(draft),
            const Text(
              'Demo prices are independent of exchange rates. Live currency conversion and barcode scanning require backend/device integration.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF657871),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                if (!form.currentState!.validate()) return;
                if (lines.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add at least one product.')),
                  );
                  return;
                }
                draft.customer = customer.text.trim();
                Navigator.pop(context, draft);
              },
              child: const Text('Save draft'),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget totals(Invoice invoice) => panel(
  Column(
    children: [
      amountRow(
        invoice.inclusive ? 'Subtotal (before tax)' : 'Subtotal',
        invoice.inclusive ? invoice.subtotal - invoice.tax : invoice.subtotal,
        invoice.currency,
      ),
      const SizedBox(height: 12),
      amountRow(
        invoice.inclusive ? 'Included tax · 16%' : 'Tax · 16%',
        invoice.tax,
        invoice.currency,
      ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(),
      ),
      amountRow('Total', invoice.total, invoice.currency, bold: true),
    ],
  ),
);

Widget amountRow(
  String label,
  double amount,
  String currency, {
  bool bold = false,
}) => Row(
  children: [
    Expanded(
      child: Text(
        label,
        style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
    ),
    const SizedBox(width: 8),
    Flexible(
      child: Text(
        '$currency ${amount.toStringAsFixed(currency == 'JOD' ? 3 : 2)}',
        textAlign: TextAlign.end,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          fontSize: bold ? 20 : 14,
        ),
      ),
    ),
  ],
);

class InvoiceDetails extends StatefulWidget {
  const InvoiceDetails({
    super.key,
    required this.invoice,
    required this.onEdit,
    required this.onDelete,
  });
  final Invoice invoice;
  final Future<void> Function() onEdit;
  final VoidCallback onDelete;
  @override
  State<InvoiceDetails> createState() => _InvoiceDetailsState();
}

class _InvoiceDetailsState extends State<InvoiceDetails> {
  Future<void> transition(String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action invoice?'),
        content: Text(
          action == 'Approve'
              ? 'This locks the invoice. Approved invoices cannot be edited.'
              : action == 'Delete'
              ? 'This removes the draft from this demo workspace.'
              : 'This marks the invoice as cancelled and keeps it in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (action == 'Delete') {
      widget.onDelete();
      Navigator.pop(context);
    } else {
      setState(
        () => widget.invoice.status = action == 'Approve'
            ? 'Approved'
            : 'Cancelled',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.invoice;
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice details')),
      body: SafeArea(
        child: pageBody([
          Align(alignment: Alignment.centerLeft, child: badge(i.status)),
          const SizedBox(height: 16),
          heading(i.number, i.customer),
          panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INVOICE ITEMS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.6,
                    color: Color(0xFF657871),
                  ),
                ),
                const SizedBox(height: 16),
                ...i.lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: amountRow(
                      '${l.name}\n${l.quantity} × ${l.price.toStringAsFixed(3)}',
                      l.price * l.quantity,
                      i.currency,
                    ),
                  ),
                ),
              ],
            ),
          ),
          totals(i),
          if (i.status == 'Draft') ...[
            FilledButton.icon(
              onPressed: () => transition('Approve'),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve invoice'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await widget.onEdit();
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit draft'),
            ),
            TextButton(
              onPressed: () => transition('Delete'),
              child: const Text(
                'Delete draft',
                style: TextStyle(color: Color(0xFF9C4949)),
              ),
            ),
          ] else if (i.status == 'Approved') ...[
            panel(
              const Row(
                children: [
                  Icon(Icons.lock_outline, color: green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Approved and locked. This invoice is ready for your records.',
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => transition('Cancel'),
              child: const Text('Cancel invoice'),
            ),
          ] else
            panel(
              const Text(
                'This invoice was cancelled. It is kept here for your records and cannot be edited.',
              ),
            ),
        ]),
      ),
    );
  }
}
