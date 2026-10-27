// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : test_driver/integration_test.dart
// Función  : Controlador de flutter drive que guarda las capturas en la PC.
// ============================================================

// Controlador de "flutter drive": guarda en la PC las capturas que toman
// las pruebas de interfaz (integration_test/capturas_test.dart).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (nombre, bytes, [args]) async {
    final archivo = File('capturas/$nombre.png');
    await archivo.parent.create(recursive: true);
    await archivo.writeAsBytes(bytes);
    return true;
  },
);
