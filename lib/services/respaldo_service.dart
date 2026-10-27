// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/services/respaldo_service.dart
// Función  : Respaldo local para cambio de celular: exporta e importa la base de datos y las fotos en un archivo .zip, sin internet.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../state/agenda_state.dart';
import 'auth_service.dart';

/// Recuperación de la información al cambiar de celular, SIN internet:
/// 1) En el celular anterior se exporta un archivo .zip con la base de datos
///    (SQLite) y las fotografías.
/// 2) El archivo se pasa al celular nuevo (cable, WhatsApp, Drive, etc.).
/// 3) En el celular nuevo se restaura y se inicia sesión con la misma cuenta.
/// Las contraseñas viajan cifradas (hash SHA-256); la huella no se copia:
/// se usa la que esté registrada en el celular nuevo.
class RespaldoService {
  RespaldoService._();
  static final RespaldoService instancia = RespaldoService._();

  static const _manifiesto = 'manifiesto.json';
  static const _archivoBD = 'agenda_academica.db';
  static const _carpetaFotos = 'materiales';

  /// Solo para las pruebas automáticas, que no pueden usar el selector de
  /// archivos del sistema.
  @visibleForTesting
  Future<bool> Function(String nombre, Uint8List bytes)? simulacionGuardar;
  @visibleForTesting
  Future<Uint8List?> Function()? simulacionElegir;

  Future<Directory> _documentos() => getApplicationDocumentsDirectory();

  /// Crea el contenido del respaldo (.zip) con la base de datos y las fotos.
  Future<Uint8List> crearRespaldo() async {
    final db = DatabaseHelper.instancia;
    final rutaBD = await db.rutaArchivo();
    // Se cierra la base de datos para copiar el archivo completo y estable.
    await db.cerrar();
    final archivo = Archive();
    archivo.add(
      ArchiveFile.bytes(_archivoBD, await File(rutaBD).readAsBytes()),
    );

    var fotos = 0;
    final carpeta = Directory(
      p.join((await _documentos()).path, _carpetaFotos),
    );
    if (await carpeta.exists()) {
      await for (final f in carpeta.list(recursive: true)) {
        if (f is File) {
          final relativa = p
              .relative(f.path, from: (await _documentos()).path)
              .replaceAll(r'\', '/');
          archivo.add(ArchiveFile.bytes(relativa, await f.readAsBytes()));
          fotos++;
        }
      }
    }
    archivo.add(
      ArchiveFile.bytes(
        _manifiesto,
        utf8.encode(
          jsonEncode({
            'app': 'agenda_academica',
            'versionBaseDatos': DatabaseHelper.version,
            'fecha': DateTime.now().toIso8601String(),
            'fotografias': fotos,
          }),
        ),
      ),
    );
    return ZipEncoder().encodeBytes(archivo);
  }

  /// Exporta el respaldo: el sistema pregunta dónde guardarlo (por ejemplo
  /// en Descargas). Devuelve false si el usuario canceló.
  Future<bool> exportar() async {
    final bytes = await crearRespaldo();
    final hoy = DateTime.now();
    final nombre =
        'respaldo_agenda_${hoy.year}-${_dos(hoy.month)}-${_dos(hoy.day)}.zip';
    if (simulacionGuardar != null) return simulacionGuardar!(nombre, bytes);
    final uri = await FilePicker.saveFile(
      fileName: nombre,
      bytes: bytes,
      mimeType: 'application/zip',
      dialogTitle: 'Guardar respaldo de la agenda',
    );
    return uri != null;
  }

  /// Pide al usuario el archivo de respaldo y lo restaura.
  /// Devuelve false si el usuario canceló.
  Future<bool> importar() async {
    Uint8List? bytes;
    if (simulacionElegir != null) {
      bytes = await simulacionElegir!();
    } else {
      final elegido = await FilePicker.pickFile(
        dialogTitle: 'Elegir el respaldo de la agenda',
      );
      bytes = await elegido?.readAsBytes();
    }
    if (bytes == null) return false;
    await restaurar(bytes);
    return true;
  }

  /// Reemplaza los datos de este celular por los del respaldo.
  Future<void> restaurar(Uint8List bytes) async {
    final Archive archivo;
    try {
      archivo = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw AgendaException('El archivo elegido no es un respaldo válido.');
    }
    final manifiesto = archivo.findFile(_manifiesto);
    final bd = archivo.findFile(_archivoBD);
    Map<String, dynamic> datos = {};
    try {
      if (manifiesto != null) {
        datos = jsonDecode(utf8.decode(manifiesto.content));
      }
    } catch (_) {}
    if (datos['app'] != 'agenda_academica' || bd == null) {
      throw AgendaException(
        'El archivo elegido no es un respaldo de Agenda Académica.',
      );
    }
    if ((datos['versionBaseDatos'] as int? ?? 0) > DatabaseHelper.version) {
      throw AgendaException(
        'El respaldo es de una versión más nueva de la app. '
        'Actualiza la aplicación e inténtalo de nuevo.',
      );
    }

    // 1) Base de datos: se cierra y se reemplaza el archivo.
    final db = DatabaseHelper.instancia;
    final rutaBD = await db.rutaArchivo();
    await db.cerrar();
    for (final extra in ['-journal', '-wal', '-shm']) {
      final f = File('$rutaBD$extra');
      if (await f.exists()) await f.delete();
    }
    await File(rutaBD).writeAsBytes(bd.content, flush: true);

    // 2) Fotografías: se reemplaza la carpeta de materiales.
    final docs = (await _documentos()).path;
    final carpeta = Directory(p.join(docs, _carpetaFotos));
    if (await carpeta.exists()) await carpeta.delete(recursive: true);
    for (final f in archivo.files) {
      if (!f.isFile || !f.name.startsWith('$_carpetaFotos/')) continue;
      final destino = File(p.join(docs, f.name));
      await destino.parent.create(recursive: true);
      await destino.writeAsBytes(f.content);
    }

    // 3) Al abrirse, la base de datos se actualiza sola si el respaldo es de
    //    una versión anterior. Se corrigen las rutas de las fotos, porque la
    //    carpeta del celular nuevo puede ser distinta.
    final base = await db.bd;
    for (final fila in await base.query('material')) {
      final ruta = (fila['rutaArchivo'] as String).replaceAll(r'\', '/');
      final i = ruta.indexOf('$_carpetaFotos/');
      if (i < 0) continue;
      await base.update(
        'material',
        {'rutaArchivo': p.join(docs, ruta.substring(i))},
        where: 'idMaterial = ?',
        whereArgs: [fila['idMaterial']],
      );
    }

    // 4) Se cierra la sesión: se ingresa con la cuenta del respaldo.
    await AuthService.instancia.cerrarSesion();
    AgendaState.instancia.limpiar();
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
