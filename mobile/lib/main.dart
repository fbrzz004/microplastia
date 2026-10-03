import 'package:flutter/material.dart';
import 'views/login_view.dart';

void main() {
  runApp(const MicroplastIAApp());
}

class MicroplastIAApp extends StatelessWidget {
  const MicroplastIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MicroplastIA MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
