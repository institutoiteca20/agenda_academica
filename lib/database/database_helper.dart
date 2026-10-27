// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/database/database_helper.dart
// Función  : Acceso a SQLite: creación de tablas, migración a la versión 2 y consultas CRUD de usuarios, materias, tareas, horarios y material.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/gestion.dart';
import '../models/horario.dart';
import '../models/material_academico.dart';
import '../models/materia.dart';
import '../models/tarea.dart';
import '../models/usuario.dart';

/// Acceso a la base de datos local SQLite (una sola instancia en toda la app).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instancia = DatabaseHelper._();

  static const _nombreBD = 'agenda_academica.db';

  /// Versión 2 (Semana 8): nombre de usuario y pregunta de seguridad.
  /// Versión 3 (Semana 8): gestiones académicas.
  static const version = 3;

  Database? _bd;

  Future<Database> get bd async => _bd ??= await _abrir();

  /// Ruta del archivo .db en el teléfono (para el respaldo).
  Future<String> rutaArchivo() async =>
      kIsWeb ? _nombreBD : join(await getDatabasesPath(), _nombreBD);

  /// Cierra la base de datos (antes de reemplazarla al restaurar un respaldo).
  Future<void> cerrar() async {
    await _bd?.close();
    _bd = null;
  }

  Future<Database> _abrir() async {
    final ruta = await rutaArchivo();
    return openDatabase(
      ruta,
      version: version,
      // Necesario para que funcione ON DELETE CASCADE.
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _crearTablas,
      onUpgrade: _actualizar,
    );
  }

  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuario (
        idUsuario      INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre            TEXT NOT NULL,
        usuario           TEXT UNIQUE,
        correo            TEXT NOT NULL UNIQUE,
        contrasenaHash    TEXT NOT NULL,
        salt              TEXT NOT NULL,
        preguntaSeguridad TEXT,
        respuestaHash     TEXT,
        fechaRegistro     TEXT NOT NULL
      )''');
    await db.execute(_tablaGestion);
    await db.execute('''
      CREATE TABLE materia (
        idMateria   INTEGER PRIMARY KEY AUTOINCREMENT,
        idUsuario   INTEGER NOT NULL,
        idGestion   INTEGER REFERENCES gestion (idGestion) ON DELETE CASCADE,
        nombre      TEXT NOT NULL,
        docente     TEXT,
        descripcion TEXT,
        color       INTEGER NOT NULL,
        FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE tarea (
        idTarea      INTEGER PRIMARY KEY AUTOINCREMENT,
        idMateria    INTEGER NOT NULL,
        titulo       TEXT NOT NULL,
        descripcion  TEXT,
        fechaEntrega TEXT NOT NULL,
        estado       TEXT NOT NULL DEFAULT 'pendiente'
                     CHECK (estado IN ('pendiente','en_progreso','completada')),
        FOREIGN KEY (idMateria) REFERENCES materia (idMateria) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE horario (
        idHorario  INTEGER PRIMARY KEY AUTOINCREMENT,
        idMateria  INTEGER NOT NULL,
        dia        INTEGER NOT NULL CHECK (dia BETWEEN 1 AND 7),
        horaInicio TEXT NOT NULL,
        horaFin    TEXT NOT NULL,
        aula       TEXT,
        FOREIGN KEY (idMateria) REFERENCES materia (idMateria) ON DELETE CASCADE
      )''');
    await db.execute('''
      CREATE TABLE material (
        idMaterial  INTEGER PRIMARY KEY AUTOINCREMENT,
        idMateria   INTEGER NOT NULL,
        nombre      TEXT NOT NULL,
        tipo        TEXT NOT NULL CHECK (tipo IN ('apunte','ejercicio','pizarra','otro')),
        formato     TEXT NOT NULL CHECK (formato IN ('jpg','jpeg','png')),
        rutaArchivo TEXT NOT NULL,
        tamanoKB    INTEGER NOT NULL,
        fecha       TEXT NOT NULL,
        FOREIGN KEY (idMateria) REFERENCES materia (idMateria) ON DELETE CASCADE
      )''');
  }

  /// De la versión 1 a la 2 sin perder datos: se agregan las columnas y a
  /// cada cuenta existente se le asigna un usuario a partir de su correo.
  /// La pregunta de seguridad se pide al entrar (es obligatoria).
  Future<void> _actualizar(Database db, int anterior, int nueva) async {
    if (anterior < 2) {
      await db.execute('ALTER TABLE usuario ADD COLUMN usuario TEXT');
      await db.execute('ALTER TABLE usuario ADD COLUMN preguntaSeguridad TEXT');
      await db.execute('ALTER TABLE usuario ADD COLUMN respuestaHash TEXT');
      final usados = <String>{};
      for (final fila in await db.query('usuario')) {
        final base = (fila['correo'] as String)
            .split('@')
            .first
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9._]'), '');
        var usuario = base.length >= 4 ? base : '${base}user';
        for (var n = 2; usados.contains(usuario); n++) {
          usuario = '$base$n';
        }
        usados.add(usuario);
        await db.update(
          'usuario',
          {'usuario': usuario},
          where: 'idUsuario = ?',
          whereArgs: [fila['idUsuario']],
        );
      }
      await db.execute(
        'CREATE UNIQUE INDEX idx_usuario_usuario ON usuario (usuario)',
      );
    }
    // De la versión 2 a la 3: gestiones académicas. Las materias que ya
    // existían pasan a una gestión con el año actual, sin perder nada.
    if (anterior < 3) {
      await db.execute(_tablaGestion);
      await db.execute(
        'ALTER TABLE materia ADD COLUMN idGestion INTEGER '
        'REFERENCES gestion (idGestion) ON DELETE CASCADE',
      );
      for (final fila in await db.query('usuario')) {
        final idUsuario = fila['idUsuario'] as int;
        final idGestion = await db.insert('gestion', {
          'idUsuario': idUsuario,
          'nombre': 'Gestión ${DateTime.now().year}',
          'activa': 1,
          'fechaCreacion': DateTime.now().toIso8601String(),
        });
        await db.update(
          'materia',
          {'idGestion': idGestion},
          where: 'idUsuario = ?',
          whereArgs: [idUsuario],
        );
      }
    }
  }

  static const _tablaGestion = '''
      CREATE TABLE gestion (
        idGestion     INTEGER PRIMARY KEY AUTOINCREMENT,
        idUsuario     INTEGER NOT NULL,
        nombre        TEXT NOT NULL,
        activa        INTEGER NOT NULL DEFAULT 0 CHECK (activa IN (0, 1)),
        fechaCreacion TEXT NOT NULL,
        FOREIGN KEY (idUsuario) REFERENCES usuario (idUsuario) ON DELETE CASCADE
      )''';

  // ---------------------------------------------------------------- Gestiones

  Future<List<Gestion>> obtenerGestiones(int idUsuario) async {
    final filas = await (await bd).query(
      'gestion',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
      orderBy: 'fechaCreacion DESC, idGestion DESC',
    );
    return filas.map(Gestion.fromMap).toList();
  }

  /// Crea una gestión y la deja como la única activa del usuario.
  Future<int> insertarGestionActiva(Gestion g) async {
    final db = await bd;
    return db.transaction((txn) async {
      await txn.update(
        'gestion',
        {'activa': 0},
        where: 'idUsuario = ?',
        whereArgs: [g.idUsuario],
      );
      return txn.insert(
        'gestion',
        (g.toMap()..remove('idGestion'))..['activa'] = 1,
      );
    });
  }

  Future<void> activarGestion(int idUsuario, int idGestion) async {
    final db = await bd;
    await db.transaction((txn) async {
      await txn.update(
        'gestion',
        {'activa': 0},
        where: 'idUsuario = ?',
        whereArgs: [idUsuario],
      );
      await txn.update(
        'gestion',
        {'activa': 1},
        where: 'idGestion = ?',
        whereArgs: [idGestion],
      );
    });
  }

  /// Cantidad de materias de cada gestión (para la pantalla de gestiones).
  Future<Map<int, int>> contarMateriasPorGestion(int idUsuario) async {
    final filas = await (await bd).rawQuery(
      'SELECT idGestion, COUNT(*) AS total FROM materia '
      'WHERE idUsuario = ? GROUP BY idGestion',
      [idUsuario],
    );
    return {
      for (final f in filas)
        if (f['idGestion'] != null) f['idGestion'] as int: f['total'] as int,
    };
  }

  // ---------------------------------------------------------------- Usuarios

  Future<int> insertarUsuario(Usuario u) async =>
      (await bd).insert('usuario', u.toMap()..remove('idUsuario'));

  Future<Usuario?> buscarUsuarioPorCorreo(String correo) async {
    final filas = await (await bd).query(
      'usuario',
      where: 'correo = ?',
      whereArgs: [correo],
      limit: 1,
    );
    return filas.isEmpty ? null : Usuario.fromMap(filas.first);
  }

  Future<Usuario?> buscarUsuarioPorNombreUsuario(String usuario) async {
    final filas = await (await bd).query(
      'usuario',
      where: 'usuario = ?',
      whereArgs: [usuario],
      limit: 1,
    );
    return filas.isEmpty ? null : Usuario.fromMap(filas.first);
  }

  Future<int> actualizarUsuario(Usuario u) async => (await bd).update(
    'usuario',
    u.toMap(),
    where: 'idUsuario = ?',
    whereArgs: [u.idUsuario],
  );

  Future<Usuario?> obtenerUsuario(int idUsuario) async {
    final filas = await (await bd).query(
      'usuario',
      where: 'idUsuario = ?',
      whereArgs: [idUsuario],
      limit: 1,
    );
    return filas.isEmpty ? null : Usuario.fromMap(filas.first);
  }

  // ---------------------------------------------------------------- Materias

  /// Materias de la gestión indicada.
  Future<List<Materia>> obtenerMaterias(int idUsuario, int idGestion) async {
    final filas = await (await bd).query(
      'materia',
      where: 'idUsuario = ? AND idGestion = ?',
      whereArgs: [idUsuario, idGestion],
      orderBy: 'nombre COLLATE NOCASE',
    );
    return filas.map(Materia.fromMap).toList();
  }

  Future<int> insertarMateria(Materia m) async =>
      (await bd).insert('materia', m.toMap()..remove('idMateria'));

  Future<int> actualizarMateria(Materia m) async => (await bd).update(
    'materia',
    m.toMap(),
    where: 'idMateria = ?',
    whereArgs: [m.idMateria],
  );

  /// También elimina sus tareas, horarios y material (ON DELETE CASCADE).
  Future<int> eliminarMateria(int idMateria) async => (await bd).delete(
    'materia',
    where: 'idMateria = ?',
    whereArgs: [idMateria],
  );

  // ------------------------------------------------------------------ Tareas

  /// Tareas del usuario, opcionalmente solo de una materia.
  Future<List<Tarea>> obtenerTareas(
    int idUsuario,
    int idGestion, {
    int? idMateria,
  }) async {
    final filas = await (await bd).rawQuery(
      '''
      SELECT t.*, m.nombre AS nombreMateria, m.color AS colorMateria
      FROM tarea t
      JOIN materia m ON m.idMateria = t.idMateria
      WHERE m.idUsuario = ? AND m.idGestion = ?
        ${idMateria != null ? 'AND t.idMateria = ?' : ''}
      ORDER BY t.fechaEntrega, t.titulo
    ''',
      [idUsuario, idGestion, ?idMateria],
    );
    return filas.map(Tarea.fromMap).toList();
  }

  Future<int> insertarTarea(Tarea t) async =>
      (await bd).insert('tarea', t.toMap()..remove('idTarea'));

  Future<int> actualizarTarea(Tarea t) async => (await bd).update(
    'tarea',
    t.toMap(),
    where: 'idTarea = ?',
    whereArgs: [t.idTarea],
  );

  Future<int> actualizarEstadoTarea(int idTarea, EstadoTarea estado) async =>
      (await bd).update(
        'tarea',
        {'estado': estado.valor},
        where: 'idTarea = ?',
        whereArgs: [idTarea],
      );

  Future<int> eliminarTarea(int idTarea) async =>
      (await bd).delete('tarea', where: 'idTarea = ?', whereArgs: [idTarea]);

  // ---------------------------------------------------------------- Horarios

  /// Horario general: une las clases de todas las materias del usuario
  /// (Semana 3, sección 9.2).
  Future<List<Horario>> obtenerHorarioGeneral(
    int idUsuario,
    int idGestion,
  ) async {
    final filas = await (await bd).rawQuery(
      '''
      SELECT h.*, m.nombre AS nombreMateria, m.color AS colorMateria
      FROM horario h
      JOIN materia m ON m.idMateria = h.idMateria
      WHERE m.idUsuario = ? AND m.idGestion = ?
      ORDER BY h.dia, h.horaInicio
    ''',
      [idUsuario, idGestion],
    );
    return filas.map(Horario.fromMap).toList();
  }

  Future<List<Horario>> obtenerHorariosMateria(int idMateria) async {
    final filas = await (await bd).rawQuery(
      '''
      SELECT h.*, m.nombre AS nombreMateria, m.color AS colorMateria
      FROM horario h
      JOIN materia m ON m.idMateria = h.idMateria
      WHERE h.idMateria = ?
      ORDER BY h.dia, h.horaInicio
    ''',
      [idMateria],
    );
    return filas.map(Horario.fromMap).toList();
  }

  Future<int> insertarHorario(Horario h) async =>
      (await bd).insert('horario', h.toMap()..remove('idHorario'));

  Future<int> actualizarHorario(Horario h) async => (await bd).update(
    'horario',
    h.toMap(),
    where: 'idHorario = ?',
    whereArgs: [h.idHorario],
  );

  Future<int> eliminarHorario(int idHorario) async => (await bd).delete(
    'horario',
    where: 'idHorario = ?',
    whereArgs: [idHorario],
  );

  // ---------------------------------------------------------------- Material

  /// Material de todas las materias del usuario, del más reciente al más antiguo.
  Future<List<MaterialAcademico>> obtenerMaterialesUsuario(
    int idUsuario,
    int idGestion,
  ) async {
    final filas = await (await bd).rawQuery(
      '''
      SELECT mt.*
      FROM material mt
      JOIN materia m ON m.idMateria = mt.idMateria
      WHERE m.idUsuario = ? AND m.idGestion = ?
      ORDER BY mt.fecha DESC
    ''',
      [idUsuario, idGestion],
    );
    return filas.map(MaterialAcademico.fromMap).toList();
  }

  Future<int> insertarMaterial(MaterialAcademico m) async =>
      (await bd).insert('material', m.toMap()..remove('idMaterial'));

  Future<int> actualizarMaterial(MaterialAcademico m) async =>
      (await bd).update(
        'material',
        m.toMap(),
        where: 'idMaterial = ?',
        whereArgs: [m.idMaterial],
      );

  Future<int> eliminarMaterial(int idMaterial) async => (await bd).delete(
    'material',
    where: 'idMaterial = ?',
    whereArgs: [idMaterial],
  );
}
