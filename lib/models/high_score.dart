/// Una partida terminada. Cada récord guarda su propia fecha y métricas.
class ScoreEntry {
  const ScoreEntry({
    required this.elapsedMs,
    required this.moves,
    required this.completedAt,
  });

  final int elapsedMs;
  final int moves;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'elapsedMs': elapsedMs,
    'moves': moves,
    'completedAt': completedAt.toIso8601String(),
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    final elapsedMs = json['elapsedMs'];
    final moves = json['moves'];
    final date = json['completedAt'];
    final completedAt = date is String ? DateTime.tryParse(date) : null;

    if (elapsedMs is! int ||
        elapsedMs < 0 ||
        moves is! int ||
        moves <= 0 ||
        completedAt == null) {
      throw const FormatException('Registro de puntuación inválido');
    }
    return ScoreEntry(
      elapsedMs: elapsedMs,
      moves: moves,
      completedAt: completedAt,
    );
  }
}

/// El récord más rápido y el de menos movimientos son independientes.
class DifficultyScores {
  const DifficultyScores({this.fastest, this.fewestMoves});

  final ScoreEntry? fastest;
  final ScoreEntry? fewestMoves;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fastest': fastest?.toJson(),
    'fewestMoves': fewestMoves?.toJson(),
  };

  factory DifficultyScores.fromJson(Map<String, dynamic> json) {
    return DifficultyScores(
      fastest: _readScore(json['fastest']),
      fewestMoves: _readScore(json['fewestMoves']),
    );
  }

  static ScoreEntry? _readScore(Object? value) {
    if (value is! Map) return null;
    try {
      return ScoreEntry.fromJson(Map<String, dynamic>.from(value));
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

class ScoreUpdate {
  const ScoreUpdate({required this.newBestTime, required this.newFewestMoves});

  final bool newBestTime;
  final bool newFewestMoves;

  bool get isNewRecord => newBestTime || newFewestMoves;
}
