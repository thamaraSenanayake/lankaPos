import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/business_setup_viewmodel.dart';
import '../widgets/business_type_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/custom_switch.dart';
import '../widgets/custom_text_field.dart';
import 'dashboard_view.dart';

class BusinessSetupView extends ConsumerStatefulWidget {
  const BusinessSetupView({super.key});

  @override
  ConsumerState<BusinessSetupView> createState() => _BusinessSetupViewState();
}

class _BusinessSetupViewState extends ConsumerState<BusinessSetupView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final config = ref.read(businessSetupProvider);
    _nameController = TextEditingController(text: config.shopName);
    _addressController = TextEditingController(text: config.address);
    _phoneController = TextEditingController(text: config.phoneNumber);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(businessSetupProvider.notifier).loadSavedConfig();
      final savedConfig = ref.read(businessSetupProvider);
      if (mounted) {
        _nameController.text = savedConfig.shopName;
        _addressController.text = savedConfig.address;
        _phoneController.text = savedConfig.phoneNumber;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(businessSetupProvider);
    final viewModel = ref.read(businessSetupProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section / Header
            Container(
              padding: const EdgeInsets.only(top: 24, bottom: 16, left: 24, right: 24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF273647),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront,
                        color: Color(0xFF10B981),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LankaPOS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setup Your Business Profile',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF8FAFC),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Customize your register interface in 60s',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFBBCABF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Step 1 of 2',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Main Content Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Business Type Selector
                      Text(
                        'Select Business Type',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          BusinessTypeCard(
                            emoji: '🛒',
                            title: 'Grocery & Retail',
                            description: 'Barcode, loose items, credit book',
                            isSelected: config.businessType == 'Grocery & Retail',
                            onTap: () => viewModel.updateBusinessType('Grocery & Retail'),
                          ),
                          BusinessTypeCard(
                            emoji: '☕',
                            title: 'Cafe & Bakery',
                            description: 'Touch billing, modifiers, takeaway',
                            isSelected: config.businessType == 'Cafe & Bakery',
                            onTap: () => viewModel.updateBusinessType('Cafe & Bakery'),
                          ),
                          BusinessTypeCard(
                            emoji: '🍛',
                            title: 'Restaurant & Hotel',
                            description: 'Dine-In tables, KOT kitchen screen',
                            isSelected: config.businessType == 'Restaurant & Hotel',
                            onTap: () => viewModel.updateBusinessType('Restaurant & Hotel'),
                          ),
                          BusinessTypeCard(
                            emoji: '🛠️',
                            title: 'Service & Other',
                            description: 'Simple bills, labor cost, quick receipt',
                            isSelected: config.businessType == 'Service & Other',
                            onTap: () => viewModel.updateBusinessType('Service & Other'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Section 2: Business Details Form
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business Details',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFF8FAFC),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CustomTextField(
                              label: 'Shop Name',
                              placeholder: 'e.g., Kandy Super Mart',
                              controller: _nameController,
                              prefixIcon: Icons.store_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Shop name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'City / Address',
                              placeholder: 'e.g., Main Street, Colombo',
                              controller: _addressController,
                              prefixIcon: Icons.location_on_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Address is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Phone Number',
                              placeholder: 'e.g., 077 123 4567',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (value.length < 9) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomDropdown<String>(
                              label: 'Receipt Language',
                              value: config.receiptLanguage,
                              items: const [
                                'Dual (Sinhala + English)',
                                'English Only',
                                'Sinhala Only',
                                'Tamil Only',
                              ],
                              itemToString: (item) => item,
                              onChanged: (val) {
                                if (val != null) viewModel.updateReceiptLanguage(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Section 3: Feature Toggles
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF334155),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Features',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF8FAFC),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enable common workflows for your store type',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFFBBCABF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Color(0xFF334155), thickness: 1),
                            // Toggle 1
                            _buildToggleTile(
                              title: 'Enable Digital Naya Potha (Customer Credit)',
                              value: config.nayaPothaEnabled,
                              onChanged: viewModel.toggleNayaPotha,
                            ),
                            const Divider(color: Color(0xFF334155), thickness: 0.5, height: 1),
                            // Toggle 2
                            _buildToggleTile(
                              title: 'Enable Kitchen Order Tickets (KOT)',
                              value: config.kotEnabled,
                              onChanged: viewModel.toggleKot,
                            ),
                            const Divider(color: Color(0xFF334155), thickness: 0.5, height: 1),
                            // Toggle 3
                            _buildToggleTile(
                              title: 'LANKAQR & Cashless Payment Codes',
                              value: config.lankaQrEnabled,
                              onChanged: viewModel.toggleLankaQr,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Sticky Bar Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF334155),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Complete Setup & Launch POS',
                icon: Icons.arrow_forward,
                onPressed: () async {
                  // Synchronize fields into viewmodel state first
                  viewModel.updateShopName(_nameController.text);
                  viewModel.updateAddress(_addressController.text);
                  viewModel.updatePhoneNumber(_phoneController.text);

                  if (_formKey.currentState!.validate()) {
                    final success = await viewModel.saveSetup();
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardView()),
                        (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save settings. Please verify details.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFF8FAFC),
              ),
            ),
          ),
          const SizedBox(width: 16),
          CustomSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
