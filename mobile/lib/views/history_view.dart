
import 'package:flutter/material.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  static const Color azul = Color(0xFF1976E9);
  static const Color texto = Color(0xFF203653);
  static const Color secundario = Color(0xFF8492A6);
  static const Color azulBorde = Color(0xFFDCE6F1);
  static const Color fondoBusqueda = Color(0xFFF4F7FB);
  static const Color verde = Color(0xFF00A878);

  final TextEditingController _busquedaController =
      TextEditingController();

  String _busqueda = '';

  // Datos provisionales hasta conectar el historial con el backend.
  final List<_AnalysisItem> _analisis = [
    _AnalysisItem(id: '024', porcentaje: 92, selected: true),
    _AnalysisItem(id: '023', porcentaje: 90, selected: true),
    _AnalysisItem(id: '022', porcentaje: 94),
    _AnalysisItem(id: '021', porcentaje: 88),
  ];

  List<_AnalysisItem> get _analisisFiltrados {
    final query = _busqueda.trim().toLowerCase();

    if (query.isEmpty) return _analisis;

    return _analisis.where((item) {
      return 'muestra #${item.id}'.contains(query) ||
          item.id.contains(query);
    }).toList();
  }

  int get _cantidadSeleccionada =>
      _analisis.where((item) => item.selected).length;

  void _alternarSeleccion(_AnalysisItem item) {
    setState(() {
      item.selected = !item.selected;
    });
  }

  void _alternarSeleccionTodos() {
    setState(() {
      final seleccionarTodos =
          _analisis.any((item) => !item.selected);

      for (final item in _analisis) {
        item.selected = seleccionarTodos;
      }
    });
  }

  void _generarReporte() {
    if (_cantidadSeleccionada == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un análisis.'),
        ),
      );
      return;
    }

    // Aquí conectaremos posteriormente el servicio de reportes.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Has seleccionado $_cantidadSeleccionada análisis. '
          'La generación del reporte está pendiente de conectar.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultados = _analisisFiltrados;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      18, 16, 18, 20,
                    ),
                    children: [
                      // Encabezado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Historial',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: texto,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Selecciona análisis para generar un reporte',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: _alternarSeleccionTodos,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: azul,
                              backgroundColor:
                                  const Color(0xFFF4F8FF),
                              side: const BorderSide(
                                color: azulBorde,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(11),
                              ),
                            ),
                            child: Text(
                              _analisis.isNotEmpty &&
                                      _analisis.every(
                                        (item) => item.selected,
                                      )
                                  ? 'Deseleccionar'
                                  : 'Seleccionar',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Buscador
                      TextField(
                        controller: _busquedaController,
                        onChanged: (value) {
                          setState(() => _busqueda = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por muestra o fecha',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: secundario,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 19,
                            color: secundario,
                          ),
                          suffixIcon: _busqueda.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _busquedaController.clear();
                                    setState(() => _busqueda = '');
                                  },
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: fondoBusqueda,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: azulBorde,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(13),
                            borderSide: const BorderSide(
                              color: azul,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tarjetas del historial
                      if (resultados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 35,
                          ),
                          child: Text(
                            'No se encontraron análisis.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secundario,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else
                        ...resultados.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _AnalysisCard(
                              item: item,
                              onTap: () =>
                                  _alternarSeleccion(item),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      Text(
                        '$_cantidadSeleccionada análisis seleccionados',
                        style: const TextStyle(
                          fontSize: 12,
                          color: secundario,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        height: 47,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _generarReporte,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azul,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Generar reporte ($_cantidadSeleccionada)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalysisItem {
  final String id;
  final int porcentaje;
  bool selected;

  _AnalysisItem({
    required this.id,
    required this.porcentaje,
    this.selected = false,
  });
}

class _AnalysisCard extends StatelessWidget {
  final _AnalysisItem item;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.item,
    required this.onTap,
  });

  static const Color azul = Color(0xFF1976E9);
  static const Color azulBorde = Color(0xFFDCE6F1);
  static const Color verde = Color(0xFF00A878);
  static const Color texto = Color(0xFF172033);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: azulBorde),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: texto,
                      ),
                      children: [
                        TextSpan(text: 'Muestra #${item.id} '),
                        TextSpan(
                          text: '${item.porcentaje}%',
                          style: const TextStyle(
                            color: verde,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Checkbox(
              value: item.selected,
              onChanged: (_) => onTap(),
              activeColor: azul,
              side: const BorderSide(
                color: Color(0xFFB8CBE0),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
