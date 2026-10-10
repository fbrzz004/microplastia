import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets(
    'La aplicación inicia correctamente',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MyApp(
          hasSession: false,
        ),
      );

      expect(find.text('Iniciar sesión'), findsOneWidget);
    },
  );
}