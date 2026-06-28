// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/screen1_overview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FireSafeApp());
}

// ── Theme notifier ────────────────────────────────────────────────────────────
class ThemeNotifier extends ChangeNotifier {
  bool _isDark = true;
  bool get isDark => _isDark;

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

// Singleton so it can be accessed from anywhere without InheritedWidget boilerplate
final themeNotifier = ThemeNotifier();

class FireSafeApp extends StatefulWidget {
  const FireSafeApp({super.key});

  @override
  State<FireSafeApp> createState() => _FireSafeAppState();
}

class _FireSafeAppState extends State<FireSafeApp> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.isDark;

    return MaterialApp(
      title: 'FIRESAFE COMMAND',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: isDark
            ? const Color(0xFF0D0D0D)
            : const Color(0xFFF4F4F5),
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ),
        colorScheme: isDark
            ? const ColorScheme.dark(
                surface: Color(0xFF0D0D0D),
                primary: Color(0xFF4EDEA3),
                secondary: Color(0xFFFFB95F),
                error: Color(0xFFFF453A),
              )
            : const ColorScheme.light(
                surface: Color(0xFFF4F4F5),
                primary: Color(0xFF10B981),
                secondary: Color(0xFFD97706),
                error: Color(0xFFDC2626),
              ),
      ),
      home: const Screen1Overview(),
    );
  }
}
