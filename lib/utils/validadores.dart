// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/utils/validadores.dart
// Función  : Validaciones de los formularios (RNF05).
// ============================================================

/// Validaciones de formularios (RNF05).
class Validadores {
  static final _regexCorreo = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? nombre(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu nombre';
    if (texto.length < 3) return 'El nombre es muy corto';
    return null;
  }

  static String? correo(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa tu correo';
    if (!_regexCorreo.hasMatch(texto)) return 'Correo no válido';
    return null;
  }

  static final _regexUsuario = RegExp(r'^[a-zA-Z0-9._]+$');

  /// Nombre de usuario: 4 a 20 caracteres, letras, números, punto o guion bajo.
  static String? nombreUsuario(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa un nombre de usuario';
    if (texto.length < 4) return 'Debe tener al menos 4 caracteres';
    if (texto.length > 20) return 'Debe tener como máximo 20 caracteres';
    if (!_regexUsuario.hasMatch(texto)) {
      return 'Solo letras, números, punto o guion bajo (sin espacios)';
    }
    return null;
  }

  /// Campo de inicio de sesión: acepta el usuario o el correo.
  static String? usuarioOCorreo(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario o correo' : null;

  static String? respuestaSeguridad(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa la respuesta';
    if (texto.length < 2) return 'La respuesta es muy corta';
    return null;
  }

  static String? contrasena(String? v) {
    final texto = v ?? '';
    if (texto.length < 6) return 'Debe tener al menos 6 caracteres';
    if (!texto.contains(RegExp(r'[A-Za-z]')) ||
        !texto.contains(RegExp(r'\d'))) {
      return 'Debe tener letras y números';
    }
    return null;
  }

  static String? requerido(String? v, String campo) =>
      (v == null || v.trim().isEmpty) ? 'Ingresa $campo' : null;

  static String? tituloTarea(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa el título de la tarea';
    if (texto.length < 3) return 'El título debe tener al menos 3 caracteres';
    return null;
  }

  static String? nombreMaterial(String? v) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return 'Ingresa un nombre para la fotografía';
    if (texto.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    return null;
  }

  /// La fecha de entrega de una tarea nueva no puede estar en el pasado.
  static String? fechaEntrega(DateTime? fecha, {required bool esNueva}) {
    if (fecha == null) return 'Elige la fecha de entrega';
    final hoy = DateTime.now();
    if (esNueva && fecha.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
      return 'La fecha de entrega no puede ser anterior a hoy';
    }
    return null;
  }

  /// Horas en formato "HH:mm". La hora de fin debe ser mayor que la de inicio.
  static String? rangoHoras(String? inicio, String? fin) {
    if (inicio == null) return 'Elige la hora de inicio';
    if (fin == null) return 'Elige la hora de fin';
    int minutos(String h) =>
        int.parse(h.substring(0, 2)) * 60 + int.parse(h.substring(3));
    if (minutos(fin) <= minutos(inicio)) {
      return 'La hora de fin debe ser mayor que la hora de inicio';
    }
    return null;
  }
}
