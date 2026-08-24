import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/custom_text_field.dart';

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
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Discount Rate',
            placeholder: 'e.g. 5',
            controller: controller,
            keyboardType: TextInputType.number,
            suffixText: '%',
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
