// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/models/gestion.dart
// Función  : Modelo Gestion: periodo académico (por ejemplo "Gestión 2026") que agrupa materias.
// ============================================================

/// Periodo académico. Al iniciar una nueva gestión, las materias de las
/// gestiones anteriores no se borran: quedan guardadas y se pueden volver a ver.
class Gestion {
  final int? idGestion;
  final int idUsuario;
  final String nombre;

  /// Solo una gestión por usuario está activa: es la que muestra la app.
  final bool activa;
  final DateTime fechaCreacion;

  Gestion({
    this.idGestion,
    required this.idUsuario,
    required this.nombre,
    this.activa = false,
    required this.fechaCreacion,
  });

  Map<String, Object?> toMap() => {
    'idGestion': idGestion,
    'idUsuario': idUsuario,
    'nombre': nombre,
    'activa': activa ? 1 : 0,
    'fechaCreacion': fechaCreacion.toIso8601String(),
  };

  factory Gestion.fromMap(Map<String, Object?> m) => Gestion(
    idGestion: m['idGestion'] as int,
    idUsuario: m['idUsuario'] as int,
    nombre: m['nombre'] as String,
    activa: (m['activa'] as int) == 1,
    fechaCreacion: DateTime.parse(m['fechaCreacion'] as String),
  );
}
