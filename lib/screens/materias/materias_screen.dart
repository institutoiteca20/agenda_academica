// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materias/materias_screen.dart
// Función  : Lista de materias registradas (RF05).
// ============================================================

import 'package:flutter/material.dart';

import '../../models/materia.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import '../../widgets/error_vista.dart';
import '../../widgets/estado_vacio.dart';
import 'detalle_materia_screen.dart';
import 'materia_form_screen.dart';

class MateriasScreen extends StatelessWidget {
  const MateriasScreen({super.key});

  void _abrirFormulario(BuildContext context, [Materia? materia]) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MateriaFormScreen(materia: materia)),
      );

  Future<void> _eliminar(BuildContext context, Materia materia) async {
    final estado = AgendaState.instancia;
    final tareas = estado.tareasDe(materia.idMateria!).length;
    final clases = estado.horariosDe(materia.idMateria!).length;
    final fotos = estado.materialesDe(materia.idMateria!).length;
    final confirmar = await Mensajes.confirmar(
      context,
      titulo: 'Eliminar materia',
      mensaje:
          '¿Eliminar "${materia.nombre}"? También se eliminarán sus '
          '${Formato.cantidad(tareas, 'tarea')}, ${Formato.cantidad(clases, 'clase')} '
          'y ${Formato.cantidad(fotos, 'fotografía')}.',
    );
    if (!confirmar || !context.mounted) return;
    await Mensajes.ejecutar(
      context,
      () => estado.eliminarMateria(materia.idMateria!),
      exito: 'Materia "${materia.nombre}" eliminada',
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    return Scaffold(
      appBar: AppBar(title: const Text('Materias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Materia'),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          if (estado.error != null && !estado.cargado) {
            return ErrorVista(
              mensaje: estado.error!,
              onReintentar: estado.cargar,
            );
          }
          final materias = estado.materias;
          if (materias.isEmpty) {
            return EstadoVacio(
              icono: Icons.class_outlined,
              titulo: 'Aún no tienes materias',
              mensaje:
                  'Registra tus materias para organizar tareas, horarios y apuntes.',
              accion: FilledButton.tonal(
                onPressed: () => _abrirFormulario(context),
                child: const Text('Registrar materia'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: materias.length,
            itemBuilder: (context, i) {
              final m = materias[i];
              final pendientes = estado.pendientesDe(m.idMateria!);
              final clases = estado.horariosDe(m.idMateria!).length;
              final fotos = estado.materialesDe(m.idMateria!).length;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: m.colorMateria,
                    foregroundColor: Colors.white,
                    child: Text(m.nombre[0].toUpperCase()),
                  ),
                  title: Text(m.nombre),
                  subtitle: Text(
                    '${m.docente?.isNotEmpty == true ? m.docente! : 'Sin docente'}\n'
                    '${Formato.cantidad(pendientes, 'pendiente')} · '
                    '${Formato.cantidad(clases, 'clase')} · '
                    '${Formato.cantidad(fotos, 'foto')}',
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetalleMateriaScreen(idMateria: m.idMateria!),
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Opciones',
                    onSelected: (op) => op == 'editar'
                        ? _abrirFormulario(context, m)
                        : _eliminar(context, m),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
