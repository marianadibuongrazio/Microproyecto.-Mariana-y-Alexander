import 'package:flutter/material.dart';
import 'package:puzzle_deslizante/game/puzzle_game_screen.dart';
import 'package:puzzle_deslizante/models/app_settings.dart';
import 'package:puzzle_deslizante/services/local_storage.dart';

/// Entrada de prueba de A2; no cambia lib/main.dart ni la navegación de Mariana.
void main() => runApp(const GamePreviewApp());

class GamePreviewApp extends StatefulWidget {
  const GamePreviewApp({super.key});

  @override
  State<GamePreviewApp> createState() => _GamePreviewAppState();
}

class _GamePreviewAppState extends State<GamePreviewApp> {
  TileStyle _tileStyle = TileStyle.classic;
  bool _animations = true;
  final LocalStorage _storage = LocalStorage();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '15-Puzzle · Vista A2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (homeContext) => Scaffold(
          appBar: AppBar(title: const Text('Vista de prueba · A2')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Elige una dificultad para probar el tablero.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TileStyle>(
                    initialValue: _tileStyle,
                    decoration: const InputDecoration(
                      labelText: 'Estilo de las piezas',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TileStyle.classic,
                        child: Text('Clásico'),
                      ),
                      DropdownMenuItem(
                        value: TileStyle.colorful,
                        child: Text('Colorido'),
                      ),
                      DropdownMenuItem(
                        value: TileStyle.retro,
                        child: Text('Retro'),
                      ),
                      DropdownMenuItem(
                        value: TileStyle.minimalist,
                        child: Text('Minimalista'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _tileStyle = value);
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Animaciones'),
                    value: _animations,
                    onChanged: (value) => setState(() => _animations = value),
                  ),
                  for (final size in [3, 4, 5]) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(homeContext).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PuzzleGameScreen(
                            gridSize: size,
                            tileStyle: _tileStyle,
                            animationsEnabled: _animations,
                            storage: _storage,
                          ),
                        ),
                      ),
                      child: Text(switch (size) {
                        3 => 'Fácil · 3×3',
                        4 => 'Medio · 4×4',
                        _ => 'Difícil · 5×5',
                      }),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
