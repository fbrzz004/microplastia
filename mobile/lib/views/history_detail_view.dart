import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/utils/format.dart';
import '../models/analysis_result.dart';
import '../services/history_service.dart';

class HistoryDetailView extends StatefulWidget {
  const HistoryDetailView({
    super.key,
    required this.resultId,
  });

  final int resultId;

  @override
  State<HistoryDetailView> createState() => _HistoryDetailViewState();
}

class _HistoryDetailViewState extends State<HistoryDetailView> {
  static const Color texto = Color(0xFF203653);
  static const Color secundario = Color(0xFF8492A6);

  final HistoryService _service = HistoryService();

  AnalysisDetail? _detalle;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detalle = await _service.obtener(widget.resultId);

      if (!mounted) return;

      setState(() {
        _detalle = detalle;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detalle del análisis'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: texto,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _contenido(),
          ),
        ),
      ),
    );
  }

  Widget _contenido() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _detalle == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 44,
              color: secundario,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'No se encontró el análisis.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: secundario),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final detalle = _detalle!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        Text(
          detalle.sampleId,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: texto,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formatearFechaHora(detalle.createdAt),
          style: const TextStyle(fontSize: 12, color: secundario),
        ),
        const SizedBox(height: 18),
        if (detalle.annotatedImageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              '${AppConfig.apiBaseUrl}${detalle.annotatedImageUrl}',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 20),
        _Dato(
          etiqueta: 'Partículas detectadas',
          valor: '${detalle.totalParticles}',
        ),
        const SizedBox(height: 8),
        _Dato(
          etiqueta: 'Confianza promedio',
          valor: '${detalle.confidencePercent}%',
        ),
        const SizedBox(height: 8),
        _Dato(
          etiqueta: 'Tiempo de procesamiento',
          valor: '${detalle.processingTimeMs} ms',
        ),
        if (detalle.breakdown.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'Desglose por morfología',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: texto,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detalle.breakdown.entries
                .map(
                  (entry) => Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor: const Color(0xFFE0F5FC),
                    labelStyle: const TextStyle(
                      color: texto,
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          '${detalle.detections.length} detecciones registradas',
          style: const TextStyle(fontSize: 12, color: secundario),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _Dato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 13,
            color: _HistoryDetailColors.secundario,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _HistoryDetailColors.texto,
          ),
        ),
      ],
    );
  }
}

class _HistoryDetailColors {
  static const Color texto = Color(0xFF203653);
  static const Color secundario = Color(0xFF8492A6);
}
