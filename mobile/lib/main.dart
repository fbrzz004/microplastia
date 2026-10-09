import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_router.dart';
import 'viewmodels/analysis_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalysisViewModel(),
        ),
      ],
      child: const MicroplastIAApp(),
    ),
  );
}

class MicroplastIAApp extends StatelessWidget {
  const MicroplastIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MicroplastIA',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF168C83),
        ),
      ),
    );
  }
}
