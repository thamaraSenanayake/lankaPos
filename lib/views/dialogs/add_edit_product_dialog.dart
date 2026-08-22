import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/inventory_item.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import 'mock_scanner_dialog.dart';
import 'recipe_composer_dialog.dart';

class AddEditProductDialog extends StatefulWidget {
  final InventoryViewModel inventoryViewModel;
  final InventoryItem? existingProduct;

  const AddEditProductDialog({
    super.key,
    required this.inventoryViewModel,
    this.existingProduct,
  });

  @override
  State<AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<AddEditProductDialog> {
  late TextEditingController nameController;
  late TextEditingController barcodeController;
  late TextEditingController categoryController;
  late TextEditingController costController;
  late TextEditingController priceController;
  late TextEditingController stockController;
  late TextEditingController unitController;
  late TextEditingController minStockController;

  @override
  void initState() {
    super.initState();
    final isEdit = widget.existingProduct != null;
    final prod = widget.existingProduct;

    nameController = TextEditingController(text: isEdit ? prod!.name : '');
    barcodeController = TextEditingController(text: isEdit ? prod!.barcode : '');
    categoryController = TextEditingController(text: isEdit ? prod!.category : 'General');
    costController = TextEditingController(text: isEdit ? prod!.costPrice.toStringAsFixed(0) : '');
    priceController = TextEditingController(text: isEdit ? prod!.price.toStringAsFixed(0) : '');
    stockController = TextEditingController(text: isEdit ? prod!.stock.toStringAsFixed(0) : '');
    unitController = TextEditingController(text: isEdit ? prod!.unit : 'pcs');
    minStockController = TextEditingController(text: isEdit ? prod!.minStock.toStringAsFixed(0) : '5');
  }

  @override
  void dispose() {
    nameController.dispose();
    barcodeController.dispose();
    categoryController.dispose();
    costController.dispose();
    priceController.dispose();
    stockController.dispose();
    unitController.dispose();
    minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProduct != null;

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      title: Text(
        isEdit ? 'Edit Stock Product' : 'Add New Product',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Name
              _buildModalField('Product Name', nameController, hint: 'e.g. Araliya Nadu Rice 5kg'),
              const SizedBox(height: 10),

              // Barcode with scanner lookup
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildModalField('EAN/ISBN Barcode', barcodeController, hint: 'Scan or enter code'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (c) => MockScannerDialog(
                          onScanned: (code) {
                            setState(() {
                              barcodeController.text = code;
                            });
                          },
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),

              // Category & Unit Row
              Row(
                children: [
                  Expanded(child: _buildModalField('Category', categoryController, hint: 'e.g. Groceries')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildModalField('Unit', unitController, hint: 'e.g. Bags, pcs')),
                ],
              ),
              const SizedBox(height: 10),

              // Cost vs Selling Price Row
              Row(
                children: [
                  Expanded(
                    child: _buildModalField(
                      'Cost Price (LKR)',
                      costController,
                      hint: '1050',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModalField(
                      'Retail Price (LKR)',
                      priceController,
                      hint: '1200',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Initial Stock vs Alert Level Row
              Row(
                children: [
                  Expanded(
                    child: _buildModalField(
                      isEdit ? 'Current Stock' : 'Initial Stock',
                      stockController,
                      hint: '45',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildModalField(
                      'Low Stock Trigger',
                      minStockController,
                      hint: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              if (isEdit) ...[
                const Divider(color: Color(0xFF334155), height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981), width: 0.5),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('LINK INGREDIENTS (RECIPE) 🥗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (c) => RecipeComposerDialog(product: widget.existingProduct!),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (isEdit)
          TextButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 16),
            label: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
            onPressed: () async {
              final confirmed = await _showConfirmDeleteDialog(context);
              if (confirmed == true && context.mounted) {
                widget.inventoryViewModel.deleteProduct(widget.existingProduct!.id!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted ${widget.existingProduct!.name}'), backgroundColor: Colors.redAccent),
                );
              }
            },
          ),
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
            final name = nameController.text.trim();
            final barcode = barcodeController.text.trim();
            final category = categoryController.text.trim();
            final cost = double.tryParse(costController.text) ?? 0.0;
            final price = double.tryParse(priceController.text) ?? 0.0;
            final stock = double.tryParse(stockController.text) ?? 0.0;
            final unit = unitController.text.trim();
            final minStock = double.tryParse(minStockController.text) ?? 0.0;

            if (name.isEmpty || price <= 0.0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please specify at least Product Name and Retail Price.'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
              return;
            }

            if (isEdit) {
              widget.inventoryViewModel.editProduct(widget.existingProduct!.copyWith(
                name: name,
                barcode: barcode,
                category: category,
                costPrice: cost,
                price: price,
                stock: stock,
                unit: unit,
                minStock: minStock,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated $name stock successfully.'), backgroundColor: const Color(0xFF10B981)),
              );
            } else {
              widget.inventoryViewModel.addProduct(InventoryItem(
                name: name,
                barcode: barcode,
                category: category,
                costPrice: cost,
                price: price,
                stock: stock,
                unit: unit,
                minStock: minStock,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added new product: $name'), backgroundColor: const Color(0xFF10B981)),
              );
            }
            Navigator.pop(context);
          },
          child: Text(isEdit ? 'SAVE CHANGES' : 'CREATE PRODUCT'),
        )
      ],
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFBBCABF),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF475569)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF10B981)),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('Delete Product?', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to permanently delete this product from database catalog?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}
