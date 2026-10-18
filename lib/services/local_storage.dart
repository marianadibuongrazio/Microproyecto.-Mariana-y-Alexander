import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/high_score.dart';

/// Almacenamiento local único: preferencias y récords usan claves separadas.
class LocalStorage {
  static const String _settingsKey = 'puzzle.settings.v1';
  static const String _highScoresKey = 'puzzle.scores.v1';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return const AppSettings();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const AppSettings();
      return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      return const AppSettings();
    } on TypeError {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<Map<int, DifficultyScores>> loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_highScoresKey);
    if (raw == null) return <int, DifficultyScores>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <int, DifficultyScores>{};
      final scores = <int, DifficultyScores>{};
      for (final size in <int>[3, 4, 5]) {
        final value = decoded['$size'];
        if (value is Map) {
          scores[size] = DifficultyScores.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
      return scores;
    } on FormatException {
      return <int, DifficultyScores>{};
    } on TypeError {
      return <int, DifficultyScores>{};
    }
  }

  /// Registrar únicamente la partida ganada; compara cada récord por separado.
  Future<ScoreUpdate> registerWin({
    required int gridSize,
    required int elapsedMs,
    required int moves,
  }) async {
    if (gridSize != 3 && gridSize != 4 && gridSize != 5) {
      throw ArgumentError.value(gridSize, 'gridSize', 'Debe ser 3, 4 o 5');
    }
    if (elapsedMs < 0) {
      throw ArgumentError.value(
        elapsedMs,
        'elapsedMs',
        'No puede ser negativo',
      );
    }
    if (moves <= 0) {
      throw ArgumentError.value(moves, 'moves', 'Debe ser positivo');
    }

    final scores = await loadHighScores();
    final current = scores[gridSize] ?? const DifficultyScores();
    final faster =
        current.fastest == null || elapsedMs < current.fastest!.elapsedMs;
    final fewer =
        current.fewestMoves == null || moves < current.fewestMoves!.moves;

    if (faster || fewer) {
      final win = ScoreEntry(
        elapsedMs: elapsedMs,
        moves: moves,
        completedAt: DateTime.now(),
      );
      scores[gridSize] = DifficultyScores(
        fastest: faster ? win : current.fastest,
        fewestMoves: fewer ? win : current.fewestMoves,
      );
      final stored = <String, dynamic>{
        for (final entry in scores.entries)
          '${entry.key}': entry.value.toJson(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_highScoresKey, jsonEncode(stored));
    }

    return ScoreUpdate(newBestTime: faster, newFewestMoves: fewer);
  }

  /// Solo elimina récords; no afecta tema, dificultad ni estilo.
  Future<void> clearHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_highScoresKey);
  }
}
