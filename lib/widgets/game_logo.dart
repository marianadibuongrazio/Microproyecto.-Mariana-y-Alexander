import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Utiliza el SVG original adjunto, sin alterar sus trazos.
/// El color de los trazos negros se adapta al tema para mantener contraste.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key, this.width = 270});

  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Logo del juego 15-Puzzle',
      image: true,
      child: SvgPicture.asset(
        'assets/branding/game_logo.svg',
        width: width,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          dark ? AppColors.white : AppColors.navy,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
