import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../dialogs/item_discount_dialog.dart';
import '../../dialogs/bill_discount_dialog.dart';
import '../../dialogs/payment_drawer_dialog.dart';
import '../../../viewmodels/naya_potha_viewmodel.dart';
import '../../../viewmodels/business_health_viewmodel.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  static void showMobileCartBottomSheet(
    BuildContext context,
    WidgetRef ref,
    DashboardState state,
    DashboardViewModel viewModel,
  ) {
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
          child: buildCartPanel(context, ref, state, viewModel, isMobile: true),
        );
      },
    );
  }

  static Widget buildCartPanel(
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
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
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
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
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
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final viewModel = ref.read(dashboardProvider.notifier);
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
                padding: const EdgeInsets.only(right: 15, top: 5, left: 15),
                child: CustomTextField(
                  label: null,
                  prefixIcon: Icons.search,
                  controller: null,
                  placeholder: 'Search product or scan ISBN/EAN',
                  onChange: viewModel.updateSearchKeyword,
                ),
              ),

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
            child: buildCartPanel(context, ref, state, viewModel, isMobile: false),
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
}
