// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/services/auth_service.dart
// Función  : Registro, inicio de sesión, sesión guardada, recuperación de contraseña y pregunta de seguridad.
// ============================================================

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/usuario.dart';

/// Autenticación local: registro, inicio de sesión, sesión guardada, cierre
/// y recuperación de contraseña con pregunta de seguridad (sin internet).
///
/// La contraseña nunca se guarda en texto plano: se guarda el hash SHA-256
/// de (salt + contraseña), con un salt aleatorio por usuario (RNF08).
/// La respuesta de seguridad se guarda de la misma forma.
class AuthService {
  AuthService._();
  static final AuthService instancia = AuthService._();

  static const _claveSesion = 'idUsuarioSesion';
  final _db = DatabaseHelper.instancia;

  /// Preguntas de seguridad que puede elegir el estudiante.
  static const preguntas = [
    '¿Cuál es el nombre de tu primera mascota?',
    '¿En qué ciudad naciste?',
    '¿Cómo se llama el colegio donde saliste bachiller?',
    '¿Cuál es tu comida favorita?',
    '¿Cómo se llama tu mejor amigo de la infancia?',
  ];

  Usuario? _usuarioActual;
  Usuario get usuarioActual => _usuarioActual!;
  bool get haySesion => _usuarioActual != null;

