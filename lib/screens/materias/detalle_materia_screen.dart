// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materias/detalle_materia_screen.dart
// Función  : Detalle de una materia con sus pestañas Tareas, Horario y Material.
// ============================================================

import 'package:flutter/material.dart';

import '../../models/horario.dart';
import '../../models/materia.dart';
import '../../models/tarea.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/horario_tile.dart';
import '../../widgets/tarea_tile.dart';
import '../horarios/horario_form_screen.dart';
import '../materiales/materiales_tab.dart';
import '../tareas/tarea_form_screen.dart';
import 'materia_form_screen.dart';

/// Detalle de materia: la pantalla central del proyecto, porque
/// aquí se reúne todo lo de una materia (tareas, horario y material).
class DetalleMateriaScreen extends StatelessWidget {
  const DetalleMateriaScreen({super.key, required this.idMateria});

  final int idMateria;

  void _abrir(BuildContext context, Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  Future<void> _eliminar(BuildContext context, Materia m) async {
    final confirmar = await Mensajes.confirmar(
      context,
      titulo: 'Eliminar materia',
      mensaje:
          '¿Eliminar "${m.nombre}"? También se eliminarán sus tareas, horarios y material.',
    );
    if (!confirmar || !context.mounted) return;
    final navigator = Navigator.of(context);
    final ok = await Mensajes.ejecutar(
      context,
      () => AgendaState.instancia.eliminarMateria(m.idMateria!),
      exito: 'Materia "${m.nombre}" eliminada',
    );
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final m = estado.materia(idMateria);
        // La materia pudo eliminarse mientras esta pantalla estaba abierta.
        if (m == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EstadoVacio(
              icono: Icons.class_outlined,
              titulo: 'La materia ya no existe',
            ),
          );
        }
        final tareas = estado.tareasDe(idMateria);
        final horarios = estado.horariosDe(idMateria);

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: m.colorMateria,
              foregroundColor: Colors.white,
              title: Text(m.nombre),
              actions: [
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  onSelected: (op) => op == 'editar'
                      ? _abrir(context, MateriaFormScreen(materia: m))
                      : _eliminar(context, m),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: Text('Editar materia'),
                    ),
                    PopupMenuItem(
                      value: 'eliminar',
                      child: Text('Eliminar materia'),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.task_alt),
                    text: 'Tareas (${tareas.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.schedule),
                    text: 'Horario (${horarios.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.photo_library_outlined),
                    text: 'Material (${estado.materialesDe(idMateria).length})',
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                if (m.docente?.isNotEmpty == true ||
                    m.descripcion?.isNotEmpty == true)
                  Material(
                    color: m.colorMateria.withValues(alpha: 0.08),
                    child: ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        m.docente?.isNotEmpty == true
                            ? m.docente!
                            : 'Sin docente',
                      ),
                      subtitle: m.descripcion?.isNotEmpty == true
                          ? Text(m.descripcion!)
                          : null,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TabTareas(idMateria: idMateria, tareas: tareas),
                      _TabHorario(idMateria: idMateria, horarios: horarios),
                      MaterialesTab(idMateria: idMateria),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabTareas extends StatelessWidget {
  const _TabTareas({required this.idMateria, required this.tareas});

  final int idMateria;
  final List<Tarea> tareas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'tarea',
        tooltip: 'Agregar tarea',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TareaFormScreen(idMateria: idMateria),
          ),
        ),
        child: const Icon(Icons.add_task),
      ),
      body: tareas.isEmpty
          ? const EstadoVacio(
              icono: Icons.task_alt,
              titulo: 'Sin tareas en esta materia',
              mensaje: 'Toca el botón + para registrar una tarea.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                for (final t in tareas)
                  TareaTile(tarea: t, mostrarMateria: false),
              ],
            ),
    );
  }
}

class _TabHorario extends StatelessWidget {
  const _TabHorario({required this.idMateria, required this.horarios});

  final int idMateria;
  final List<Horario> horarios;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'horario',
        tooltip: 'Agregar clase',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HorarioFormScreen(idMateria: idMateria),
          ),
        ),
        child: const Icon(Icons.more_time),
      ),
      body: horarios.isEmpty
          ? const EstadoVacio(
              icono: Icons.schedule,
              titulo: 'Sin horario registrado',
              mensaje: 'Agrega los días y horas en que pasas esta materia.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                for (final h in horarios) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Text(
                      Formato.nombreDia(h.dia),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  HorarioTile(
                    horario: h,
                    mostrarMateria: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HorarioFormScreen(horario: h),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
