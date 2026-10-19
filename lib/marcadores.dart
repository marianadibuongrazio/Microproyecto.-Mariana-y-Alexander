import 'package:flutter/material.dart';

import 'models/high_score.dart';
import 'services/local_storage.dart';

class Marcadores extends StatefulWidget {
  const Marcadores({super.key});

  @override
  State<Marcadores> createState() => _MarcadoresState();
}

class _MarcadoresState extends State<Marcadores> {
  final LocalStorage _storage = LocalStorage();
  late Future<Map<int, DifficultyScores>> _resultados;
  bool _borrando = false;

  @override
  void initState() {
    super.initState();
    _resultados = _storage.loadHighScores();
  }

  void _recargar() {
    setState(() {
      _resultados = _storage.loadHighScores();
    });
  }

  String _fecha(DateTime fecha) {
    final local = fecha.toLocal();
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${local.year} · $hora:$minuto';
  }

  Widget _registro(String titulo, ScoreEntry? partida) {
    if (partida == null) {
      return ListTile(
        title: Text(titulo),
        subtitle: const Text('Todavía no hay un récord registrado.'),
      );
    }

    final segundos = (partida.elapsedMs / 1000).toStringAsFixed(2);

    return ListTile(
      title: Text(titulo),
      subtitle: Text(
        'Tiempo: $segundos s\n'
        'Movimientos: ${partida.moves}\n'
        'Fecha: ${_fecha(partida.completedAt)}',
      ),
      isThreeLine: true,
    );
  }

  Widget _tarjeta(String nombre, int tamano, DifficultyScores? resultados) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$nombre · $tamano×$tamano',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _registro('Mejor tiempo', resultados?.fastest),
            const Divider(),
            _registro('Menos movimientos', resultados?.fewestMoves),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarBorrado() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Borrar todos los marcadores?'),
        content: const Text(
          'Se eliminarán los récords de las tres dificultades. '
          'Tus preferencias de configuración se conservarán. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _borrando = true);

    try {
      await _storage.clearHighScores();

      if (!mounted) return;

      setState(() {
        _borrando = false;
        _resultados = _storage.loadHighScores();
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Marcadores eliminados.')));
    } catch (_) {
      if (!mounted) return;

      setState(() => _borrando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron borrar los marcadores.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marcadores')),
      body: FutureBuilder<Map<int, DifficultyScores>>(
        future: _resultados,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar los marcadores.'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _recargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final resultados = snapshot.data ?? <int, DifficultyScores>{};
          final hayRecords = resultados.values.any(
            (registro) =>
                registro.fastest != null || registro.fewestMoves != null,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hayRecords) ...[
                      const Icon(Icons.emoji_events_outlined, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        '¡Tu primer récord te espera!\n'
                        'Completa una partida para registrar tu resultado.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _tarjeta('Fácil', 3, resultados[3]),
                    _tarjeta('Medio', 4, resultados[4]),
                    _tarjeta('Difícil', 5, resultados[5]),
                    const Text(
                      'El mejor tiempo y los menores movimientos pueden '
                      'corresponder a partidas diferentes.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: hayRecords && !_borrando
                          ? _confirmarBorrado
                          : null,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        _borrando
                            ? 'Borrando...'
                            : 'Borrar todos los marcadores',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Volver al menú'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
