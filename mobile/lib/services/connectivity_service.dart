
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'session_service.dart';
import 'sync_service.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _initialized = false;

  /// Inicializa la escucha de cambios de conectividad.
  Future<void> initialize({required bool hasSession}) async {
    if (_initialized) return;

    _initialized = true;

    // Recuperar los envíos que quedaron interrumpidos.
    await SyncService.instance
        .recuperarSincronizacionesInterrumpidas();

    // Escuchar cambios en la conexión.
    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) async {
        final hasNetwork =
            results.any((result) => result != ConnectivityResult.none);

        if (hasNetwork && await SessionService.hasToken()) {
          await SyncService.instance.sincronizarPendientes();
        }
      },
    );

    // Comprobar si ya existe conexión al iniciar la aplicación.
    if (hasSession) {
      final results = await _connectivity.checkConnectivity();

      final hasNetwork =
          results.any((result) => result != ConnectivityResult.none);

      if (hasNetwork) {
        await SyncService.instance.sincronizarPendientes();
      }
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }
}
