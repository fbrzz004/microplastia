import 'package:flutter/foundation.dart';

import '../core/utils/format.dart';
import '../models/analysis_result.dart';
import '../services/history_service.dart';
import '../services/local_database_service.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({HistoryService? service})
      : _service = service ?? HistoryService();

  final HistoryService _service;
  final LocalDatabaseService _database = LocalDatabaseService.instance;

  List<AnalysisSummary> _items = const [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _busqueda = '';
  final Set<int> _seleccionados = <int>{};

  List<AnalysisSummary> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String get busqueda => _busqueda;
  int get cantidadSeleccionada => _seleccionados.length;

  int get cantidadPendiente => _items.where(
        (item) =>
            item.isLocal &&
            item.syncStatus != 'synced',
      ).length;

  bool get todosSeleccionados {
    final seleccionables = _items
        .where((item) => item.canOpenDetail)
        .toList();

    return seleccionables.isNotEmpty &&
        seleccionables.every((item) => _seleccionados.contains(item.id));
  }

  List<AnalysisSummary> get filtrados {
    final consulta = _busqueda.trim().toLowerCase();

    if (consulta.isEmpty) return items;

    return _items.where((item) {
      final fecha = formatearFecha(item.createdAt).toLowerCase();

      return item.sampleId.toLowerCase().contains(consulta) ||
          fecha.contains(consulta);
    }).toList();
  }

  bool estaSeleccionado(int id) => _seleccionados.contains(id);

  Future<void> cargar({bool forzar = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !forzar) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    List<AnalysisSummary> localItems = [];
    List<AnalysisSummary> remoteItems = [];

    String? localError;
    String? remoteError;

    // 1. Consultar SQLite.
    try {
      final samples = await _database.getAllSamples();

      localItems = samples
          .map(AnalysisSummary.fromPendingSample)
          .toList();
    } catch (e) {
      localError = e.toString().replaceFirst('Exception: ', '');
    }

    // 2. Consultar el historial de FastAPI.
    try {
      remoteItems = await _service.listar();
    } catch (e) {
      remoteError = e.toString().replaceFirst('Exception: ', '');
    }

    // 3. Combinar registros. La versión remota tiene prioridad
    // cuando una muestra aparece en ambas fuentes.
    final combined = <String, AnalysisSummary>{};

    for (final item in localItems) {
      combined[item.sampleId] = item;
    }

    for (final item in remoteItems) {
      combined[item.sampleId] = item;
    }

    // 4. Ordenar por fecha descendente.
    _items = combined.values.toList()
      ..sort((a, b) {
        final fechaA = a.createdAt ?? DateTime(1970);
        final fechaB = b.createdAt ?? DateTime(1970);
        return fechaB.compareTo(fechaA);
      });

    // 5. Informar si alguna fuente no estuvo disponible.
    if (remoteError != null && localItems.isNotEmpty) {
      _errorMessage =
          'No se pudo actualizar el historial del servidor. '
          'Se muestran los registros guardados en el dispositivo.';
    } else if (remoteError != null && localItems.isEmpty) {
      _errorMessage = remoteError;
    } else if (localError != null) {
      _errorMessage =
          'No se pudieron consultar todos los registros locales: '
          '$localError';
    }

    _hasLoaded = true;

    // Mantener únicamente las selecciones que siguen existiendo.
    _seleccionados.removeWhere(
      (id) => !_items.any((item) => item.id == id),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refrescar() => cargar(forzar: true);

  void buscar(String valor) {
    if (_busqueda == valor) return;

    _busqueda = valor;
    notifyListeners();
  }

  void alternarSeleccion(int id) {
    if (!_seleccionados.remove(id)) {
      _seleccionados.add(id);
    }

    notifyListeners();
  }

  void alternarSeleccionTodos() {
    final seleccionables = _items
        .where((item) => item.canOpenDetail)
        .toList();

    if (seleccionables.isEmpty) return;

    if (todosSeleccionados) {
      _seleccionados.removeAll(
        seleccionables.map((item) => item.id),
      );
    } else {
      _seleccionados.addAll(
        seleccionables.map((item) => item.id),
      );
    }

    notifyListeners();
  }
}
