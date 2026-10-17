import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodels/register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  static const Color azul = Color(0xFF1976E9);
  static const Color azulClaro = Color(0xFFE1F5FE);
  static const Color azulBorde = Color(0xFFDCE6F1);
  static const Color azulOscuro = Color(0xFF142F55);
  static const Color grisTexto = Color(0xFF647895);

  String? _errorConfirmacion;

  Future<void> _register() async {
    final viewModel = context.read<RegisterViewModel>();

    final password = _passwordController.text;
    final confirmarPassword = _confirmarPasswordController.text;

    if (password != confirmarPassword) {
      setState(() {
        _errorConfirmacion = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      _errorConfirmacion = null;
    });

    final correcto = await viewModel.register(
      nombre: _nombreController.text,
      apellido: _apellidoController.text,
      correo: _correoController.text,
      password: password,
    );

    if (!mounted) return;

    if (correcto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuario registrado correctamente'),
        ),
      );

      context.go('/login');
    }
  }

  InputDecoration _decoracionCampo({
    required String label,
    String? hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      labelStyle: const TextStyle(
        fontSize: 12,
        color: grisTexto,
      ),
      hintStyle: const TextStyle(
        fontSize: 12,
        color: grisTexto,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulBorde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulBorde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: azul,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();

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
                      const SizedBox(height: 22),

                      // Logo MicroplastIA
                      Center(
                        child: Container(
                          width: 62,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: azulClaro,
                            borderRadius: BorderRadius.circular(20),
                          ),
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

                      const SizedBox(height: 10),

                      // Título
                      const Text(
                        'Crear cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: azulOscuro,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Regístrate para comenzar a analizar muestras',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: grisTexto,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Nombre
                      TextField(
                        controller: _nombreController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => viewModel.clearError(),
                        decoration: _decoracionCampo(
                          label: 'Nombre',
                          hint: 'Tu nombre',
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Apellido
                      TextField(
                        controller: _apellidoController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => viewModel.clearError(),
                        decoration: _decoracionCampo(
                          label: 'Apellido',
                          hint: 'Tu apellido',
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Correo
                      TextField(
                        controller: _correoController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => viewModel.clearError(),
                        decoration: _decoracionCampo(
                          label: 'Correo',
                          hint: 'nombre@universidad.edu.pe',
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Contraseña
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          viewModel.clearError();
                          if (_errorConfirmacion != null) {
                            setState(() {
                              _errorConfirmacion = null;
                            });
                          }
                        },
                        decoration: _decoracionCampo(
                          label: 'Contraseña',
                          hint: '••••••••',
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Confirmar contraseña
                      TextField(
                        controller: _confirmarPasswordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_errorConfirmacion != null) {
                            setState(() {
                              _errorConfirmacion = null;
                            });
                          }
                        },
                        onSubmitted: (_) {
                          if (!viewModel.isLoading) {
                            _register();
                          }
                        },
                        decoration: _decoracionCampo(
                          label: 'Confirmar contraseña',
                          hint: '••••••••',
                          errorText: _errorConfirmacion,
                        ),
                      ),

                      // Error del backend o de validación
                      if (viewModel.errorMessage != null) ...[
                        const SizedBox(height: 10),
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

                      // Botón Crear cuenta
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azul,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                azul.withValues(alpha: 0.6),
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
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Volver al login
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: azul,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const Spacer(),

                      const SizedBox(height: 24),

                      // Pie de página
                      const Text(
                        'Proyecto académico · Taller de Construcción de Software Móvil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: grisTexto,
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(height: 8),
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
