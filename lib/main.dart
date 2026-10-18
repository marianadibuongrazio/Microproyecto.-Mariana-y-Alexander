import 'package:flutter/material.dart';

import 'game/puzzle_game_screen.dart';
import 'models/app_settings.dart';
import 'services/local_storage.dart';

void main() {
  runApp(const MyApp());
}

// Configuración general de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rompecabezas Deslizante',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MenuPrincipal(),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  // Aviso temporal para las funciones que todavía faltan.
  void mostrarAviso(BuildContext context, String nombre) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nombre estará disponible próximamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('15-Puzzle'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.extension,
                  size: 90,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Rompecabezas Deslizante',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ordena las piezas y desafía tu habilidad.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => PuzzleGameScreen(
                          gridSize: 3,
                          tileStyle: TileStyle.classic,
                          animationsEnabled: true,
                          storage: LocalStorage(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Jugar'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => mostrarAviso(context, 'Marcadores'),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Marcadores'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => mostrarAviso(context, 'Configuración'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Configuración'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const Instrucciones(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Cómo jugar'),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Mariana Di Buongrazio y Alexander Ramirez \nMicroproyecto Sistemas de Información',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Instrucciones extends StatelessWidget {
  const Instrucciones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cómo jugar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objetivo del juego',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Ordena las piezas de menor a mayor, de izquierda '
                  'a derecha y de arriba hacia abajo. El espacio vacío '
                  'debe quedar en la esquina inferior derecha.',
                  style: TextStyle(fontSize: 17),
                ),
                SizedBox(height: 24),
                Text(
                  'Cómo mover las piezas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Toca una pieza que esté al lado del espacio vacío '
                  'para moverla. Puedes mover piezas hacia arriba, '
                  'abajo, izquierda o derecha, pero nunca en diagonal.',
                  style: TextStyle(fontSize: 17),
                ),
                SizedBox(height: 24),
                Text(
                  'Dificultades previstas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Fácil: tablero de 3 × 3.\n'
                  'Medio: tablero de 4 × 4.\n'
                  'Difícil: tablero de 5 × 5.',
                  style: TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
