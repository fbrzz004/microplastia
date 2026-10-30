import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/validators/validators.dart';
import '../viewmodels/profile_viewmodel.dart';

class ChangePasswordView extends StatefulWidget {
  const ChangePasswordView({
    super.key,
  });

  @override
  State<ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  late final ProfileViewModel _viewModel;

  final _formKey = GlobalKey<FormState>();

  final _actualController = TextEditingController();

  final _nuevaController = TextEditingController();

  final _confirmarController = TextEditingController();

  bool _ocultarActual = true;
  bool _ocultarNueva = true;
  bool _ocultarConfirmacion = true;

  static const Color azul = Color(0xFF1976E9);

  static const Color oscuro = Color(0xFF203653);

  static const Color gris = Color(0xFF687B98);

  static const Color borde = Color(0xFFE0E8F3);

  @override
  void initState() {
    super.initState();

    _viewModel = ProfileViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();

    _actualController.dispose();
    _nuevaController.dispose();
    _confirmarController.dispose();

    super.dispose();
  }

  InputDecoration _decoracionCampo({
    required String label,
    required bool ocultar,
    required VoidCallback alternarVisibilidad,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: gris,
        fontSize: 13,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      suffixIcon: IconButton(
        tooltip: ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: alternarVisibilidad,
        icon: Icon(
          ocultar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 19,
          color: gris,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          11,
        ),
        borderSide: const BorderSide(
          color: borde,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          11,
        ),
        borderSide: const BorderSide(
          color: azul,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          11,
        ),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          11,
        ),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _campoContrasena({
    required String label,
    required TextEditingController controller,
    required bool ocultar,
    required VoidCallback alternarVisibilidad,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: ocultar,
      autocorrect: false,
      enableSuggestions: false,
      decoration: _decoracionCampo(
        label: label,
        ocultar: ocultar,
        alternarVisibilidad: alternarVisibilidad,
      ),
      validator: validator,
      onChanged: (_) {
        if (_viewModel.errorMessage != null ||
            _viewModel.successMessage != null) {
          _viewModel.clearMessages();
        }

        setState(() {});
      },
    );
  }

  double get _nivelSeguridad {
    final password = _nuevaController.text;

    if (password.isEmpty) {
      return 0;
    }

    int puntos = 0;

    if (password.length >= 8) {
      puntos++;
    }

    if (RegExp(
      r'[A-Z]',
    ).hasMatch(password)) {
      puntos++;
    }

    if (RegExp(
      r'[a-z]',
    ).hasMatch(password)) {
      puntos++;
    }

    if (RegExp(
      r'[0-9]',
    ).hasMatch(password)) {
      puntos++;
    }

    if (RegExp(
      r'[!@#$%^&*()_\-+=\[\]{};:,.?]',
    ).hasMatch(password)) {
      puntos++;
    }

    return puntos / 5;
  }

  Color get _colorSeguridad {
    if (_nivelSeguridad < 0.4) {
      return const Color(
        0xFFE05252,
      );
    }

    if (_nivelSeguridad < 0.8) {
      return const Color(
        0xFFF2B544,
      );
    }

    return const Color(
      0xFF2DBB76,
    );
  }

  String get _textoSeguridad {
    if (_nuevaController.text.isEmpty) {
      return 'Seguridad de contraseña';
    }

    if (_nivelSeguridad < 0.4) {
      return 'Contraseña débil';
    }

    if (_nivelSeguridad < 0.8) {
      return 'Contraseña media';
    }

    return 'Contraseña segura';
  }

  Future<void> _guardar() async {
    FocusScope.of(
      context,
    ).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final correcto = await _viewModel.changePassword(
      passwordActual: _actualController.text,
      passwordNueva: _nuevaController.text,
      confirmarPassword: _confirmarController.text,
    );

    if (!mounted) {
      return;
    }

    // Si la sesión venció, el router
    // redirigirá automáticamente.
    if (_viewModel.sessionExpired) {
      return;
    }

    if (correcto) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Contraseña actualizada correctamente.',
          ),
          backgroundColor: Color(
            0xFF239B66,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop();

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          _viewModel.errorMessage ?? 'No se pudo actualizar la contraseña.',
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (
        context,
        _,
      ) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 0,
          ),
          body: SafeArea(
            top: true,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                24,
              ),
              children: [
                const Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    color: oscuro,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                const Text(
                  'Actualiza tu contraseña de acceso',
                  style: TextStyle(
                    color: gris,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 32,
                ),

                // ==========================================
                // INFORMACIÓN DE SEGURIDAD
                // ==========================================

                Container(
                  padding: const EdgeInsets.all(
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF0F6FF,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFFCEE0FF,
                      ),
                    ),
                    borderRadius: BorderRadius.circular(
                      11,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usa una contraseña segura',
                        style: TextStyle(
                          color: Color(
                            0xFF17477F,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: 7,
                      ),
                      Text(
                        'Usa al menos 8 caracteres e incluye '
                        'una mayúscula, una minúscula, '
                        'un número y un carácter especial.',
                        style: TextStyle(
                          color: gris,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 26,
                ),

                // ==========================================
                // FORMULARIO
                // ==========================================

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _campoContrasena(
                        label: 'Contraseña actual',
                        controller: _actualController,
                        ocultar: _ocultarActual,
                        alternarVisibilidad: () {
                          setState(
                            () {
                              _ocultarActual = !_ocultarActual;
                            },
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña actual';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      _campoContrasena(
                        label: 'Nueva contraseña',
                        controller: _nuevaController,
                        ocultar: _ocultarNueva,
                        alternarVisibilidad: () {
                          setState(
                            () {
                              _ocultarNueva = !_ocultarNueva;
                            },
                          );
                        },
                        validator: (value) {
                          return Validators.validatePassword(
                            value ?? '',
                          );
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      _campoContrasena(
                        label: 'Confirmar nueva contraseña',
                        controller: _confirmarController,
                        ocultar: _ocultarConfirmacion,
                        alternarVisibilidad: () {
                          setState(
                            () {
                              _ocultarConfirmacion = !_ocultarConfirmacion;
                            },
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirma tu nueva contraseña';
                          }

                          if (value != _nuevaController.text) {
                            return 'Las contraseñas no coinciden';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 14,
                ),

                // ==========================================
                // NIVEL DE SEGURIDAD
                // ==========================================

                Text(
                  _textoSeguridad,
                  style: const TextStyle(
                    color: gris,
                    fontSize: 9,
                  ),
                ),

                const SizedBox(
                  height: 9,
                ),

                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  child: LinearProgressIndicator(
                    value: _nivelSeguridad,
                    minHeight: 6,
                    backgroundColor: const Color(
                      0xFFE4EAF2,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _colorSeguridad,
                    ),
                  ),
                ),

                if (_viewModel.errorMessage != null) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  Text(
                    _viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 24,
                ),

                // ==========================================
                // ACTUALIZAR
                // ==========================================

                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _viewModel.isChangingPassword ? null : _guardar,
                    style: FilledButton.styleFrom(
                      backgroundColor: azul,
                      disabledBackgroundColor: azul.withValues(
                        alpha: 0.6,
                      ),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: _viewModel.isChangingPassword
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Actualizar contraseña',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                TextButton(
                  onPressed: _viewModel.isChangingPassword
                      ? null
                      : () => context.pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: azul,
                    minimumSize: const Size(
                      double.infinity,
                      40,
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
