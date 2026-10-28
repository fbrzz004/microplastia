import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileViewModel({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService();

  bool isLoading = false;
  bool isSavingProfile = false;
  bool isChangingPassword = false;

  String? errorMessage;
  String? successMessage;

  String nombre = '';
  String apellido = '';
  String correo = '';
  String rol = 'usuario';

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final profile = await _profileService.getMyProfile();

      nombre = profile['nombre']?.toString() ?? '';
      apellido = profile['apellido']?.toString() ?? '';
      correo = profile['correo']?.toString() ?? '';
      rol = profile['rol']?.toString() ?? 'usuario';
    } catch (e) {
      errorMessage = _cleanError(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String nombre,
    required String apellido,
    required String correo,
  }) async {
    if (nombre.trim().isEmpty || correo.trim().isEmpty) {
      errorMessage = 'El nombre y el correo son obligatorios.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    isSavingProfile = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final updated = await _profileService.updateProfile(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
      );

      this.nombre = updated['nombre']?.toString() ?? nombre.trim();
      this.apellido = updated['apellido']?.toString() ?? apellido.trim();
      this.correo = updated['correo']?.toString() ?? correo.trim();

      successMessage = 'Perfil actualizado correctamente.';
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      isSavingProfile = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String passwordActual,
    required String passwordNueva,
    required String confirmarPassword,
  }) async {
    if (passwordActual.isEmpty ||
        passwordNueva.isEmpty ||
        confirmarPassword.isEmpty) {
      errorMessage = 'Completa todos los campos de contraseña.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    if (passwordNueva.length < 8) {
      errorMessage = 'La nueva contraseña debe tener al menos 8 caracteres.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    if (passwordNueva != confirmarPassword) {
      errorMessage = 'Las contraseñas nuevas no coinciden.';
      successMessage = null;
      notifyListeners();
      return false;
    }

    isChangingPassword = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _profileService.changePassword(
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
        confirmarPassword: confirmarPassword,
      );

      successMessage = 'Contraseña actualizada correctamente.';
      return true;
    } catch (e) {
      errorMessage = _cleanError(e);
      return false;
    } finally {
      isChangingPassword = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _profileService.dispose();
    super.dispose();
  }
}
