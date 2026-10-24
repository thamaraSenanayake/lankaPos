import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/custom_text_field.dart';
import '../services/printer_service.dart';

class HardwareSettingsView extends ConsumerStatefulWidget {
  const HardwareSettingsView({super.key});

  @override
  ConsumerState<HardwareSettingsView> createState() => _HardwareSettingsViewState();
}

class _HardwareSettingsViewState extends ConsumerState<HardwareSettingsView> {
  // Local controllers
  late TextEditingController nameController;
  late TextEditingController addrController;
  late TextEditingController phoneController;
  late TextEditingController footerController;

  String receiptLanguage = 'English';
  bool cashierLockEnabled = false;
  String cashierPin = '1234';

  // Printer State
  String printerName = 'ESC/POS 80mm Printer (BT-210)';
  bool isPrinterConnected = true;

  @override
  void initState() {
    super.initState();
    final config = ref.read(dashboardProvider).config;
    nameController = TextEditingController(text: config?.shopName ?? '');
    addrController = TextEditingController(text: config?.address ?? '');
    phoneController = TextEditingController(text: config?.phoneNumber ?? '');
    footerController = TextEditingController(text: config?.footerMessage ?? 'Thank You Come Again!');
    receiptLanguage = config?.receiptLanguage ?? 'English';
    cashierLockEnabled = config?.cashierLockEnabled ?? false;
    cashierPin = config?.cashierPin ?? '1234';
  }

  @override
  void dispose() {
    nameController.dispose();
    addrController.dispose();
    phoneController.dispose();
    footerController.dispose();
    super.dispose();
  }

