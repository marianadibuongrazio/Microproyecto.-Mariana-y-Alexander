import 'package:flutter/material.dart';

import 'configuracion.dart';
import 'game/puzzle_game_screen.dart';
import 'models/app_settings.dart';
import 'services/local_storage.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/game_logo.dart';

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
      home: MenuPrincipal(alCambiarPreferencias: _aplicarPreferencias),
    );
  }
}

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key, required this.alCambiarPreferencias});

  final ValueChanged<AppSettings> alCambiarPreferencias;

  Future<int?> _mostrarSelectorDificultad(
    BuildContext context, {
    required int? dificultadActual,
  }) {
    const opciones = [
      (3, 'Fácil', '8 piezas'),
      (4, 'Medio', '15 piezas'),
      (5, 'Difícil', '24 piezas'),
    ];

    return showDialog<int>(
      context: context,
      barrierColor: AppColors.navy.withValues(alpha: 0.72),
      builder: (dialogContext) => Dialog(
        key: const Key('difficulty-dialog'),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: AppColors.cobalt, width: 2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Selecciona la dificultad',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'CalSans',
                    fontSize: 28,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Elige el tamaño del tablero para tu partida.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 14,
                    color: AppColors.navy.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 22),
                for (final opcion in opciones) ...[
                  _opcionDificultad(
                    valor: opcion.$1,
                    titulo: '${opcion.$2} · ${opcion.$1}×${opcion.$1}',
                    subtitulo: opcion.$3,
                    seleccionada: dificultadActual == opcion.$1,
                    onTap: () => Navigator.pop(dialogContext, opcion.$1),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    backgroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.navy, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _opcionDificultad({
    required int valor,
    required String titulo,
    required String subtitulo,
    required bool seleccionada,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: 'Dificultad $titulo, $subtitulo',
      selected: seleccionada,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          key: Key('difficulty-option-$valor'),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: seleccionada
                ? AppColors.yellow.withValues(alpha: 0.18)
                : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionada
                  ? AppColors.cobalt
                  : AppColors.navy.withValues(alpha: 0.18),
              width: seleccionada ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.cobalt,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontFamily: 'CalSans',
                        fontSize: 18,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 14,
                        color: AppColors.navy.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (seleccionada)
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.yellow,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.navy,
                    size: 22,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> seleccionarDificultad(BuildContext context) async {
    final storage = LocalStorage();
    final preferencias = await storage.loadSettings();
    if (!context.mounted) return;

    final dificultad = await _mostrarSelectorDificultad(
      context,
      dificultadActual: preferencias.gridSize,
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
                  onPressed: () => mostrarAviso(context, 'Marcadores'),
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
                  'Dificultades previstas',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fácil: tablero de 3 × 3.\n'
                  'Medio: tablero de 4 × 4.\n'
                  'Difícil: tablero de 5 × 5.',
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
