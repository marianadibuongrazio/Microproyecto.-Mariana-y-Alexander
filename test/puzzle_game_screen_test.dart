import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/game/puzzle_engine.dart';
import 'package:puzzle_deslizante/game/puzzle_game_screen.dart';
import 'package:puzzle_deslizante/models/app_settings.dart';
import 'package:puzzle_deslizante/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> openGame(
    WidgetTester tester, {
    required List<int> initialBoard,
    TileStyle style = TileStyle.classic,
    bool animationsEnabled = false,
  }) async {
    // Pantalla alta para que todas las piezas sean accesibles al probar taps.
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleGameScreen(
          gridSize: 3,
          tileStyle: style,
          animationsEnabled: animationsEnabled,
          storage: LocalStorage(),
          initialEngine: PuzzleEngine(gridSize: 3, initialBoard: initialBoard),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Presenta las dificultades 3x3, 4x4 y 5x5', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [3, 4, 5]) {
      await tester.pumpWidget(
        MaterialApp(
          home: PuzzleGameScreen(
            gridSize: size,
            tileStyle: TileStyle.classic,
            animationsEnabled: false,
            storage: LocalStorage(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('puzzle-board')), findsOneWidget);
      expect(find.byKey(Key('tile-${size * size - 1}')), findsOneWidget);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('El tablero muestra fichas, vacío y contador en cero', (
    tester,
  ) async {
    await openGame(tester, initialBoard: [1, 2, 3, 4, 5, 6, 0, 7, 8]);
    expect(find.byKey(const Key('puzzle-board')), findsOneWidget);
    expect(find.byKey(const Key('tile-0')), findsOneWidget);
    expect(find.byKey(const Key('tile-8')), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);
    expect(find.byKey(const Key('move-count')), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Movimiento ilegal no cambia estado; el legal sí', (
    tester,
  ) async {
    await openGame(tester, initialBoard: [1, 2, 3, 4, 5, 6, 0, 7, 8]);
    await tester.tap(find.byKey(const Key('tile-1')));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tile-7')));
    await tester.pump();
    expect(find.text('1'), findsWidgets); // ficha 1 y contador
    final counter = tester.widget<Text>(find.byKey(const Key('move-count')));
    expect(counter.data, '1');
    await tester.pumpWidget(const SizedBox.shrink()); // Cancela el timer.
  });

  testWidgets('Resolver congela la partida y muestra el resumen', (
    tester,
  ) async {
    await openGame(tester, initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    await tester.tap(find.byKey(const Key('tile-8')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('victory-dialog')), findsOneWidget);
    expect(find.textContaining('Movimientos: 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('victory-reset-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('victory-dialog')), findsNothing);
    final counter = tester.widget<Text>(find.byKey(const Key('move-count')));
    expect(counter.data, '0');
  });

  testWidgets('Botón Reiniciar restaura los contadores', (tester) async {
    await openGame(tester, initialBoard: [1, 2, 3, 4, 5, 6, 0, 7, 8]);
    await tester.tap(find.byKey(const Key('tile-7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('reset-button')));
    await tester.pump();
    final counter = tester.widget<Text>(find.byKey(const Key('move-count')));
    expect(counter.data, '0');
    expect(find.text('00:00'), findsOneWidget);
  });

  testWidgets('Estilo retro y animaciones desactivadas funcionan', (
    tester,
  ) async {
    await openGame(
      tester,
      initialBoard: [1, 2, 3, 4, 5, 6, 0, 7, 8],
      style: TileStyle.retro,
    );
    expect(find.byKey(const Key('tile-8')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tile-7')));
    await tester.pump();
    expect(find.byKey(const Key('tile-7')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink()); // Cancela el timer.
  });
}
