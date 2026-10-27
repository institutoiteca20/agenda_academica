// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : integration_test/app_test.dart
// Función  : Pruebas funcionales automáticas CP01 a CP14 en el emulador o el teléfono.
// ============================================================

// Pruebas funcionales de las Semanas 7 y 8.
//
// Se ejecutan en el emulador o en un teléfono real y usan la aplicación
// como lo haría una persona: tocan botones, escriben en los campos y
// comprueban lo que aparece en la pantalla.
//
//   flutter drive --driver=test_driver/integration_test.dart
//     --target=integration_test/app_test.dart -d <dispositivo>
//
// Cada caso de prueba (CP) corresponde a una fila de la tabla de casos de
// prueba del documento de la Semana 7. Si alguna pantalla se desborda en el
// tamaño de pantalla probado, Flutter registra el error y la prueba falla.
// Si un caso falla, se guarda una captura del momento del error.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:agenda_academica/database/db_factory.dart';
import 'package:agenda_academica/main.dart';
import 'package:agenda_academica/services/auth_service.dart';
import 'package:agenda_academica/services/biometria_service.dart';
import 'package:agenda_academica/services/respaldo_service.dart';
import 'package:agenda_academica/services/storage_service.dart';
import 'package:agenda_academica/utils/formato.dart';

/// Cada ejecución usa un correo nuevo para no chocar con cuentas anteriores.
final _correo = 'prueba${DateTime.now().millisecondsSinceEpoch}@agenda.test';
final _usuario = 'p${DateTime.now().millisecondsSinceEpoch}';
const _contrasena = 'prueba123';
const _nueva = 'nueva456';
const _respuesta = 'Cochabamba';

/// Resultado que dará el sensor de huella simulado en cada caso.
var _huella = ResultadoHuella.correcta;

