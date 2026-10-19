import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/main.dart';

void main() {
  testWidgets('Abrir instrucciones y regresar al menú', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Espera a que termine el Splash.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Jugar'), findsOneWidget);

    // El nuevo diseño puede colocar "Cómo jugar" fuera
    // del área visible en pantallas pequeñas.
    final howToPlayButton = find.text('Cómo jugar');

    await tester.ensureVisible(howToPlayButton);
    await tester.pumpAndSettle();

    // Abrir la pantalla de instrucciones.
    await tester.tap(howToPlayButton);
    await tester.pumpAndSettle();

    // Verificar que navegamos correctamente.
    expect(find.text('Objetivo del juego'), findsOneWidget);

    // Regresar al menú principal.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Jugar'), findsOneWidget);
  });
}
