// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/tareas/tareas_screen.dart
// Función  : Lista de tareas con filtros por materia y estado (RF08).
// ============================================================

import 'package:flutter/material.dart';

import '../../models/tarea.dart';
import '../../state/agenda_state.dart';
import '../../widgets/error_vista.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarea_tile.dart';
import 'tarea_form_screen.dart';

/// Lista de todas las tareas con filtros por estado (Semana 3, sección 7)
/// y por materia.
class TareasScreen extends StatefulWidget {
  const TareasScreen({super.key});

  @override
  State<TareasScreen> createState() => _TareasScreenState();
}

class _TareasScreenState extends State<TareasScreen> {
  final _estado = AgendaState.instancia;

  /// null = "Todas"
  EstadoTarea? _filtroEstado;

  /// null = todas las materias
  int? _filtroMateria;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TareaFormScreen(idMateria: _filtroMateria),
          ),
        ),
        icon: const Icon(Icons.add_task),
        label: const Text('Tarea'),
      ),
      body: ListenableBuilder(
        listenable: _estado,
        builder: (context, _) {
          if (_estado.error != null && !_estado.cargado) {
            return ErrorVista(
              mensaje: _estado.error!,
              onReintentar: _estado.cargar,
            );
          }
          // Si la materia filtrada se eliminó, se vuelve a mostrar todas.
          if (_filtroMateria != null &&
              _estado.materia(_filtroMateria!) == null) {
            _filtroMateria = null;
          }
          final deMateria = _estado.tareas
              .where(
                (t) => _filtroMateria == null || t.idMateria == _filtroMateria,
              )
              .toList();
          int contar(EstadoTarea? e) =>
              deMateria.where((t) => e == null || t.estadoVisible == e).length;
          final filtradas = deMateria
              .where(
                (t) =>
                    _filtroEstado == null || t.estadoVisible == _filtroEstado,
              )
              .toList();

          return Column(
            children: [
              if (_estado.materias.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DropdownButtonFormField<int?>(
                    isExpanded: true,
                    key: ValueKey(_filtroMateria),
                    initialValue: _filtroMateria,
                    isDense: true,
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      prefixIcon: Icon(Icons.filter_list),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Todas las materias'),
                      ),
                      for (final m in _estado.materias)
                        DropdownMenuItem(
                          value: m.idMateria,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 6,
                                backgroundColor: m.colorMateria,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  m.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _filtroMateria = v),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    for (final e in <EstadoTarea?>[null, ...EstadoTarea.values])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${e?.etiqueta ?? 'Todas'} (${contar(e)})',
                          ),
                          selected: _filtroEstado == e,
                          onSelected: (_) => setState(() => _filtroEstado = e),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtradas.isEmpty
                    ? EstadoVacio(
                        icono: Icons.task_alt,
                        titulo: _estado.tareas.isEmpty
                            ? 'No tienes tareas registradas'
                            : 'No hay tareas con este filtro',
                        mensaje: _estado.materias.isEmpty
                            ? 'Primero registra una materia desde Inicio.'
                            : 'Toca "+ Tarea" para registrar una.',
                      )
                    : RefreshIndicator(
                        onRefresh: _estado.cargar,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                          children: [
                            for (final t in filtradas) TareaTile(tarea: t),
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
