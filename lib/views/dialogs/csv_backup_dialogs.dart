import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/inventory_viewmodel.dart';

class CSVDataSummaryDialog extends StatelessWidget {
  final String title;
  final String csvData;

  const CSVDataSummaryDialog({
    super.key,
    required this.title,
    required this.csvData,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CSV spreadsheet data formatted below:',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF)),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF475569)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  csvData,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                ),
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
          child: const Text('DONE'),
        )
      ],
    );
  }
}

class CSVImportDialog extends StatelessWidget {
  final InventoryViewModel inventoryViewModel;

  const CSVImportDialog({super.key, required this.inventoryViewModel});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Text(
        'Import Stock CSV',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste CSV stock spreadsheet data to parse and merge:',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'ID,Barcode,Name,Category,Stock,Unit,MinStock,CostPrice,SellingPrice\n1,47920010012,"Araliya Nadu Rice 5kg",Groceries,45,Bags,10,1050.0,1200.0',
                hintStyle: TextStyle(color: const Color(0xFFBBCABF).withOpacity(0.3), fontSize: 10),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          ),
          onPressed: () async {
            final success = await inventoryViewModel.importCsvData(controller.text);
            if (context.mounted) {
              Navigator.pop(context);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV inventory spreadsheet imported successfully.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to parse CSV spreadsheet.'), backgroundColor: Colors.redAccent),
                );
              }
            }
          },
          child: const Text('IMPORT'),
        )
      ],
    );
  }
}
