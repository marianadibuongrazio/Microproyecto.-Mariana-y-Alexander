import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_deslizante/game/puzzle_engine.dart';

void main() {
  group('Tablero y validación', () {
    test('solo permite 3x3, 4x4 y 5x5', () {
      for (final size in [3, 4, 5]) {
        expect(PuzzleEngine(gridSize: size).tiles.length, size * size);
      }
      expect(() => PuzzleEngine(gridSize: 2), throwsArgumentError);
      expect(() => PuzzleEngine(gridSize: 6), throwsArgumentError);
    });

    test('genera la meta con el hueco al final', () {
      for (final size in [3, 4, 5]) {
        final goal = PuzzleEngine.solvedBoard(size);
        expect(goal.length, size * size);
        expect(goal.last, 0);
        expect(
          goal.take(goal.length - 1).toList(),
          List<int>.generate(size * size - 1, (i) => i + 1),
        );
        expect(PuzzleEngine.isSolvedBoard(goal, size), isTrue);
        expect(PuzzleEngine.isSolvable(goal, size), isTrue);
      }
    });

    test('rechaza tableros con huecos duplicados o números fuera de rango', () {
      expect(
        () => PuzzleEngine.isSolvable([1, 2, 3, 4, 5, 6, 7, 0, 0], 3),
        throwsArgumentError,
      );
      expect(
        () => PuzzleEngine.isSolvable([1, 2, 3, 4, 5, 6, 7, 8, 9], 3),
        throwsArgumentError,
      );
      expect(() => PuzzleEngine.isSolvable([1, 2, 3], 3), throwsArgumentError);
    });
  });

  group('Solvencia matemática', () {
    test('3x3: inversiones pares e impares', () {
      final solvable = [1, 2, 3, 4, 5, 6, 7, 0, 8];
      final impossible = [2, 1, 3, 4, 5, 6, 7, 8, 0];
      expect(PuzzleEngine.countInversions(solvable, 3), 0);
      expect(PuzzleEngine.isSolvable(solvable, 3), isTrue);
      expect(PuzzleEngine.countInversions(impossible, 3), 1);
      expect(PuzzleEngine.isSolvable(impossible, 3), isFalse);
    });

    test('4x4: combina inversiones y fila del hueco desde abajo', () {
      final goal = PuzzleEngine.solvedBoard(4);
      final legalOneMove = [...goal];
      legalOneMove[14] = 0;
      legalOneMove[15] = 15;
      final impossible = [...goal];
      impossible[0] = 2;
      impossible[1] = 1;

      // Movimiento vertical desde la meta: el hueco pasa a la fila 2
      // contando desde abajo; aparecen 3 inversiones (3 + 2 es impar).
      final verticalMove = [...goal];
      verticalMove[11] = 0;
      verticalMove[15] = 12;

      expect(PuzzleEngine.isSolvable(goal, 4), isTrue);
      expect(PuzzleEngine.isSolvable(legalOneMove, 4), isTrue);
      expect(PuzzleEngine.countInversions(verticalMove, 4), 3);
      expect(PuzzleEngine.isSolvable(verticalMove, 4), isTrue);
      expect(PuzzleEngine.isSolvable(impossible, 4), isFalse);
    });

    test('5x5: paridad de inversiones, sin regla de fila', () {
      final goal = PuzzleEngine.solvedBoard(5);
      final impossible = [...goal];
      impossible[0] = 2;
      impossible[1] = 1;
      expect(PuzzleEngine.isSolvable(goal, 5), isTrue);
      expect(PuzzleEngine.isSolvable(impossible, 5), isFalse);
    });

    test('mezclas aleatorias siempre válidas, resolubles y no ganadas', () {
      for (final size in [3, 4, 5]) {
        final engine = PuzzleEngine(gridSize: size, random: Random(2026));
        for (var attempt = 0; attempt < 50; attempt++) {
          final tiles = engine.tiles;
          expect(
            tiles.toSet(),
            Set<int>.from(List<int>.generate(size * size, (i) => i)),
          );
          expect(PuzzleEngine.isSolvable(tiles, size), isTrue);
          expect(engine.isSolved, isFalse);
          expect(engine.moves, 0);
          engine.reset();
        }
      }
    });

    test('el tablero inyectado debe ser válido y resoluble', () {
      final impossible = [2, 1, 3, 4, 5, 6, 7, 8, 0];
      expect(
        () => PuzzleEngine(gridSize: 3, initialBoard: impossible),
        throwsArgumentError,
      );
    });
  });

  group('Movimientos y victoria', () {
    test('mueve una pieza vecina y detecta victoria', () {
      final engine = PuzzleEngine(
        gridSize: 3,
        initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8],
      );
      expect(engine.isSolved, isFalse);
      expect(engine.emptyIndex, 7);
      expect(engine.canMove(8), isTrue);
      expect(engine.move(8), isTrue);
      expect(engine.moves, 1);
      expect(engine.isSolved, isTrue);
      expect(engine.tiles, PuzzleEngine.solvedBoard(3));
    });

    test('taps inválidos no cambian tablero ni movimientos', () {
      final engine = PuzzleEngine(
        gridSize: 3,
        initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8],
      );
      final snapshot = engine.tiles;
      for (final index in [-1, 7, 0, 3, 9]) {
        expect(engine.canMove(index), isFalse);
        expect(engine.move(index), isFalse);
      }
      expect(engine.tiles, snapshot);
      expect(engine.moves, 0);
    });

    test('no permite saltar del final de una fila a la próxima', () {
      // Hueco en índice 3 (fila 1, columna 0); índice 2 está arriba a la
      // derecha: diferencia lineal 1, distancia Manhattan 3.
      final engine = PuzzleEngine(
        gridSize: 3,
        initialBoard: PuzzleEngine.solvedBoard(3),
      );
      for (final index in [5, 2, 1, 0, 3]) {
        expect(engine.move(index), isTrue);
      }
      final snapshot = engine.tiles;
      final moves = engine.moves;
      expect(engine.emptyIndex, 3);
      expect(engine.move(2), isFalse);
      expect(engine.tiles, snapshot);
      expect(engine.moves, moves);
    });

    test('el tablero público no se puede mutar desde la UI', () {
      final engine = PuzzleEngine(gridSize: 3, random: Random(42));
      expect(() => engine.tiles[0] = 99, throwsUnsupportedError);
    });

    test('reset genera otra partida válida y reinicia movimientos', () {
      final engine = PuzzleEngine(
        gridSize: 3,
        initialBoard: [1, 2, 3, 4, 5, 6, 7, 0, 8],
        random: Random(2026),
      );
      expect(engine.move(8), isTrue);
      expect(engine.moves, 1);
      engine.reset();
      expect(engine.moves, 0);
      expect(engine.isSolved, isFalse);
      expect(PuzzleEngine.isSolvable(engine.tiles, 3), isTrue);
    });
  });
}
