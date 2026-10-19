import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/high_score.dart';
import '../services/local_storage.dart';
import '../theme/app_colors.dart';
import 'puzzle_engine.dart';

/// Pantalla del juego: solo usa el motor A1 y los contratos de M1.
/// A3 guarda victorias mediante LocalStorage, una vez por partida.
class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({
    super.key,
    required this.gridSize,
    required this.tileStyle,
    required this.animationsEnabled,
    required this.storage,
    this.initialEngine,
  }) : assert(gridSize == 3 || gridSize == 4 || gridSize == 5);

  final int gridSize;
  final TileStyle tileStyle;
  final bool animationsEnabled;
  final LocalStorage storage;

  /// Solo para pruebas deterministas; en partidas reales se genera el tablero.
  final PuzzleEngine? initialEngine;

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  late PuzzleEngine _engine;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _refreshTimer;
  bool _finished = false;
  int _gameSession = 0;

  @override
  void initState() {
    super.initState();
    _engine = widget.initialEngine ?? PuzzleEngine(gridSize: widget.gridSize);
  }

  @override
  void didUpdateWidget(covariant PuzzleGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gridSize != widget.gridSize ||
        oldWidget.initialEngine != widget.initialEngine) {
      _gameSession++;
      _stopClock();
      _stopwatch.reset();
      _engine = widget.initialEngine ?? PuzzleEngine(gridSize: widget.gridSize);
      _finished = false;
    }
  }

  @override
  void dispose() {
    _stopClock();
    super.dispose();
  }

  String get _difficulty => switch (widget.gridSize) {
    3 => 'Fácil',
    4 => 'Medio',
    _ => 'Difícil',
  };

  String get _elapsed {
    final totalSeconds = _stopwatch.elapsed.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startClock() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _stopClock() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _stopwatch.stop();
  }

  void _move(int index) {
    if (_finished || !_engine.canMove(index)) return;

    setState(() {
      _engine.move(index);
      if (_engine.moves == 1) _startClock();
      if (_engine.isSolved) {
        _finished = true;
        _stopClock();
      }
    });

    if (_finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showVictory();
      });
    }
  }

  void _reset() {
    _gameSession++;
    _stopClock();
    _stopwatch.reset();
    setState(() {
      _engine.reset();
      _finished = false;
    });
  }

  Future<void> _showVictory() async {
    // Capturamos métricas del tablero ya resuelto antes de cualquier await.
    // _finished impide volver a invocar este método por nuevos movimientos.
    final session = _gameSession;
    final gridSize = widget.gridSize;
    final difficulty = _difficulty;
    final elapsed = _elapsed;
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final moves = _engine.moves;

    ScoreUpdate? update;
    var saveFailed = false;
    try {
      update = await widget.storage.registerWin(
        gridSize: gridSize,
        elapsedMs: elapsedMs,
        moves: moves,
      );
    } catch (_) {
      saveFailed = true;
    }

    // Si se reinició/cambió la partida o se cerró la pantalla mientras
    // guardábamos, no mostramos un resumen de una partida anterior.
    if (!mounted || !_finished || session != _gameSession) return;

    final recordMessage = switch ((
      update?.newBestTime,
      update?.newFewestMoves,
    )) {
      (true, true) => '\n¡Nuevo récord de tiempo y movimientos!',
      (true, _) => '\n¡Nuevo récord de tiempo!',
      (_, true) => '\n¡Nuevo récord de movimientos!',
      _ => '',
    };
    final errorMessage = saveFailed
        ? '\nNo se pudo guardar el resultado en este dispositivo.'
        : '';

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.navy.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        key: const Key('victory-dialog'),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.cobalt, width: 2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 54,
                  color: AppColors.cobalt,
                ),
                const SizedBox(height: 12),
                const Text(
                  '¡Rompecabezas resuelto!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 26,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cobalt.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.cobalt.withValues(alpha: 0.35),
                    ),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16,
                      color: AppColors.navy,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dificultad: $difficulty ($gridSize×$gridSize)'),
                        const SizedBox(height: 6),
                        Text('Tiempo: $elapsed'),
                        const SizedBox(height: 6),
                        Text('Movimientos: $moves'),
                      ],
                    ),
                  ),
                ),
                if (recordMessage.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      recordMessage.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
                if (errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage.trim(),
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: AppColors.navy,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.navy),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).maybePop();
                      },
                      child: const Text('Menú Principal'),
                    ),
                    FilledButton(
                      key: const Key('victory-reset-button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: AppColors.navy,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _reset();
                      },
                      child: const Text('Reiniciar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Mantiene los cuatro estilos de Mariana dentro de la nueva paleta.
  Color _tileBackground(int value) {
    return switch (widget.tileStyle) {
      TileStyle.classic => AppColors.cobalt,
      TileStyle.colorful => switch ((value - 1) % 4) {
        0 => AppColors.cobalt,
        1 => AppColors.yellow,
        2 => AppColors.navy,
        _ => AppColors.white,
      },
      TileStyle.retro => AppColors.navy,
      TileStyle.minimalist => AppColors.white,
    };
  }

  Color _tileForeground(int value) {
    if (widget.tileStyle == TileStyle.minimalist) return AppColors.navy;
    if (widget.tileStyle == TileStyle.retro) return AppColors.yellow;
    if (widget.tileStyle == TileStyle.colorful &&
        (value - 1) % 4 != 0 &&
        (value - 1) % 4 != 2) {
      return AppColors.navy;
    }
    return AppColors.white;
  }

  /// Las fichas viven en un Stack por ID (valor), nunca por indice de celda.
  /// AnimatedPositioned cambia realmente de X/Y cuando el motor mueve una ficha.
  Widget _animatedTile(int value, double cell, double gap) {
    final index = _engine.tiles.indexOf(value);
    final row = index ~/ widget.gridSize;
    final column = index % widget.gridSize;
    final radius = widget.tileStyle == TileStyle.minimalist ? 8.0 : 14.0;
    return AnimatedPositioned(
      key: ValueKey<String>('positioned-$value'),
      duration: widget.animationsEnabled
          ? const Duration(milliseconds: 240)
          : Duration.zero,
      curve: Curves.easeInOutCubic,
      left: column * (cell + gap),
      top: row * (cell + gap),
      width: cell,
      height: cell,
      child: Semantics(
        label: 'Pieza $value',
        button: true,
        child: Material(
          color: _tileBackground(value),
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('tile-$value'),
            onTap: () => _move(_engine.tiles.indexOf(value)),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: widget.tileStyle == TileStyle.minimalist
                      ? AppColors.cobalt
                      : AppColors.navy.withValues(alpha: 0.16),
                  width: widget.tileStyle == TileStyle.minimalist ? 2 : 1,
                ),
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  fontFamily: 'CalSans',
                  fontSize: math.max(13.0, math.min(cell * 0.36, 42.0)),
                  color: _tileForeground(value),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _board(double side) {
    final tiles = _engine.tiles;
    final grid = widget.gridSize;
    final gap = grid == 5 ? 5.0 : 8.0;
    const padding = 8.0;
    final inner = side - padding * 2;
    final cell = (inner - gap * (grid - 1)) / grid;
    final empty = _engine.emptyIndex;
    final emptyRow = empty ~/ grid;
    final emptyColumn = empty % grid;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox.square(
      dimension: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark
              ? AppColors.cobalt.withValues(alpha: 0.18)
              : AppColors.cobalt.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.cobalt, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(padding),
          child: Stack(
            key: const Key('puzzle-board'),
            children: [
              // La casilla vacia marca el destino, sin interceptar taps.
              Positioned(
                left: emptyColumn * (cell + gap),
                top: emptyRow * (cell + gap),
                width: cell,
                height: cell,
                child: Semantics(
                  label: 'Espacio vacío',
                  child: Container(
                    key: const Key('tile-0'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.cobalt.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              for (final value in tiles)
                if (value != 0) _animatedTile(value, cell, gap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Key key) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.cobalt.withValues(alpha: 0.18)
            : AppColors.cobalt.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: scheme.primary),
          const SizedBox(width: 9),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                key: key,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('$_difficulty · ${widget.gridSize}×${widget.gridSize}'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _reset,
            tooltip: 'Reiniciar partida',
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = math.max(0.0, constraints.maxWidth - 32);
          final boardSide = math.min(470.0, availableWidth);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Ordena las piezas',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Toca una pieza que esté junto al espacio vacío.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _stat(
                            Icons.timer_outlined,
                            'Tiempo',
                            _elapsed,
                            const Key('elapsed-time'),
                          ),
                          _stat(
                            Icons.touch_app_outlined,
                            'Movimientos',
                            '${_engine.moves}',
                            const Key('move-count'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _board(boardSide),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('menu-button'),
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Menú Principal'),
                          ),
                          FilledButton.icon(
                            key: const Key('reset-button'),
                            onPressed: _reset,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reiniciar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El cronómetro comienza con el primer movimiento válido.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
