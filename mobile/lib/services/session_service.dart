import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = 'access_token';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Evita bloquear la aplicación si el plugin de
  // almacenamiento seguro no responde (por ejemplo,
  // en pruebas o en escritorio sin libsecret).
  static const Duration _secureTimeout = Duration(seconds: 1);

  // ======================================================
  // ALMACENAMIENTO SEGURO
  // ======================================================

  static Future<String?> _readSecureToken() async {
    try {
      return await _secureStorage
          .read(
            key: _tokenKey,
          )
          .timeout(_secureTimeout);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _writeSecureToken(
    String token,
  ) async {
    try {
      await _secureStorage
          .write(
            key: _tokenKey,
            value: token,
          )
          .timeout(_secureTimeout);

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _deleteSecureToken() async {
    try {
      await _secureStorage
          .delete(
            key: _tokenKey,
          )
          .timeout(_secureTimeout);
    } catch (_) {
      // Sin almacenamiento seguro disponible.
    }
  }

  static final ValueNotifier<bool> sessionNotifier = ValueNotifier<bool>(false);

  static bool get hasActiveSession => sessionNotifier.value;

  static Future<bool> initialize() async {
    final valid = await hasToken();
    sessionNotifier.value = valid;
    return valid;
  }

  static Future<void> saveToken(
    String token,
  ) async {
    final storedSecurely = await _writeSecureToken(
      token,
    );

    final prefs = await SharedPreferences.getInstance();

    if (storedSecurely) {
      await prefs.remove(_tokenKey);
    } else {
      // Respaldo para plataformas sin almacenamiento
      // seguro disponible (por ejemplo, escritorio Linux
      // sin libsecret o pruebas automatizadas).
      await prefs.setString(
        _tokenKey,
        token,
      );
    }

    sessionNotifier.value = true;
  }

  static Future<String?> getToken() async {
    final secureToken = await _readSecureToken();

    if (secureToken != null && secureToken.trim().isNotEmpty) {
      return secureToken;
    }

    // Migración desde la versión que guardaba el
    // token en texto plano.
    final prefs = await SharedPreferences.getInstance();

    final legacyToken = prefs.getString(
      _tokenKey,
    );

    if (legacyToken == null || legacyToken.trim().isEmpty) {
      return null;
    }

    final storedSecurely = await _writeSecureToken(
      legacyToken,
    );

    if (storedSecurely) {
      await prefs.remove(_tokenKey);
    }

    return legacyToken;
  }

  static Future<bool> hasToken() async {
    final token = await getToken();

    if (token == null || token.trim().isEmpty) {
      sessionNotifier.value = false;
      return false;
    }

    if (_isJwtExpired(token)) {
      await clearToken();
      return false;
    }

    sessionNotifier.value = true;

    return true;
  }

  static Future<String?> getValidToken() async {
    final token = await getToken();

    if (token == null || token.trim().isEmpty) {
      sessionNotifier.value = false;
      return null;
    }

    if (_isJwtExpired(token)) {
      await clearToken();
      return null;
    }

    sessionNotifier.value = true;

    return token;
  }

  static Future<void> clearToken() async {
    await _deleteSecureToken();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _tokenKey,
    );

    sessionNotifier.value = false;
  }

  static bool _isJwtExpired(
    String token,
  ) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(
            parts[1],
          ),
        ),
      );

      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return true;
      }

      final exp = decoded['exp'];

      if (exp is! num) {
        return true;
      }

      final expiration = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );

      return DateTime.now().toUtc().isAfter(expiration);
    } catch (_) {
      return true;
    }
  }
}
