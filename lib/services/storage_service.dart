// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/services/storage_service.dart
// Función  : Cámara, galería y carpeta privada donde se guardan las fotografías; valida formato y tamaño.
// ============================================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/material_academico.dart';
import '../state/agenda_state.dart';

/// Fuente de datos local de archivos: cámara, galería y la carpeta privada
/// de la aplicación donde se guardan las fotografías (Semana 3, sección 8).
class StorageService {
  StorageService._();
  static final StorageService instancia = StorageService._();

  final _picker = ImagePicker();

  /// Solo para las pruebas automáticas, que no pueden usar la cámara ni
  /// elegir una imagen de la galería.
  @visibleForTesting
  Future<XFile?> Function(ImageSource origen)? simulacion;

  /// Abre la cámara o la galería. Devuelve null si el usuario cancela.
  /// Las fotos se comprimen al 80 % con un ancho máximo de 1920 px.
  Future<XFile?> elegirImagen(ImageSource origen) async {
    if (simulacion != null) return simulacion!(origen);
    try {
      return await _picker.pickImage(
        source: origen,
        imageQuality: 80,
        maxWidth: 1920,
      );
    } on PlatformException catch (e) {
      debugPrint('Error al abrir ${origen.name}: ${e.code} ${e.message}');
      if (e.code.contains('access_denied')) {
        throw AgendaException(
          origen == ImageSource.camera
              ? 'No hay permiso para usar la cámara. Actívalo en Ajustes > Aplicaciones.'
              : 'No hay permiso para acceder a la galería.',
        );
      }
      if (e.code == 'no_available_camera') {
        throw AgendaException(
          'Este dispositivo no tiene una cámara disponible.',
        );
      }
      throw AgendaException(
        'No se pudo abrir la ${origen == ImageSource.camera ? 'cámara' : 'galería'}.',
      );
    }
  }

  /// Comprueba el formato (JPG o PNG) y el tamaño (máximo 10 MB).
  /// Devuelve el formato y el tamaño en KB.
  Future<({String formato, int tamanoKB})> validar(XFile archivo) async {
    final extension = p
        .extension(archivo.name.isNotEmpty ? archivo.name : archivo.path)
        .replaceFirst('.', '')
        .toLowerCase();
    if (!MaterialAcademico.formatosPermitidos.contains(extension)) {
      throw AgendaException(
        'Formato no permitido (${extension.isEmpty ? 'desconocido' : '.$extension'}). '
        'Solo se aceptan imágenes JPG o PNG.',
      );
    }
    final tamanoKB = (await archivo.length() / 1024).ceil();
    if (tamanoKB > MaterialAcademico.tamanoMaximoKB) {
      throw AgendaException(
        'La imagen pesa ${(tamanoKB / 1024).toStringAsFixed(1)} MB; '
        'el máximo permitido es 10 MB.',
      );
    }
    return (formato: extension, tamanoKB: tamanoKB);
  }

  Future<Directory> _carpetaMateria(int idMateria) async {
    final base = await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'materiales', 'materia_$idMateria'));
  }

  /// Copia la imagen a `materiales/materia_<id>/<tipo>_<milisegundos>.<ext>`
  /// y devuelve la ruta final.
  Future<String> guardar(
    XFile archivo, {
    required int idMateria,
    required TipoMaterial tipo,
    required String formato,
  }) async {
    try {
      final carpeta = await _carpetaMateria(idMateria);
      await carpeta.create(recursive: true);
      final nombre =
          '${tipo.valor}_${DateTime.now().millisecondsSinceEpoch}.$formato';
      final ruta = p.join(carpeta.path, nombre);
      await archivo.saveTo(ruta);
      return ruta;
    } on FileSystemException catch (e) {
      debugPrint('No se pudo guardar el archivo: $e');
      throw AgendaException(
        'No se pudo guardar la imagen en el teléfono. Revisa el espacio disponible.',
      );
    }
  }

  /// Borra un archivo; si ya no existe no es un error.
  Future<void> eliminarArchivo(String ruta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    } on FileSystemException catch (e) {
      debugPrint('No se pudo borrar $ruta: $e');
    }
  }

  /// Al eliminar una materia se borra toda su carpeta de fotografías.
  Future<void> eliminarCarpetaMateria(int idMateria) async {
    try {
      final carpeta = await _carpetaMateria(idMateria);
      if (await carpeta.exists()) await carpeta.delete(recursive: true);
    } on FileSystemException catch (e) {
      debugPrint('No se pudo borrar la carpeta de la materia $idMateria: $e');
    }
  }

  /// Indica si el archivo de una fotografía sigue existiendo en el teléfono.
  bool existe(String ruta) => !kIsWeb && File(ruta).existsSync();
}
