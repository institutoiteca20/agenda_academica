// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : integration_test/capturas_test.dart
// Función  : Recorre las pantallas y guarda capturas para las pruebas de interfaz.
// ============================================================

// Pruebas de interfaz de las Semanas 7 y 8: recorre las pantallas principales y
// guarda una captura de cada una. Se ejecuta con distintos tamaños de
// pantalla para comprobar que todo se ve y nada se desborda.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/capturas_test.dart \
//     --dart-define=TAMANO=normal -d <dispositivo>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:agenda_academica/database/db_factory.dart';
import 'package:agenda_academica/main.dart';
import 'package:agenda_academica/services/auth_service.dart';
import 'package:agenda_academica/services/biometria_service.dart';
import 'package:agenda_academica/services/storage_service.dart';
import 'package:agenda_academica/utils/rutas.dart';

const _tamano = String.fromEnvironment('TAMANO', defaultValue: 'normal');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configurarBaseDatos();

  // La foto de ejemplo se dibuja antes de la prueba: toImage necesita tiempo
  // real y dentro de testWidgets el reloj es simulado.
  late String foto;
  setUpAll(() async => foto = await _crearFotoApunte());

  testWidgets('Capturas de las pantallas principales ($_tamano)', (
    tester,
  ) async {
    await AuthService.instancia.cerrarSesion();
    // El sensor de huella se simula: primero falla para capturar el aviso.
    var huella = ResultadoHuella.cancelada;
    BiometriaService.instancia.simulacion = (_) async => huella;
    StorageService.instancia.simulacion = (_) async => XFile(foto);
    await binding.convertFlutterSurfaceToImage();

    // Espera con límite: si algo queda girando, la prueba falla en 20 s.
    Future<void> esperar() => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 20),
    );

    Future<void> captura(String nombre) async {
      debugPrint('Captura: $nombre');
      await esperar();
      await binding.takeScreenshot('${_tamano}_$nombre');
    }

    Future<void> tocar(Finder f) async {
      // Cierra el teclado para que no tape el botón.
      FocusManager.instance.primaryFocus?.unfocus();
      await esperar();
      await tester.ensureVisible(f);
      await esperar();
      await tester.tap(f, warnIfMissed: false);
      await esperar();
    }

    // Vuelve a la pantalla anterior como el botón Atrás del teléfono.
    Future<void> volver() async {
      await tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .maybePop();
      await tester.pumpAndSettle();
    }

    Finder campo(String etiqueta) =>
        find.widgetWithText(TextFormField, etiqueta);

    await tester.pumpWidget(const AgendaAcademicaApp());
    await tester.pumpAndSettle();
    await captura('01_login');

    await tocar(find.text('¿Olvidaste tu contraseña?'));
    await captura('14_recuperar');
    await volver();

    await tocar(find.text('Regístrate'));
    await captura('02_registro');
    final ms = DateTime.now().millisecondsSinceEpoch;
    await tester.enterText(campo('Nombre completo'), 'Reyshell Yana');
    await tester.enterText(campo('Nombre de usuario'), 'cap$ms');
    await tester.enterText(
      campo('Correo electrónico'),
      'capturas$ms@agenda.test',
    );
    await tester.enterText(campo('Contraseña'), 'prueba123');
    await tester.enterText(campo('Confirmar contraseña'), 'prueba123');
    await tocar(find.text('Pregunta de seguridad'));
    await tocar(find.text('¿En qué ciudad naciste?').last);
    await tester.enterText(campo('Respuesta'), 'Cochabamba');
    await captura('02b_registro_lleno');
    await tocar(find.widgetWithText(FilledButton, 'Crear cuenta'));

    // Huella obligatoria: si falla, no se entra.
    await captura('13_bloqueo_huella');
    huella = ResultadoHuella.correcta;
    await tocar(find.text('Usar huella'));

    await tocar(find.text('Perfil'));
    await tocar(find.text('Cargar datos de ejemplo'));
    await captura('03_perfil');

    // Semana 8: gestiones académicas y respaldo para cambio de celular.
    await tocar(find.text('Gestión académica'));
    await tocar(find.widgetWithText(FloatingActionButton, 'Nueva gestión'));
    await captura('21_nueva_gestion');
    await tocar(find.widgetWithText(FilledButton, 'Iniciar'));
    await captura('20_gestiones');
    await tocar(find.text('Gestión ${DateTime.now().year}'));
    await tocar(find.widgetWithText(FilledButton, 'Abrir'));
    await volver();
    await tocar(find.text('Respaldo y cambio de celular'));
    await captura('22_respaldo');
    await volver();

    await tocar(find.text('Inicio'));
    await captura('04_inicio');

    // Semana 8: fotos desde Inicio.
    await tocar(find.text('Fotos'));
    await captura('15_fotos');
    await tocar(find.widgetWithText(FloatingActionButton, 'Foto'));
    await captura('16_fotos_origen');
    await tocar(find.text('Elegir de la galería'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre *'),
      'Derivadas - clase 5',
    );
    await tocar(find.text('Materia *'));
    await tocar(find.text('Matemáticas').last);
    await captura('18_form_foto');
    await tocar(find.widgetWithText(FilledButton, 'Guardar'));
    await captura('19_fotos_con_foto');
    await volver(); // vuelve a Inicio

    await tocar(find.text('Horario'));
    await captura('05_horario_general');

    await tocar(find.widgetWithText(FloatingActionButton, 'Clase'));
    await captura('06_form_clase');
    await tocar(find.text('Inicio *'));
    await captura('07_selector_hora');
    // Cierra el selector de hora y vuelve al horario general.
    final cancelar = find.byWidgetPredicate(
      (w) => w is Text && w.data?.toUpperCase() == 'CANCELAR',
    );
    if (cancelar.evaluate().isNotEmpty) await tocar(cancelar.last);
    await volver();
    if (find.text('Descartar').evaluate().isNotEmpty) {
      await tocar(find.text('Descartar'));
    }

    await tocar(find.text('Inicio').last);
    await tocar(find.text('Tareas').first);
    await captura('08_tareas');

    await tocar(find.widgetWithText(FloatingActionButton, 'Tarea'));
    await tocar(find.widgetWithText(FilledButton, 'Guardar'));
    await captura('09_form_tarea_validacion');
    await volver();
    await volver();

    await tocar(find.text('Materias').first);
    await captura('10_materias');
    await tocar(find.text('Programación'));
    await captura('11_detalle_materia');

    await tocar(find.textContaining('Material ('));
    await captura('12_material');

    // Sin await: pushNamed termina recién cuando se cierra la pantalla.
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pushNamed(Rutas.acercaDe);
    await captura('17_acerca_de');
  });
}

