import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../viewmodels/dashboard_viewmodel.dart';
import '../../dialogs/mock_scanner_dialog.dart';
import '../../business_setup_view.dart';

class TopAppBar extends ConsumerWidget {
  const TopAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.read(dashboardProvider.notifier);

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title
          Row(
            children: [
              // const Icon(Icons.storefront, color: Color(0xFF10B981), size: 24),
              Image.asset("assets/logo.png", width: 24, height: 24),
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

          // Quick Actions
          Row(
            children: [
              // Camera Barcode Scanner Trigger Button
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
                tooltip: 'Camera Barcode Lookup',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => const MockScannerDialog(),
                  );
                },
              ),

              // Reconfigure POS Settings (Reset profile)
              IconButton(
                icon: const Icon(Icons.settings_backup_restore, color: Colors.orangeAccent),
                tooltip: 'Reconfigure POS',
                onPressed: () => _showResetDialog(context, viewModel),
              ),
            ],
          ),
        ],
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
