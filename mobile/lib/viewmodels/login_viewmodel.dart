import 'dart:async';

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

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
    if (_isLoading) return false;

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
        // El JWT ya fue guardado por AuthService.
        // Iniciar la sincronización sin bloquear el inicio de sesión.
        unawaited(_sincronizarPendientes());

        return true;
      }

      _errorMessage = result['message']?.toString()
          ?? 'Error al iniciar sesión';

      return false;
    } on TimeoutException {
      _errorMessage =
          'El servidor no respondió. Verifica la conexión e inténtalo de nuevo';
      return false;
    } on FormatException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'No se pudo conectar con el servidor';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _sincronizarPendientes() async {
    try {
      await SyncService.instance.sincronizarPendientes();
    } catch (e) {
      debugPrint('Error al sincronizar muestras pendientes: $e');
    }
  }

  void clearError() {
    if (_errorMessage == null) return;

    _errorMessage = null;
    notifyListeners();
  }
}