/// Dibuja una hoja de cuaderno con un ejercicio para simular una foto de
/// apuntes (la prueba no puede usar la cámara ni la galería).
Future<String> _crearFotoApunte() async {
  const ancho = 900.0, alto = 1200.0;
  final grabadora = ui.PictureRecorder();
  final lienzo = Canvas(grabadora);
  lienzo.drawRect(
    const Rect.fromLTWH(0, 0, ancho, alto),
    Paint()..color = const Color(0xFFFFFDF5),
  );
  final renglon = Paint()
    ..color = const Color(0xFF90CAF9)
    ..strokeWidth = 2;
  for (var y = 120.0; y < alto; y += 60) {
    lienzo.drawLine(Offset(0, y), Offset(ancho, y), renglon);
  }
  lienzo.drawLine(
    const Offset(110, 0),
    const Offset(110, alto),
    Paint()
      ..color = const Color(0xFFEF9A9A)
      ..strokeWidth = 3,
  );
  const lineas = [
    'Derivadas - Clase 5',
    '',
    '1) f(x) = 3x² + 2x',
    "   f'(x) = 6x + 2",
    '',
    '2) g(x) = x³ - 5x',
    "   g'(x) = 3x² - 5",
    '',
    'Regla: d/dx (xⁿ) = n·xⁿ⁻¹',
  ];
  for (var i = 0; i < lineas.length; i++) {
    final builder =
        ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: i == 0 ? 44 : 38))
          ..pushStyle(
            ui.TextStyle(
              color: i == 0 ? const Color(0xFF1A237E) : const Color(0xFF263238),
              fontWeight: i == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          )
          ..addText(lineas[i]);
    final parrafo = builder.build()
      ..layout(const ui.ParagraphConstraints(width: ancho - 160));
    lienzo.drawParagraph(parrafo, Offset(140, 70 + i * 60.0));
  }
  final imagen = await grabadora.endRecording().toImage(
    ancho.toInt(),
    alto.toInt(),
  );
  final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
  final archivo = File('${(await getTemporaryDirectory()).path}/apunte.png');
  await archivo.writeAsBytes(bytes!.buffer.asUint8List());
  return archivo.path;
}
