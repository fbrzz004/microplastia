
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar muestra'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.science_outlined,
                size: 72,
              ),
              const SizedBox(height: 16),
              const Text(
                'Análisis de microplásticos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Aquí podrás seleccionar una imagen '
                'para analizar una muestra.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La selección de imágenes se implementará después.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Seleccionar imagen'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}