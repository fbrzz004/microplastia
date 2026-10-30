import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/utils/format.dart';
import '../models/analysis_result.dart';
import '../services/history_service.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    HistoryService? service,
  }) : _service = service ?? HistoryService();

  final HistoryService _service;

  List<AnalysisSummary> _items = const [];

  bool _isLoading = false;
  bool _hasLoaded = false;

  String? _errorMessage;

  bool _sessionExpired = false;

  String _busqueda = '';

  final Set<int> _seleccionados = <int>{};

  List<AnalysisSummary> get items => List.unmodifiable(_items);

  bool get isLoading => _isLoading;

  bool get hasLoaded => _hasLoaded;

  String? get errorMessage => _errorMessage;

  bool get sessionExpired => _sessionExpired;

  String get busqueda => _busqueda;

  int get cantidadSeleccionada => _seleccionados.length;

  bool get todosSeleccionados =>
      _items.isNotEmpty && _seleccionados.length == _items.length;

  List<AnalysisSummary> get filtrados {
    final consulta = _busqueda.trim().toLowerCase();

    if (consulta.isEmpty) {
      return items;
    }

    return _items.where(
      (item) {
        final fecha = formatearFecha(
          item.createdAt,
        ).toLowerCase();

        return item.sampleId.toLowerCase().contains(
                  consulta,
                ) ||
            fecha.contains(
              consulta,
            );
      },
    ).toList();
  }

  bool estaSeleccionado(
    int id,
  ) =>
      _seleccionados.contains(id);

  Future<void> cargar({
    bool forzar = false,
  }) async {
    if (_isLoading) {
      return;
    }

    if (_hasLoaded && !forzar) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;
    _sessionExpired = false;

    notifyListeners();

    try {
      _items = await _service.listar();

      _hasLoaded = true;

      _seleccionados.removeWhere(
        (id) => !_items.any(
          (item) => item.id == id,
        ),
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;

      _sessionExpired = e.sessionExpired;
    } catch (_) {
      _errorMessage = 'No se pudo cargar '
          'el historial.';
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  Future<void> refrescar() => cargar(
        forzar: true,
      );

  void buscar(
    String valor,
  ) {
    if (_busqueda == valor) {
      return;
    }

    _busqueda = valor;

    notifyListeners();
  }

  void alternarSeleccion(
    int id,
  ) {
    if (!_seleccionados.remove(id)) {
      _seleccionados.add(id);
    }

    notifyListeners();
  }

  void alternarSeleccionTodos() {
    if (todosSeleccionados) {
      _seleccionados.clear();
    } else {
      _seleccionados
        ..clear()
        ..addAll(
          _items.map(
            (item) => item.id,
          ),
        );
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();

    super.dispose();
  }
}
