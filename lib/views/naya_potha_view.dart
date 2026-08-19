import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/credit_account.dart';
import '../models/supplier_account.dart';
import '../viewmodels/naya_potha_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class NayaPothaView extends ConsumerWidget {
  const NayaPothaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nayaPothaProvider);
    final viewModel = ref.read(nayaPothaProvider.notifier);



    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Naya Potha (Credit Ledger) 📖',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: () => viewModel.loadLedger(),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dual Tab Selector
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => viewModel.changeTab('Customer'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: state.activeTab == 'Customer' ? const Color(0xFF0F172A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Customer Debtors',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: state.activeTab == 'Customer' ? const Color(0xFF10B981) : const Color(0xFFBBCABF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => viewModel.changeTab('Supplier'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: state.activeTab == 'Supplier' ? const Color(0xFF0F172A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Supplier Ledger',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: state.activeTab == 'Supplier' ? const Color(0xFF10B981) : const Color(0xFFBBCABF),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Summary Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155), width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.activeTab == 'Customer' ? 'TOTAL CUSTOMER DEBT' : 'TOTAL SUPPLIER OUTSTANDING',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.activeTab == 'Customer'
                                ? 'LKR ${viewModel.totalCustomerDebt.toStringAsFixed(0)}'
                                : 'LKR ${state.suppliers.fold(0.0, (sum, s) => sum + s.balance).toStringAsFixed(0)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: const Color(0xFF334155),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.activeTab == 'Customer' ? 'OVERDUE ACCOUNTS' : 'ACTIVE INVOICES',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state.activeTab == 'Customer'
                                ? '${viewModel.overdueRemindersCount} Customers'
                                : '${state.suppliers.where((s) => s.balance > 0).length} Suppliers',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Filter
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF334155), width: 0.5),
                ),
                child: TextField(
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  onChanged: viewModel.updateSearchKeyword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFBBCABF), size: 18),
                    hintText: state.activeTab == 'Customer'
                        ? 'Search debtor by name or phone...'
                        : 'Search distributor by name...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

            // List of Accounts
            Expanded(
              child: state.activeTab == 'Customer'
                  ? _buildCustomerList(context, ref, viewModel)
                  : _buildSupplierList(context, viewModel),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: const Color(0xFF0F172A),
        icon: Icon(state.activeTab == 'Customer' ? Icons.person_add : Icons.add_business),
        label: Text(
          state.activeTab == 'Customer' ? 'New Customer' : 'New Supplier',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        onPressed: () {
          if (state.activeTab == 'Customer') {
            _showAddCustomerDialog(context, viewModel);
          } else {
            _showAddSupplierDialog(context, viewModel);
          }
        },
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, WidgetRef ref, NayaPothaViewModel viewModel) {
    final list = viewModel.filteredCustomers;

    if (list.isEmpty) {
      return Center(
        child: Text(
          'No debtor profiles found.',
          style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final debtor = list[index];
        final formattedDate = DateFormat('yyyy-MM-dd').format(debtor.lastUpdated);

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debtor.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 12, color: Color(0xFFBBCABF)),
                            const SizedBox(width: 4),
                            Text(
                              debtor.phone.isEmpty ? 'NO PHONE' : debtor.phone,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL DUE',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'LKR ${debtor.balance.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: debtor.balance > 0 ? Colors.redAccent : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Last Purchase/Payment: $formattedDate',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF).withOpacity(0.8)),
                ),
                const Divider(color: Color(0xFF334155), height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.payments, size: 16),
                        label: const Text('Record Payment'),
                        onPressed: () => _showRecordPaymentDialog(context, debtor, viewModel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                      tooltip: 'WhatsApp Reminder',
                      onPressed: () {
                        final shop = ref.read(dashboardProvider).config?.shopName ?? 'Store';
                        final msg = viewModel.getWhatsAppMessage(debtor, shop);
                        _showWhatsAppMessagePreview(context, debtor, msg);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () async {
                        final confirm = await _showConfirmDeleteDialog(context, debtor.name);
                        if (confirm == true) viewModel.deleteCustomer(debtor.id!);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupplierList(BuildContext context, NayaPothaViewModel viewModel) {
    final list = viewModel.filteredSuppliers;

    if (list.isEmpty) {
      return Center(
        child: Text(
          'No distributor invoice records found.',
          style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final supplier = list[index];
        final formattedDueDate = DateFormat('yyyy-MM-dd').format(supplier.dueDate);

        return Card(
          color: const Color(0xFF1E293B),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF334155), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 12, color: Color(0xFFBBCABF)),
                            const SizedBox(width: 4),
                            Text(
                              supplier.phone.isEmpty ? 'NO PHONE' : supplier.phone,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL OUTSTANDING',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'LKR ${supplier.balance.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: supplier.balance > 0 ? Colors.redAccent : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Invoice Due Date: $formattedDueDate',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: supplier.dueDate.isBefore(DateTime.now()) ? Colors.redAccent : const Color(0xFFBBCABF),
                  ),
                ),
                const Divider(color: Color(0xFF334155), height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.payments, size: 16),
                        label: const Text('Pay Supplier'),
                        onPressed: () => _showRecordSupplierPaymentDialog(context, supplier, viewModel),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () async {
                        final confirm = await _showConfirmDeleteDialog(context, supplier.name);
                        if (confirm == true) viewModel.deleteSupplier(supplier.id!);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecordPaymentDialog(BuildContext context, CreditAccount debtor, NayaPothaViewModel viewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Record Naya Payment', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter collected amount from ${debtor.name}:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF))),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. 1000',
                  prefixText: 'LKR ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
              onPressed: () {
                final amt = double.tryParse(controller.text) ?? 0.0;
                if (amt > 0) {
                  viewModel.recordCustomerPayment(debtor.id!, amt);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recorded LKR $amt payment for ${debtor.name}'), backgroundColor: const Color(0xFF10B981)),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('RECORD'),
            )
          ],
        );
      },
    );
  }

  void _showRecordSupplierPaymentDialog(BuildContext context, SupplierAccount supplier, NayaPothaViewModel viewModel) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Record Supplier Settlement', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter paid invoice amount to ${supplier.name}:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF))),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. 5000',
                  prefixText: 'LKR ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
              onPressed: () {
                final amt = double.tryParse(controller.text) ?? 0.0;
                if (amt > 0) {
                  viewModel.recordSupplierPayment(supplier.id!, amt);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recorded LKR $amt paid to supplier ${supplier.name}'), backgroundColor: const Color(0xFF10B981)),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('RECORD'),
            )
          ],
        );
      },
    );
  }

  void _showWhatsAppMessagePreview(BuildContext context, CreditAccount account, String msg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF334155))),
          title: Row(
            children: const [
              Icon(Icons.chat, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text('WhatsApp Credit Reminder', style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pre-filled reminder message for ${account.name} (${account.phone}):',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Text(
                  msg,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '[Simulating redirect launcher to WhatsApp...]',
                style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontStyle: FontStyle.italic),
              )
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
              child: const Text('SEND MOCK Remind'),
            )
          ],
        );
      },
    );
  }

  void _showAddCustomerDialog(BuildContext context, NayaPothaViewModel viewModel) {
    final nameCont = TextEditingController();
    final phoneCont = TextEditingController();
    final balCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('New Debt Account', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCont,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Customer Name', hintStyle: TextStyle(color: Colors.white30)),
              ),
              TextField(
                controller: phoneCont,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Phone Number', hintStyle: TextStyle(color: Colors.white30)),
              ),
              TextField(
                controller: balCont,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Initial Debt (LKR)', hintStyle: TextStyle(color: Colors.white30)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF)))),
            ElevatedButton(
              onPressed: () {
                final name = nameCont.text.trim();
                final phone = phoneCont.text.trim();
                final bal = double.tryParse(balCont.text) ?? 0.0;
                if (name.isNotEmpty) {
                  viewModel.addCustomerAccount(name, phone, bal);
                }
                Navigator.pop(context);
              },
              child: const Text('CREATE'),
            )
          ],
        );
      },
    );
  }

  void _showAddSupplierDialog(BuildContext context, NayaPothaViewModel viewModel) {
    final nameCont = TextEditingController();
    final phoneCont = TextEditingController();
    final balCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('New Supplier Ledger', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCont,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Supplier / Distributor Name', hintStyle: TextStyle(color: Colors.white30)),
              ),
              TextField(
                controller: phoneCont,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Contact Phone', hintStyle: TextStyle(color: Colors.white30)),
              ),
              TextField(
                controller: balCont,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Invoice Due (LKR)', hintStyle: TextStyle(color: Colors.white30)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF)))),
            ElevatedButton(
              onPressed: () {
                final name = nameCont.text.trim();
                final phone = phoneCont.text.trim();
                final bal = double.tryParse(balCont.text) ?? 0.0;
                if (name.isNotEmpty) {
                  viewModel.addSupplierAccount(name, phone, bal, DateTime.now().add(const Duration(days: 7)));
                }
                Navigator.pop(context);
              },
              child: const Text('CREATE'),
            )
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to permanently delete $name from credit history?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF)))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}
