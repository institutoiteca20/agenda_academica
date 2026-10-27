// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/utils/formato.dart
// Función  : Formato de fechas, horas, duraciones y tamaños.
// ============================================================

/// Funciones para dar formato a fechas y horas.
class Formato {
  static const dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const meses = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// 1 = lunes … 7 = domingo (igual que DateTime.weekday).
  static String nombreDia(int dia) => dias[dia - 1];

  static String _dos(int n) => n.toString().padLeft(2, '0');

  /// 30/09/2026
  static String fecha(DateTime f) =>
      '${_dos(f.day)}/${_dos(f.month)}/${f.year}';

  /// Martes, 30 de septiembre
  static String fechaLarga(DateTime f) =>
      '${nombreDia(f.weekday)}, ${f.day} de ${meses[f.month - 1]}';

  /// 2026-09-30 (formato guardado en SQLite)
  static String fechaIso(DateTime f) =>
      '${f.year}-${_dos(f.month)}-${_dos(f.day)}';

  /// "08:30" → 510 minutos
  static int aMinutos(String hora) {
    final partes = hora.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  /// (1, 'clase') → "1 clase"; (3, 'clase') → "3 clases"
  static String cantidad(int n, String palabra) =>
      '$n ${n == 1 ? palabra : '${palabra}s'}';

  /// 845 → "845 KB"; 2560 → "2.5 MB"
  static String tamano(int kb) =>
      kb < 1024 ? '$kb KB' : '${(kb / 1024).toStringAsFixed(1)} MB';

  /// 450 → "7 h 30 min"
  static String duracion(int minutos) {
    final h = minutos ~/ 60;
    final m = minutos % 60;
    if (h == 0) return '$m min';
    if (m == 0) return '$h h';
    return '$h h $m min';
  }

  /// "Hoy", "Mañana" o "En 27 días".
  static String dentroDe(DateTime fecha) {
    final hoy = DateTime.now();
    final dias = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Mañana';
    return 'En $dias días';
  }

  /// Texto relativo para la fecha de entrega de una tarea.
  static String entrega(DateTime fechaEntrega) {
    final hoy = DateTime.now();
    final dias = DateTime(
      fechaEntrega.year,
      fechaEntrega.month,
      fechaEntrega.day,
    ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    if (dias == 0) return 'Hoy';
    if (dias == 1) return 'Mañana';
    if (dias == -1) return 'Ayer';
    if (dias > 1 && dias < 7) return 'En $dias días';
    // Del año actual se omite el año para que quepa en pantallas pequeñas.
    if (fechaEntrega.year == hoy.year) {
      return '${_dos(fechaEntrega.day)}/${_dos(fechaEntrega.month)}';
    }
    return fecha(fechaEntrega);
  }
}
