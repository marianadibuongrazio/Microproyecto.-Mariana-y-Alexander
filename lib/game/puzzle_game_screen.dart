import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/high_score.dart';
import '../services/local_storage.dart';
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
      builder: (dialogContext) => AlertDialog(
        key: const Key('victory-dialog'),
        icon: const Icon(Icons.emoji_events_outlined, size: 42),
        title: const Text('¡Rompecabezas resuelto!'),
        content: Text(
          'Dificultad: $difficulty ($gridSize×$gridSize)\n'
          'Tiempo: $elapsed\n'
          'Movimientos: $moves$recordMessage$errorMessage',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Menú Principal'),
          ),
          FilledButton(
            key: const Key('victory-reset-button'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _reset();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  Color _tileBackground(int value, ColorScheme scheme) {
    return switch (widget.tileStyle) {
      TileStyle.classic => scheme.primaryContainer,
      TileStyle.colorful =>
        Colors.primaries[(value - 1) % Colors.primaries.length].shade200,
      TileStyle.retro => const Color(0xFFE5BB82),
      TileStyle.minimalist => scheme.surfaceContainerHighest,
    };
  }

  Color _tileForeground(ColorScheme scheme) {
    return switch (widget.tileStyle) {
      TileStyle.classic => scheme.onPrimaryContainer,
      TileStyle.colorful => const Color(0xFF17212B),
      TileStyle.retro => const Color(0xFF492D1E),
      TileStyle.minimalist => scheme.onSurface,
    };
  }

  Widget _tile(int index, int value, double side) {
    final scheme = Theme.of(context).colorScheme;
    final isEmpty = value == 0;
    final duration = widget.animationsEnabled
        ? const Duration(milliseconds: 180)
        : Duration.zero;
    final radius = switch (widget.tileStyle) {
      TileStyle.retro => 6.0,
      TileStyle.minimalist => 4.0,
      _ => 14.0,
    };

    return Semantics(
      label: isEmpty ? 'Espacio vacío' : 'Pieza $value',
      button: !isEmpty,
      child: InkWell(
        key: Key('tile-$value'),
        borderRadius: BorderRadius.circular(radius),
        onTap: isEmpty ? null : () => _move(index),
        child: AnimatedSwitcher(
          duration: duration,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: isEmpty
              ? Container(
                  key: const ValueKey<int>(0),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                  ),
                )
              : Container(
                  key: ValueKey<int>(value),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _tileBackground(value, scheme),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '$value',
                    style: TextStyle(
                      fontSize: math.max(
                        13.0,
                        math.min(side / widget.gridSize * 0.34, 32.0),
                      ),
                      fontWeight: widget.tileStyle == TileStyle.minimalist
                          ? FontWeight.w500
                          : FontWeight.w800,
                      color: _tileForeground(scheme),
                    ),
                  ),
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
        color: scheme.surfaceContainerLow,
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
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
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
    final tiles = _engine.tiles;
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
          final gap = widget.gridSize == 5 ? 5.0 : 8.0;
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                      SizedBox.square(
                        dimension: boardSide,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: GridView.builder(
                              key: const Key('puzzle-board'),
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tiles.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: widget.gridSize,
                                    crossAxisSpacing: gap,
                                    mainAxisSpacing: gap,
                                  ),
                              itemBuilder: (context, index) =>
                                  _tile(index, tiles[index], boardSide - 16),
                            ),
                          ),
                        ),
                      ),
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
                          FilledButton.tonalIcon(
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
