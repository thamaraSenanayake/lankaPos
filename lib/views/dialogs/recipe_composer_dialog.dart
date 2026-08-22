import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/inventory_item.dart';
import '../../services/database_service.dart';
import '../../viewmodels/inventory_viewmodel.dart';

class RecipeComposerDialog extends ConsumerStatefulWidget {
  final InventoryItem product;

  const RecipeComposerDialog({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<RecipeComposerDialog> createState() => _RecipeComposerDialogState();
}

class _RecipeComposerDialogState extends ConsumerState<RecipeComposerDialog> {
  final List<Map<String, dynamic>> _ingredientsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    try {
      final recipe = await DatabaseService.instance.getRecipeForProduct(widget.product.id!);
      setState(() {
        for (var row in recipe) {
          _ingredientsList.add({
            'ingredientId': row['ingredientId'] as int,
            'quantity': (row['quantity'] as num).toDouble(),
          });
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _addIngredientRow(List<InventoryItem> allItems) {
    // Find first ingredient not already added
    final addedIds = _ingredientsList.map((row) => row['ingredientId'] as int).toSet();
    final available = allItems.where((item) => item.id != widget.product.id && !addedIds.contains(item.id)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All available stock ingredients are already linked.'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }

    setState(() {
      _ingredientsList.add({
        'ingredientId': available.first.id!,
        'quantity': 1.0,
      });
    });
  }

  void _removeRow(int index) {
    setState(() {
      _ingredientsList.removeAt(index);
    });
  }

  Future<void> _saveRecipe() async {
    // Validate rows
    for (var row in _ingredientsList) {
      if (row['ingredientId'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select valid ingredient items.'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
      final double qty = row['quantity'] as double;
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingredient quantities must be greater than 0.'), backgroundColor: Colors.orangeAccent),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await DatabaseService.instance.saveRecipe(widget.product.id!, _ingredientsList);
      await ref.read(inventoryProvider.notifier).loadInventory();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe ingredients linked successfully!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save recipe.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final invState = ref.watch(inventoryProvider);
    final allItems = invState.inventory;
    
    // Filter out the product itself from ingredient options
    final ingredientOptions = allItems.where((item) => item.id != widget.product.id).toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      title: Text(
        'Recipe Ingredients: ${widget.product.name}',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
      ),
      content: SizedBox(
        width: 500,
        height: 380,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : Column(
                children: [
                  Text(
                    'Define the raw ingredients and consumption quantities deducted from stock when 1 unit of this product is sold.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF)),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _ingredientsList.isEmpty
                        ? Center(
                            child: Text(
                              'No ingredients linked. Stock is deducted directly.',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF).withOpacity(0.4)),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _ingredientsList.length,
                            itemBuilder: (context, index) {
                              final row = _ingredientsList[index];
                              final selectedIngId = row['ingredientId'] as int;
                              final quantity = row['quantity'] as double;
                              
                              // Find selected item to get unit
                              final selectedItem = allItems.firstWhere(
                                (item) => item.id == selectedIngId,
                                orElse: () => InventoryItem(name: 'Unknown', stock: 0, unit: '', minStock: 0, price: 0, costPrice: 0),
                              );

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    // Dropdown choice
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF334155), width: 0.5),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            dropdownColor: const Color(0xFF0F172A),
                                            value: selectedIngId,
                                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                            items: ingredientOptions.map((item) {
                                              return DropdownMenuItem<int>(
                                                value: item.id,
                                                child: Text('${item.name} (${item.unit})'),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                setState(() {
                                                  row['ingredientId'] = val;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Quantity Input
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                                        decoration: InputDecoration(
                                          suffixText: selectedItem.unit,
                                          suffixStyle: const TextStyle(color: Color(0xFFBBCABF), fontSize: 10),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          filled: true,
                                          fillColor: const Color(0xFF0F172A),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        controller: TextEditingController(text: quantity.toString())
                                          ..selection = TextSelection.fromPosition(
                                            TextPosition(offset: quantity.toString().length),
                                          ),
                                        onChanged: (val) {
                                          final d = double.tryParse(val) ?? 0.0;
                                          row['quantity'] = d;
                                        },
                                      ),
                                    ),

                                    // Trash button
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () => _removeRow(index),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFF10B981)),
                      label: Text(
                        'Add Ingredient Row',
                        style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _addIngredientRow(ingredientOptions),
                    ),
                  ),
                ],
              ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _saveRecipe,
          child: const Text('SAVE RECIPE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
