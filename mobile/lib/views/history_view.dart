import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de muestras'),
        backgroundColor: Colors.blue.shade50,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: Colors.blueGrey,
              ),
              SizedBox(height: 16),
              Text(
                'Historial de análisis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Aquí aparecerán las muestras analizadas.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'La carga de datos estará disponible '
                'cuando se implemente el almacenamiento.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}