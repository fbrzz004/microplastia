import 'package:go_router/go_router.dart';
import '../views/login_view.dart';
import '../views/home_view.dart';
import '../views/analysis_view.dart';
import '../views/result_view.dart';
import '../views/history_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: '/analysis',
      name: 'analysis',
      builder: (context, state) => const AnalysisView(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) => const ResultView(),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryView(),
    ),
  ],
);