import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile/viewmodels/analysis_viewmodel.dart';
import 'package:mobile/views/analysis_view.dart';

void main() {
  testWidgets('La pantalla de análisis muestra sus acciones principales',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AnalysisViewModel(),
        child: const MaterialApp(
          home: AnalysisView(),
        ),
      ),
    );

    expect(find.text('Nueva muestra'), findsOneWidget);
    expect(find.text('Tomar fotografía'), findsOneWidget);
    expect(find.text('Seleccionar imagen'), findsOneWidget);
    // El botón de analizar solo aparece cuando hay una imagen seleccionada.
    expect(find.text('Analizar imagen'), findsNothing);
  });
}
