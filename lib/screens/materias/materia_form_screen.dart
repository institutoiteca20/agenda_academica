// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materias/materia_form_screen.dart
// Función  : Formulario para registrar o editar una materia (RF04, RF06).
// ============================================================

import 'package:flutter/material.dart';

import '../../models/materia.dart';
import '../../services/auth_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/mensajes.dart';
import '../../utils/tema.dart';
import '../../utils/validadores.dart';

/// Registrar o editar una materia (RF04, RF06).
class MateriaFormScreen extends StatefulWidget {
  const MateriaFormScreen({super.key, this.materia});

  final Materia? materia;

  @override
  State<MateriaFormScreen> createState() => _MateriaFormScreenState();
}

class _MateriaFormScreenState extends State<MateriaFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.materia?.nombre);
  late final _docente = TextEditingController(text: widget.materia?.docente);
  late final _descripcion = TextEditingController(
    text: widget.materia?.descripcion,
  );
  late int _color = widget.materia?.color ?? _siguienteColor();
  bool _guardando = false;

  /// Después del primer intento de guardar, cada campo se valida al modificarlo.
  bool _intentoGuardar = false;
  bool _modificado = false;

  bool get _esEdicion => widget.materia != null;

  /// Propone un color que todavía no use otra materia.
  int _siguienteColor() {
    final usados = AgendaState.instancia.materias.map((m) => m.color).toSet();
    return Tema.coloresMateria
        .map((c) => c.toARGB32())
        .firstWhere(
          (c) => !usados.contains(c),
          orElse: () => Tema.coloresMateria.first.toARGB32(),
        );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _docente.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _intentoGuardar = true);
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);
    final materia = Materia(
      idMateria: widget.materia?.idMateria,
      idUsuario: AuthService.instancia.usuarioActual.idUsuario!,
      nombre: _nombre.text.trim(),
      docente: _docente.text.trim(),
      descripcion: _descripcion.text.trim(),
      color: _color,
    );
    final ok = await Mensajes.ejecutar(
      context,
      () => AgendaState.instancia.guardarMateria(materia),
      exito: _esEdicion ? 'Materia actualizada' : 'Materia registrada',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(_esEdicion ? 'Editar materia' : 'Nueva materia'),
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
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 50,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la materia *',
                        prefixIcon: Icon(Icons.class_outlined),
                      ),
                      validator: (v) =>
                          Validadores.requerido(v, 'el nombre de la materia'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _docente,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Docente',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descripcion,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Color',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final c in Tema.coloresMateria)
                          InkWell(
                            onTap: () => setState(() {
                              _color = c.toARGB32();
                              _modificado = true;
                            }),
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: c,
                              child: _color == c.toARGB32()
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
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
