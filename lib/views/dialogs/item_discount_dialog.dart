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

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Apply Item Discount',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFBBCABF), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final discount = double.tryParse(controller.text) ?? 0.0;
                  viewModel.updateItemDiscount(item.name, discount);
                  Navigator.pop(context);
                },
                child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
