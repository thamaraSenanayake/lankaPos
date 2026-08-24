import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../viewmodels/business_health_viewmodel.dart';
import '../widgets/custom_text_field.dart';

class BusinessHealthView extends ConsumerWidget {
  const BusinessHealthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessHealthProvider);
    final viewModel = ref.read(businessHealthProvider.notifier);

    final isLargeScreen = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Business Health & P&L 📊',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF10B981)),
            onPressed: () => viewModel.loadHealth(),
          ),
        ],
      ),
      body: SafeArea(
        child: isLargeScreen
            ? Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_android, size: 64, color: Color(0xFF10B981)),
                          const SizedBox(height: 16),
                          Text(
                            'Responsive Layout Notice',
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Please view on a mobile device or toggle simulator viewport size to check details.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : _buildMobileLayout(context, state, viewModel),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    BusinessHealthState state,
    BusinessHealthViewModel viewModel,
  ) {
    final formattedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date Range Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Analytics',
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _showRangePicker(context, state, viewModel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF334155), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 14, color: Color(0xFFBBCABF)),
                        const SizedBox(width: 6),
                        Text(
                          '${state.selectedRange} (${formattedMonth})',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFFBBCABF)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Horizontal metrics swipe carousel
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              // Net Profit Card
              _buildMetricCard(
                title: 'Net Profit',
                value: 'LKR ${viewModel.netProfitOrLoss.toStringAsFixed(0)}',
                icon: Icons.trending_up,
                isHighlighted: true,
                trendColor: viewModel.netProfitOrLoss >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
              ),
              const SizedBox(width: 12),

              // Total Revenue Card
              _buildMetricCard(
                title: 'Total Revenue',
                value: 'LKR ${viewModel.grossSalesRevenue.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet,
                isHighlighted: false,
                iconColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 12),

              // Cost of Goods Card
              _buildMetricCard(
                title: 'Cost of Goods (COGS)',
                value: 'LKR ${viewModel.costOfGoodsSold.toStringAsFixed(0)}',
                icon: Icons.shopping_cart,
                isHighlighted: false,
                iconColor: const Color(0xFFBBCABF),
              ),
              const SizedBox(width: 12),

              // Operating Expenses Card
              _buildMetricCard(
                title: 'Operating Exp',
                value: 'LKR ${viewModel.totalShopExpenses.toStringAsFixed(0)}',
                icon: Icons.receipt_long,
                isHighlighted: false,
                iconColor: const Color(0xFFBBCABF),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Daily Sales visual bar chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Sales (Last 7 Days)',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              _buildDailySalesChart(viewModel),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent Shop Expenses List
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Shop Expenses',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'VIEW ALL',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF334155), height: 1),
              state.expenses.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No expenses logged yet.',
                          style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 12),
                        ),
                      ),
                    )
                  : Column(
                      children: viewModel.filteredExpenses.map((exp) {
                        return _buildExpenseRow(context, exp, viewModel);
                      }).toList(),
                    ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Primary Action Logger Trigger
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: const Color(0xFF0F172A),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          icon: const Icon(Icons.add),
          label: Text(
            'Log New Shop Expense',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
          onPressed: () => _showLogExpenseDialog(context, viewModel),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '(Rent, Bills, Wages, Logistics)',
            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBBCABF).withOpacity(0.6)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isHighlighted,
    Color? iconColor,
    Color? trendColor,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? const Color(0xFF10B981) : const Color(0xFF334155),
          width: isHighlighted ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFBBCABF),
                ),
              ),
              Icon(icon, color: isHighlighted ? trendColor : iconColor, size: 18),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? (trendColor ?? Colors.white) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySalesChart(BusinessHealthViewModel viewModel) {
    final weeklySales = viewModel.weeklySalesGraphData;
    final maxSale = weeklySales.fold(1.0, (m, element) => element > m ? element : m);

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final amount = weeklySales[index];
        final percentageHeight = (amount / maxSale).clamp(0.05, 1.0);
        final height = 90 * percentageHeight;

        final isToday = DateTime.now().weekday - 1 == index;

        return Column(
          children: [
            Text(
              amount > 0 ? '${(amount / 1000).toStringAsFixed(0)}k' : '-',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFF10B981) : const Color(0xFFBBCABF),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: height,
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFF10B981) : const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              days[index],
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? const Color(0xFF10B981) : const Color(0xFFBBCABF),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildExpenseRow(BuildContext context, Expense exp, BusinessHealthViewModel viewModel) {
    final formattedDate = DateFormat('MMM dd, yyyy').format(exp.timestamp);
    IconData icon = Icons.storefront;
    if (exp.category == 'Bills') icon = Icons.bolt;
    if (exp.category == 'Wages') icon = Icons.badge;
    if (exp.category == 'Transport') icon = Icons.two_wheeler;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF273647), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFFBBCABF), size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    exp.note.isEmpty ? exp.category : exp.note,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$formattedDate ${exp.photoPath.isNotEmpty ? " • 📷 Receipt" : ""}',
                    style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBBCABF)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '- LKR ${exp.amount.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  final confirmed = await _showConfirmDeleteDialog(context, exp.category);
                  if (confirmed == true) {
                    await viewModel.deleteExpense(exp.id!);
                  }
                },
              )
            ],
          )
        ],
      ),
    );
  }

  void _showRangePicker(BuildContext context, BusinessHealthState state, BusinessHealthViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filter Report Range',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            _buildRangeOption(context, 'Today', state.selectedRange, viewModel),
            _buildRangeOption(context, 'This Week', state.selectedRange, viewModel),
            _buildRangeOption(context, 'This Month', state.selectedRange, viewModel),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildRangeOption(
    BuildContext context,
    String label,
    String selected,
    BusinessHealthViewModel viewModel,
  ) {
    final isSel = label == selected;
    return ListTile(
      title: Text(label, style: TextStyle(color: isSel ? const Color(0xFF10B981) : Colors.white, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
      trailing: isSel ? const Icon(Icons.check, color: Color(0xFF10B981)) : null,
      onTap: () {
        viewModel.changeRange(label);
        Navigator.pop(context);
      },
    );
  }

  void _showLogExpenseDialog(BuildContext context, BusinessHealthViewModel viewModel) {
    String selectedCategory = 'Bills';
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String photoPath = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
              title: Text(
                'Log Shop Expense',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text('EXPENSE TYPE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          dropdownColor: const Color(0xFF0F172A),
                          decoration: const InputDecoration(border: InputBorder.none),
                          style: const TextStyle(color: Colors.white),
                          items: ['Bills', 'Rent', 'Wages', 'Transport', 'Stock Purchase']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Amount
                      CustomTextField(
                        label: 'Amount (LKR)',
                        placeholder: 'e.g. 15000',
                        controller: amountController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),

                      // Notes
                      CustomTextField(
                        label: 'Notes / Memo',
                        placeholder: 'e.g. CEB Electricity bill August',
                        controller: noteController,
                      ),
                      const SizedBox(height: 16),

                      // Photo receipts simulation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            photoPath.isEmpty ? 'No Receipt Photo Attached' : 'Receipt_Capture_821.jpg',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF)),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF10B981)),
                            label: Text(
                              photoPath.isEmpty ? 'CAMERA' : 'RETAKE',
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
                            ),
                            onPressed: () {
                              setModalState(() {
                                photoPath = 'mock_receipt_captured_path_821.jpg';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Mock Camera: Photo captured successfully!'), backgroundColor: Color(0xFF10B981)),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
                  onPressed: () {
                    final amt = double.tryParse(amountController.text) ?? 0.0;
                    final note = noteController.text.trim();
                    if (amt > 0) {
                      viewModel.logExpense(selectedCategory, amt, note, photoPath);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logged LKR $amt under $selectedCategory.'), backgroundColor: const Color(0xFF10B981)),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('LOG EXPENSE'),
                )
              ],
            );
          },
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
          title: const Text('Delete Expense?', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to permanently delete $name expense record?'),
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
