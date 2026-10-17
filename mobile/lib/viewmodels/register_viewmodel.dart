import 'package:flutter/foundation.dart';
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
    if (_isLoading) return false;

    if (nombre.trim().isEmpty ||
        correo.trim().isEmpty ||
        password.isEmpty) {
      _errorMessage = 'Completa los campos obligatorios';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.register(
        nombre: nombre.trim(),
        apellido: apellido?.trim().isEmpty == true
            ? null
            : apellido?.trim(),
        correo: correo.trim(),
        password: password,
      );

      if (result['success'] == true) {
        return true;
      }

      _errorMessage = result['message']?.toString()
          ?? 'Error al registrar usuario';

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
