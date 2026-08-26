import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../../viewmodels/naya_potha_viewmodel.dart';
import '../../naya_potha_view.dart';
import '../../business_health_view.dart';
import '../../hardware_settings_view.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);

    final todaySales = viewModel.totalIncomeToday;
    final todayTx = viewModel.salesCountToday;

    // Read from live credit ledger databases
    final nayaState = ref.watch(nayaPothaProvider);
    final creditLedger = nayaState.customers.fold(0.0, (sum, acc) => sum + acc.balance);
    final supplierOutstanding = nayaState.suppliers.fold(0.0, (sum, s) => sum + s.balance);

    final breakdown = viewModel.paymentMethodBreakdown;
    final topSellers = viewModel.topSellingProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Reports Dashboard 📊',
            style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),

          // Operations menu links
          Text(
            'Ledger & System Operations',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF), letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 768 ? 3 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
            children: [
              _buildNavigationCard(
                context,
                title: 'Naya Potha Credit Ledger',
                subtitle: 'Manage customer debts & supplier invoices',
                icon: Icons.menu_book,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NayaPothaView())),
              ),
              _buildNavigationCard(
                context,
                title: 'Business Health & P&L',
                subtitle: 'Analyze sales revenues & cost margins',
                icon: Icons.monitor_heart,
                color: Colors.cyanAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BusinessHealthView())),
              ),
              _buildNavigationCard(
                context,
                title: 'Hardware & POS Settings',
                subtitle: 'Configure printing papers and peripherals',
                icon: Icons.settings,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HardwareSettingsView())),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Analytical Cards Row
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width >= 900 ? 4 : (MediaQuery.of(context).size.width >= 600 ? 2 : 1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildReportMetricCard(
                title: "TODAY'S REVENUE",
                value: 'LKR ${todaySales.toStringAsFixed(0)}',
                subtitle: '$todayTx sales logged today',
                icon: Icons.monetization_on_outlined,
                accentColor: const Color(0xFF10B981),
              ),
              _buildReportMetricCard(
                title: 'OUTSTANDING DEBT (NAYA)',
                value: 'LKR ${creditLedger.toStringAsFixed(0)}',
                subtitle: 'Outstanding store customer credits',
                icon: Icons.menu_book,
                accentColor: Colors.orangeAccent,
              ),
              _buildReportMetricCard(
                title: 'SUPPLIER OUTSTANDING',
                value: 'LKR ${supplierOutstanding.toStringAsFixed(0)}',
                subtitle: 'Outstanding invoices to distributors',
                icon: Icons.add_business,
                accentColor: Colors.purpleAccent,
              ),
              _buildReportMetricCard(
                title: 'TOTAL REGISTER TRANSACTIONS',
                value: '${state.salesHistory.length} bills',
                subtitle: 'All-time checkout transactions',
                icon: Icons.receipt_long_outlined,
                accentColor: Colors.cyanAccent,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Payment breakdowns vs top products
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      'Sales Channels Breakdown',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    ...breakdown.entries.map((e) {
                      final value = e.value;
                      final percentage = viewModel.totalIncomeAllTime > 0
                          ? (value / viewModel.totalIncomeAllTime) * 100
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF), fontWeight: FontWeight.bold)),
                                Text('LKR ${value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%)', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: const Color(0xFF0F172A),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  e.key == 'Naya Potha' ? Colors.orangeAccent : const Color(0xFF10B981),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                      'Top 5 Fast Selling Items',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    topSellers.isEmpty
                        ? Center(
                            child: Text(
                              'No sales logged yet to calculate top products.',
                              style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topSellers.length,
                            itemBuilder: (context, index) {
                              final item = topSellers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Wrap(
                                  runAlignment: WrapAlignment.spaceBetween,
                                  alignment: WrapAlignment.spaceBetween,
                                  // crossAxisAlignment: WrapCrossAlignment.,
                                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '#${index + 1} ${item.key}',
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                    SizedBox(width: 10,),
                                    Text(
                                      '${item.value} units sold',
                                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: const Color(0xFFBBCABF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBBCABF).withOpacity(0.7)),
                ),
              ],
            ),
          ),
          Icon(icon, color: accentColor, size: 28),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFFBBCABF).withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFBBCABF), size: 16),
          ],
        ),
      ),
    );
  }
}
