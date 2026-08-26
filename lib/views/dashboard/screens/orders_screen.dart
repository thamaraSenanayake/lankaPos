import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../models/sale.dart';
import '../../../services/printer_service.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);

    return DefaultTabController(
      length: state.config!.kotEnabled ? 2 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: const Color(0xFF334155),
            indicatorColor: const Color(0xFF10B981),
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: const Color(0xFFBBCABF),
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              const Tab(text: 'Past Sales Logs 📊'),
              if (state.config!.kotEnabled) const Tab(text: 'Kitchen KOT Queue 🍳'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPastSalesLogTab(context, ref, state, viewModel),
                if (state.config!.kotEnabled) _buildKitchenQueueTab(context, state, viewModel),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPastSalesLogTab(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    return state.salesHistory.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: const Color(0xFFBBCABF).withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'No transactions found',
                  style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.5)),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.salesHistory.length,
            itemBuilder: (context, index) {
              final sale = state.salesHistory[index];
              return Card(
                color: const Color(0xFF1E293B),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF334155), width: 0.5),
                ),
                child: ExpansionTile(
                  backgroundColor: Colors.transparent,
                  collapsedBackgroundColor: Colors.transparent,
                  iconColor: const Color(0xFF10B981),
                  collapsedIconColor: const Color(0xFFBBCABF),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bill ID: #${sale.id ?? index + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFFF8FAFC),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('yyyy-MM-dd kk:mm').format(sale.timestamp)} • ${sale.orderType}',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sale.paymentMethod,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sale.paymentMethod == 'Naya Potha' ? Colors.orangeAccent : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    'LKR ${sale.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xFFF8FAFC),
                    ),
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF111E2E),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sale.customerName != null) ...[
                            Text(
                              'Customer/Debt Ledger: ${sale.customerName}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            'Itemized Items Details:',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFBBCABF), fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          ...sale.items.map((i) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${i.quantity}x ${i.name}', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                                    Text('LKR ${i.total.toStringAsFixed(0)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              )),
                          const Divider(color: Color(0xFF334155), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal:', style: GoogleFonts.inter(color: const Color(0xFFBBCABF), fontSize: 12)),
                              Text('LKR ${(sale.totalAmount + sale.discountAmount).toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                          if (sale.discountAmount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Discount:', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12)),
                                Text('- LKR ${sale.discountAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.orangeAccent, fontSize: 12)),
                              ],
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E293B),
                                  foregroundColor: const Color(0xFF10B981),
                                  side: const BorderSide(color: Color(0xFF10B981), width: 0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                icon: const Icon(Icons.print, size: 14),
                                label: const Text('REPRINT RECEIPT'),
                                onPressed: () {
                                  _showReceiptPopup(context, ref, sale);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  void _showReceiptPopup(BuildContext context, WidgetRef ref, Sale sale) async {
    final state = ref.read(dashboardProvider);
    final config = state.config;
    if (config != null) {
      try {
        final bytes = await PrinterService.instance.generateSaleReceipt(config, sale, '80mm');
        debugPrint('Generated ESC/POS Sale receipt reprint: ${bytes.length} bytes.');
      } catch (e) {
        debugPrint('Failed to generate ESC/POS bytes for sale receipt: $e');
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Invoice Reprint', style: TextStyle(color: Colors.white)),
          content: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF475569)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('=== REPRINT RECEIPT ===', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Text('Order ID: #${sale.id}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                Text('Date: ${DateFormat('yyyy-MM-dd kk:mm').format(sale.timestamp)}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                Text('Payment: ${sale.paymentMethod}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                const Divider(color: Color(0xFF334155), height: 8),
                ...sale.items.map((i) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${i.quantity}x ${i.name}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        Text('LKR ${i.total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    )),
                const Divider(color: Color(0xFF334155), height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('LKR ${sale.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  Widget _buildKitchenQueueTab(
    BuildContext context,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    return state.activeKotQueue.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.kitchen_outlined, size: 64, color: const Color(0xFFBBCABF).withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'No active KOT orders in kitchen',
                  style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.5)),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: state.activeKotQueue.length,
            itemBuilder: (context, index) {
              final ticket = state.activeKotQueue[index];
              return Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF334155), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'KOT TICKET #${ticket.id}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          Text(
                            DateFormat('kk:mm:ss').format(ticket.timestamp),
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF)),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF334155), height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: ticket.items.length,
                          itemBuilder: (context, idx) {
                            final item = ticket.items[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${item.quantity}x ${item.name}',
                                style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            viewModel.completeKotOrder(ticket.id!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('KOT Ticket #${ticket.id} served!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          },
                          child: Text(
                            'SERVE TICKET',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
