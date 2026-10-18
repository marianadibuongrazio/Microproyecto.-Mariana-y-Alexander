import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/models/app_settings.dart';
import 'package:puzzle_deslizante/services/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('Preferencias por defecto: sin dificultad elegida', () async {
    final settings = await LocalStorage().loadSettings();
    expect(settings.gridSize, isNull);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.tileStyle, TileStyle.classic);
    expect(settings.animationsEnabled, isTrue);
  });

  test('Las preferencias se guardan y se vuelven a cargar', () async {
    final storage = LocalStorage();
    await storage.saveSettings(
      const AppSettings(
        gridSize: 5,
        themeMode: ThemeMode.dark,
        tileStyle: TileStyle.retro,
        animationsEnabled: false,
      ),
    );

    final settings = await LocalStorage().loadSettings();
    expect(settings.gridSize, 5);
    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.tileStyle, TileStyle.retro);
    expect(settings.animationsEnabled, isFalse);
  });

  test('Una configuración inválida vuelve a valores seguros', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'puzzle.settings.v1': jsonEncode(<String, Object>{
        'gridSize': 9,
        'themeMode': 'unknown',
        'tileStyle': 'unknown',
        'animationsEnabled': 'no',
      }),
    });
    final settings = await LocalStorage().loadSettings();
    expect(settings.gridSize, isNull);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.tileStyle, TileStyle.classic);
    expect(settings.animationsEnabled, isTrue);
  });

  test('La primera victoria fija ambos récords y su fecha', () async {
    final storage = LocalStorage();
    final update = await storage.registerWin(
      gridSize: 4,
      elapsedMs: 15000,
      moves: 25,
    );
    expect(update.isNewRecord, isTrue);
    expect(update.newBestTime, isTrue);
    expect(update.newFewestMoves, isTrue);

    final scores = (await storage.loadHighScores())[4]!;
    expect(scores.fastest!.elapsedMs, 15000);
    expect(scores.fewestMoves!.moves, 25);
    expect(scores.fastest!.completedAt, scores.fewestMoves!.completedAt);
  });

  test(
    'Los récords de tiempo y movimientos se actualizan por separado',
    () async {
      final storage = LocalStorage();
      await storage.registerWin(gridSize: 3, elapsedMs: 20000, moves: 30);
      final oldDate =
          (await storage.loadHighScores())[3]!.fewestMoves!.completedAt;

      final faster = await storage.registerWin(
        gridSize: 3,
        elapsedMs: 10000,
        moves: 40,
      );
      expect(faster.newBestTime, isTrue);
      expect(faster.newFewestMoves, isFalse);
      var scores = (await storage.loadHighScores())[3]!;
      expect(scores.fastest!.elapsedMs, 10000);
      expect(scores.fewestMoves!.moves, 30);
      expect(scores.fewestMoves!.completedAt, oldDate);

      final fewer = await storage.registerWin(
        gridSize: 3,
        elapsedMs: 30000,
        moves: 25,
      );
      expect(fewer.newBestTime, isFalse);
      expect(fewer.newFewestMoves, isTrue);
      scores = (await storage.loadHighScores())[3]!;
      expect(scores.fastest!.elapsedMs, 10000);
      expect(scores.fewestMoves!.moves, 25);
      expect(scores.fewestMoves!.completedAt, isNotNull);
    },
  );

  test('Empate o peor resultado no modifica los récords', () async {
    final storage = LocalStorage();
    await storage.registerWin(gridSize: 5, elapsedMs: 50000, moves: 80);
    final previous = (await storage.loadHighScores())[5]!.fastest!.completedAt;
    final update = await storage.registerWin(
      gridSize: 5,
      elapsedMs: 50000,
      moves: 81,
    );
    expect(update.isNewRecord, isFalse);
    expect((await storage.loadHighScores())[5]!.fastest!.completedAt, previous);
  });

  test('Borrar marcadores conserva configuración', () async {
    final storage = LocalStorage();
    await storage.saveSettings(
      const AppSettings(gridSize: 4, themeMode: ThemeMode.light),
    );
    await storage.registerWin(gridSize: 4, elapsedMs: 30000, moves: 50);
    await storage.clearHighScores();
    expect(await storage.loadHighScores(), isEmpty);
    expect((await storage.loadSettings()).gridSize, 4);
    expect((await storage.loadSettings()).themeMode, ThemeMode.light);
  });

  test('Una puntuación corrupta no bloquea la lectura de otras', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'puzzle.scores.v1': jsonEncode(<String, dynamic>{
        '3': <String, dynamic>{
          'fastest': <String, dynamic>{
            'elapsedMs': -10,
            'moves': 20,
            'completedAt': 'fecha incorrecta',
          },
          'fewestMoves': <String, dynamic>{
            'elapsedMs': 40000,
            'moves': 17,
            'completedAt': '2026-10-17T12:00:00.000',
          },
        },
      }),
    });
    final scores = (await LocalStorage().loadHighScores())[3]!;
    expect(scores.fastest, isNull);
    expect(scores.fewestMoves!.moves, 17);
  });

  test('La dificultad y métricas inválidas se rechazan', () async {
    final storage = LocalStorage();
    await expectLater(
      storage.registerWin(gridSize: 6, elapsedMs: 100, moves: 4),
      throwsArgumentError,
    );
    await expectLater(
      storage.registerWin(gridSize: 3, elapsedMs: -1, moves: 4),
      throwsArgumentError,
    );
    await expectLater(
      storage.registerWin(gridSize: 3, elapsedMs: 100, moves: 0),
      throwsArgumentError,
    );
  });
}
