import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);

    return Container(
      width: 90,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          right: BorderSide(color: Color(0xFF273647), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSidebarButton(
            icon: Icons.point_of_sale,
            label: 'Register',
            isActive: state.activeTab == 'register',
            onTap: () => viewModel.changeTab('register'),
          ),
          _buildSidebarButton(
            icon: Icons.receipt_long,
            label: 'Orders',
            isActive: state.activeTab == 'orders',
            onTap: () => viewModel.changeTab('orders'),
          ),
          _buildSidebarButton(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            isActive: state.activeTab == 'inventory',
            onTap: () => viewModel.changeTab('inventory'),
          ),
          _buildSidebarButton(
            icon: Icons.analytics,
            label: 'Reports',
            isActive: state.activeTab == 'reports',
            onTap: () => viewModel.changeTab('reports'),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF10B981).withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? const Color(0xFF10B981) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFBBCABF),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF10B981) : const Color(0xFFBBCABF),
              ),
            )
          ],
        ),
      ),
    );
  }
}
