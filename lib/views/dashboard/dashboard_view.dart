import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/dashboard_viewmodel.dart';
import '../inventory_view.dart';
import 'screens/register_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/reports_screen.dart';
import 'subWidgets/top_app_bar.dart';
import 'subWidgets/sidebar.dart';
import 'subWidgets/bottom_nav_bar.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);

    if (state.config == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    final isLargeScreen = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            const TopAppBar(),

            // Content Area with Sidebar or main screen
            Expanded(
              child: Row(
                children: [
                  if (isLargeScreen) const Sidebar(),
                  Expanded(
                    child: _buildActiveScreen(state),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isLargeScreen ? const BottomNavBar() : null,
      floatingActionButton: !isLargeScreen && state.activeTab == 'register' && state.cart.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: const Color(0xFF0F172A),
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'Cart (${state.cart.length}) - LKR ${viewModel.cartTotal.toStringAsFixed(0)}',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                RegisterScreen.showMobileCartBottomSheet(context, ref, state, viewModel);
              },
            )
          : null,
    );
  }

  Widget _buildActiveScreen(DashboardState state) {
    switch (state.activeTab) {
      case 'orders':
        return const OrdersScreen();
      case 'inventory':
        return const InventoryView();
      case 'reports':
        return const ReportsScreen();
      case 'register':
      default:
        return const RegisterScreen();
    }
  }
}
