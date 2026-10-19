import 'package:flutter/material.dart';

import 'configuracion.dart';
import 'game/puzzle_game_screen.dart';
import 'models/app_settings.dart';
import 'services/local_storage.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/game_logo.dart';
import 'marcadores.dart';
import 'splash.dart';

void main() {
  runApp(const MyApp());
}

// Conserva el almacenamiento y los callbacks de tema de Mariana.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _tema = ThemeMode.system;
  bool _mostrarSplash = true;

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
      // Mantiene tema del sistema si la persistencia no esta disponible.
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _mostrarSplash
          ? Splash(
              alTerminar: () {
                setState(() => _mostrarSplash = false);
              },
            )
          : TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              builder: (context, valor, child) {
                return Opacity(opacity: valor, child: child);
              },
              child: MenuPrincipal(alCambiarPreferencias: _aplicarPreferencias),
            ),
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

        // Si ya existe una dificultad preferida, inicia directamente.
    final dificultadGuardada = preferencias.gridSize;

    if (dificultadGuardada != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => PuzzleGameScreen(
            gridSize: dificultadGuardada,
            tileStyle: preferencias.tileStyle,
            animationsEnabled: preferencias.animationsEnabled,
            storage: storage,
          ),
        ),
      );
      return;
    }

    final dificultad = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(
          'Selecciona la dificultad',
          style: Theme.of(dialogContext).textTheme.titleLarge,
        ),
        children: [
          for (final opcion in [
            (3, 'Fácil', '8 piezas'),
            (4, 'Medio', '15 piezas'),
            (5, 'Difícil', '24 piezas'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, opcion.$1),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.grid_view),
                title: Text('${opcion.$2} · ${opcion.$1}×${opcion.$1}'),
                subtitle: Text(opcion.$3),
                trailing: preferencias.gridSize == opcion.$1
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(dialogContext).colorScheme.primary,
                      )
                    : null,
              ),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

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

  void mostrarAviso(BuildContext context, String nombre) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$nombre estará disponible próximamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('15-Puzzle'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: GameLogo(width: 270)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '8 · 15 · 24 PIEZAS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: AppColors.navy,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Rompecabezas Deslizante',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  'Ordena las piezas y desafía tu habilidad.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark ? AppColors.white : scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: () => seleccionarDificultad(context),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Jugar'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const Marcadores(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Marcadores'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => abrirConfiguracion(context),
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Configuración'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const Instrucciones(),
                    ),
                  ),
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Cómo jugar'),
                ),
                const SizedBox(height: 30),
                Text(
                  'Mariana Di Buongrazio y Alexander Ramirez\nMicroproyecto Sistemas de Información',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objetivo del juego',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ordena las piezas de menor a mayor, de izquierda '
                  'a derecha y de arriba hacia abajo. El espacio vacío '
                  'debe quedar en la esquina inferior derecha.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Cómo mover las piezas',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Toca una pieza que esté al lado del espacio vacío '
                  'para moverla. Puedes mover piezas hacia arriba, '
                  'abajo, izquierda o derecha, pero nunca en diagonal.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Text(
                  'Dificultades',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fácil: tablero de 3 × 3.\n'
                  'Medio: tablero de 4 × 4.\n'
                  'Difícil: tablero de 5 × 5.\n\n'
                  'Puedes cambiar la dificultad desde Configuración. '
                  'Al pulsar Jugar se utiliza tu última selección guardada.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
