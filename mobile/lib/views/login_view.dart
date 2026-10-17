import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/login_viewmodel.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Color azul = Color(0xFF1976E9);
  static const Color azulClaro = Color(0xFFE1F5FE);
  static const Color azulBorde = Color(0xFFDCE6F1);
  static const Color azulOscuro = Color(0xFF142F55);
  static const Color grisTexto = Color(0xFF647895);

  Future<void> _login() async {
    final viewModel = context.read<LoginViewModel>();

    final correcto = await viewModel.login(
      correo: _correoController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (correcto) {
      context.go('/home');
    }
  }

  void _recuperarContrasena() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La recuperación de contraseña estará disponible próximamente.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 50),

                      // Logo
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: azulClaro,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'μ',
                            style: TextStyle(
                              color: azul,
                              fontSize: 38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Nombre de la aplicación
                      const Text(
                        'MicroplastIA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Detección inteligente de microplásticos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: grisTexto,
                        ),
                      ),

                      const SizedBox(height: 34),

                      // Correo
                      const Text(
                        'Correo institucional',
                        style: TextStyle(
                          fontSize: 12,
                          color: grisTexto,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 5),

                      TextField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => viewModel.clearError(),
                        decoration: InputDecoration(
                          hintText: 'nombre@universidad.edu.pe',
                          hintStyle: const TextStyle(
                            color: grisTexto,
                            fontSize: 12,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azulBorde,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azulBorde,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azul,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Contraseña
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 12,
                          color: grisTexto,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 5),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => viewModel.clearError(),
                        onSubmitted: (_) {
                          if (!viewModel.isLoading) {
                            _login();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(
                            color: grisTexto,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azulBorde,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azulBorde,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: azul,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      // Mensaje de error
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Recuperar contraseña
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _recuperarContrasena,
                          style: TextButton.styleFrom(
                            foregroundColor: azul,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Botón de inicio de sesión
                      SizedBox(
                        height: 43,
                        child: ElevatedButton(
                          onPressed:
                              viewModel.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azul,
                            disabledBackgroundColor:
                                azul.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      TextButton(
                        onPressed: () {
                          context.go('/register');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: azulOscuro,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          '¿No tienes una cuenta? Regístrate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),


                      const Spacer(),

                      const SizedBox(height: 35),

                      // Pie de página
                      const Text(
                        'Proyecto académico · Taller de Construcción de Software Móvil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: grisTexto,
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
