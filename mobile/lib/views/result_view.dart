
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/analysis_viewmodel.dart';
import 'package:go_router/go_router.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

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

          final total = data is Map
              ? data['total_particles']
              : null;

          final tiempo = data is Map
              ? data['processing_time_ms']
              : null;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.analytics_outlined,
                    size: 72,
                    color: Color(0xFF1976E9),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Resultados del análisis',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Partículas detectadas: ${total ?? "No disponible"}'),
                  const SizedBox(height: 8),
                  Text('Tiempo de procesamiento: ${tiempo ?? "No disponible"} ms'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.limpiarResultado();
                      context.go('/analysis');
                    },
                    child: const Text('Analizar otra muestra'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}