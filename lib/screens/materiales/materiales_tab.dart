// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materiales/materiales_tab.dart
// Función  : Pestaña Material de una materia y miniaturas de las fotografías (RF13, RF14).
// ============================================================

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../models/material_academico.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../widgets/estado_vacio.dart';
import 'agregar_foto.dart';
import 'material_form_screen.dart';
import 'material_visor_screen.dart';

/// Material académico de una materia: fotografías de apuntes, ejercicios
/// y pizarra, filtradas por tipo de contenido.
class MaterialesTab extends StatefulWidget {
  const MaterialesTab({super.key, required this.idMateria});

  final int idMateria;

  @override
  State<MaterialesTab> createState() => _MaterialesTabState();
}

class _MaterialesTabState extends State<MaterialesTab> {
  TipoMaterial? _filtro;

  /// Flujo de registro: elegir la foto y completar el formulario.
  Future<void> _agregar() async {
    final imagen = await elegirFotografia(context);
    if (imagen == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MaterialFormScreen(idMateria: widget.idMateria, imagen: imagen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'material',
        tooltip: 'Agregar fotografía',
        onPressed: _agregar,
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          final todos = estado.materialesDe(widget.idMateria);
          final filtrados = todos
              .where((m) => _filtro == null || m.tipo == _filtro)
              .toList();
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    for (final tipo in <TipoMaterial?>[
                      null,
                      ...TipoMaterial.values,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${tipo?.etiqueta ?? 'Todos'} '
                            '(${todos.where((m) => tipo == null || m.tipo == tipo).length})',
                          ),
                          selected: _filtro == tipo,
                          onSelected: (_) => setState(() => _filtro = tipo),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? EstadoVacio(
                        icono: Icons.photo_library_outlined,
                        titulo: todos.isEmpty
                            ? 'Sin material guardado'
                            : 'No hay material de este tipo',
                        mensaje:
                            'Toca el botón de la cámara para guardar fotos de '
                            'apuntes, ejercicios o la pizarra.\n'
                            'Formatos permitidos: JPG y PNG · Máximo 10 MB',
                      )
                    // Cuadrícula adaptable: más columnas en pantallas anchas.
                    : GridView.extent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 0.8,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (final m in filtrados)
                            MiniaturaMaterial(material: m),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Miniatura de una fotografía; al tocarla abre el visor.
class MiniaturaMaterial extends StatelessWidget {
  const MiniaturaMaterial({
    super.key,
    required this.material,
    this.mostrarMateria = false,
  });

  final MaterialAcademico material;

  /// En la pantalla "Fotos" de Inicio se muestra a qué materia pertenece.
  final bool mostrarMateria;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                MaterialVisorScreen(idMaterial: material.idMaterial!),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: kIsWeb
                  ? const Icon(Icons.image_outlined, size: 48)
                  : Image.file(
                      File(material.rutaArchivo),
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                      // Respuesta ante fallos: el archivo fue borrado del teléfono.
                      errorBuilder: (context, error, stack) => Container(
                        color: tema.colorScheme.errorContainer,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: tema.colorScheme.error,
                              size: 36,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Archivo no encontrado',
                              style: tema.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.nombre,
                    style: tema.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mostrarMateria
                        ? AgendaState.instancia
                                  .materia(material.idMateria)
                                  ?.nombre ??
                              material.tipo.etiqueta
                        : '${material.tipo.etiqueta} · ${Formato.fecha(material.fecha)}',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: tema.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
