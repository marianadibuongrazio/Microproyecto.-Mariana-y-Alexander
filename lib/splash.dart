import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/game_logo.dart';

class Splash extends StatefulWidget {
  const Splash({super.key, required this.alTerminar});

  final VoidCallback alTerminar;

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _animacion;
  Timer? _temporizador;
  bool _terminado = false;

  @override
  void initState() {
    super.initState();

    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animacion = CurvedAnimation(
      parent: _controlador,
      curve: Curves.easeOutCubic,
    );

    _controlador.forward();

    _temporizador = Timer(const Duration(milliseconds: 2400), _terminar);
  }

  void _terminar() {
    if (!mounted || _terminado) return;

    _terminado = true;
    _temporizador?.cancel();
    widget.alTerminar();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _animacion,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.85,
                      end: 1,
                    ).animate(_animacion),
                    child: const GameLogo(width: 270),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '15-Puzzle Flutter',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cada movimiento cuenta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextButton(onPressed: _terminar, child: const Text('Saltar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
