// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/state/agenda_state.dart
// Función  : Estado de la aplicación (ChangeNotifier): carga los datos del usuario y avisa a las pantallas.
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import '../models/gestion.dart';
import '../models/horario.dart';
import '../models/material_academico.dart';
import '../models/materia.dart';
import '../models/tarea.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Error con un mensaje que se puede mostrar directamente al usuario.
class AgendaException implements Exception {
  AgendaException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Estado central de la aplicación (gestión del estado).
///
/// Guarda en memoria las materias, tareas y horarios del usuario que inició
/// sesión. Cada operación se guarda primero en SQLite y después se recargan
/// los datos y se avisa a las pantallas con [notifyListeners], así todas las
/// pantallas que usan ListenableBuilder se actualizan solas.
class AgendaState extends ChangeNotifier {
  AgendaState._();
  static final AgendaState instancia = AgendaState._();

  final _db = DatabaseHelper.instancia;

  Gestion? _gestion;
  List<Gestion> _gestiones = [];
  Map<int, int> _materiasPorGestion = {};
  List<Materia> _materias = [];
  List<Tarea> _tareas = [];
  List<Horario> _horarios = [];
  List<MaterialAcademico> _materiales = [];
  bool _cargando = false;
  bool _cargado = false;
  String? _error;

  /// Gestión (periodo académico) que se está mostrando.
  Gestion? get gestion => _gestion;
  List<Gestion> get gestiones => List.unmodifiable(_gestiones);
  int materiasEnGestion(int idGestion) => _materiasPorGestion[idGestion] ?? 0;
  List<Materia> get materias => List.unmodifiable(_materias);
  List<Tarea> get tareas => List.unmodifiable(_tareas);
  List<Horario> get horarios => List.unmodifiable(_horarios);
  List<MaterialAcademico> get materiales => List.unmodifiable(_materiales);
  bool get cargando => _cargando;
  bool get cargado => _cargado;
  String? get error => _error;

  int get _idUsuario => AuthService.instancia.usuarioActual.idUsuario!;

  // ------------------------------------------------------------- Carga

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await _recargar();
      _cargado = true;
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      _error = 'No se pudo cargar tu información.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _recargar() async {
    final id = _idUsuario;
    _gestiones = await _db.obtenerGestiones(id);
    // Cuenta nueva: se crea la primera gestión con el año actual.
    if (_gestiones.isEmpty) {
      await _db.insertarGestionActiva(
        Gestion(
          idUsuario: id,
          nombre: 'Gestión ${DateTime.now().year}',
          fechaCreacion: DateTime.now(),
        ),
      );
      _gestiones = await _db.obtenerGestiones(id);
    }
    _gestion =
        _gestiones.where((g) => g.activa).firstOrNull ?? _gestiones.first;
    final ig = _gestion!.idGestion!;
    _materias = await _db.obtenerMaterias(id, ig);
    _tareas = await _db.obtenerTareas(id, ig);
    _horarios = await _db.obtenerHorarioGeneral(id, ig);
    _materiales = await _db.obtenerMaterialesUsuario(id, ig);
    _materiasPorGestion = await _db.contarMateriasPorGestion(id);
  }

