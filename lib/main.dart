import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5CE1E6),
          brightness: Brightness.dark,
          primary: const Color(0xFF5CE1E6),
          onPrimary: const Color(0xFF0A1628),
          surface: const Color(0xFF0A1628),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A1628),
      ),
      home: const LoginPage(),
    );
  }
}
