// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/utils/tema.dart
// Función  : Colores, tipografía y estilos visuales de la aplicación.
// ============================================================

import 'package:flutter/material.dart';

class Tema {
  static const colorPrincipal = Color(0xFF3949AB);

  /// Colores disponibles para identificar cada materia.
  static const coloresMateria = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFFE53935),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
  ];

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(seedColor: colorPrincipal);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: esquema.primary,
        foregroundColor: esquema.onPrimary,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        margin: EdgeInsets.symmetric(vertical: 4),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
