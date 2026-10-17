import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/main.dart';

void main() {
  testWidgets('Abrir instrucciones y regresar al menú', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Jugar'), findsOneWidget);

    await tester.tap(find.text('Cómo jugar'));
    await tester.pumpAndSettle();

    expect(find.text('Objetivo del juego'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Jugar'), findsOneWidget);
  });
}
