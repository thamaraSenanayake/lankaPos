import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sale.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/custom_text_field.dart';

class ItemDiscountDialog extends StatelessWidget {
  final SaleItem item;
  final DashboardViewModel viewModel;

  const ItemDiscountDialog({
    super.key,
    required this.item,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: item.discount > 0 ? item.discount.toStringAsFixed(0) : '');

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        'Apply Item Discount',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter discount percentage (0-100%) for ${item.name}:',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF)),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Discount Rate',
            placeholder: 'e.g. 10',
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
            viewModel.updateItemDiscount(item.name, discount);
            Navigator.pop(context);
          },
          child: const Text('APPLY'),
        )
      ],
    );
  }
}
