import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/profile_viewmodel.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final ProfileViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();

  static const Color azul = Color(0xFF1976E9);
  static const Color oscuro = Color(0xFF203653);
  static const Color gris = Color(0xFF8290A5);
  static const Color borde = Color(0xFFDCE5F1);

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    await _viewModel.loadProfile();

    if (!mounted) return;

    _nombreController.text = _viewModel.nombre;
    _apellidoController.text = _viewModel.apellido;
    _correoController.text = _viewModel.correo;
  }

  String get _iniciales {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();

    final primera = nombre.isNotEmpty ? nombre[0] : '';
    final segunda = apellido.isNotEmpty ? apellido[0] : '';

    final resultado = '$primera$segunda'.toUpperCase();
    return resultado.isEmpty ? 'U' : resultado;
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  InputDecoration _decoracion(String etiqueta) {
    return InputDecoration(
      hintText: etiqueta,
      hintStyle: const TextStyle(
        color: Color(0xFF657793),
        fontSize: 12,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: azul, width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _campo({
    required String etiqueta,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: Color(0xFF536783),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          autocorrect: false,
          decoration: _decoracion(etiqueta),
          validator: validator,
          style: const TextStyle(
            fontSize: 12,
            color: oscuro,
          ),
        ),
      ],
    );
  }

  Future<void> _guardarCambios() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final correcto = await _viewModel.updateProfile(
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      correo: _correoController.text.trim(),
    );

    if (!mounted) return;

    if (correcto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
          backgroundColor: Color(0xFF239B66),
          behavior: SnackBarBehavior.floating,
        ),
      );

      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.errorMessage ??
                'No se pudieron guardar los cambios.',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
          ),
          body: SafeArea(
            top: true,
            bottom: false,
            child: _viewModel.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: azul),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(23, 20, 23, 24),
                    children: [
                      const Text(
                        'Editar perfil',
                        style: TextStyle(
                          color: oscuro,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Actualiza tu información personal',
                        style: TextStyle(
                          color: gris,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Avatar e iniciales
                      Center(
                        child: Container(
                          width: 73,
                          height: 73,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F1FF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFBED8FF),
                            ),
                          ),
                          child: Text(
                            _iniciales,
                            style: const TextStyle(
                              color: Color(0xFF17477F),
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _campo(
                              etiqueta: 'Nombre',
                              controller: _nombreController,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu nombre';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 13),

                            _campo(
                              etiqueta: 'Apellido',
                              controller: _apellidoController,
                              textCapitalization: TextCapitalization.words,
                              validator: (_) => null,
                            ),

                            const SizedBox(height: 13),

                            _campo(
                              etiqueta: 'Correo',
                              controller: _correoController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final correo = value?.trim() ?? '';

                                if (correo.isEmpty) {
                                  return 'Ingresa tu correo';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(correo)) {
                                  return 'Ingresa un correo válido';
                                }

                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Rol: ${_viewModel.rol}',
                        style: const TextStyle(
                          color: gris,
                          fontSize: 9,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _viewModel.isSavingProfile
                              ? null
                              : _guardarCambios,
                          style: FilledButton.styleFrom(
                            backgroundColor: azul,
                            disabledBackgroundColor:
                                azul.withValues(alpha: 0.6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: _viewModel.isSavingProfile
                              ? const SizedBox(
                                  height: 19,
                                  width: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Guardar cambios',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      TextButton(
                        onPressed: _viewModel.isSavingProfile
                            ? null
                            : () => context.pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: azul,
                          minimumSize: const Size(double.infinity, 38),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 11),
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
