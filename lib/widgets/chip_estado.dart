// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/widgets/chip_estado.dart
// Función  : Etiqueta de color con el estado de una tarea.
// ============================================================

import 'package:flutter/material.dart';

import '../models/tarea.dart';

/// Etiqueta de color con el estado de una tarea. Al tocarla cambia de estado.
class ChipEstado extends StatelessWidget {
  const ChipEstado({super.key, required this.estado, this.onTap});

  final EstadoTarea estado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: estado.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: estado.color),
        ),
        child: Text(
          estado.etiqueta,
          style: TextStyle(
            color: estado.color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
