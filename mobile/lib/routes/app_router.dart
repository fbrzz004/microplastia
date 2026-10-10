import 'package:go_router/go_router.dart';

import '../views/login_view.dart';
import '../views/register_view.dart';
import '../views/home_view.dart';
import '../views/analysis_view.dart';
import '../views/result_view.dart';
import '../views/history_view.dart';

GoRouter createRouter(bool hasSession) {
  return GoRouter(
    initialLocation: hasSession ? '/home' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) => const AnalysisView(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultView(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryView(),
      ),
    ],
  );
}