  /// Al cerrar sesión se borran los datos en memoria del usuario anterior.
  void limpiar() {
    _gestion = null;
    _gestiones = [];
    _materiasPorGestion = {};
    _materias = [];
    _tareas = [];
    _horarios = [];
    _materiales = [];
    _cargado = false;
    _error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------- Consultas

  Materia? materia(int idMateria) =>
      _materias.where((m) => m.idMateria == idMateria).firstOrNull;

  List<Tarea> tareasDe(int idMateria) =>
      _tareas.where((t) => t.idMateria == idMateria).toList();

  List<Horario> horariosDe(int idMateria) =>
      _horarios.where((h) => h.idMateria == idMateria).toList();

  List<MaterialAcademico> materialesDe(int idMateria) =>
      _materiales.where((m) => m.idMateria == idMateria).toList();

  /// Tareas no completadas, ordenadas por fecha de entrega.
  List<Tarea> get proximas =>
      _tareas.where((t) => t.estado != EstadoTarea.completada).toList();

  int pendientesDe(int idMateria) => tareasDe(
    idMateria,
  ).where((t) => t.estado != EstadoTarea.completada).length;

  // ------------------------------------------------------------- Materias

  Future<void> guardarMateria(Materia m) async {
    final nombre = m.nombre.trim().toLowerCase();
    final repetida = _materias.any(
      (otra) =>
          otra.idMateria != m.idMateria &&
          otra.nombre.trim().toLowerCase() == nombre,
    );
    if (repetida) {
      throw AgendaException(
        'Ya tienes una materia llamada "${m.nombre.trim()}".',
      );
    }

    await _ejecutar(
      () => m.idMateria == null
          // Una materia nueva pertenece a la gestión activa.
          ? _db.insertarMateria(
              Materia(
                idUsuario: m.idUsuario,
                idGestion: _gestion!.idGestion,
                nombre: m.nombre,
                docente: m.docente,
                descripcion: m.descripcion,
                color: m.color,
              ),
            )
          : _db.actualizarMateria(m),
    );
  }

  // ------------------------------------------------------------- Gestiones

  /// Inicia una nueva gestión (por ejemplo "Gestión 2027"). Las gestiones
  /// anteriores no se borran: se pueden volver a abrir con [cambiarGestion].
  Future<void> nuevaGestion(String nombre) async {
    final limpio = nombre.trim();
    if (_gestiones.any(
      (g) => g.nombre.trim().toLowerCase() == limpio.toLowerCase(),
    )) {
      throw AgendaException('Ya existe una gestión llamada "$limpio".');
    }
    await _ejecutar(
      () => _db.insertarGestionActiva(
        Gestion(
          idUsuario: _idUsuario,
          nombre: limpio,
          fechaCreacion: DateTime.now(),
        ),
      ),
    );
  }

  /// Muestra otra gestión (por ejemplo para consultar una anterior).
  Future<void> cambiarGestion(Gestion g) =>
      _ejecutar(() => _db.activarGestion(_idUsuario, g.idGestion!));

  /// Elimina la materia (y en cascada sus tareas, horarios y material)
  /// y después borra la carpeta con sus fotografías.
  Future<void> eliminarMateria(int idMateria) async {
    await _ejecutar(() => _db.eliminarMateria(idMateria));
    await StorageService.instancia.eliminarCarpetaMateria(idMateria);
  }

  // ------------------------------------------------------------- Tareas

  Future<void> guardarTarea(Tarea t) => _ejecutar(
    () => t.idTarea == null ? _db.insertarTarea(t) : _db.actualizarTarea(t),
  );

  Future<void> eliminarTarea(int idTarea) =>
      _ejecutar(() => _db.eliminarTarea(idTarea));

  Future<void> cambiarEstado(Tarea t, EstadoTarea estado) =>
      _ejecutar(() => _db.actualizarEstadoTarea(t.idTarea!, estado));

  // ------------------------------------------------------------- Horarios

  Future<void> guardarHorario(Horario h) async {
    // Se valida contra las clases de TODAS las materias (Semana 3, sección 9.3).
    final cruce = h.buscarCruce(_horarios);
    if (cruce != null) {
      throw AgendaException(
        'Se cruza con ${cruce.nombreMateria} (${cruce.horaInicio} – ${cruce.horaFin}).',
      );
    }
    await _ejecutar(
      () => h.idHorario == null
          ? _db.insertarHorario(h)
          : _db.actualizarHorario(h),
    );
  }

  Future<void> eliminarHorario(int idHorario) =>
      _ejecutar(() => _db.eliminarHorario(idHorario));

  // ------------------------------------------------------------- Material

  /// Registra una fotografía: valida el archivo, lo copia a la carpeta de la
  /// materia y guarda sus datos en SQLite. Si SQLite falla, se borra el
  /// archivo copiado para no dejar archivos sueltos.
  Future<void> registrarMaterial({
    required XFile imagen,
    required int idMateria,
    required String nombre,
    required TipoMaterial tipo,
  }) async {
    final storage = StorageService.instancia;
    final datos = await storage.validar(imagen);
    final ruta = await storage.guardar(
      imagen,
      idMateria: idMateria,
      tipo: tipo,
      formato: datos.formato,
    );
    try {
      await _ejecutar(
        () => _db.insertarMaterial(
          MaterialAcademico(
            idMateria: idMateria,
            nombre: nombre,
            tipo: tipo,
            formato: datos.formato,
            rutaArchivo: ruta,
            tamanoKB: datos.tamanoKB,
            fecha: DateTime.now(),
          ),
        ),
      );
    } catch (_) {
      await storage.eliminarArchivo(ruta);
      rethrow;
    }
  }

  /// Actualiza el nombre o el tipo de una fotografía.
  Future<void> actualizarMaterial(MaterialAcademico m) =>
      _ejecutar(() => _db.actualizarMaterial(m));

  /// Elimina el registro y el archivo de la fotografía.
  Future<void> eliminarMaterial(MaterialAcademico m) async {
    await _ejecutar(() => _db.eliminarMaterial(m.idMaterial!));
    await StorageService.instancia.eliminarArchivo(m.rutaArchivo);
  }

  // ------------------------------------------------------------- Auxiliar

  /// Ejecuta una operación en SQLite, recarga los datos y avisa a las pantallas.
  /// Cualquier error de base de datos se convierte en un mensaje entendible.
  Future<void> _ejecutar(Future<Object?> Function() operacion) async {
    try {
      await operacion();
      await _recargar();
    } on AgendaException {
      rethrow;
    } catch (e) {
      debugPrint('Error de base de datos: $e');
      throw AgendaException(
        'No se pudo guardar el cambio. Inténtalo de nuevo.',
      );
    } finally {
      notifyListeners();
    }
  }
}
