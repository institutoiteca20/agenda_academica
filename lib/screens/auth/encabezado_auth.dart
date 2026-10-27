// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/encabezado_auth.dart
// Función  : Logo y título de las pantallas de autenticación.
// ============================================================

import 'package:flutter/material.dart';

/// Logo y título compartidos por Login y Registro.
class EncabezadoAuth extends StatelessWidget {
  const EncabezadoAuth({
    super.key,
    required this.titulo,
    required this.subtitulo,
  });

  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        // Ícono de la aplicación (libro + calendario).
        Image.asset('assets/icono.png', width: 96, height: 96),
        const SizedBox(height: 16),
        Text(
          titulo,
          style: tema.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitulo,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.outline,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
