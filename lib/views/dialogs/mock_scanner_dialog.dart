import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/inventory_viewmodel.dart';

class MockScannerDialog extends ConsumerWidget {
  final void Function(String)? onScanned;

  const MockScannerDialog({super.key, this.onScanned});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final dashboardViewModel = ref.read(dashboardProvider.notifier);
    final inventoryState = ref.watch(inventoryProvider);

    final textController = TextEditingController();
    final mockScannableProducts = dashboardState.availableProducts;

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155), width: 1.5),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.camera_alt, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Camera Barcode Scanner', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Viewfinder box
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 220,
                      height: 2,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.qr_code_scanner, color: Colors.white24, size: 64),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Text(
                      '[Camera Active Viewfinder]',
                      style: GoogleFonts.inter(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual Input
            Text(
              'MANUAL BARCODE LOOKUP',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. 94100010022',
                hintStyle: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF475569)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Scan Shortcut List
            Text(
              'SIMULATE SCAN SHORTCUTS',
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFBBCABF)),
            ),
            const SizedBox(height: 6),
            Container(
              height: 120,
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: mockScannableProducts.isEmpty
                  ? Center(
                      child: Text(
                        'No products available to scan',
                        style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 11),
                      ),
                    )
                  : ListView.builder(
                      itemCount: mockScannableProducts.length,
                      itemBuilder: (context, index) {
                        final prodName = mockScannableProducts[index].name;
                        final invList = inventoryState.inventory.where((i) => i.name == prodName).toList();
                        final barcode = invList.isNotEmpty ? invList.first.barcode : '479000000000$index';

                        if (barcode.isEmpty) return const SizedBox();

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          title: Text(prodName, style: const TextStyle(color: Colors.white, fontSize: 11)),
                          subtitle: Text('Code: $barcode', style: const TextStyle(color: Color(0xFFBBCABF), fontSize: 10)),
                          trailing: const Icon(Icons.subdirectory_arrow_left, size: 12, color: Color(0xFF10B981)),
                          onTap: () {
                            Navigator.pop(context);
                            if (onScanned != null) {
                              onScanned!(barcode);
                            } else {
                              dashboardViewModel.addScannedBarcodeToCart(barcode);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Scanned barcode: $barcode -> added $prodName to cart.'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: const Color(0xFF0F172A),
          ),
          onPressed: () {
            final barcode = textController.text.trim();
            if (barcode.isNotEmpty) {
              Navigator.pop(context);
              if (onScanned != null) {
                onScanned!(barcode);
              } else {
                dashboardViewModel.addScannedBarcodeToCart(barcode);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Scanned barcode: $barcode'), backgroundColor: const Color(0xFF10B981)),
                );
              }
            }
          },
          child: const Text('SUBMIT LOOKUP'),
        )
      ],
    );
  }
}
