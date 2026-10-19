import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'services/local_storage.dart';
import 'theme/app_colors.dart';

/// Configuración creada por Mariana; A7 solo adapta la presentación visual.
class Configuracion extends StatefulWidget {
  const Configuracion({
    super.key,
    required this.preferencias,
    required this.alGuardar,
  });

  final AppSettings preferencias;
  final ValueChanged<AppSettings> alGuardar;

  @override
  State<Configuracion> createState() => _ConfiguracionState();
}

class _ConfiguracionState extends State<Configuracion> {
  late AppSettings _preferencias;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _preferencias = widget.preferencias;
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await LocalStorage().saveSettings(_preferencias);
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron guardar los ajustes. Intenta otra vez.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    widget.alGuardar(_preferencias);
    Navigator.pop(context);
  }

  Widget _section(String heading, Widget child) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.cobalt.withValues(alpha: 0.18)
            : AppColors.cobalt.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: dark
              ? AppColors.cobalt
              : AppColors.cobalt.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(heading, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hazlo a tu manera',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaliza cada partida.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                _section(
                  'Tema',
                  DropdownButtonFormField<ThemeMode>(
                    dropdownColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.navy
                        : AppColors.white,
                    initialValue: _preferencias.themeMode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tema de la aplicación',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Claro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Oscuro'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('Automático'),
                      ),
                    ],
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            if (valor == null) return;
                            setState(
                              () => _preferencias = _preferencias.copyWith(
                                themeMode: valor,
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  'Dificultad',
                  DropdownButtonFormField<int>(
                    dropdownColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.navy
                        : AppColors.white,
                    initialValue: _preferencias.gridSize,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dificultad preferida',
                    ),
                    items: const [
                      DropdownMenuItem(value: 3, child: Text('Fácil · 3×3')),
                      DropdownMenuItem(value: 4, child: Text('Medio · 4×4')),
                      DropdownMenuItem(value: 5, child: Text('Difícil · 5×5')),
                    ],
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            if (valor == null) return;
                            setState(
                              () => _preferencias = _preferencias.copyWith(
                                gridSize: valor,
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  'Estilo de las piezas',
                  DropdownButtonFormField<TileStyle>(
                    dropdownColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.navy
                        : AppColors.white,
                    initialValue: _preferencias.tileStyle,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Diseño del tablero',
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
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            if (valor == null) return;
                            setState(
                              () => _preferencias = _preferencias.copyWith(
                                tileStyle: valor,
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(height: 16),
                _section(
                  'Movimiento',
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Animaciones de las piezas'),
                    subtitle: const Text(
                      'Las fichas se deslizan hasta el espacio vacío.',
                    ),
                    value: _preferencias.animationsEnabled,
                    onChanged: _guardando
                        ? null
                        : (valor) {
                            setState(
                              () => _preferencias = _preferencias.copyWith(
                                animationsEnabled: valor,
                              ),
                            );
                          },
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Los ajustes se aplican al guardar. El tema automático sigue la configuración del dispositivo.',
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
