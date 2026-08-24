import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/inventory_viewmodel.dart';
import 'dialogs/add_edit_product_dialog.dart';
import 'dialogs/csv_backup_dialogs.dart';

class InventoryView extends ConsumerWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryProvider);
    final viewModel = ref.read(inventoryProvider.notifier);
    final filteredList = viewModel.filteredInventory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inventory Title & Add Product Button Row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory & Stock Control 📦',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF8FAFC),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage items, barcode lookups, and cost allocations.',
                      style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBBCABF)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Product',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (c) => AddEditProductDialog(inventoryViewModel: viewModel),
                  );
                },
              ),
            ],
          ),
        ),

        // Filters Container Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155), width: 0.5),
          ),
          child: Row(
            children: [
              // Category filter dropdown
              Expanded(
                child: Theme(
                  data: Theme.of(context).copyWith(canvasColor: const Color(0xFF1E293B)),
                  child: DropdownButtonFormField<String>(
                    value: state.selectedCategoryFilter,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFBBCABF)),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF475569)),
                      ),
                    ),
                    items: viewModel.allCategoriesList.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) viewModel.updateCategoryFilter(val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Low Stock switch
              InkWell(
                onTap: () => viewModel.toggleLowStockFilter(!state.lowStockOnlyFilter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: state.lowStockOnlyFilter ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.lowStockOnlyFilter ? const Color(0xFFEF4444) : const Color(0xFF475569),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: state.lowStockOnlyFilter ? const Color(0xFFEF4444) : const Color(0xFFBBCABF),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Low Stock (${viewModel.lowStockCount})',
                        style: GoogleFonts.inter(
                          color: state.lowStockOnlyFilter ? const Color(0xFFEF4444) : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 12),

        // List View Stock control table
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Text(
                    'No stock items matched.',
                    style: GoogleFonts.inter(color: const Color(0xFFBBCABF).withOpacity(0.4)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final isLow = item.stock <= item.minStock;
                    final hasIngredients = state.ingredients.containsKey(item.id);

                    Color stockTypeColor;
                    String stockTypeLabel;
                    switch (item.stockType) {
                      case 'Ingredients':
                        stockTypeColor = Colors.orangeAccent;
                        stockTypeLabel = 'Ingredient 🌾';
                        break;
                      case 'Products':
                        stockTypeColor = const Color(0xFF10B981);
                        stockTypeLabel = 'Product 🍔';
                        break;
                      default:
                        stockTypeColor = const Color(0xFF3B82F6);
                        stockTypeLabel = 'General 📦';
                    }

                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isLow ? const Color(0xFFEF4444) : const Color(0xFF334155),
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (c) => AddEditProductDialog(
                              inventoryViewModel: viewModel,
                              existingProduct: item,
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isLow ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isLow ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                            color: isLow ? const Color(0xFFEF4444) : const Color(0xFFBBCABF),
                          ),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: stockTypeColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: stockTypeColor, width: 0.5),
                                  ),
                                  child: Text(
                                    stockTypeLabel,
                                    style: GoogleFonts.inter(color: stockTypeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (item.stockType == 'Products' && hasIngredients)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(left: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF10B981), width: 0.5),
                                    ),
                                    child: Text(
                                      'Ingredients Linked 🥗',
                                      style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.barcode_reader, size: 12, color: Color(0xFFBBCABF)),
                                const SizedBox(width: 4),
                                Text(
                                  item.barcode.isEmpty ? 'NO BARCODE' : item.barcode,
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBBCABF)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Category: ${item.category} • Cost: LKR ${item.costPrice.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF).withOpacity(0.8)),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.stock.toStringAsFixed(0)} ${item.unit}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isLow ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LKR ${item.price.toStringAsFixed(0)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom Backup Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF334155), width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF94A3B8)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export CSV Backup'),
                  onPressed: () {
                    final csv = viewModel.exportCsvData();
                    showDialog(
                      context: context,
                      builder: (c) => CSVDataSummaryDialog(
                        title: 'Exported Backup CSV Data',
                        csvData: csv,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF94A3B8)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Import CSV Stocks'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (c) => CSVImportDialog(inventoryViewModel: viewModel),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
