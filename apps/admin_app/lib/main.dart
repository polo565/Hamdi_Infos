import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const AdminApp());

const Color kTeal = Color(0xFF0F766E);
const Color kNavy = Color(0xFF1E293B);
const Color kAccent = Color(0xFFF59E0B);

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: kTeal)),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF2B3142),
      ),
      home: Directionality(textDirection: TextDirection.rtl, child: const LoginScreen()),
    );
  }
}
