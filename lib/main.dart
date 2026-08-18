import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/database_service.dart';
import 'views/business_setup_view.dart';
import 'views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-initialize the database connection
  final dbService = DatabaseService.instance;
  final savedConfig = await dbService.getBusinessConfig();

  runApp(
    ProviderScope(
      child: MyApp(initialHome: savedConfig != null ? const DashboardView() : const BusinessSetupView()),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget initialHome;

  const MyApp({super.key, required this.initialHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LankaPOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF4edea3),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: initialHome,
    );
  }
}
