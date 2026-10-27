// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/tareas/tarea_form_screen.dart
// Función  : Formulario para registrar, editar o eliminar una tarea (RF07, RF09, RF10).
// ============================================================

import 'package:flutter/material.dart';

import '../../models/materia.dart';
import '../../models/tarea.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../materias/materia_form_screen.dart';

/// Registrar, editar o eliminar una tarea (RF07, RF09, RF10).
class TareaFormScreen extends StatefulWidget {
  const TareaFormScreen({super.key, this.tarea, this.idMateria});

  /// Tarea a editar; null para una tarea nueva.
  final Tarea? tarea;

  /// Materia preseleccionada al crear desde el detalle de una materia.
  final int? idMateria;

  @override
  State<TareaFormScreen> createState() => _TareaFormScreenState();
}

class _TareaFormScreenState extends State<TareaFormScreen> {
  final _estado = AgendaState.instancia;
  final _formulario = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.tarea?.titulo);
  late final _descripcion = TextEditingController(
    text: widget.tarea?.descripcion,
  );
  late int? _idMateria = widget.tarea?.idMateria ?? widget.idMateria;
  late DateTime? _fecha = widget.tarea?.fechaEntrega;
  late EstadoTarea _estadoTarea = widget.tarea?.estado ?? EstadoTarea.pendiente;
  String? _errorFecha;
  bool _guardando = false;

  /// Después del primer intento de guardar, cada campo se valida al modificarlo.
  bool _intentoGuardar = false;
  bool _modificado = false;

  bool get _esNueva => widget.tarea == null;

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  void _cambio() {
    if (!_modificado) setState(() => _modificado = true);
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    // Al editar una tarea vencida se permite mantener su fecha anterior.
    final primera = _fecha != null && _fecha!.isBefore(inicio)
        ? _fecha!
        : inicio;
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha ?? inicio,
      firstDate: _esNueva ? inicio : primera,
      lastDate: DateTime(hoy.year + 2, 12, 31),
      helpText: 'Fecha de entrega',
    );
    if (elegida == null) return;
    setState(() {
      _fecha = elegida;
      _errorFecha = null;
      _modificado = true;
    });
  }

  Future<void> _guardar() async {
    setState(() => _intentoGuardar = true);
    final errorFecha = Validadores.fechaEntrega(_fecha, esNueva: _esNueva);
    setState(() => _errorFecha = errorFecha);
    final valido = _formulario.currentState!.validate();
    if (!valido || errorFecha != null) return;

    setState(() => _guardando = true);
    final tarea = Tarea(
      idTarea: widget.tarea?.idTarea,
      idMateria: _idMateria!,
      titulo: _titulo.text.trim(),
      descripcion: _descripcion.text.trim(),
      fechaEntrega: _fecha!,
      estado: _estadoTarea,
    );
    final ok = await Mensajes.ejecutar(
      context,
      () => _estado.guardarTarea(tarea),
      exito: _esNueva ? 'Tarea registrada' : 'Tarea actualizada',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _guardando = false);
    }
  }

  Future<void> _eliminar() async {
    final confirmar = await Mensajes.confirmar(
      context,
      titulo: 'Eliminar tarea',
      mensaje:
          '¿Eliminar "${widget.tarea!.titulo}"? Esta acción no se puede deshacer.',
    );
    if (!confirmar || !mounted) return;
    final ok = await Mensajes.ejecutar(
      context,
      () => _estado.eliminarTarea(widget.tarea!.idTarea!),
      exito: 'Tarea eliminada',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final materias = _estado.materias;
    return PopScope(
      // Si hay cambios sin guardar se pide confirmación antes de salir.
      canPop: !_modificado || _guardando,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await Mensajes.descartarCambios(context) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_esNueva ? 'Nueva tarea' : 'Editar tarea'),
          actions: [
            if (!_esNueva)
              IconButton(
                tooltip: 'Eliminar tarea',
                icon: const Icon(Icons.delete_outline),
                onPressed: _guardando ? null : _eliminar,
              ),
          ],
        ),
        body: materias.isEmpty
            ? const _SinMaterias()
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Form(
                      key: _formulario,
                      autovalidateMode: _intentoGuardar
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      onChanged: _cambio,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _titulo,
                            textCapitalization: TextCapitalization.sentences,
                            maxLength: 80,
                            decoration: const InputDecoration(
                              labelText: 'Título *',
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: Validadores.tituloTarea,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue:
                                materias.any((m) => m.idMateria == _idMateria)
                                ? _idMateria
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Materia *',
                              prefixIcon: Icon(Icons.class_outlined),
                            ),
                            items: [for (final m in materias) _itemMateria(m)],
                            onChanged: (v) => setState(() => _idMateria = v),
                            validator: (v) =>
                                v == null ? 'Elige una materia' : null,
                          ),
                          const SizedBox(height: 16),
                          _CampoFecha(
                            fecha: _fecha,
                            error: _errorFecha,
                            onTap: _elegirFecha,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descripcion,
                            maxLines: 3,
                            maxLength: 300,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Estado',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              for (final e in [
                                EstadoTarea.pendiente,
                                EstadoTarea.enProgreso,
                                EstadoTarea.completada,
                              ])
                                ChoiceChip(
                                  label: Text(e.etiqueta),
                                  selected: _estadoTarea == e,
                                  selectedColor: e.color.withValues(alpha: 0.2),
                                  side: BorderSide(color: e.color),
                                  onSelected: (_) => setState(() {
                                    _estadoTarea = e;
                                    _modificado = true;
                                  }),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          FilledButton.icon(
                            onPressed: _guardando ? null : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  DropdownMenuItem<int> _itemMateria(Materia m) => DropdownMenuItem(
    value: m.idMateria,
    child: Row(
      children: [
        CircleAvatar(radius: 6, backgroundColor: m.colorMateria),
        const SizedBox(width: 8),
        Flexible(child: Text(m.nombre, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

/// Campo que abre el calendario (showDatePicker).
class _CampoFecha extends StatelessWidget {
  const _CampoFecha({
    required this.fecha,
    required this.error,
    required this.onTap,
  });

  final DateTime? fecha;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de entrega *',
          prefixIcon: const Icon(Icons.event),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          errorText: error,
        ),
        isEmpty: fecha == null,
        child: Text(
          fecha == null
              ? ''
              : '${Formato.fechaLarga(fecha!)} · ${Formato.entrega(fecha!)}',
        ),
      ),
    );
  }
}

class _SinMaterias extends StatelessWidget {
  const _SinMaterias();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.class_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            const Text(
              'Primero registra una materia',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cada tarea pertenece a una materia.',
              textAlign: TextAlign.center,
            ),
            // Corrección Semana 7: antes no había forma de salir de aquí
            // hacia el registro de materias.
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const MateriaFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Registrar materia'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            ),
          ],
        ),
      ),
    );
  }
}
