// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/models/usuario.dart
// Función  : Modelo Usuario: datos de la cuenta, usuario, hashes de contraseña y respuesta de seguridad.
// ============================================================

class Usuario {
  final int? idUsuario;
  final String nombre;

  /// Nombre de usuario para iniciar sesión (Semana 8). Puede ser null solo en
  /// cuentas creadas antes de la versión 2 de la base de datos.
  final String? usuario;
  final String correo;
  final String contrasenaHash;
  final String salt;

  /// Pregunta de seguridad para recuperar la contraseña sin internet.
  final String? preguntaSeguridad;
  final String? respuestaHash;
  final DateTime fechaRegistro;

  Usuario({
    this.idUsuario,
    required this.nombre,
    this.usuario,
    required this.correo,
    required this.contrasenaHash,
    required this.salt,
    this.preguntaSeguridad,
    this.respuestaHash,
    required this.fechaRegistro,
  });

  bool get tienePreguntaSeguridad =>
      preguntaSeguridad != null && respuestaHash != null;

  Map<String, Object?> toMap() => {
    'idUsuario': idUsuario,
    'nombre': nombre,
    'usuario': usuario,
    'correo': correo,
    'contrasenaHash': contrasenaHash,
    'salt': salt,
    'preguntaSeguridad': preguntaSeguridad,
    'respuestaHash': respuestaHash,
    'fechaRegistro': fechaRegistro.toIso8601String(),
  };

  factory Usuario.fromMap(Map<String, Object?> m) => Usuario(
    idUsuario: m['idUsuario'] as int,
    nombre: m['nombre'] as String,
    usuario: m['usuario'] as String?,
    correo: m['correo'] as String,
    contrasenaHash: m['contrasenaHash'] as String,
    salt: m['salt'] as String,
    preguntaSeguridad: m['preguntaSeguridad'] as String?,
    respuestaHash: m['respuestaHash'] as String?,
    fechaRegistro: DateTime.parse(m['fechaRegistro'] as String),
  );

  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
