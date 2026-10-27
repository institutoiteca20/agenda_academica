// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materiales/material_visor_screen.dart
// Función  : Visor de una fotografía a pantalla completa con zoom.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/material_academico.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import 'material_form_screen.dart';

/// Visor de una fotografía a pantalla completa, con zoom, edición y eliminación.
class MaterialVisorScreen extends StatelessWidget {
  const MaterialVisorScreen({super.key, required this.idMaterial});

  final int idMaterial;

  Future<void> _eliminar(BuildContext context, MaterialAcademico m) async {
    final confirmar = await Mensajes.confirmar(
      context,
      titulo: 'Eliminar fotografía',
      mensaje:
          '¿Eliminar "${m.nombre}"? También se borrará el archivo del teléfono.',
    );
    if (!confirmar || !context.mounted) return;
    final navigator = Navigator.of(context);
    final ok = await Mensajes.ejecutar(
      context,
      () => AgendaState.instancia.eliminarMaterial(m),
      exito: 'Fotografía eliminada',
    );
    if (ok) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final m = estado.materiales
            .where((x) => x.idMaterial == idMaterial)
            .firstOrNull;
        if (m == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('La fotografía ya no existe')),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(m.nombre, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MaterialFormScreen(idMateria: m.idMateria, material: m),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _eliminar(context, m),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                // Zoom con dos dedos.
                child: InteractiveViewer(
                  maxScale: 5,
                  child: Center(
                    child: Image.file(
                      File(m.rutaArchivo),
                      errorBuilder: (context, error, stack) => const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 64,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No se encontró el archivo en el teléfono.\n'
                            'Puede que haya sido borrado.',
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Colors.black87,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: SafeArea(
                  top: false,
                  child: Text(
                    '${m.tipo.etiqueta} · ${m.formato.toUpperCase()} · '
                    '${Formato.tamano(m.tamanoKB)} · ${Formato.fecha(m.fecha)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
