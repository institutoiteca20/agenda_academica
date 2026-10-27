// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/database/db_factory.dart
// Función  : Elige la configuración de SQLite según la plataforma (Android o web).
// ============================================================

// Importación condicional: el navegador usa la versión web de SQLite
// y Android usa la versión nativa.
export 'db_factory_stub.dart'
    if (dart.library.js_interop) 'db_factory_web.dart';