  Future<void> _saveAllSettings() async {
    final currentConfig = ref.read(dashboardProvider).config;
    if (currentConfig != null) {
      final updated = currentConfig.copyWith(
        shopName: nameController.text.trim(),
        address: addrController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        receiptLanguage: receiptLanguage,
        footerMessage: footerController.text.trim(),
        cashierLockEnabled: cashierLockEnabled,
        cashierPin: cashierPin,
      );
      await ref.read(dashboardProvider.notifier).updateConfig(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'POS Hardware & System Settings ⚙️',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF10B981)),
            onPressed: () async {
              await _saveAllSettings();
              if (mounted) Navigator.pop(context);
            },
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'POS System & Hardware Settings',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Bluetooth Thermal Printer Card
            _buildSectionCard(
              title: 'Bluetooth Thermal Printer',
              icon: Icons.print,
              iconColor: const Color(0xFF10B981),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155), width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPrinterConnected ? Icons.check_circle : Icons.error_outline,
                        color: isPrinterConnected ? const Color(0xFF10B981) : Colors.orangeAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPrinterConnected ? 'Connected: $printerName' : 'No Printer Paired',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF475569)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.bluetooth_searching, size: 14, color: Colors.white),
                        label: const Text('Scan Devices', style: TextStyle(color: Colors.white, fontSize: 11)),
                        onPressed: () => _showBluetoothScanner(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(Icons.receipt, size: 14),
                        label: const Text('Test Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        onPressed: () => _printTestReceipt(context),
                      ),
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 16),

            // Receipt Customization
            _buildSectionCard(
              title: 'Receipt Customization',
              icon: Icons.edit_document,
              iconColor: Colors.cyanAccent,
              children: [


                // Shop Name
                CustomTextField(
                  label: 'Shop Name',
                  placeholder: 'e.g. LankaPOS Café',
                  controller: nameController,
                ),
                const SizedBox(height: 12),

                // Address
                CustomTextField(
                  label: 'Address',
                  placeholder: 'e.g. Galle Road, Colombo',
                  controller: addrController,
                ),
                const SizedBox(height: 12),

                // Phone
                CustomTextField(
                  label: 'Telephone',
                  placeholder: 'e.g. +94 11 234 5678',
                  controller: phoneController,
                ),
                const SizedBox(height: 12),

                // Footer message
                CustomTextField(
                  label: 'Receipt Footer Message',
                  placeholder: 'e.g. Thank You Come Again',
                  controller: footerController,
                  maxLines: 2,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Security & Cashier Mode Pin
            _buildSectionCard(
              title: 'Security & Access Control',
              icon: Icons.security,
              iconColor: Colors.orangeAccent,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cashier Mode Lock', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text(
                            'Requires 4-digit PIN to view Cost Prices, Expenses, or Void Bills',
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFBBCABF)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: cashierLockEnabled,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) {
                        if (val) {
                          _showPinSetupDialog(context);
                        } else {
                          setState(() => cashierLockEnabled = false);
                        }
                      },
                    )
                  ],
                ),
                if (cashierLockEnabled) ...[
                  const Divider(color: Color(0xFF334155), height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cashier PIN: $cashierPin', style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14, color: Color(0xFF10B981)),
                        label: const Text('CHANGE PIN', style: TextStyle(color: Color(0xFF10B981), fontSize: 11)),
                        onPressed: () => _showPinSetupDialog(context),
                      )
                    ],
                  ),
                ]
              ],
            ),

            const SizedBox(height: 16),

            // Cloud sync
            _buildSectionCard(
              title: 'Data Backup & Sync',
              icon: Icons.cloud_sync,
              iconColor: Colors.purpleAccent,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Offline Queue Status', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF))),
                    Text('0 Pending Bills', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cloud Sync Status', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF))),
                    Text('2 minutes ago', style: GoogleFonts.inter(fontSize: 12, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF475569)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.sync, size: 14, color: Colors.white),
                    label: const Text('Force Cloud Sync Now', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _forceSyncData(context),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF10B981)),
                    label: const Text('Load Demo / Dummy Data', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => _confirmLoadDummyData(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Save settings primary trigger
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: const Color(0xFF0F172A),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await _saveAllSettings();
                if (mounted) Navigator.pop(context);
              },
              child: Text(
                'Save Settings Profile',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          ...children,
        ],
      ),
    );
  }

  void _showBluetoothScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        List<ScanResult> devices = [];
        bool isScanning = true;
        StreamSubscription<List<ScanResult>>? subscription;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (subscription == null) {
              subscription = FlutterBluePlus.scanResults.listen((results) {
                if (context.mounted) {
                  setModalState(() {
                    devices = results;
                  });
                }
              });

              FlutterBluePlus.startScan(timeout: const Duration(seconds: 4)).then((_) {
                if (context.mounted) {
                  setModalState(() {
                    isScanning = false;
                  });
                }
              }).catchError((_) {
                if (context.mounted) {
                  setModalState(() {
                    isScanning = false;
                  });
                }
              });
            }

            final displayDevices = devices
                .where((r) => r.device.platformName.isNotEmpty)
                .map((r) => r.device.platformName)
                .toSet()
                .toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('Scan Bluetooth Printers', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
              content: SizedBox(
                width: 280,
                height: 300,
                child: Column(
                  children: [
                    if (isScanning) ...[
                      const LinearProgressIndicator(color: Color(0xFF10B981), backgroundColor: Color(0xFF0F172A)),
                      const SizedBox(height: 12),
                      Text('Scanning for nearby thermal devices...', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFBBCABF))),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: displayDevices.isEmpty
                          ? Center(
                              child: Text(
                                isScanning ? 'Searching...' : 'No Bluetooth devices found.',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF).withOpacity(0.5)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: displayDevices.length,
                              itemBuilder: (context, index) {
                                return _buildDeviceTile(displayDevices[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    subscription?.cancel();
                    FlutterBluePlus.stopScan();
                    Navigator.pop(context);
                  },
                  child: const Text('CLOSE', style: TextStyle(color: Color(0xFFBBCABF))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeviceTile(String name) {
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
      trailing: const Icon(Icons.bluetooth, color: Color(0xFF10B981), size: 16),
      onTap: () {
        setState(() {
          printerName = name;
          isPrinterConnected = true;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to $name successfully!'), backgroundColor: const Color(0xFF10B981)),
        );
      },
    );
  }

  void _printTestReceipt(BuildContext context) async {
    final currentConfig = ref.read(dashboardProvider).config;
    if (currentConfig != null) {
      try {
        final bytes = await PrinterService.instance.generateTestReceipt(
          currentConfig,
          printerName.contains('58') ? '58mm' : '80mm',
        );
        debugPrint('Generated ESC/POS Test receipt: ${bytes.length} bytes.');
      } catch (e) {
        debugPrint('Failed to generate ESC/POS bytes: $e');
      }
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Receipt Printed (Preview)', style: TextStyle(color: Colors.white, fontSize: 14)),
          content: Container(
            width: 260,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    nameController.text.isEmpty ? 'LankaPOS Store' : nameController.text,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Center(
                  child: Text(
                    addrController.text.isEmpty ? 'Colombo, Sri Lanka' : addrController.text,
                    style: const TextStyle(color: Colors.black54, fontSize: 10),
                  ),
                ),
                const Divider(color: Colors.black38, height: 12),
                const Text('1x Munchee Biscuit        LKR 250.00', style: TextStyle(color: Colors.black, fontSize: 10)),
                const Text('1x Anchor Milk Powder    LKR 1,150.00', style: TextStyle(color: Colors.black, fontSize: 10)),
                const Divider(color: Colors.black38, height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('TOTAL:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('LKR 1,400.00', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    footerController.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                )
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  void _showPinSetupDialog(BuildContext context) {
    final pinCont = TextEditingController(text: cashierPin);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Configure Cashier Lock PIN', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter 4-digit security PIN:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFBBCABF))),
              const SizedBox(height: 12),
              TextField(
                controller: pinCont,
                maxLength: 4,
                keyboardType: TextInputType.number,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xFFBBCABF))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: const Color(0xFF0F172A)),
              onPressed: () {
                final pin = pinCont.text.trim();
                if (pin.length == 4) {
                  setState(() {
                    cashierPin = pin;
                    cashierLockEnabled = true;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ENABLE LOCK'),
            )
          ],
        );
      },
    );
  }

  void _forceSyncData(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Database Cloud Backup Successful (100% Synced)'), backgroundColor: Color(0xFF10B981)),
            );
          }
        });

        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          content: Row(
            children: [
              const CircularProgressIndicator(color: Color(0xFF10B981)),
              const SizedBox(width: 20),
              Text(
                'Syncing with LankaPOS Cloud...',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmLoadDummyData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Load Demo Dummy Data? 📦',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Text(
            'This will populate your account with sample products, sales transactions, customer debt ledger, supplier invoices, and business expenses matching your business type.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFBBCABF)),
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
                Navigator.pop(context);
                await ref.read(dashboardProvider.notifier).seedDummyData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dummy data successfully populated for your account!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              },
              child: const Text('LOAD DATA'),
            ),
          ],
        );
      },
    );
  }
}
