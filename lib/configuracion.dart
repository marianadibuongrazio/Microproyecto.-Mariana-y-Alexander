import 'package:flutter/material.dart';

import 'models/app_settings.dart';
import 'services/local_storage.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<ThemeMode>(
                  initialValue: _preferencias.themeMode,
                  decoration: const InputDecoration(
                    labelText: 'Tema de la aplicación',
                    border: OutlineInputBorder(),
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
                          setState(() {
                            _preferencias = _preferencias.copyWith(
                              themeMode: valor,
                            );
                          });
                        },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  initialValue: _preferencias.gridSize,
                  decoration: const InputDecoration(
                    labelText: 'Dificultad preferida',
                    border: OutlineInputBorder(),
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
                          setState(() {
                            _preferencias = _preferencias.copyWith(
                              gridSize: valor,
                            );
                          });
                        },
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<TileStyle>(
                  initialValue: _preferencias.tileStyle,
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
                  onChanged: _guardando
                      ? null
                      : (valor) {
                          if (valor == null) return;
                          setState(() {
                            _preferencias = _preferencias.copyWith(
                              tileStyle: valor,
                            );
                          });
                        },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Animaciones de las piezas'),
                  value: _preferencias.animationsEnabled,
                  onChanged: _guardando
                      ? null
                      : (valor) {
                          setState(() {
                            _preferencias = _preferencias.copyWith(
                              animationsEnabled: valor,
                            );
                          });
                        },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.save),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Los ajustes se aplican al guardar. '
                  'El tema automático sigue la configuración del dispositivo.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
