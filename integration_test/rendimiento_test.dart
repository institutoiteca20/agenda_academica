// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : integration_test/rendimiento_test.dart
// Función  : Mide el rendimiento: carga de datos, escritura en SQLite, fluidez al desplazar listas y respaldo.
// ============================================================

// Se ejecuta en modo profile (como la app real, sin herramientas de depuración):
//   flutter drive --profile --driver=test_driver/integration_test.dart \
//     --target=integration_test/rendimiento_test.dart -d <dispositivo>
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:agenda_academica/database/database_helper.dart';
import 'package:agenda_academica/database/db_factory.dart';
import 'package:agenda_academica/main.dart';
import 'package:agenda_academica/models/tarea.dart';
import 'package:agenda_academica/services/auth_service.dart';
import 'package:agenda_academica/services/biometria_service.dart';
import 'package:agenda_academica/services/datos_ejemplo_service.dart';
import 'package:agenda_academica/services/respaldo_service.dart';
import 'package:agenda_academica/state/agenda_state.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configurarBaseDatos();
  final resultados = <String, Object>{};

  void medir(String nombre, Object valor) {
    resultados[nombre] = valor;
    // ignore: avoid_print
    print('RENDIMIENTO $nombre = $valor');
  }

  testWidgets('Rendimiento de la aplicación', (tester) async {
    BiometriaService.instancia.simulacion = (_) async =>
        ResultadoHuella.correcta;
    final ms = DateTime.now().millisecondsSinceEpoch;
    await AuthService.instancia.registrar(
      nombre: 'Prueba Rendimiento',
      usuario: 'rend$ms',
      correo: 'rend$ms@agenda.test',
      contrasena: 'prueba123',
      pregunta: AuthService.preguntas.first,
      respuesta: 'Firulais',
    );
    final estado = AgendaState.instancia;

    // 1) Carga inicial de datos (4 materias, 5 clases, 5 tareas).
    var reloj = Stopwatch()..start();
    await estado.cargar();
    await DatosEjemploService.cargar(
      AuthService.instancia.usuarioActual.idUsuario!,
      estado.gestion!.idGestion!,
    );
    await estado.cargar();
    medir('carga_datos_ejemplo_ms', reloj.elapsedMilliseconds);

    // 2) Escritura en SQLite: 200 tareas.
    final idMateria = estado.materias.first.idMateria!;
    reloj = Stopwatch()..start();
    final db = DatabaseHelper.instancia;
    final hoy = DateTime.now();
    for (var i = 0; i < 200; i++) {
      await db.insertarTarea(
        Tarea(
          idMateria: idMateria,
          titulo: 'Tarea de rendimiento $i',
          fechaEntrega: DateTime(hoy.year, hoy.month, hoy.day + i % 30),
        ),
      );
    }
    medir('insertar_200_tareas_ms', reloj.elapsedMilliseconds);
    medir(
      'promedio_por_tarea_ms',
      (reloj.elapsedMicroseconds / 200 / 1000).toStringAsFixed(2),
    );

    // 3) Lectura: recargar todo con 205 tareas.
    reloj = Stopwatch()..start();
    await estado.cargar();
    medir('recargar_205_tareas_ms', reloj.elapsedMilliseconds);

    // 4) Interfaz: abrir la app y desplazar la lista de 205 tareas.
    await tester.pumpWidget(const AgendaAcademicaApp());
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 20),
    );
    await tester.tap(find.text('Tareas').first);
    await tester.pumpAndSettle();
    final lista = find.byType(Scrollable).last;
    // Se registra el tiempo de cada cuadro (frame) que dibuja Flutter.
    final cuadros = <FrameTiming>[];
    void alRecibir(List<FrameTiming> t) => cuadros.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(alRecibir);
    for (var i = 0; i < 6; i++) {
      await tester.fling(lista, const Offset(0, -600), 2500);
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 6; i++) {
      await tester.fling(lista, const Offset(0, 600), 2500);
      await tester.pumpAndSettle();
    }
    await Future<void>.delayed(const Duration(seconds: 2));
    SchedulerBinding.instance.removeTimingsCallback(alRecibir);
    final totales =
        cuadros.map((c) => c.totalSpan.inMicroseconds / 1000).toList()..sort();
    final construir =
        cuadros.map((c) => c.buildDuration.inMicroseconds / 1000).toList()
          ..sort();
    final dibujar =
        cuadros.map((c) => c.rasterDuration.inMicroseconds / 1000).toList()
          ..sort();
    double prom(List<double> l) =>
        l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
    double p90(List<double> l) =>
        l.isEmpty ? 0 : l[(l.length * 0.9).floor().clamp(0, l.length - 1)];
    medir('cuadros_medidos', cuadros.length);
    medir(
      'cuadro_construccion_promedio_ms',
      prom(construir).toStringAsFixed(2),
    );
    medir('cuadro_dibujo_promedio_ms', prom(dibujar).toStringAsFixed(2));
    medir('cuadro_total_promedio_ms', prom(totales).toStringAsFixed(2));
    medir('cuadro_total_p90_ms', p90(totales).toStringAsFixed(2));
    medir(
      'cuadros_mayores_16ms_porcentaje',
      totales.isEmpty
          ? 0
          : (100 * totales.where((x) => x > 16.7).length / totales.length)
                .toStringAsFixed(1),
    );
    // 5) Respaldo: crear el archivo .zip.
    reloj = Stopwatch()..start();
    final bytes = await RespaldoService.instancia.crearRespaldo();
    medir('crear_respaldo_ms', reloj.elapsedMilliseconds);
    medir('tamano_respaldo_kb', (bytes.length / 1024).round());

    binding.reportData = {...?binding.reportData, 'mediciones': resultados};
  });
}
