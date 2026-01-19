import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

void main() {
  runApp(const MxLiveApp());
}

class MxLiveApp extends StatelessWidget {
  const MxLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MXLive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
        primaryColor: Colors.redAccent,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Data Model ---
class Channel {
  final String name;
  final String url;
  final String logo;
  final String group;

  Channel({required this.name, required this.url, required this.logo, required this.group});
}
