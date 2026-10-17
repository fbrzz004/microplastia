import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/config/app_config.dart';
import '../viewmodels/analysis_viewmodel.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

  static const Color azul = Color(0xFF1976E9);
  static const Color texto = Color(0xFF203653);
  static const Color secundario = Color(0xFF8492A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: Consumer<AnalysisViewModel>(
        builder: (context, viewModel, child) {
          final resultado = viewModel.resultado;

          if (resultado == null) {
            return const Center(
              child: Text('No hay resultados disponibles.'),
            );
          }

          final data = resultado['data'];
          if (data is! Map) {
            return const Center(
              child: Text('No hay resultados disponibles.'),
            );
          }

          final total = data['total_particles'] ?? 0;
          final tiempo = data['processing_time_ms'];
          final annotatedUrl = data['annotated_image_url'] as String?;
          final breakdown = data['breakdown'];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 56,
                color: azul,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Resultados del análisis',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: texto,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (annotatedUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    '${AppConfig.apiBaseUrl}$annotatedUrl',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 20),
              _Dato(
                etiqueta: 'Partículas detectadas',
                valor: '$total',
              ),
              const SizedBox(height: 8),
              _Dato(
                etiqueta: 'Tiempo de procesamiento',
                valor: tiempo != null ? '$tiempo ms' : 'No disponible',
              ),
              if (breakdown is Map && breakdown.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Desglose por morfología',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: texto,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: breakdown.entries
                      .map(
                        (e) => Chip(
                          label: Text('${e.key}: ${e.value}'),
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
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  viewModel.limpiarResultado();
                  context.go('/analysis');
                },
                child: const Text('Analizar otra muestra'),
              ),
            ],
          );
        },
      ),
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
            color: ResultView.secundario,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ResultView.texto,
          ),
        ),
      ],
    );
  }
}
