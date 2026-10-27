// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/widgets/horario_tile.dart
// Función  : Tarjeta de una clase del horario.
// ============================================================

import 'package:flutter/material.dart';

import '../models/horario.dart';

/// Una clase del horario, con una barra del color de la materia.
class HorarioTile extends StatelessWidget {
  const HorarioTile({
    super.key,
    required this.horario,
    this.mostrarMateria = true,
    this.onTap,
  });

  final Horario horario;
  final bool mostrarMateria;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(horario.colorMateria ?? Colors.grey.toARGB32());
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              horario.horaInicio,
                              style: tema.textTheme.titleSmall,
                            ),
                            Text(
                              horario.horaFin,
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mostrarMateria
                                  ? (horario.nombreMateria ?? '')
                                  : 'Clase',
                              style: tema.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (horario.aula != null &&
                                horario.aula!.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.room_outlined,
                                    size: 14,
                                    color: tema.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    horario.aula!,
                                    style: tema.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
