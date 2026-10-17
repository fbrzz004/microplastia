import 'package:flutter/foundation.dart';
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
    // Evitar solicitudes simultáneas.
    if (_isLoading) return false;

    // Validar los campos antes de llamar a la API.
    if (correo.trim().isEmpty || password.trim().isEmpty) {
      _errorMessage = 'Completa todos los campos';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        correo: correo.trim(),
        password: password,
      );

      if (result['success'] == true) {
        return true;
      }

      _errorMessage = result['message']?.toString()
          ?? 'Error al iniciar sesión';

      return false;
    } catch (e) {
      _errorMessage = 'No se pudo conectar con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }
}