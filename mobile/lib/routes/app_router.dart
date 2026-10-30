import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/session_service.dart';

import '../views/analysis_view.dart';
import '../views/change_password_view.dart';
import '../views/edit_profile_view.dart';
import '../views/history_detail_view.dart';
import '../views/history_view.dart';
import '../views/home_view.dart';
import '../views/login_view.dart';
import '../views/profile_view.dart';
import '../views/register_view.dart';

GoRouter createRouter() {
  return GoRouter(
    // ======================================================
    // SESIÓN
    // ======================================================

    refreshListenable: SessionService.sessionNotifier,

    initialLocation: SessionService.hasActiveSession ? '/home' : '/login',

    // ======================================================
    // PROTECCIÓN DE RUTAS
    // ======================================================

    redirect: (
      context,
      state,
    ) {
      final loggedIn = SessionService.hasActiveSession;

      final location = state.matchedLocation;

      final isLogin = location == '/login';

      final isRegister = location == '/register';

      final isPublicRoute = isLogin || isRegister;

      // Usuario SIN sesión intentando acceder
      // a una pantalla privada.
      if (!loggedIn && !isPublicRoute) {
        return '/login';
      }

      // Usuario CON sesión intentando volver
      // al login o al registro.
      if (loggedIn && isPublicRoute) {
        return '/home';
      }

      return null;
    },

    // ======================================================
    // RUTAS
    // ======================================================

    routes: [
      // ====================================================
      // AUTENTICACIÓN
      // ====================================================

      GoRoute(
        path: '/login',
        builder: (
          context,
          state,
        ) =>
            const LoginView(),
      ),

      GoRoute(
        path: '/register',
        builder: (
          context,
          state,
        ) =>
            const RegisterView(),
      ),

      // ====================================================
      // DASHBOARD PRINCIPAL
      // ====================================================

      StatefulShellRoute.indexedStack(
        builder: (
          context,
          state,
          navigationShell,
        ) {
          return DashboardWrapper(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // =================================================
          // 0. INICIO
          // =================================================

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (
                  context,
                  state,
                ) =>
                    const HomeView(),
              ),
            ],
          ),

          // =================================================
          // 1. ANÁLISIS
          // =================================================

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analysis',
                builder: (
                  context,
                  state,
                ) =>
                    const AnalysisView(),
              ),
            ],
          ),

          // =================================================
          // 2. HISTORIAL
          // =================================================

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (
                  context,
                  state,
                ) =>
                    const HistoryView(),
                routes: [
                  // =========================================
                  // DETALLE DE ANÁLISIS
                  // =========================================

                  GoRoute(
                    path: ':id',
                    builder: (
                      context,
                      state,
                    ) {
                      final rawId = state.pathParameters['id'];

                      final id = int.tryParse(
                        rawId ?? '',
                      );

                      if (id == null) {
                        return const HistoryView();
                      }

                      return HistoryDetailView(
                        resultId: id,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // =================================================
          // 3. PERFIL
          // =================================================

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (
                  context,
                  state,
                ) =>
                    const ProfileView(),
                routes: [
                  // =========================================
                  // EDITAR PERFIL
                  // =========================================

                  GoRoute(
                    path: 'edit',
                    builder: (
                      context,
                      state,
                    ) =>
                        const EditProfileView(),
                  ),

                  // =========================================
                  // CAMBIAR CONTRASEÑA
                  // =========================================

                  GoRoute(
                    path: 'password',
                    builder: (
                      context,
                      state,
                    ) =>
                        const ChangePasswordView(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],

    // ======================================================
    // ERROR DE RUTA
    // ======================================================

    errorBuilder: (
      context,
      state,
    ) {
      return const _RouteNotFoundView();
    },
  );
}

// ==========================================================
// DASHBOARD WRAPPER
// ==========================================================

class DashboardWrapper extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const DashboardWrapper({
    super.key,
    required this.navigationShell,
  });

  static const Color azul = Color(0xFF1976E9);

  static const Color texto = Color(0xFF203653);

  static const Color gris = Color(0xFF8290A5);

  void _navegar(
    BuildContext context,
    int index,
  ) {
    navigationShell.goBranch(
      index,

      // Si pulsa nuevamente la pestaña actual,
      // vuelve a la ruta principal de esa rama.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(
                0xFFE3EAF2,
              ),
            ),
            borderRadius: BorderRadius.circular(
              19,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.035,
                ),
                blurRadius: 12,
                offset: const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              // =============================================
              // INICIO
              // =============================================

              _ItemNavegacion(
                icono: Icons.home_outlined,
                iconoActivo: Icons.home_rounded,
                texto: 'Inicio',
                seleccionado: navigationShell.currentIndex == 0,
                onTap: () => _navegar(
                  context,
                  0,
                ),
              ),

              // =============================================
              // ANALIZAR
              // =============================================

              _ItemNavegacion(
                icono: Icons.biotech_outlined,
                iconoActivo: Icons.biotech_rounded,
                texto: 'Analizar',
                seleccionado: navigationShell.currentIndex == 1,
                onTap: () => _navegar(
                  context,
                  1,
                ),
              ),

              // =============================================
              // HISTORIAL
              // =============================================

              _ItemNavegacion(
                icono: Icons.history_outlined,
                iconoActivo: Icons.history_rounded,
                texto: 'Historial',
                seleccionado: navigationShell.currentIndex == 2,
                onTap: () => _navegar(
                  context,
                  2,
                ),
              ),

              // =============================================
              // PERFIL
              // =============================================

              _ItemNavegacion(
                icono: Icons.person_outline_rounded,
                iconoActivo: Icons.person_rounded,
                texto: 'Perfil',
                seleccionado: navigationShell.currentIndex == 3,
                onTap: () => _navegar(
                  context,
                  3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ITEM DE NAVEGACIÓN
// ==========================================================

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
  Widget build(
    BuildContext context,
  ) {
    final color = seleccionado ? DashboardWrapper.azul : DashboardWrapper.gris;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            12,
          ),
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
                const SizedBox(
                  height: 4,
                ),
                Text(
                  texto,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        seleccionado ? FontWeight.w700 : FontWeight.w400,
                    color: seleccionado
                        ? DashboardWrapper.texto
                        : DashboardWrapper.gris,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
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
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
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

// ==========================================================
// RUTA NO ENCONTRADA
// ==========================================================

class _RouteNotFoundView extends StatelessWidget {
  const _RouteNotFoundView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search_off_rounded,
                  size: 58,
                  color: Color(
                    0xFF8290A5,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Página no encontrada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(
                      0xFF203653,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'La pantalla que intentas abrir '
                  'no está disponible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(
                      0xFF8290A5,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 22,
                ),
                FilledButton(
                  onPressed: () {
                    if (SessionService.hasActiveSession) {
                      context.go(
                        '/home',
                      );
                    } else {
                      context.go(
                        '/login',
                      );
                    }
                  },
                  child: const Text(
                    'Volver',
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
