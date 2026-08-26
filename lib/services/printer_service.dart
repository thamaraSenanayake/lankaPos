import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import '../models/business_config.dart';
import '../models/sale.dart';

class PrinterService {
  static final PrinterService instance = PrinterService._();
  PrinterService._();

  String _safeText(String text) {
    // Keep only ASCII characters (0-127) to guarantee no printer encoding crashes
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  Future<List<int>> generateTestReceipt(BusinessConfig config, String paperSize) async {
    final profile = await CapabilityProfile.load();
    final size = paperSize.contains('58') ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(size, profile);
    List<int> bytes = [];

    final shopName = _safeText(config.shopName.isEmpty ? 'LankaPOS Store' : config.shopName);
    final address = _safeText(config.address.isEmpty ? 'Colombo, Sri Lanka' : config.address);
    final phone = _safeText(config.phoneNumber);

    bytes += generator.text(shopName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
    if (phone.isNotEmpty) {
      bytes += generator.text('Tel: $phone', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr();
    bytes += generator.text('TEST RECEIPT', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.hr();
    
    // Test items
    bytes += generator.row([
      PosColumn(text: '1x Munchee Biscuit', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: 'LKR 250', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: '1x Anchor Milk Powder', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: 'LKR 1150', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'LKR 1400', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();
    
    final footer = _safeText(config.footerMessage);
    if (footer.isNotEmpty) {
      bytes += generator.text(footer, styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> generateSaleReceipt(BusinessConfig config, Sale sale, String paperSize) async {
    final profile = await CapabilityProfile.load();
    final size = paperSize.contains('58') ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(size, profile);
    List<int> bytes = [];

    final shopName = _safeText(config.shopName.isEmpty ? 'LankaPOS Store' : config.shopName);
    final address = _safeText(config.address.isEmpty ? 'Colombo, Sri Lanka' : config.address);
    final phone = _safeText(config.phoneNumber);

    bytes += generator.text(shopName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
    if (phone.isNotEmpty) {
      bytes += generator.text('Tel: $phone', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr();
    bytes += generator.text('Bill ID: #${sale.id ?? ""}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Date: ${sale.timestamp.toIso8601String().substring(0, 16).replaceAll("T", " ")}',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Payment: ${sale.paymentMethod}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Order Type: ${sale.orderType}', styles: const PosStyles(align: PosAlign.left));
    if (sale.customerName != null) {
      final customer = _safeText(sale.customerName!);
      bytes += generator.text('Customer: $customer', styles: const PosStyles(align: PosAlign.left));
    }
    bytes += generator.hr();

    for (var item in sale.items) {
      final name = _safeText(item.name);
      bytes += generator.row([
        PosColumn(text: '${item.quantity}x $name', width: 8, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: 'LKR ${item.total.toStringAsFixed(0)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 6, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(text: 'LKR ${(sale.totalAmount + sale.discountAmount).toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (sale.discountAmount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 6, styles: const PosStyles(align: PosAlign.left)),
        PosColumn(text: '- LKR ${sale.discountAmount.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(text: 'LKR ${sale.totalAmount.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();

    final footer = _safeText(config.footerMessage);
    if (footer.isNotEmpty) {
      bytes += generator.text(footer, styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
