import 'package:flutter/material.dart';

enum TileStyle { classic, colorful, retro, minimalist }

/// Preferencias simples de la aplicación.
/// `gridSize == null` significa que aún no se eligió dificultad.
class AppSettings {
  const AppSettings({
    this.gridSize,
    this.themeMode = ThemeMode.system,
    this.tileStyle = TileStyle.classic,
    this.animationsEnabled = true,
  }) : assert(
         gridSize == null || gridSize == 3 || gridSize == 4 || gridSize == 5,
       );

  final int? gridSize;
  final ThemeMode themeMode;
  final TileStyle tileStyle;
  final bool animationsEnabled;

  AppSettings copyWith({
    int? gridSize,
    ThemeMode? themeMode,
    TileStyle? tileStyle,
    bool? animationsEnabled,
  }) {
    return AppSettings(
      gridSize: gridSize ?? this.gridSize,
      themeMode: themeMode ?? this.themeMode,
      tileStyle: tileStyle ?? this.tileStyle,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'gridSize': gridSize,
    'themeMode': themeMode.name,
    'tileStyle': tileStyle.name,
    'animationsEnabled': animationsEnabled,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawSize = json['gridSize'];
    final int? size =
        rawSize is int && (rawSize == 3 || rawSize == 4 || rawSize == 5)
        ? rawSize
        : null;

    return AppSettings(
      gridSize: size,
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      tileStyle: TileStyle.values.firstWhere(
        (style) => style.name == json['tileStyle'],
        orElse: () => TileStyle.classic,
      ),
      animationsEnabled: json['animationsEnabled'] is bool
          ? json['animationsEnabled'] as bool
          : true,
    );
  }
}
