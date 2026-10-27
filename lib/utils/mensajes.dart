// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/utils/mensajes.dart
// Función  : Mensajes de éxito o error y diálogos de confirmación.
// ============================================================

import 'package:flutter/material.dart';

import '../state/agenda_state.dart';

/// Mensajes y controles comunes: avisos de éxito o error y confirmaciones.
class Mensajes {
  static const _verde = Color(0xFF2E7D32);
  static const _rojo = Color(0xFFC62828);

  static void _mostrar(
    ScaffoldMessengerState messenger,
    String texto,
    bool esError,
  ) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                esError ? Icons.error_outline : Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(texto)),
            ],
          ),
          backgroundColor: esError ? _rojo : _verde,
          duration: Duration(seconds: esError ? 4 : 2),
        ),
      );
  }

  static void exito(BuildContext context, String texto) =>
      _mostrar(ScaffoldMessenger.of(context), texto, false);

  static void error(BuildContext context, String texto) =>
      _mostrar(ScaffoldMessenger.of(context), texto, true);

  /// Ejecuta una acción del estado y muestra el resultado.
  /// Devuelve true si terminó sin errores.
  ///
  /// El ScaffoldMessenger se obtiene antes de la operación, para que el
  /// mensaje se vea aunque la pantalla que lo pidió ya se haya cerrado.
  static Future<bool> ejecutar(
    BuildContext context,
    Future<void> Function() accion, {
    String? exito,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await accion();
      if (exito != null) _mostrar(messenger, exito, false);
      return true;
    } on AgendaException catch (e) {
      _mostrar(messenger, e.mensaje, true);
    } catch (_) {
      _mostrar(
        messenger,
        'Ocurrió un error inesperado. Inténtalo de nuevo.',
        true,
      );
    }
    return false;
  }

  /// Diálogo de confirmación antes de una acción irreversible.
  static Future<bool> confirmar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String accion = 'Eliminar',
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(accion),
          ),
        ],
      ),
    );
    return respuesta == true;
  }

  /// Pregunta antes de salir de un formulario con cambios sin guardar.
  static Future<bool> descartarCambios(BuildContext context) => confirmar(
    context,
    titulo: '¿Descartar cambios?',
    mensaje: 'Tienes cambios sin guardar. Si sales ahora se perderán.',
    accion: 'Descartar',
  );
}
