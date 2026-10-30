import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/validators/validators.dart';
import '../services/profile_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;

  ProfileViewModel({
    ProfileService? profileService,
  }) : _profileService = profileService ?? ProfileService();

  bool isLoading = false;
  bool isSavingProfile = false;
  bool isChangingPassword = false;

  String? errorMessage;
  String? successMessage;

  bool sessionExpired = false;

  String nombre = '';
  String apellido = '';
  String correo = '';
  String rol = 'usuario';

  Future<void> loadProfile() async {
    isLoading = true;

    errorMessage = null;
    successMessage = null;
    sessionExpired = false;

    notifyListeners();

    try {
      final profile = await _profileService.getMyProfile();

      nombre = profile['nombre']?.toString() ?? '';

      apellido = profile['apellido']?.toString() ?? '';

      correo = profile['correo']?.toString() ?? '';

      rol = profile['rol']?.toString() ?? 'usuario';
    } on ApiException catch (e) {
      errorMessage = e.message;

      sessionExpired = e.sessionExpired;
    } catch (_) {
      errorMessage = 'No se pudo cargar el perfil.';
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
    final nameError = Validators.validateName(
      nombre,
    );

    if (nameError != null) {
      _setError(nameError);

      return false;
    }

    final lastNameError = Validators.validateOptionalLastName(
      apellido,
    );

    if (lastNameError != null) {
      _setError(lastNameError);

      return false;
    }

    final emailError = Validators.validateEmail(
      correo,
    );

    if (emailError != null) {
      _setError(emailError);

      return false;
    }

    isSavingProfile = true;

    errorMessage = null;
    successMessage = null;
    sessionExpired = false;

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
    } on ApiException catch (e) {
      errorMessage = e.message;

      sessionExpired = e.sessionExpired;

      return false;
    } catch (_) {
      errorMessage = 'No se pudo actualizar el perfil.';

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
    if (passwordActual.isEmpty) {
      _setError(
        'Ingresa tu contraseña actual.',
      );

      return false;
    }

    final passwordError = Validators.validatePassword(
      passwordNueva,
    );

    if (passwordError != null) {
      _setError(
        Validators.passwordErrors(
          passwordNueva,
        ).join('\n'),
      );

      return false;
    }

    if (passwordNueva != confirmarPassword) {
      _setError(
        'Las contraseñas nuevas '
        'no coinciden.',
      );

      return false;
    }

    if (passwordActual == passwordNueva) {
      _setError(
        'La nueva contraseña debe '
        'ser diferente de la actual.',
      );

      return false;
    }

    isChangingPassword = true;

    errorMessage = null;
    successMessage = null;
    sessionExpired = false;

    notifyListeners();

    try {
      await _profileService.changePassword(
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
        confirmarPassword: confirmarPassword,
      );

      successMessage = 'Contraseña actualizada '
          'correctamente.';

      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;

      sessionExpired = e.sessionExpired;

      return false;
    } catch (_) {
      errorMessage = 'No se pudo cambiar '
          'la contraseña.';

      return false;
    } finally {
      isChangingPassword = false;

      notifyListeners();
    }
  }

  void _setError(
    String message,
  ) {
    errorMessage = message;
    successMessage = null;

    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _profileService.dispose();

    super.dispose();
  }
}
