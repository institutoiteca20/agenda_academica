// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/widgets/tarea_tile.dart
// Función  : Tarjeta de una tarea con casilla y estado.
// ============================================================

import 'package:flutter/material.dart';

import '../models/tarea.dart';
import '../screens/tareas/tarea_form_screen.dart';
import '../state/agenda_state.dart';
import '../utils/formato.dart';
import '../utils/mensajes.dart';
import 'chip_estado.dart';

/// Tarjeta de una tarea: casilla de completado, etiqueta de estado
/// y, al tocarla, el formulario de edición.
class TareaTile extends StatelessWidget {
  const TareaTile({super.key, required this.tarea, this.mostrarMateria = true});

  final Tarea tarea;
  final bool mostrarMateria;

  Future<void> _cambiarEstado(BuildContext context, EstadoTarea nuevo) =>
      Mensajes.ejecutar(
        context,
        () => AgendaState.instancia.cambiarEstado(tarea, nuevo),
      );

  @override
  Widget build(BuildContext context) {
    final completada = tarea.estado == EstadoTarea.completada;
    final estado = tarea.estadoVisible;
    final subtitulo = [
      if (mostrarMateria && tarea.nombreMateria != null) tarea.nombreMateria!,
      'Entrega: ${Formato.entrega(tarea.fechaEntrega)}',
    ].join('\n'); // la fecha de entrega va siempre en su propia línea

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 4, right: 12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TareaFormScreen(tarea: tarea)),
        ),
        leading: Checkbox(
          value: completada,
          onChanged: (v) => _cambiarEstado(
            context,
            v == true ? EstadoTarea.completada : EstadoTarea.pendiente,
          ),
        ),
        title: Text(
          tarea.titulo,
          style: completada
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                )
              : null,
        ),
        subtitle: Row(
          children: [
            if (mostrarMateria && tarea.colorMateria != null) ...[
              CircleAvatar(
                radius: 5,
                backgroundColor: Color(tarea.colorMateria!),
              ),
              const SizedBox(width: 6),
            ],
            // Hasta 2 líneas: en pantallas pequeñas o con letra grande la
            // fecha de entrega se cortaba (corrección Semana 7).
            Expanded(
              child: Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: ChipEstado(
          estado: estado,
          // Una tarea vencida sigue su ciclo desde el estado guardado.
          onTap: () => _cambiarEstado(context, tarea.estado.siguiente),
        ),
      ),
    );
  }
}
