import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/validators/validators.dart';
import '../services/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> register({
    required String nombre,
    String? apellido,
    required String correo,
    required String password,
  }) async {
    if (_isLoading) {
      return false;
    }

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

    final passwordError = Validators.validatePassword(
      password,
    );

    if (passwordError != null) {
      final errors = Validators.passwordErrors(
        password,
      );

      _setError(
        errors.join('\n'),
      );

      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _authService.register(
        nombre: nombre,
        apellido: apellido,
        correo: correo,
        password: password,
      );

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;

      return false;
    } catch (_) {
      _errorMessage = 'No se pudo completar el registro. '
          'Inténtalo nuevamente.';

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setError(
    String message,
  ) {
    _errorMessage = message;

    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }
}
