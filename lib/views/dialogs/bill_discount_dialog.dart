import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/dashboard_viewmodel.dart';

class BillDiscountDialog extends StatelessWidget {
  final DashboardState state;
  final DashboardViewModel viewModel;

  const BillDiscountDialog({
    super.key,
    required this.state,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: state.cartDiscount > 0 ? state.cartDiscount.toStringAsFixed(0) : '');

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        'Apply Bill Discount',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter overall checkout bill discount (0-100%):',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'e.g. 5',
              suffixText: '%',
              suffixStyle: const TextStyle(color: Colors.white),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: const Color(0xFF0F172A),
          ),
          onPressed: () {
            final discount = double.tryParse(controller.text) ?? 0.0;
            viewModel.updateCartDiscount(discount);
            Navigator.pop(context);
          },
          child: const Text('APPLY'),
        )
      ],
    );
  }
}
