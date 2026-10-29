import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/utils/format.dart';
import '../models/analysis_result.dart';
import '../viewmodels/history_viewmodel.dart';

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

  final TextEditingController _busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HistoryViewModel>().cargar();
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _generarReporte(HistoryViewModel viewModel) async {
    if (viewModel.cantidadSeleccionada == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un análisis.'),
        ),
      );
      return;
    }

    final reportUrl = await viewModel.generarReporte();

    if (!mounted) return;

    if (reportUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.reportError ?? 'No se pudo generar el reporte.',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reporte generado'),
        content: Text(
          'Se generó el reporte con '
          '${viewModel.cantidadSeleccionada} análisis.\n\n'
          'Puedes abrir el PDF desde el navegador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(
                '${AppConfig.apiBaseUrl}$reportUrl',
              );
              final opened = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );

              if (!dialogContext.mounted) return;

              if (opened) {
                Navigator.of(dialogContext).pop();
                return;
              }

              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo abrir el PDF.'),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Abrir PDF'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoryViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              onRefresh: viewModel.refrescar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                children: [
                  _encabezado(viewModel),
                  const SizedBox(height: 24),
                  _buscador(viewModel),
                  const SizedBox(height: 20),
                  ..._contenido(viewModel),
                  const SizedBox(height: 8),
                  Text(
                    '${viewModel.cantidadSeleccionada} análisis seleccionados',
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
                      onPressed: viewModel.isGeneratingReport
                          ? null
                          : () => _generarReporte(viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azul,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            azul.withValues(alpha: 0.6),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isGeneratingReport
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Generando reporte...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Generar reporte '
                              '(${viewModel.cantidadSeleccionada})',
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
          ),
        ),
      ),
    );
  }

  Widget _encabezado(HistoryViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Tus análisis guardados',
                style: TextStyle(
                  fontSize: 12,
                  color: secundario,
                ),
              ),
            ],
          ),
        ),
        if (viewModel.items.isNotEmpty)
          OutlinedButton(
            onPressed: viewModel.alternarSeleccionTodos,
            style: OutlinedButton.styleFrom(
              foregroundColor: azul,
              backgroundColor: const Color(0xFFF4F8FF),
              side: const BorderSide(color: azulBorde),
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            child: Text(
              viewModel.todosSeleccionados ? 'Deseleccionar' : 'Seleccionar',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buscador(HistoryViewModel viewModel) {
    return TextField(
      controller: _busquedaController,
      onChanged: viewModel.buscar,
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
        suffixIcon: viewModel.busqueda.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _busquedaController.clear();
                  viewModel.buscar('');
                },
                icon: const Icon(Icons.close, size: 18),
              )
            : null,
        filled: true,
        fillColor: fondoBusqueda,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: azulBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: azul),
        ),
      ),
    );
  }

  List<Widget> _contenido(HistoryViewModel viewModel) {
    if (viewModel.isLoading && !viewModel.hasLoaded) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (viewModel.errorMessage != null && viewModel.items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: secundario,
              ),
              const SizedBox(height: 10),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: secundario,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: viewModel.refrescar,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ];
    }

    if (viewModel.items.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off,
                size: 48,
                color: secundario,
              ),
              SizedBox(height: 10),
              Text(
                'Todavía no hay análisis guardados.\n'
                'Analiza una muestra para verla aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secundario),
              ),
            ],
          ),
        ),
      ];
    }

    final resultados = viewModel.filtrados;

    if (resultados.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 35),
          child: Text(
            'No se encontraron análisis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: secundario, fontSize: 13),
          ),
        ),
      ];
    }

    return [
      if (viewModel.errorMessage != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'No se pudo actualizar: ${viewModel.errorMessage}',
            style: const TextStyle(fontSize: 11, color: Colors.redAccent),
          ),
        ),
      ...resultados.map(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AnalysisCard(
            item: item,
            selected: viewModel.estaSeleccionado(item.id),
            onOpen: () => context.push('/history/${item.id}'),
            onToggle: () => viewModel.alternarSeleccion(item.id),
          ),
        ),
      ),
    ];
  }
}

class _AnalysisCard extends StatelessWidget {
  static const Color azul = Color(0xFF1976E9);
  static const Color azulClaro = Color(0xFFE1F5FE);
  static const Color azulBorde = Color(0xFFDCE6F1);
  static const Color verde = Color(0xFF00A878);
  static const Color texto = Color(0xFF172033);
  static const Color secundario = Color(0xFF8492A6);

  final AnalysisSummary item;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  const _AnalysisCard({
    required this.item,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? azul : azulBorde,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: azulClaro,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.biotech_outlined,
                size: 21,
                color: azul,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.sampleId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: texto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatearFecha(item.createdAt)} · '
                    '${item.totalParticles} partículas',
                    style: const TextStyle(
                      fontSize: 11,
                      color: secundario,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${item.confidencePercent}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: verde,
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) => onToggle(),
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
