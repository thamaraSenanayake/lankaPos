import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/sale.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/printer_service.dart';

class PaymentDrawerDialog extends StatefulWidget {
  final DashboardState state;
  final DashboardViewModel viewModel;
  final VoidCallback? onCheckoutSuccess;

  const PaymentDrawerDialog({
    super.key,
    required this.state,
    required this.viewModel,
    this.onCheckoutSuccess,
  });

  @override
  State<PaymentDrawerDialog> createState() => _PaymentDrawerDialogState();
}

class _PaymentDrawerDialogState extends State<PaymentDrawerDialog> {
  String selectedMethod = 'Cash';
  final customerController = TextEditingController();

  @override
  void dispose() {
    customerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // Drag handle indicator
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

          // Header title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checkout Invoice Payment',
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

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose payment type for total LKR ${widget.viewModel.cartTotal.toStringAsFixed(2)}:',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPaymentOptionChip('Cash 💵', selectedMethod == 'Cash', () => setState(() => selectedMethod = 'Cash')),
                      _buildPaymentOptionChip('Card 💳', selectedMethod == 'Card', () => setState(() => selectedMethod = 'Card')),
                      if (widget.state.config!.lankaQrEnabled)
                        _buildPaymentOptionChip('LANKAQR 📲', selectedMethod == 'LANKAQR', () => setState(() => selectedMethod = 'LANKAQR')),
                      if (widget.state.config!.nayaPothaEnabled)
                        _buildPaymentOptionChip('Naya (Credit) 📖', selectedMethod == 'Naya Potha', () => setState(() => selectedMethod = 'Naya Potha')),
                    ],
                  ),

                  if (selectedMethod == 'Naya Potha') ...[
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Customer Details',
                      placeholder: "Enter customer's full name",
                      controller: customerController,
                    ),
                  ],

                  if (selectedMethod == 'LANKAQR') ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Image.network(
                              'https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=LANKAQR_INVOICE_TOTAL_${widget.viewModel.cartTotal}',
                              width: 100,
                              height: 100,
                              errorBuilder: (c, e, s) => const Icon(Icons.qr_code_2, size: 100, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan to pay LKR ${widget.viewModel.cartTotal.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.state.config!.kotEnabled && widget.state.orderType == 'Dine-In')
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.restaurant, color: Colors.orangeAccent),
                  onPressed: () {
                    _showMockKotTicketDialog(context, widget.state.cart, widget.state.orderType);
                  },
                ),
              const Spacer(),
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
                onPressed: () async {
                  if (selectedMethod == 'Naya Potha' && customerController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please specify customer name for credit logging.'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                    return;
                  }
                  final customerName = selectedMethod == 'Naya Potha' ? customerController.text.trim() : null;
                  final tempCartItems = List<SaleItem>.from(widget.state.cart);
                  final tempTotal = widget.viewModel.cartTotal;
                  final tempDiscount = widget.viewModel.cartDiscountAmount;

                  Navigator.pop(context);

                  final success = await widget.viewModel.checkout(
                    paymentMethod: selectedMethod,
                    customerName: customerName,
                  );
                  if (!context.mounted) return;

                  if (success) {
                    widget.onCheckoutSuccess?.call();
                    final generatedSale = Sale(
                      id: widget.state.salesHistory.isNotEmpty ? widget.state.salesHistory.first.id : 1,
                      timestamp: DateTime.now(),
                      items: tempCartItems,
                      totalAmount: tempTotal,
                      paymentMethod: selectedMethod,
                      customerName: customerName,
                      orderType: widget.state.orderType,
                      discountAmount: tempDiscount,
                    );
                    _showMockPrintInvoiceDialog(context, generatedSale);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checkout failed.'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: const Text('COMPLETE SALE', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: isSelected ? const Color(0xFF10B981) : const Color(0xFF475569)),
      ),
    );
  }

  void _showMockKotTicketDialog(BuildContext context, List<SaleItem> items, String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: const [
              Icon(Icons.kitchen, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Kitchen Ticket Printed 🧾', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
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
                const Center(
                  child: Text(
                    '=== KITCHEN ORDER ===',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Type: $type', style: const TextStyle(color: Colors.white, fontSize: 11)),
                Text('Date: ${DateFormat('kk:mm:ss').format(DateTime.now())}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                const Divider(color: Color(0xFF334155), height: 12),
                ...items.map((i) => Text(
                      '${i.quantity}x ${i.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    )),
                const Divider(color: Color(0xFF334155), height: 12),
                const Center(
                  child: Text(
                    '[KOT queued successfully]',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontStyle: FontStyle.italic),
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
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  void _showMockPrintInvoiceDialog(BuildContext context, Sale sale) async {
    final config = widget.state.config;
    if (config != null) {
      try {
        final bytes = await PrinterService.instance.generateSaleReceipt(config, sale, '80mm');
        debugPrint('Generated ESC/POS Sale receipt on checkout: ${bytes.length} bytes.');
      } catch (e) {
        debugPrint('Failed to generate ESC/POS checkout print bytes: $e');
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: const [
              Icon(Icons.print, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('Printing Invoice Receipt...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            width: 280,
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
                const Center(
                  child: Text(
                    '--- LANKAPOS INVOICE ---',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text('Order ID: #${sale.id}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                Text('Date: ${DateFormat('yyyy-MM-dd kk:mm').format(sale.timestamp)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                Text('Type: ${sale.orderType}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                Text('Payment: ${sale.paymentMethod}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                if (sale.customerName != null) Text('Customer: ${sale.customerName}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                const Divider(color: Color(0xFF334155), height: 12),
                ...sale.items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${i.quantity}x ${i.name}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          Text('LKR ${i.total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    )),
                const Divider(color: Color(0xFF334155), height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(color: Color(0xFFBBCABF), fontSize: 11)),
                    Text('LKR ${(sale.totalAmount + sale.discountAmount).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
                if (sale.discountAmount > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount:', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                      Text('- LKR ${sale.discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GRAND TOTAL:', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('LKR ${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'THANK YOU!',
                    style: TextStyle(color: Color(0xFFBBCABF), fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('DONE'),
            )
          ],
        );
      },
    );
  }
}
