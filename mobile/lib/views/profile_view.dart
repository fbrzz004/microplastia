
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileViewModel _viewModel;
  bool _notificaciones = true;

  static const azul = Color(0xFF1976E9);
  static const oscuro = Color(0xFF203653);
  static const borde = Color(0xFFD7E2F2);

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.loadProfile();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _editarPerfil() async {
    await context.push('/profile/edit');
    if (!mounted) return;
    await _viewModel.loadProfile();
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          '¿Estás seguro de que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await AuthService().logout();

    if (mounted) context.go('/login');
  }

  Widget _opcion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: borde),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: azul, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: oscuro,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        color: Color(0xFF8290A5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF8290A5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final nombreCompleto =
            '${_viewModel.nombre} ${_viewModel.apellido}'.trim();

        final iniciales = nombreCompleto
            .split(RegExp(r'\s+'))
            .where((parte) => parte.isNotEmpty)
            .take(2)
            .map((parte) => parte[0].toUpperCase())
            .join();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Perfil',
              style: TextStyle(
                color: oscuro,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: _viewModel.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: azul),
                )
              : RefreshIndicator(
                  onRefresh: _viewModel.loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      const Text(
                        'Gestiona tu cuenta y preferencias',
                        style: TextStyle(
                          color: Color(0xFF8290A5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFBFD9FF),
                            ),
                          ),
                          child: Text(
                            iniciales.isEmpty ? 'U' : iniciales,
                            style: const TextStyle(
                              color: Color(0xFF17477F),
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          nombreCompleto.isEmpty
                              ? 'Mi cuenta'
                              : nombreCompleto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF172747),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          _viewModel.correo,
                          style: const TextStyle(
                            color: Color(0xFF8290A5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Rol: ${_viewModel.rol}',
                          style: const TextStyle(
                            color: azul,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Mi cuenta',
                        style: TextStyle(
                          color: oscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _opcion(
                        icono: Icons.edit_outlined,
                        titulo: 'Editar perfil',
                        subtitulo: 'Actualiza tu nombre y apellido',
                        onTap: _editarPerfil,
                      ),
                      const SizedBox(height: 8),
                      _opcion(
                        icono: Icons.lock_outline,
                        titulo: 'Cambiar contraseña',
                        subtitulo: 'Protege el acceso a tu cuenta',
                        onTap: () => context.push('/profile/password'),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Preferencias',
                        style: TextStyle(
                          color: oscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: borde),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notificaciones',
                                    style: TextStyle(
                                      color: oscuro,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Avisos cuando un análisis termine',
                                    style: TextStyle(
                                      color: Color(0xFF8290A5),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _notificaciones,
                              activeTrackColor: azul,
                              onChanged: (value) {
                                setState(() => _notificaciones = value);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: _cerrarSesion,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE32636),
                            side: const BorderSide(
                              color: Color(0xFFFFB5B5),
                            ),
                            backgroundColor: const Color(0xFFFFF6F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (_viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _viewModel.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
