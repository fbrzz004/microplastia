
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultView extends StatelessWidget {
  const ResultView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 72,
              ),
              const SizedBox(height: 16),
              const Text(
                'Resultados del análisis',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Los resultados de la muestra aparecerán aquí '
                'cuando conectemos el modelo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/analysis'),
                child: const Text('Analizar otra muestra'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}