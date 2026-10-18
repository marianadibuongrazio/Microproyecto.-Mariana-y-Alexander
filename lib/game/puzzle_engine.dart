import 'dart:math';

/// Lógica del rompecabezas deslizante, independiente de Flutter y de la UI.
///
/// 0 representa el espacio vacío. Una partida normal siempre comienza con un
/// tablero mezclado, resoluble y diferente del tablero resuelto.
class PuzzleEngine {
  PuzzleEngine({
    required this.gridSize,
    Random? random,
    List<int>? initialBoard,
  }) : _random = random ?? Random() {
    _validateSize(gridSize);

    if (initialBoard == null) {
      reset();
    } else {
      _validateBoard(initialBoard, gridSize);
      if (!isSolvable(initialBoard, gridSize)) {
        throw ArgumentError.value(
          initialBoard,
          'initialBoard',
          'El tablero inicial debe ser resoluble.',
        );
      }
      _board = List<int>.of(initialBoard);
    }
  }

  /// Dificultad: 3 (fácil), 4 (medio) o 5 (difícil).
  final int gridSize;
  final Random _random;
  late List<int> _board;
  int _moves = 0;

  /// Copia inmutable: la UI no puede modificar el estado del motor.
  List<int> get tiles => List<int>.unmodifiable(_board);

  int get moves => _moves;
  int get emptyIndex => _board.indexOf(0);
  bool get isSolved => isSolvedBoard(_board, gridSize);

  /// Crea el tablero meta: [1, 2, ..., n*n - 1, 0].
  static List<int> solvedBoard(int gridSize) {
    _validateSize(gridSize);
    return <int>[
      for (int value = 1; value < gridSize * gridSize; value++) value,
      0,
    ];
  }

  /// Número de pares de fichas invertidos; el 0 no cuenta.
  static int countInversions(List<int> board, int gridSize) {
    _validateBoard(board, gridSize);
    var inversions = 0;
    for (var i = 0; i < board.length; i++) {
      if (board[i] == 0) continue;
      for (var j = i + 1; j < board.length; j++) {
        if (board[j] != 0 && board[i] > board[j]) {
          inversions++;
        }
      }
    }
    return inversions;
  }

  /// Criterio de solvencia desde la configuración meta (0 al final).
  ///
  /// - Ancho impar: las inversiones son pares.
  /// - Ancho par: (inversiones + fila del 0 desde abajo) es impar.
  /// La fila del 0 se cuenta desde abajo empezando en 1.
  static bool isSolvable(List<int> board, int gridSize) {
    _validateBoard(board, gridSize);
    final inversions = countInversions(board, gridSize);
    if (gridSize.isOdd) return inversions.isEven;

    final emptyRowFromTop = board.indexOf(0) ~/ gridSize;
    final emptyRowFromBottom = gridSize - emptyRowFromTop;
    return (inversions + emptyRowFromBottom).isOdd;
  }

  /// Verifica orden estricto de las fichas y hueco en la última casilla.
  static bool isSolvedBoard(List<int> board, int gridSize) {
    _validateBoard(board, gridSize);
    for (var i = 0; i < board.length - 1; i++) {
      if (board[i] != i + 1) return false;
    }
    return board.last == 0;
  }

  /// Permite mover únicamente una ficha contigua al hueco.
  /// La distancia Manhattan evita diagonales y saltos entre filas.
  bool canMove(int index) {
    if (index < 0 || index >= _board.length || _board[index] == 0) {
      return false;
    }
    final empty = emptyIndex;
    final rowDistance = (index ~/ gridSize - empty ~/ gridSize).abs();
    final columnDistance = (index % gridSize - empty % gridSize).abs();
    return rowDistance + columnDistance == 1;
  }

  /// True solo si hubo movimiento. Un intento inválido no cambia el estado.
  bool move(int index) {
    if (!canMove(index)) return false;
    final empty = emptyIndex;
    _board[empty] = _board[index];
    _board[index] = 0;
    _moves++;
    return true;
  }

  /// Inicia una nueva partida sin movimientos y con tablero siempre resoluble.
  void reset() {
    final candidate = solvedBoard(gridSize);
    do {
      candidate.shuffle(_random);
    } while (isSolvedBoard(candidate, gridSize) ||
        !isSolvable(candidate, gridSize));

    _board = candidate;
    _moves = 0;
  }

  static void _validateSize(int gridSize) {
    if (gridSize != 3 && gridSize != 4 && gridSize != 5) {
      throw ArgumentError.value(
        gridSize,
        'gridSize',
        'Las únicas dificultades válidas son 3, 4 y 5.',
      );
    }
  }

  static void _validateBoard(List<int> board, int gridSize) {
    _validateSize(gridSize);
    final expectedLength = gridSize * gridSize;
    if (board.length != expectedLength ||
        board.toSet().length != expectedLength ||
        board.any((value) => value < 0 || value >= expectedLength)) {
      throw ArgumentError.value(
        board,
        'board',
        'Se requieren exactamente los valores 0..${expectedLength - 1}.',
      );
    }
  }
}
