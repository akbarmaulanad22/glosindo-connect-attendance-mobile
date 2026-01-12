import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glosindo_connect/viewmodels/progress_ticket_viewmodel.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Import ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/presensi_viewmodel.dart';
import 'viewmodels/tiket_viewmodel.dart';
import 'viewmodels/kasbon_viewmodel.dart';
import 'viewmodels/pengajuan_viewmodel.dart';
import 'viewmodels/shifting_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  // Set orientasi portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const GlosindoConnectApp());
}

class GlosindoConnectApp extends StatelessWidget {
  const GlosindoConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => PresensiViewModel()),
        ChangeNotifierProvider(create: (_) => TiketViewModel()),
        ChangeNotifierProvider(create: (_) => KasbonViewModel()),
        ChangeNotifierProvider(create: (_) => PengajuanViewModel()),
        ChangeNotifierProvider(create: (_) => ShiftingViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ProgressTicketViewModel()),
      ],
      child: MaterialApp(
        title: 'Glosindo Connect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Primary Colors
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1E88E5),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E88E5),
            brightness: Brightness.light,
            primary: const Color(0xFF1E88E5),
            secondary: const Color(0xFF1976D2),
          ),

          // Scaffold Background
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),

          // App Bar Theme
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
          ),

          // Text Theme
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),

          // Button Themes
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFF1E88E5), width: 2),
              textStyle: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),

          // Card Theme
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
          ),

          // Floating Action Button Theme
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 4,
          ),

          // Bottom Sheet Theme
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),

          // Dialog Theme
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          // Chip Theme
          chipTheme: ChipThemeData(
            backgroundColor: Colors.grey.shade200,
            selectedColor: const Color(0xFF1E88E5),
            labelStyle: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // Divider Theme
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade300,
            thickness: 1,
            space: 1,
          ),

          // Icon Theme
          iconTheme: const IconThemeData(color: Color(0xFF1E88E5)),

          // List Tile Theme
          listTileTheme: ListTileThemeData(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            subtitleTextStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          // Progress Indicator Theme
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF1E88E5),
          ),

          // Snackbar Theme
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.grey.shade900,
            contentTextStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            behavior: SnackBarBehavior.floating,
          ),

          // Tab Bar Theme
          tabBarTheme: TabBarThemeData(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            indicator: const UnderlineTabIndicator(
              borderSide: BorderSide(color: Colors.white, width: 3),
            ),
          ),

          // Switch Theme
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1E88E5);
              }
              return Colors.grey;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xFF1E88E5).withOpacity(0.5);
              }
              return Colors.grey.withOpacity(0.5);
            }),
          ),

          // Use Material 3
          useMaterial3: true,
        ),

        // Routes
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },

        // On Unknown Route
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const SplashScreen());
        },
      ),
    );
  }
}
