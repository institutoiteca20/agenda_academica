// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/horarios/horario_form_screen.dart
// Función  : Formulario para registrar o editar una clase del horario (RF11).
// ============================================================

import 'package:flutter/material.dart';

import '../../models/horario.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';

/// Registrar, editar o eliminar una clase del horario (RF11).
/// Valida que la hora de fin sea mayor y que no se cruce con otra clase.
class HorarioFormScreen extends StatefulWidget {
  const HorarioFormScreen({super.key, this.horario, this.idMateria});

  final Horario? horario;
  final int? idMateria;

  @override
  State<HorarioFormScreen> createState() => _HorarioFormScreenState();
}

class _HorarioFormScreenState extends State<HorarioFormScreen> {
  final _estado = AgendaState.instancia;
  final _formulario = GlobalKey<FormState>();
  late final _aula = TextEditingController(text: widget.horario?.aula);
  late int? _idMateria = widget.horario?.idMateria ?? widget.idMateria;
  late int? _dia = widget.horario?.dia;
  late String? _inicio = widget.horario?.horaInicio;
  late String? _fin = widget.horario?.horaFin;
  String? _errorHoras;
  bool _guardando = false;

  /// Después del primer intento de guardar, cada campo se valida al modificarlo.
  bool _intentoGuardar = false;
  bool _modificado = false;

  bool get _esNuevo => widget.horario == null;

  @override
  void dispose() {
    _aula.dispose();
    super.dispose();
  }

  Future<void> _elegirHora(bool esInicio) async {
    final actual = esInicio ? _inicio : _fin;
    final inicial = actual != null
        ? TimeOfDay(
            hour: int.parse(actual.substring(0, 2)),
            minute: int.parse(actual.substring(3)),
          )
        : TimeOfDay(hour: esInicio ? 8 : 9, minute: esInicio ? 0 : 30);
    final elegida = await showTimePicker(
      context: context,
      initialTime: inicial,
      helpText: esInicio ? 'Hora de inicio' : 'Hora de fin',
      // Formato de 24 horas (Semana 3, sección 9.3).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (elegida == null) return;
    final texto =
        '${elegida.hour.toString().padLeft(2, '0')}:${elegida.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (esInicio) {
        _inicio = texto;
      } else {
        _fin = texto;
      }
      _errorHoras = null;
      _modificado = true;
    });
  }

  Future<void> _guardar() async {
    setState(() => _intentoGuardar = true);
    final errorHoras = Validadores.rangoHoras(_inicio, _fin);
    setState(() => _errorHoras = errorHoras);
    final valido = _formulario.currentState!.validate();
    if (!valido || errorHoras != null) return;

    setState(() => _guardando = true);
    final horario = Horario(
      idHorario: widget.horario?.idHorario,
      idMateria: _idMateria!,
      dia: _dia!,
      horaInicio: _inicio!,
      horaFin: _fin!,
      aula: _aula.text.trim(),
    );
    final ok = await Mensajes.ejecutar(
      context,
      () => _estado.guardarHorario(horario),
      exito: _esNuevo ? 'Clase registrada' : 'Clase actualizada',
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
      titulo: 'Eliminar clase',
      mensaje:
          '¿Eliminar la clase del ${Formato.nombreDia(widget.horario!.dia).toLowerCase()} '
          '(${widget.horario!.horaInicio} – ${widget.horario!.horaFin})?',
    );
    if (!confirmar || !mounted) return;
    final ok = await Mensajes.ejecutar(
      context,
      () => _estado.eliminarHorario(widget.horario!.idHorario!),
      exito: 'Clase eliminada',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final materias = _estado.materias;
    final tema = Theme.of(context);
    return PopScope(
      canPop: !_modificado || _guardando,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await Mensajes.descartarCambios(context) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_esNuevo ? 'Nueva clase' : 'Editar clase'),
          actions: [
            if (!_esNuevo)
              IconButton(
                tooltip: 'Eliminar clase',
                icon: const Icon(Icons.delete_outline),
                onPressed: _guardando ? null : _eliminar,
              ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formulario,
                autovalidateMode: _intentoGuardar
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                onChanged: () {
                  if (!_modificado) setState(() => _modificado = true);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      items: [
                        for (final m in materias)
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
                      onChanged: (v) => setState(() => _idMateria = v),
                      validator: (v) => v == null ? 'Elige una materia' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: _dia,
                      decoration: const InputDecoration(
                        labelText: 'Día *',
                        prefixIcon: Icon(Icons.today_outlined),
                      ),
                      items: [
                        for (var d = 1; d <= 7; d++)
                          DropdownMenuItem(
                            value: d,
                            child: Text(Formato.nombreDia(d)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _dia = v),
                      validator: (v) =>
                          v == null ? 'Elige el día de la clase' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _CampoHora(
                            etiqueta: 'Inicio *',
                            hora: _inicio,
                            onTap: () => _elegirHora(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CampoHora(
                            etiqueta: 'Fin *',
                            hora: _fin,
                            onTap: () => _elegirHora(false),
                          ),
                        ),
                      ],
                    ),
                    if (_errorHoras != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          _errorHoras!,
                          style: TextStyle(
                            color: tema.colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aula,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Aula',
                        hintText: 'Ej.: Aula 12, Lab. 2',
                        prefixIcon: Icon(Icons.room_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No se puede registrar una clase que se cruce con otra del mismo día.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
}

class _CampoHora extends StatelessWidget {
  const _CampoHora({
    required this.etiqueta,
    required this.hora,
    required this.onTap,
  });

  final String etiqueta;
  final String? hora;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: const Icon(Icons.schedule),
        ),
        isEmpty: hora == null,
        child: Text(hora ?? ''),
      ),
    );
  }
}
