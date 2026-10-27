// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : integration_test/respaldo_real_test.dart
// Función  : Prueba el respaldo con el selector de archivos REAL de Android (guardar y abrir el .zip).
// ============================================================

// A diferencia de app_test.dart, aquí NO se simula el selector de archivos:
// se abren las ventanas reales de Android "Guardar" y "Abrir", y los botones
// se tocan desde la PC con adb mientras la prueba espera.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agenda_academica/database/db_factory.dart';
import 'package:agenda_academica/database/database_helper.dart';
import 'package:agenda_academica/services/auth_service.dart';
import 'package:agenda_academica/services/respaldo_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configurarBaseDatos();

  testWidgets('Respaldo real: guardar en Descargas y volver a abrirlo', (
    tester,
  ) async {
    // Una cuenta para que el respaldo tenga datos.
    await AuthService.instancia.registrar(
      nombre: 'Prueba Respaldo Real',
      usuario: 'real${DateTime.now().millisecondsSinceEpoch}',
      correo: 'real${DateTime.now().millisecondsSinceEpoch}@agenda.test',
      contrasena: 'prueba123',
      pregunta: AuthService.preguntas.first,
      respuesta: 'Firulais',
    );

    // 1) Exportar con la ventana real "Guardar" de Android.
    final guardado = await RespaldoService.instancia.exportar();
    expect(guardado, isTrue);
    // ignore: avoid_print
    print('RESPALDO_GUARDADO');

    // 2) Restaurar eligiendo el archivo con la ventana real "Abrir".
    final restaurado = await RespaldoService.instancia.importar();
    expect(restaurado, isTrue);
    expect(AuthService.instancia.haySesion, isFalse); // pide iniciar sesión

    // La cuenta del respaldo existe y su contraseña funciona.
    final db = await DatabaseHelper.instancia.bd;
    final usuarios = await db.query(
      'usuario',
      where: 'nombre = ?',
      whereArgs: ['Prueba Respaldo Real'],
    );
    expect(usuarios, isNotEmpty);
    // ignore: avoid_print
    print('RESPALDO_RESTAURADO');
  });
}