/// Imagen PNG de 1 x 1 píxel para simular la galería.
const _pngPrueba =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configurarBaseDatos();

  // Las pruebas siempre empiezan sin sesión iniciada, aunque el dispositivo
  // tenga guardada la sesión de otro usuario.
  setUpAll(() async {
    await AuthService.instancia.cerrarSesion();
    // Una prueba automática no puede poner el dedo en el sensor: se simula
    // su respuesta. La app instalada normalmente siempre usa el sensor real.
    BiometriaService.instancia.simulacion = (_) async => _huella;
    // Tampoco puede elegir una imagen en la galería: se usa un PNG de prueba.
    final png = File('${(await getTemporaryDirectory()).path}/prueba.png');
    await png.writeAsBytes(base64Decode(_pngPrueba));
    StorageService.instancia.simulacion = (_) async => XFile(png.path);
  });

  /// Espera a que terminen las animaciones, con un límite de 20 segundos
  /// para que una pantalla trabada haga fallar la prueba en lugar de colgarla.
  Future<void> esperar(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 20),
  );

  /// Define un caso de prueba; si falla, guarda una captura de la pantalla.
  void caso(String nombre, Future<void> Function(WidgetTester) cuerpo) {
    testWidgets(nombre, (tester) async {
      try {
        await cuerpo(tester);
      } catch (_) {
        try {
          await binding.convertFlutterSurfaceToImage();
          await tester.pump();
          await binding.takeScreenshot('fallo_${nombre.substring(0, 4)}');
        } catch (_) {}
        rethrow;
      }
    });
  }

  Future<void> abrirApp(WidgetTester tester) async {
    await tester.pumpWidget(const AgendaAcademicaApp());
    await esperar(tester);
  }

  Finder campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

  Future<void> tocar(WidgetTester tester, Finder finder) async {
    // Cierra el teclado para que no tape el botón.
    FocusManager.instance.primaryFocus?.unfocus();
    await esperar(tester);
    await tester.ensureVisible(finder);
    await esperar(tester);
    await tester.tap(finder, warnIfMissed: false);
    await esperar(tester);
  }

  /// Toca el campo, espera a que el teclado se conecte y escribe el texto.
  Future<void> escribir(WidgetTester tester, Finder campo, String texto) async {
    await tester.tap(campo, warnIfMissed: false);
    await esperar(tester);
    await tester.enterText(campo, texto);
    await esperar(tester);
  }

  /// En pantallas pequeñas el texto puede estar más abajo y la lista aún no
  /// lo construyó: se desplaza hasta encontrarlo, como lo haría una persona.
  Future<void> tocarTexto(WidgetTester tester, String texto) async {
    final f = find.text(texto);
    if (f.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        f,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await esperar(tester);
    }
    await tocar(tester, f.last);
  }

  /// Botón "Aceptar" de los selectores de fecha y hora (en mayúsculas o no).
  Future<void> aceptarSelector(WidgetTester tester) => tocar(
    tester,
    find
        .byWidgetPredicate(
          (w) => w is Text && w.data?.toUpperCase() == 'ACEPTAR',
        )
        .last,
  );

  /// Elige una opción de un desplegable a partir de su etiqueta.
  Future<void> elegir(
    WidgetTester tester,
    String etiqueta,
    String opcion,
  ) async {
    await tocar(tester, find.text(etiqueta));
    await tocarTexto(tester, opcion);
  }

  caso('CP01 Registro: no permite enviar el formulario vacío', (tester) async {
    await abrirApp(tester);
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await tocarTexto(tester, 'Regístrate');
    await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

    expect(find.text('Ingresa tu nombre'), findsOneWidget);
    expect(find.text('Ingresa un nombre de usuario'), findsOneWidget);
    expect(find.text('Ingresa tu correo'), findsOneWidget);
    expect(find.text('Debe tener al menos 6 caracteres'), findsOneWidget);
    await tester.ensureVisible(find.text('Elige una pregunta'));
    expect(find.text('Elige una pregunta'), findsOneWidget);
    expect(find.text('Ingresa la respuesta'), findsOneWidget);
  });

  caso('CP02 Registro: crea la cuenta, pide la huella y abre Inicio', (
    tester,
  ) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Regístrate');

    await escribir(tester, campo('Nombre completo'), 'Prueba Semana Ocho');
    await escribir(tester, campo('Nombre de usuario'), _usuario);
    await escribir(tester, campo('Correo electrónico'), _correo);
    await escribir(tester, campo('Contraseña'), _contrasena);
    await escribir(tester, campo('Confirmar contraseña'), _contrasena);
    await elegir(tester, 'Pregunta de seguridad', '¿En qué ciudad naciste?');
    await escribir(tester, campo('Respuesta'), _respuesta);
    await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));

    expect(find.text('Hola, Prueba'), findsOneWidget);
    expect(find.text('0 registradas'), findsOneWidget);
  });

  // Semana 8: sin huella no se entra, aunque la sesión esté guardada.
  caso('CP12 Huella: sin huella correcta no se entra', (tester) async {
    _huella = ResultadoHuella.cancelada;
    await abrirApp(tester);
    expect(find.text('Usar huella'), findsOneWidget);
    expect(find.text(ResultadoHuella.cancelada.mensaje), findsOneWidget);
    expect(find.text('0 registradas'), findsNothing);

    _huella = ResultadoHuella.sinHuellaRegistrada;
    await tocarTexto(tester, 'Usar huella');
    expect(
      find.text(ResultadoHuella.sinHuellaRegistrada.mensaje),
      findsOneWidget,
    );

    _huella = ResultadoHuella.correcta;
    await tocarTexto(tester, 'Usar huella');
    expect(find.text('Hola, Prueba'), findsOneWidget);
  });

  // Prueba de regresión del error E9: sin materias, el formulario de tarea
  // no ofrecía ninguna forma de registrar una.
  caso('CP11 Tareas: sin materias ofrece registrar una', (tester) async {
    await abrirApp(tester);
    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Tarea'));
    expect(find.text('Primero registra una materia'), findsOneWidget);

    await tocarTexto(tester, 'Registrar materia');
    expect(find.text('Nueva materia'), findsOneWidget);
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await esperar(tester);
    expect(find.text('Hola, Prueba'), findsOneWidget);
  });

  caso('CP03 Perfil: carga los datos de ejemplo', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Perfil');
    await tocarTexto(tester, 'Cargar datos de ejemplo');
    expect(
      find.text('Se cargaron 4 materias, 5 clases y 5 tareas'),
      findsOneWidget,
    );

    await tocarTexto(tester, 'Inicio');
    expect(find.text('4 registradas'), findsOneWidget);
    expect(find.text('5 clases'), findsOneWidget);
  });

  // Semana 8: acceso directo a las fotos desde Inicio.
  caso('CP13 Fotos: se abren desde Inicio con filtro por materia', (
    tester,
  ) async {
    await abrirApp(tester);
    expect(find.text('0 guardadas'), findsOneWidget);
    await tocarTexto(tester, 'Fotos');

    expect(find.text('Sin fotos guardadas'), findsOneWidget);
    expect(find.text('Todas (0)'), findsOneWidget);
    expect(find.text('Programación (0)'), findsOneWidget);

    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Foto'));
    expect(find.text('Tomar foto'), findsOneWidget);
    await tocarTexto(tester, 'Elegir de la galería');

    // Formulario: primero la foto, después la materia (obligatoria).
    expect(find.text('Nueva fotografía'), findsOneWidget);
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect(find.text('Elige la materia de la foto'), findsOneWidget);
    expect(find.text('Ingresa un nombre para la fotografía'), findsOneWidget);

    await escribir(tester, campo('Nombre *'), 'Apuntes desde Inicio');
    await elegir(tester, 'Materia *', 'Programación');
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect(find.text('Fotografía guardada'), findsOneWidget);

    // Aparece en Fotos con su materia y también dentro de la materia.
    expect(find.text('Todas (1)'), findsOneWidget);
    expect(find.text('Programación (1)'), findsOneWidget);
    expect(find.text('Apuntes desde Inicio'), findsOneWidget);
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await esperar(tester);
    expect(find.text('1 guardada'), findsOneWidget);

    await tocarTexto(tester, 'Materias');
    await tocarTexto(tester, 'Programación');
    await tocar(tester, find.textContaining('Material ('));
    expect(find.text('Material (1)'), findsOneWidget);
    expect(find.text('Apuntes desde Inicio'), findsOneWidget);
  });

  caso('CP04 Materias: no permite un nombre repetido', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Materias');
    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Materia'));

    await escribir(tester, campo('Nombre de la materia *'), 'programación');
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

    expect(
      find.text('Ya tienes una materia llamada "programación".'),
      findsOneWidget,
    );
  });

  caso('CP05 Tareas: valida los campos y registra una tarea', (tester) async {
    await abrirApp(tester);
    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Tarea'));

    // Sin datos: tres errores.
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect(find.text('Ingresa el título de la tarea'), findsOneWidget);
    expect(find.text('Elige una materia'), findsOneWidget);
    expect(find.text('Elige la fecha de entrega'), findsOneWidget);

    // Con datos válidos.
    await escribir(tester, campo('Título *'), 'Tarea de prueba automatizada');
    await elegir(tester, 'Materia *', 'Programación');
    await tocar(tester, find.text('Fecha de entrega *'));
    await aceptarSelector(tester);
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

    expect(find.text('Tarea registrada'), findsOneWidget);
    expect(find.text('5 pendientes'), findsOneWidget);
  });

  caso('CP06 Tareas: cambia el estado tocando la etiqueta', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Tareas');

    final fila = find.ancestor(
      of: find.text('Tarea de prueba automatizada'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: fila, matching: find.text('Pendiente')),
      findsOneWidget,
    );
    await tocar(
      tester,
      find.descendant(of: fila, matching: find.text('Pendiente')),
    );
    expect(
      find.descendant(of: fila, matching: find.text('En progreso')),
      findsOneWidget,
    );
  });

  caso('CP07 Horario: rechaza una clase que se cruza', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Horario');
    expect(find.text('7 h 30 min'), findsOneWidget);

    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Clase'));
    await elegir(tester, 'Materia *', 'Redes');
    await elegir(tester, 'Día *', 'Lunes');
    await tocar(tester, find.text('Inicio *'));
    await aceptarSelector(tester); // 08:00
    await tocar(tester, find.text('Fin *'));
    await aceptarSelector(tester); // 09:30
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

    expect(
      find.text('Se cruza con Programación (08:00 – 09:30).'),
      findsOneWidget,
    );
  });

  caso('CP08 Horario: registra la clase en un día libre', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Horario');
    await tocar(tester, find.widgetWithText(FloatingActionButton, 'Clase'));
    await elegir(tester, 'Materia *', 'Redes');
    await elegir(tester, 'Día *', 'Jueves');
    await tocar(tester, find.text('Inicio *'));
    await aceptarSelector(tester);
    await tocar(tester, find.text('Fin *'));
    await aceptarSelector(tester);
    await tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

    expect(find.text('Clase registrada'), findsOneWidget);
    expect(find.text('9 h'), findsOneWidget);
  });

  caso('CP09 Tareas: elimina una tarea con confirmación', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Tareas');
    await tocarTexto(tester, 'Tarea de prueba automatizada');
    await tocar(tester, find.byTooltip('Eliminar tarea'));
    expect(find.text('Eliminar tarea'), findsWidgets);

    await tocar(tester, find.widgetWithText(FilledButton, 'Eliminar'));
    expect(find.text('Tarea eliminada'), findsOneWidget);
    expect(find.text('Tarea de prueba automatizada'), findsNothing);
  });

  // Semana 8: nueva gestión sin borrar la anterior.
  caso('CP15 Gestión: nueva gestión vacía y la anterior se conserva', (
    tester,
  ) async {
    final actual = 'Gestión ${DateTime.now().year}';
    final nueva = 'Gestión ${DateTime.now().year + 1}';
    await abrirApp(tester);
    expect(find.text(actual), findsOneWidget);
    expect(find.text('4 registradas'), findsOneWidget);

    await tocarTexto(tester, actual); // chip de la gestión en Inicio
    await tocar(
      tester,
      find.widgetWithText(FloatingActionButton, 'Nueva gestión'),
    );
    await tocar(tester, find.widgetWithText(FilledButton, 'Iniciar'));
    expect(find.text('Se inició la gestión "$nueva"'), findsOneWidget);
    expect(find.text('Actual'), findsOneWidget);

    // La gestión nueva empieza vacía.
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await esperar(tester);
    expect(find.text(nueva), findsOneWidget);
    expect(find.text('0 registradas'), findsOneWidget);

    // La gestión anterior sigue con sus 4 materias.
    await tocarTexto(tester, nueva);
    expect(
      find.text('4 materias · creada el ${Formato.fecha(DateTime.now())}'),
      findsOneWidget,
    );
    await tocarTexto(tester, actual);
    await tocar(tester, find.widgetWithText(FilledButton, 'Abrir'));
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await esperar(tester);
    expect(find.text('4 registradas'), findsOneWidget);
  });

  // Semana 8: respaldo local para cambio de celular (sin internet).
  caso('CP16 Respaldo: exporta y restaura datos y fotos', (tester) async {
    Uint8List? respaldo;
    RespaldoService.instancia.simulacionGuardar = (nombre, bytes) async {
      respaldo = bytes;
      return true;
    };
    await abrirApp(tester);
    await tocarTexto(tester, 'Perfil');
    await tocarTexto(tester, 'Respaldo y cambio de celular');
    await tocar(tester, find.widgetWithText(FilledButton, 'Exportar respaldo'));
    expect(find.text('Respaldo guardado correctamente'), findsOneWidget);
    expect(respaldo, isNotNull);

    // Un archivo que no es respaldo se rechaza.
    RespaldoService.instancia.simulacionElegir = () async =>
        Uint8List.fromList(utf8.encode('esto no es un respaldo'));
    await tocar(
      tester,
      find.widgetWithText(OutlinedButton, 'Restaurar respaldo'),
    );
    await tocar(tester, find.widgetWithText(FilledButton, 'Elegir archivo'));
    expect(
      find.text('El archivo elegido no es un respaldo de Agenda Académica.'),
      findsOneWidget,
    );

    // Se simula el "celular nuevo": se cambia a una gestión vacía y luego
    // se restaura el respaldo; todo debe volver como estaba.
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await esperar(tester);
    await tocarTexto(tester, 'Gestión académica');
    await tocarTexto(tester, 'Gestión ${DateTime.now().year + 1}');
    await tocar(tester, find.widgetWithText(FilledButton, 'Abrir'));
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await esperar(tester);

    RespaldoService.instancia.simulacionElegir = () async => respaldo;
    await tocarTexto(tester, 'Respaldo y cambio de celular');
    await tocar(
      tester,
      find.widgetWithText(OutlinedButton, 'Restaurar respaldo'),
    );
    await tocar(tester, find.widgetWithText(FilledButton, 'Elegir archivo'));
    expect(find.text('Iniciar sesión'), findsOneWidget);

    await escribir(tester, campo('Usuario o correo'), _usuario);
    await escribir(tester, campo('Contraseña'), _contrasena);
    await tocar(tester, find.widgetWithText(FilledButton, 'Ingresar'));
    expect(find.text('Gestión ${DateTime.now().year}'), findsOneWidget);
    expect(find.text('4 registradas'), findsOneWidget);
    await tocarTexto(tester, 'Fotos');
    expect(find.text('Apuntes desde Inicio'), findsOneWidget);
  });

  caso('CP10 Sesión: cierra sesión y valida la contraseña', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, 'Perfil');
    await tocarTexto(tester, 'Cerrar sesión');
    await tocar(tester, find.widgetWithText(FilledButton, 'Salir'));
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Contraseña incorrecta (se ingresa con el nombre de usuario).
    await escribir(tester, campo('Usuario o correo'), _usuario);
    await escribir(tester, campo('Contraseña'), 'incorrecta1');
    await tocar(tester, find.widgetWithText(FilledButton, 'Ingresar'));
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);

    // Contraseña correcta + huella: los datos siguen guardados.
    await escribir(tester, campo('Contraseña'), _contrasena);
    await tocar(tester, find.widgetWithText(FilledButton, 'Ingresar'));
    expect(find.text('Hola, Prueba'), findsOneWidget);
    expect(find.text('4 registradas'), findsOneWidget);

    // Se deja la app sin sesión iniciada.
    await tocarTexto(tester, 'Perfil');
    await tocarTexto(tester, 'Cerrar sesión');
    await tocar(tester, find.widgetWithText(FilledButton, 'Salir'));
  });

  // Semana 8: recuperar la contraseña con la pregunta de seguridad + huella.
  caso('CP14 Sesión: recupera la contraseña olvidada', (tester) async {
    await abrirApp(tester);
    await tocarTexto(tester, '¿Olvidaste tu contraseña?');

    await escribir(tester, campo('Correo electrónico'), 'nadie@agenda.test');
    await tocar(tester, find.widgetWithText(FilledButton, 'Continuar'));
    expect(find.text('No hay ninguna cuenta con ese correo'), findsOneWidget);

    await escribir(tester, campo('Correo electrónico'), _correo);
    await tocar(tester, find.widgetWithText(FilledButton, 'Continuar'));
    expect(find.text('¿En qué ciudad naciste?'), findsOneWidget);

    // Respuesta incorrecta.
    await escribir(tester, campo('Respuesta'), 'La Paz');
    await escribir(tester, campo('Contraseña nueva'), _nueva);
    await escribir(tester, campo('Confirmar contraseña nueva'), _nueva);
    await tocar(
      tester,
      find.widgetWithText(FilledButton, 'Cambiar contraseña'),
    );
    expect(find.text('La respuesta no es correcta'), findsOneWidget);

    // Respuesta correcta (sin importar mayúsculas) y huella.
    await escribir(tester, campo('Respuesta'), '  cochabamba ');
    await tocar(
      tester,
      find.widgetWithText(FilledButton, 'Cambiar contraseña'),
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // La contraseña anterior ya no sirve; la nueva sí.
    await escribir(tester, campo('Usuario o correo'), _correo);
    await escribir(tester, campo('Contraseña'), _contrasena);
    await tocar(tester, find.widgetWithText(FilledButton, 'Ingresar'));
    expect(find.text('Usuario o contraseña incorrectos'), findsOneWidget);
    await escribir(tester, campo('Contraseña'), _nueva);
    await tocar(tester, find.widgetWithText(FilledButton, 'Ingresar'));
    expect(find.text('Hola, Prueba'), findsOneWidget);

    await tocarTexto(tester, 'Perfil');
    await tocarTexto(tester, 'Cerrar sesión');
    await tocar(tester, find.widgetWithText(FilledButton, 'Salir'));
  });
}
