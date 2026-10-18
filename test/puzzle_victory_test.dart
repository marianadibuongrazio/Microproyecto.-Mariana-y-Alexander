import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/game/puzzle_engine.dart';
import 'package:puzzle_deslizante/game/puzzle_game_screen.dart';
import 'package:puzzle_deslizante/models/app_settings.dart';
import 'package:puzzle_deslizante/models/high_score.dart';
import 'package:puzzle_deslizante/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingStorage extends LocalStorage {
  int saves = 0;

  @override
  Future<ScoreUpdate> registerWin({
    required int gridSize,
    required int elapsedMs,
    required int moves,
  }) {
    saves++;
    return super.registerWin(
      gridSize: gridSize,
      elapsedMs: elapsedMs,
      moves: moves,
    );
  }
}

class DelayedStorage extends LocalStorage {
  final Completer<ScoreUpdate> pending = Completer<ScoreUpdate>();
  int saves = 0;

  @override
  Future<ScoreUpdate> registerWin({
    required int gridSize,
    required int elapsedMs,
    required int moves,
  }) {
    saves++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> openGame(
    WidgetTester tester,
    LocalStorage storage, {
    List<int> board = const [1, 2, 3, 4, 5, 6, 7, 0, 8],
  }) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: PuzzleGameScreen(
          gridSize: 3,
          tileStyle: TileStyle.classic,
          animationsEnabled: false,
          storage: storage,
          initialEngine: PuzzleEngine(gridSize: 3, initialBoard: board),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Victoria: guarda una vez y establece ambos récords', (
    tester,
  ) async {
    final storage = CountingStorage();
    await openGame(tester, storage);

    await tester.tap(find.byKey(const Key('tile-8')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('victory-dialog')), findsOneWidget);
    expect(
      find.textContaining('¡Nuevo récord de tiempo y movimientos!'),
      findsOneWidget,
    );
    expect(storage.saves, 1);
    final score = (await storage.loadHighScores())[3]!;
    expect(score.fastest, isNotNull);
    expect(score.fastest!.moves, 1);
    expect(score.fewestMoves!.moves, 1);
    expect(score.fastest!.elapsedMs, greaterThanOrEqualTo(0));

    await tester.pump();
    expect(storage.saves, 1);
    await tester.tap(find.byKey(const Key('victory-reset-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('victory-dialog')), findsNothing);
  });

  testWidgets('Victoria: récord de movimientos sin mejorar el tiempo', (
    tester,
  ) async {
    final storage = LocalStorage();
    await storage.registerWin(gridSize: 3, elapsedMs: 0, moves: 5);
    await openGame(tester, storage);

    await tester.tap(find.byKey(const Key('tile-8')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('¡Nuevo récord de movimientos!'),
      findsOneWidget,
    );
    final score = (await storage.loadHighScores())[3]!;
    expect(score.fastest!.elapsedMs, 0);
    expect(score.fewestMoves!.moves, 1);
  });

  testWidgets('Victoria: récord de tiempo sin mejorar movimientos', (
    tester,
  ) async {
    final storage = LocalStorage();
    await storage.registerWin(gridSize: 3, elapsedMs: 1000000, moves: 1);
    await openGame(tester, storage);

    await tester.tap(find.byKey(const Key('tile-8')));
    await tester.pumpAndSettle();

    expect(find.textContaining('¡Nuevo récord de tiempo!'), findsOneWidget);
    final score = (await storage.loadHighScores())[3]!;
    expect(score.fastest!.elapsedMs, lessThan(1000000));
    expect(score.fewestMoves!.moves, 1);
  });

  testWidgets('Una partida incompleta nunca guarda puntuación', (tester) async {
    final storage = CountingStorage();
    await openGame(tester, storage, board: [1, 2, 3, 4, 5, 6, 0, 7, 8]);

    await tester.tap(find.byKey(const Key('tile-7')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('reset-button')));
    await tester.pump();

    expect(storage.saves, 0);
    expect(await storage.loadHighScores(), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reinicio mientras se guarda no muestra diálogo antiguo', (
    tester,
  ) async {
    final storage = DelayedStorage();
    await openGame(tester, storage);

    await tester.tap(find.byKey(const Key('tile-8')));
    await tester.pump();
    expect(storage.saves, 1);

    await tester.tap(find.byKey(const Key('reset-button')));
    await tester.pump();
    storage.pending.complete(
      const ScoreUpdate(newBestTime: true, newFewestMoves: true),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('victory-dialog')), findsNothing);
  });
}
