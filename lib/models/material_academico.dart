// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/models/material_academico.dart
// Función  : Modelo MaterialAcademico: datos y ruta de cada fotografía y su tipo.
// ============================================================

/// Tipo de contenido del material (Semana 3, sección 8.1).
enum TipoMaterial {
  apunte('apunte', 'Apunte'),
  ejercicio('ejercicio', 'Ejercicio'),
  pizarra('pizarra', 'Foto de pizarra'),
  otro('otro', 'Otro');

  const TipoMaterial(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoMaterial desdeValor(String valor) =>
      TipoMaterial.values.firstWhere((t) => t.valor == valor);
}

/// Se llama MaterialAcademico para no confundirse con Material de Flutter.
class MaterialAcademico {
  /// Formatos permitidos en la versión 1 (Semana 3, sección 8.2).
  static const formatosPermitidos = ['jpg', 'jpeg', 'png'];
  static const tamanoMaximoKB = 10 * 1024;

  final int? idMaterial;
  final int idMateria;
  final String nombre;
  final TipoMaterial tipo;
  final String formato;
  final String rutaArchivo;
  final int tamanoKB;
  final DateTime fecha;

  MaterialAcademico({
    this.idMaterial,
    required this.idMateria,
    required this.nombre,
    required this.tipo,
    required this.formato,
    required this.rutaArchivo,
    required this.tamanoKB,
    required this.fecha,
  });

  Map<String, Object?> toMap() => {
    'idMaterial': idMaterial,
    'idMateria': idMateria,
    'nombre': nombre,
    'tipo': tipo.valor,
    'formato': formato,
    'rutaArchivo': rutaArchivo,
    'tamanoKB': tamanoKB,
    'fecha': fecha.toIso8601String(),
  };

  factory MaterialAcademico.fromMap(Map<String, Object?> m) =>
      MaterialAcademico(
        idMaterial: m['idMaterial'] as int,
        idMateria: m['idMateria'] as int,
        nombre: m['nombre'] as String,
        tipo: TipoMaterial.desdeValor(m['tipo'] as String),
        formato: m['formato'] as String,
        rutaArchivo: m['rutaArchivo'] as String,
        tamanoKB: m['tamanoKB'] as int,
        fecha: DateTime.parse(m['fecha'] as String),
      );
}
