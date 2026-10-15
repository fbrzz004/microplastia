import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes/app_router.dart';
import 'services/session_service.dart';
import 'viewmodels/analysis_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hasSession = await SessionService.hasToken();

  runApp(
    MyApp(
      hasSession: hasSession,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSession;

  const MyApp({
    super.key,
    required this.hasSession,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalysisViewModel(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        routerConfig: createRouter(hasSession),
      ),
    );
  }
}