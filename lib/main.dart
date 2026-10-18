import 'package:flutter/material.dart';

import 'configuracion.dart';
import 'models/app_settings.dart';
import 'game/puzzle_game_screen.dart';
import 'services/local_storage.dart';

void main() {
  runApp(const MyApp());
}

// Configuración general de la aplicación.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _tema = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _cargarTema();
  }

  Future<void> _cargarTema() async {
    try {
      final preferencias = await LocalStorage().loadSettings();

      if (!mounted) return;

      setState(() => _tema = preferencias.themeMode);
    } catch (_) {
      // Si no se puede leer el almacenamiento, se conserva el tema del sistema.
    }
  }

  void _aplicarPreferencias(AppSettings preferencias) {
    setState(() => _tema = preferencias.themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rompecabezas Deslizante',
      debugShowCheckedModeBanner: false,
      themeMode: _tema,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: MenuPrincipal(alCambiarPreferencias: _aplicarPreferencias),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key, required this.alCambiarPreferencias});

  final ValueChanged<AppSettings> alCambiarPreferencias;

  Future<void> seleccionarDificultad(BuildContext context) async {
    final storage = LocalStorage();
    final preferencias = await storage.loadSettings();

    if (!context.mounted) return;

    final dificultad = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Selecciona la dificultad'),
          children: [
            for (final opcion in [
              (3, 'Fácil', '8 piezas'),
              (4, 'Medio', '15 piezas'),
              (5, 'Difícil', '24 piezas'),
            ])
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(dialogContext, opcion.$1);
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.grid_view),
                  title: Text('${opcion.$2} · ${opcion.$1}×${opcion.$1}'),
                  subtitle: Text(opcion.$3),
                  trailing: preferencias.gridSize == opcion.$1
                      ? const Icon(Icons.check, color: Colors.teal)
                      : null,
                ),
              ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    // Al cancelar, no se inicia una partida ni se cambia la preferencia.
    if (dificultad == null || !context.mounted) return;

    final nuevasPreferencias = preferencias.copyWith(gridSize: dificultad);

    try {
      await storage.saveSettings(nuevasPreferencias);
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la dificultad elegida.'),
        ),
      );
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PuzzleGameScreen(
          gridSize: dificultad,
          tileStyle: nuevasPreferencias.tileStyle,
          animationsEnabled: nuevasPreferencias.animationsEnabled,
          storage: storage,
        ),
      ),
    );
  }

  Future<void> abrirConfiguracion(BuildContext context) async {
    final preferencias = await LocalStorage().loadSettings();

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Configuracion(
          preferencias: preferencias,
          alGuardar: alCambiarPreferencias,
        ),
      ),
    );
  }

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
                  onPressed: () => seleccionarDificultad(context),
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
                  onPressed: () => abrirConfiguracion(context),
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
