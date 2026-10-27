// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/database/db_factory_web.dart
// Función  : Configuración de SQLite para la versión web (WebAssembly).
// ============================================================

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: SQLite se ejecuta con WebAssembly (web/sqlite3.wasm).
void configurarBaseDatos() {
  databaseFactory = databaseFactoryFfiWeb;
}
