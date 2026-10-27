// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/widgets/error_vista.dart
// Función  : Vista de error con botón para reintentar.
// ============================================================

import 'package:flutter/material.dart';

import 'estado_vacio.dart';

/// Pantalla de error con botón para reintentar.
class ErrorVista extends StatelessWidget {
  const ErrorVista({
    super.key,
    required this.mensaje,
    required this.onReintentar,
  });

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return EstadoVacio(
      icono: Icons.cloud_off_outlined,
      titulo: mensaje,
      mensaje: 'Revisa el almacenamiento del teléfono y vuelve a intentarlo.',
      accion: FilledButton.icon(
        onPressed: onReintentar,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
        style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
      ),
    );
  }
}