  /// Recupera la sesión guardada al abrir la aplicación.
  /// Aun así, la huella se pide siempre antes de entrar (BloqueoScreen).
  Future<bool> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_claveSesion);
    if (id == null) return false;
    _usuarioActual = await _db.obtenerUsuario(id);
    if (_usuarioActual == null) await prefs.remove(_claveSesion);
    return haySesion;
  }

  /// Devuelve null si todo salió bien, o un mensaje de error.
  Future<String?> registrar({
    required String nombre,
    required String usuario,
    required String correo,
    required String contrasena,
    required String pregunta,
    required String respuesta,
  }) async {
    final correoNormalizado = correo.trim().toLowerCase();
    final usuarioNormalizado = usuario.trim().toLowerCase();
    if (await _db.buscarUsuarioPorNombreUsuario(usuarioNormalizado) != null) {
      return 'Ese nombre de usuario ya está en uso';
    }
    if (await _db.buscarUsuarioPorCorreo(correoNormalizado) != null) {
      return 'Ya existe una cuenta con ese correo';
    }
    final salt = _generarSalt();
    final nuevo = Usuario(
      nombre: nombre.trim(),
      usuario: usuarioNormalizado,
      correo: correoNormalizado,
      contrasenaHash: _hash(contrasena, salt),
      salt: salt,
      preguntaSeguridad: pregunta,
      respuestaHash: _hash(_normalizar(respuesta), salt),
      fechaRegistro: DateTime.now(),
    );
    final id = await _db.insertarUsuario(nuevo);
    await _guardarSesion(id);
    return null;
  }

  /// Valida las credenciales (RF03) con el usuario o el correo.
  /// Devuelve null o un mensaje de error.
  Future<String?> iniciarSesion(
    String usuarioOCorreo,
    String contrasena,
  ) async {
    final usuario = await _buscar(usuarioOCorreo);
    // Mismo mensaje en ambos casos para no revelar qué cuentas existen.
    if (usuario == null ||
        _hash(contrasena, usuario.salt) != usuario.contrasenaHash) {
      return 'Usuario o contraseña incorrectos';
    }
    await _guardarSesion(usuario.idUsuario!);
    return null;
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveSesion);
    _usuarioActual = null;
  }

  // ---------------------------------------------- Recuperar la contraseña

  /// Paso 1: busca la cuenta por correo y devuelve su pregunta de seguridad.
  /// Lanza [AuthException] si no se puede recuperar.
  Future<String> preguntaDe(String correo) async {
    final usuario = await _db.buscarUsuarioPorCorreo(
      correo.trim().toLowerCase(),
    );
    if (usuario == null) {
      throw AuthException('No hay ninguna cuenta con ese correo');
    }
    if (!usuario.tienePreguntaSeguridad) {
      throw AuthException(
        'Esta cuenta todavía no tiene pregunta de seguridad, '
        'por eso no se puede recuperar.',
      );
    }
    return usuario.preguntaSeguridad!;
  }

  /// Paso 2: comprueba la respuesta. Devuelve null o un mensaje de error.
  Future<String?> verificarRespuesta(String correo, String respuesta) async {
    final usuario = await _db.buscarUsuarioPorCorreo(
      correo.trim().toLowerCase(),
    );
    if (usuario == null ||
        !usuario.tienePreguntaSeguridad ||
        _hash(_normalizar(respuesta), usuario.salt) != usuario.respuestaHash) {
      return 'La respuesta no es correcta';
    }
    return null;
  }

  /// Paso 3 (después de la huella): guarda la contraseña nueva.
  Future<String?> restablecerContrasena({
    required String correo,
    required String respuesta,
    required String nueva,
  }) async {
    final error = await verificarRespuesta(correo, respuesta);
    if (error != null) return error;
    final usuario = (await _db.buscarUsuarioPorCorreo(
      correo.trim().toLowerCase(),
    ))!;
    // Salt nuevo: se vuelven a calcular los dos hashes.
    final salt = _generarSalt();
    await _db.actualizarUsuario(
      _copiar(
        usuario,
        salt: salt,
        contrasenaHash: _hash(nueva, salt),
        respuestaHash: _hash(_normalizar(respuesta), salt),
      ),
    );
    return null;
  }

  // ---------------------------------------- Completar la cuenta (obligatorio)

  /// Cuentas creadas antes de la Semana 8 no tienen pregunta de seguridad;
  /// se pide al entrar. Devuelve null o un mensaje de error.
  Future<String?> completarSeguridad({
    required String usuario,
    required String pregunta,
    required String respuesta,
  }) async {
    final actual = usuarioActual;
    final usuarioNormalizado = usuario.trim().toLowerCase();
    final otro = await _db.buscarUsuarioPorNombreUsuario(usuarioNormalizado);
    if (otro != null && otro.idUsuario != actual.idUsuario) {
      return 'Ese nombre de usuario ya está en uso';
    }
    await _db.actualizarUsuario(
      _copiar(
        actual,
        usuario: usuarioNormalizado,
        pregunta: pregunta,
        respuestaHash: _hash(_normalizar(respuesta), actual.salt),
      ),
    );
    _usuarioActual = await _db.obtenerUsuario(actual.idUsuario!);
    return null;
  }

  // ------------------------------------------------------------ Auxiliares

  Future<Usuario?> _buscar(String usuarioOCorreo) {
    final texto = usuarioOCorreo.trim().toLowerCase();
    return texto.contains('@')
        ? _db.buscarUsuarioPorCorreo(texto)
        : _db.buscarUsuarioPorNombreUsuario(texto);
  }

  Usuario _copiar(
    Usuario u, {
    String? usuario,
    String? salt,
    String? contrasenaHash,
    String? pregunta,
    String? respuestaHash,
  }) => Usuario(
    idUsuario: u.idUsuario,
    nombre: u.nombre,
    usuario: usuario ?? u.usuario,
    correo: u.correo,
    contrasenaHash: contrasenaHash ?? u.contrasenaHash,
    salt: salt ?? u.salt,
    preguntaSeguridad: pregunta ?? u.preguntaSeguridad,
    respuestaHash: respuestaHash ?? u.respuestaHash,
    fechaRegistro: u.fechaRegistro,
  );

  Future<void> _guardarSesion(int idUsuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveSesion, idUsuario);
    _usuarioActual = await _db.obtenerUsuario(idUsuario);
  }

  /// "  Cochabamba " y "cochabamba" son la misma respuesta.
  String _normalizar(String respuesta) =>
      respuesta.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String _generarSalt() {
    final aleatorio = Random.secure();
    return base64Url.encode(
      List<int>.generate(16, (_) => aleatorio.nextInt(256)),
    );
  }

  String _hash(String texto, String salt) =>
      sha256.convert(utf8.encode('$salt$texto')).toString();
}

class AuthException implements Exception {
  AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}
