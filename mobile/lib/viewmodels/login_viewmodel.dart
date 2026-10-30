import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/validators/validators.dart';
import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String correo,
    required String password,
  }) async {
    if (_isLoading) {
      return false;
    }

    final emailError = Validators.validateEmail(
      correo,
    );

    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();

      return false;
    }

    final passwordError = Validators.validateLoginPassword(
      password,
    );

    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();

      return false;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      await _authService.login(
        correo: correo,
        password: password,
      );

      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;

      return false;
    } catch (_) {
      _errorMessage = 'No se pudo completar el inicio '
          'de sesión. Inténtalo nuevamente.';

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }
}
