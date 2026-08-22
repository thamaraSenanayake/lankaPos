import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../models/sale.dart';
import 'business_setup_view.dart';
import 'inventory_view.dart';
import 'naya_potha_view.dart';
import 'business_health_view.dart';
import 'hardware_settings_view.dart';
import '../viewmodels/naya_potha_viewmodel.dart';
import '../viewmodels/business_health_viewmodel.dart';
import 'dialogs/mock_scanner_dialog.dart';
import 'dialogs/payment_drawer_dialog.dart';
import 'dialogs/item_discount_dialog.dart';
import 'dialogs/bill_discount_dialog.dart';

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
            _buildTopAppBar(context, state, viewModel),

            // Content Area with Sidebar or main screen
            Expanded(
              child: Row(
                children: [
                  if (isLargeScreen) _buildSidebar(state, viewModel),
                  Expanded(
                    child: _buildActiveScreen(context, ref, state, viewModel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isLargeScreen ? _buildBottomNavBar(state, viewModel) : null,
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
                _showMobileCartBottomSheet(context, ref, state, viewModel);
              },
            )
          : null,
    );
  }

  // --- TOP APP BAR ---
  Widget _buildTopAppBar(
    BuildContext context,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF273647), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // App Title
          Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 8),
              Text(
                'LankaPOS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),

          // Search Field (Only for Register Tab)
          if (state.activeTab == 'register')
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF475569), width: 0.5),
                ),
                child: TextField(
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  onChanged: viewModel.updateSearchKeyword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFBBCABF), size: 20),
                    hintText: 'Search product or scan ISBN/EAN',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          // const SizedBox(width: 16),

          // Camera Barcode Scanner Trigger Button
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
            tooltip: 'Camera Barcode Lookup',
            onPressed: () {
              showDialog(
                context: context,
                builder: (c) => const MockScannerDialog(),
              );
            },
          ),

          const SizedBox(width: 12),

          // Cashier Profile


          IconButton(
            icon: const Icon(Icons.settings_backup_restore, color: Colors.orangeAccent),
            tooltip: 'Reconfigure POS',
            onPressed: () => _showResetDialog(context, viewModel),
          ),
        ],
      ),
    );
  }

  // --- NAVIGATION SIDEBAR (DESKTOP) ---
  Widget _buildSidebar(DashboardState state, DashboardViewModel viewModel) {
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

  // --- BOTTOM NAV BAR (MOBILE) ---
  Widget _buildBottomNavBar(DashboardState state, DashboardViewModel viewModel) {
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

  // --- DISPATCH ACTIVE SCREEN ---
  Widget _buildActiveScreen(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    switch (state.activeTab) {
      case 'orders':
        return _buildOrdersScreen(context, state, viewModel);
      case 'inventory':
        return const InventoryView();
      case 'reports':
        return _buildReportsScreen(context, ref, state, viewModel);
      case 'register':
      default:
        return _buildRegisterScreen(context, ref, state, viewModel);
    }
  }

  // ==========================================
  // SCREEN 1: REGISTER SCREEN
  // ==========================================
  Widget _buildRegisterScreen(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
    final isDesktop = MediaQuery.of(context).size.width >= 950;

    return Row(
      children: [
        // Grid Products Pane
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.config!.kotEnabled)
                _buildOrderTypeSelector(state, viewModel),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Quick Items Catalog',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF8FAFC),
                  ),
                ),
              ),

              // Catalog Grid
              Expanded(
                child: viewModel.filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No products matched this filter search.',
                          style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4)),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: viewModel.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = viewModel.filteredProducts[index];
                          return _buildCatalogCard(product, viewModel);
                        },
                      ),
              ),
            ],
          ),
        ),

        // Cart Drawer Panel (Only on desktop)
        if (isDesktop)
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(
                left: BorderSide(color: Color(0xFF273647), width: 0.5),
              ),
            ),
            child: _buildCartPanel(context, ref, state, viewModel, isMobile: false),
          ),
      ],
    );
  }

  Widget _buildOrderTypeSelector(DashboardState state, DashboardViewModel viewModel) {
    final businessType = state.config!.businessType;
    final List<String> allowedTypes = [];

    if (businessType == 'Restaurant & Hotel' || businessType == 'Cafe & Bakery') {
      allowedTypes.addAll(['Dine-In', 'Takeaway', 'Delivery']);
    } else {
      allowedTypes.addAll(['Retail', 'Delivery']);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: allowedTypes.map((type) {
            final isSelected = state.orderType == type;
            IconData icon = Icons.storefront;
            if (type == 'Dine-In') icon = Icons.restaurant;
            if (type == 'Takeaway') icon = Icons.shopping_bag;
            if (type == 'Delivery') icon = Icons.two_wheeler;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                showCheckmark: false,
                avatar: Icon(icon, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFBBCABF), size: 16),
                label: Text(
                  type == 'Dine-In' ? 'Table Dine-In (KOT)' : type,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFBBCABF),
                  ),
                ),
                selected: isSelected,
                onSelected: (val) {
                  if (val) viewModel.setOrderType(type);
                },
                selectedColor: const Color(0xFF10B981),
                backgroundColor: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF334155)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCatalogCard(ProductItem product, DashboardViewModel viewModel) {
    return InkWell(
      onTap: () => viewModel.addToCart(product),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              product.emoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF8FAFC),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'LKR ${product.price.toStringAsFixed(0)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardViewModel viewModel, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Current Bill',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${state.cart.length} items',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (state.cart.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 22),
                  onPressed: viewModel.clearCart,
                )
            ],
          ),
        ),
        const Divider(color: Color(0xFF334155), height: 1),

        // Cart Scroll
        Expanded(
          child: state.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_checkout_outlined, size: 40, color: const Color(0xFFBBCABF).withOpacity(0.3)),
                      const SizedBox(height: 8),
                      Text(
                        'Checkout cart is empty',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF).withOpacity(0.4)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.cart.length,
                  itemBuilder: (context, index) {
                    final item = state.cart[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'LKR ${item.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF)),
                                    ),
                                    if (item.discount > 0) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '-${item.discount.toStringAsFixed(0)}%',
                                        style: GoogleFonts.inter(fontSize: 11, color: Colors.orangeAccent, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (c) => ItemDiscountDialog(item: item, viewModel: viewModel),
                                        );
                                      },
                                      child: Text(
                                        'Discount',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF10B981),
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: Color(0xFFBBCABF)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => viewModel.updateQuantity(item.name, -1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${item.quantity}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF10B981)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => viewModel.updateQuantity(item.name, 1),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 65,
                            child: Text(
                              'LKR ${item.total.toStringAsFixed(0)}',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => viewModel.removeFromCart(item.name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(color: Color(0xFF334155), height: 1),

        // Totals & Checkout Proceed Panel
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF111E2E),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF))),
                  Text('LKR ${viewModel.cartSubtotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Bill Discount ', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF))),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (c) => BillDiscountDialog(state: state, viewModel: viewModel),
                          );
                        },
                        child: Text(
                          '(${state.cartDiscount.toStringAsFixed(0)}%)',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('- LKR ${viewModel.cartDiscountAmount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 13, color: Colors.orangeAccent)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GRAND TOTAL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white)),
                  Text(
                    'LKR ${viewModel.cartTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: const Color(0xFF0F172A),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: state.cart.isEmpty
                      ? null
                      : () {
                          if (isMobile) Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (c) => PaymentDrawerDialog(
                              state: state,
                              viewModel: viewModel,
                              onCheckoutSuccess: () {
                                ref.read(nayaPothaProvider.notifier).loadLedger();
                                ref.read(businessHealthProvider.notifier).loadHealth();
                              },
                            ),
                          );
                        },
                  child: Text(
                    'PROCEED TO CHECKOUT',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMobileCartBottomSheet(BuildContext context, WidgetRef ref, DashboardState state, DashboardViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: _buildCartPanel(context, ref, state, viewModel, isMobile: true),
        );
      },
    );
  }

  // ==========================================
  // SCREEN 2: ORDERS SCREEN
  // ==========================================
  Widget _buildOrdersScreen(
    BuildContext context,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
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
                _buildPastSalesLogTab(context, state, viewModel),
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
                                  // Trigger mock dialog inside payment_drawer
                                  _showReceiptPopup(context, sale);
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

  void _showReceiptPopup(BuildContext context, Sale sale) {
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

  // ==========================================
  // SCREEN 3: REPORTS SCREEN
  // ==========================================
  Widget _buildReportsScreen(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
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
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#${index + 1} ${item.key}',
                                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
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

  void _showResetDialog(BuildContext context, DashboardViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF334155)),
          ),
          title: Text(
            'Reset App Settings?',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFFF8FAFC)),
          ),
          content: Text(
            'This will delete your business profile configuration, credit logs, and transaction history. You will be redirected back to the Welcome setup screen. Are you sure?',
            style: GoogleFonts.inter(color: const Color(0xFFBBCABF)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.inter(color: const Color(0xFFBBCABF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await viewModel.clearAllData();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const BusinessSetupView()),
                  (route) => false,
                );
              },
              child: Text(
                'YES, RESET ALL',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
