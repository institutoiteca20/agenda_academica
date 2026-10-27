// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materiales/material_form_screen.dart
// Función  : Formulario para guardar o editar una fotografía y elegir su materia.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/material_academico.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';

/// Registrar una fotografía nueva ([imagen]) o editar los datos de una
/// ya guardada ([material]): nombre y tipo de contenido.
class MaterialFormScreen extends StatefulWidget {
  const MaterialFormScreen({
    super.key,
    this.idMateria,
    this.imagen,
    this.material,
  }) : assert(imagen != null || material != null);

  /// null al registrar desde Inicio: la materia se elige en el formulario.
  final int? idMateria;
  final XFile? imagen;
  final MaterialAcademico? material;

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formulario = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.material?.nombre);
  late TipoMaterial _tipo = widget.material?.tipo ?? TipoMaterial.apunte;
  late int? _idMateria = widget.idMateria ?? widget.material?.idMateria;
  bool _guardando = false;
  bool _modificado = false;

  /// Después del primer intento de guardar, cada campo se valida al modificarlo.
  bool _intentoGuardar = false;

  bool get _esNuevo => widget.material == null;

  String get _ruta => widget.imagen?.path ?? widget.material!.rutaArchivo;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _intentoGuardar = true);
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);

    final estado = AgendaState.instancia;
    final ok = await Mensajes.ejecutar(
      context,
      () => _esNuevo
          ? estado.registrarMaterial(
              imagen: widget.imagen!,
              idMateria: _idMateria!,
              nombre: _nombre.text.trim(),
              tipo: _tipo,
            )
          : estado.actualizarMaterial(
              MaterialAcademico(
                idMaterial: widget.material!.idMaterial,
                idMateria: widget.material!.idMateria,
                nombre: _nombre.text.trim(),
                tipo: _tipo,
                formato: widget.material!.formato,
                rutaArchivo: widget.material!.rutaArchivo,
                tamanoKB: widget.material!.tamanoKB,
                fecha: widget.material!.fecha,
              ),
            ),
      exito: _esNuevo ? 'Fotografía guardada' : 'Fotografía actualizada',
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
    final tema = Theme.of(context);
    final estado = AgendaState.instancia;
    final materia = _idMateria == null ? null : estado.materia(_idMateria!);
    // Desde Inicio se elige la materia; desde una materia ya viene definida.
    final elegirMateria = _esNuevo && widget.idMateria == null;
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
          title: Text(_esNuevo ? 'Nueva fotografía' : 'Editar fotografía'),
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
                    // Vista previa de la imagen.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 260,
                        color: Colors.black,
                        child: Image.file(
                          File(_ruta),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (materia != null && !elegirMateria)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 6,
                              backgroundColor: materia.colorMateria,
                            ),
                            const SizedBox(width: 8),
                            Text('Materia: ${materia.nombre}'),
                          ],
                        ),
                      ),
                    if (elegirMateria) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        isExpanded: true,
                        initialValue: _idMateria,
                        decoration: const InputDecoration(
                          labelText: 'Materia *',
                          helperText: '¿A qué materia pertenece esta foto?',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        items: [
                          for (final m in estado.materias)
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
                        onChanged: (v) => setState(() {
                          _idMateria = v;
                          _modificado = true;
                        }),
                        validator: (v) =>
                            v == null ? 'Elige la materia de la foto' : null,
                      ),
                    ],
                    if (!_esNuevo)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${widget.material!.formato.toUpperCase()} · '
                          '${Formato.tamano(widget.material!.tamanoKB)} · '
                          '${Formato.fecha(widget.material!.fecha)}',
                          style: tema.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 60,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        hintText: 'Ej.: Ejercicio de listas',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: Validadores.nombreMaterial,
                    ),
                    const SizedBox(height: 8),
                    Text('Tipo de contenido', style: tema.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in TipoMaterial.values)
                          ChoiceChip(
                            label: Text(t.etiqueta),
                            selected: _tipo == t,
                            onSelected: (_) => setState(() {
                              _tipo = t;
                              _modificado = true;
                            }),
                          ),
                      ],
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
