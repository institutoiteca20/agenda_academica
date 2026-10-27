// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/widgets/estado_vacio.dart
// Función  : Mensaje para listas sin elementos.
// ============================================================

import 'package:flutter/material.dart';

/// Mensaje que se muestra cuando una lista no tiene elementos.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: tema.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (mensaje != null) ...[
              const SizedBox(height: 8),
              Text(
                mensaje!,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (accion != null) ...[const SizedBox(height: 16), accion!],
          ],
        ),
      ),
    );
  }
}
