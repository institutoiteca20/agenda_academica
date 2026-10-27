// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materiales/agregar_foto.dart
// Función  : Flujo para tomar o elegir una fotografía y validarla.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/storage_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/mensajes.dart';

/// Flujo para obtener una fotografía: elegir origen → abrir cámara/galería →
/// validar formato y tamaño. Se usa desde una materia y desde Inicio.
/// Devuelve null si el usuario canceló o hubo un error (ya se mostró).
Future<XFile?> elegirFotografia(BuildContext context) async {
  if (kIsWeb) {
    Mensajes.error(
      context,
      'Las fotografías solo están disponibles en Android.',
    );
    return null;
  }
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Agregar material',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            subtitle: const Text('Apuntes, ejercicios o la pizarra'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            subtitle: const Text('Formatos JPG o PNG · máximo 10 MB'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (origen == null || !context.mounted) return null;

  final storage = StorageService.instancia;
  try {
    final imagen = await storage.elegirImagen(origen);
    if (imagen == null) return null; // el usuario canceló
    await storage.validar(imagen);
    return imagen;
  } on AgendaException catch (e) {
    if (context.mounted) Mensajes.error(context, e.mensaje);
    return null;
  }
}
