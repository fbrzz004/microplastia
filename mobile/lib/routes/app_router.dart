<<<<<<< Updated upstream

import 'package:flutter/material.dart';
=======
<<<<<<< Updated upstream
=======
import 'package:flutter/material.dart';
>>>>>>> Stashed changes
>>>>>>> Stashed changes
import 'package:go_router/go_router.dart';
import '../views/login_view.dart';
import '../views/register_view.dart';
import '../views/home_view.dart';
import '../views/analysis_view.dart';
import '../views/result_view.dart';
import '../views/history_view.dart';
<<<<<<< Updated upstream
import '../views/history_detail_view.dart';
=======
<<<<<<< Updated upstream
=======
import '../views/history_detail_view.dart';
import '../views/profile_view.dart';
import '../views/edit_profile_view.dart';
import '../views/change_password_view.dart';
>>>>>>> Stashed changes
>>>>>>> Stashed changes

GoRouter createRouter(bool hasSession) {
  return GoRouter(
    initialLocation: hasSession ? '/home' : '/login',
    routes: [
      // Autenticación: sin barra inferior.
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/analysis',
        builder: (context, state) => const AnalysisView(),
=======
>>>>>>> Stashed changes

      // Pantallas principales: con barra inferior.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DashboardWrapper(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analysis',
                builder: (context, state) => const AnalysisView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryView(),
<<<<<<< Updated upstream
=======
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = int.tryParse(
                        state.pathParameters['id'] ?? '',
                      );

                      if (id == null) {
                        return const HistoryView();
                      }

                      return HistoryDetailView(resultId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileView(),
                  ),
                  GoRoute(
                    path: 'password',
                    builder: (context, state) => const ChangePasswordView(),
                  ),
                ],
>>>>>>> Stashed changes
              ),
            ],
          ),
        ],
<<<<<<< Updated upstream
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
      ),

      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultView(),
      ),

      GoRoute(
        path: '/history/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');

          if (id == null) {
            return const HistoryView();
          }

          return HistoryDetailView(resultId: id);
        },
      ),
    ],
  );
<<<<<<< Updated upstream
=======
<<<<<<< Updated upstream
}
=======
>>>>>>> Stashed changes
}

class DashboardWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardWrapper({
    super.key,
    required this.navigationShell,
  });

  static const Color azul = Color(0xFF1976E9);
  static const Color texto = Color(0xFF203653);
  static const Color gris = Color(0xFF8290A5);

  void _navegar(BuildContext context, int index) {
<<<<<<< Updated upstream
    // Perfil todavía no tiene una pantalla.
    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La sección Perfil estará disponible pronto.',
          ),
        ),
      );
      return;
    }

=======
>>>>>>> Stashed changes
    navigationShell.goBranch(
      index,
      initialLocation:
          index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE3EAF2),
            ),
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _ItemNavegacion(
                icono: Icons.home_outlined,
                iconoActivo: Icons.home_rounded,
                texto: 'Inicio',
                seleccionado:
                    navigationShell.currentIndex == 0,
                onTap: () => _navegar(context, 0),
              ),
              _ItemNavegacion(
                icono: Icons.biotech_outlined,
                iconoActivo: Icons.biotech_rounded,
                texto: 'Analizar',
                seleccionado:
                    navigationShell.currentIndex == 1,
                onTap: () => _navegar(context, 1),
              ),
              _ItemNavegacion(
                icono: Icons.history_rounded,
                iconoActivo: Icons.history_rounded,
                texto: 'Historial',
                seleccionado:
                    navigationShell.currentIndex == 2,
                onTap: () => _navegar(context, 2),
              ),
              _ItemNavegacion(
                icono: Icons.person_outline_rounded,
                iconoActivo: Icons.person_rounded,
                texto: 'Perfil',
<<<<<<< Updated upstream
                seleccionado: false,
=======
                seleccionado: navigationShell.currentIndex == 3,
>>>>>>> Stashed changes
                onTap: () => _navegar(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacion extends StatelessWidget {
  final IconData icono;
  final IconData iconoActivo;
  final String texto;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ItemNavegacion({
    required this.icono,
    required this.iconoActivo,
    required this.texto,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = seleccionado
        ? DashboardWrapper.azul
        : DashboardWrapper.gris;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  seleccionado ? iconoActivo : icono,
                  size: 22,
                  color: color,
                ),
                const SizedBox(height: 4),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: seleccionado
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: seleccionado
                        ? DashboardWrapper.texto
                        : DashboardWrapper.gris,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  width: seleccionado ? 16 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? DashboardWrapper.azul
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
<<<<<<< Updated upstream
=======
>>>>>>> Stashed changes
>>>>>>> Stashed changes
