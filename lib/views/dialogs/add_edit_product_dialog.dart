import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/inventory_item.dart';
import '../../viewmodels/inventory_viewmodel.dart';
import '../../widgets/custom_text_field.dart';
import 'mock_scanner_dialog.dart';
import 'product_ingredients_dialog.dart';

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
  late String selectedStockType;

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
    selectedStockType = isEdit ? prod!.stockType : 'General';
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
                isEdit ? 'Edit Stock Product' : 'Add New Product',
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

          // Form fields content pane
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  CustomTextField(
                    label: 'Product Name',
                    placeholder: 'e.g. Araliya Nadu Rice 5kg',
                    controller: nameController,
                  ),
                  const SizedBox(height: 10),

                  // Barcode with scanner lookup
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'EAN/ISBN Barcode',
                          placeholder: 'Scan or enter code',
                          controller: barcodeController,
                        ),
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

                  // Stock Type Dropdown
                  Text(
                    'STOCK TYPE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFBBCABF),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF475569)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStockType,
                        dropdownColor: const Color(0xFF0F172A),
                        isExpanded: true,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                        items: ['General', 'Ingredients', 'Products'].map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedStockType = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Category & Unit Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Category',
                          placeholder: 'e.g. Groceries',
                          controller: categoryController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          label: 'Unit',
                          placeholder: 'e.g. Bags, pcs',
                          controller: unitController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Cost vs Selling Price Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Cost Price (LKR)',
                          placeholder: '1050',
                          controller: costController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          label: 'Retail Price (LKR)',
                          placeholder: '1200',
                          controller: priceController,
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
                        child: CustomTextField(
                          label: isEdit ? 'Current Stock' : 'Initial Stock',
                          placeholder: '45',
                          controller: stockController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CustomTextField(
                          label: 'Low Stock Trigger',
                          placeholder: '5',
                          controller: minStockController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  // Link Ingredients
                  if (selectedStockType == 'Products') ...[
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
                      label: const Text('LINK INGREDIENTS 🥗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (c) => ProductIngredientsDialog(product: widget.existingProduct!),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isEdit)
                        TextButton.icon(
                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 16),
                          label: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
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
                              stockType: selectedStockType,
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
                              stockType: selectedStockType,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Added new product: $name'), backgroundColor: const Color(0xFF10B981)),
                            );
                          }
                          Navigator.pop(context);
                        },
                        child: Text(isEdit ? 'SAVE CHANGES' : 'CREATE PRODUCT', style: const TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
