import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);

    return BottomNavigationBar(
      currentIndex: _activeTabIndex(state.activeTab),
      onTap: (index) {
        final tabs = ['register', 'orders', 'inventory', 'reports'];
        viewModel.changeTab(tabs[index]);
      },
      backgroundColor: const Color(0xFF1E293B),
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: const Color(0xFFBBCABF),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 11),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Register'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
      ],
    );
  }

  int _activeTabIndex(String activeTab) {
    switch (activeTab) {
      case 'orders':
        return 1;
      case 'inventory':
        return 2;
      case 'reports':
        return 3;
      case 'register':
      default:
        return 0;
    }
  }
}
