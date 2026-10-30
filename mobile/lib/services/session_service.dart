import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = 'access_token';

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
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _tokenKey,
      token,
    );

    sessionNotifier.value = true;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      _tokenKey,
    );
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
