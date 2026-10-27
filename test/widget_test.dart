// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : test/widget_test.dart
// Función  : Pruebas unitarias de validaciones, estados, horarios y formatos.
// ============================================================

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agenda_academica/models/horario.dart';
import 'package:agenda_academica/models/tarea.dart';
import 'package:agenda_academica/services/storage_service.dart';
import 'package:agenda_academica/state/agenda_state.dart';
import 'package:agenda_academica/utils/formato.dart';
import 'package:agenda_academica/utils/validadores.dart';

void main() {
  group('Material académico (Semana 6)', () {
    final storage = StorageService.instancia;
    XFile imagen(String nombre, int bytes) =>
        XFile.fromData(Uint8List(bytes), name: nombre, path: nombre);

    test('acepta JPG y PNG y calcula el tamaño en KB', () async {
      final jpg = await storage.validar(imagen('apunte.JPG', 845 * 1024));
      expect(jpg.formato, 'jpg');
      expect(jpg.tamanoKB, 845);
      expect(
        (await storage.validar(imagen('captura.png', 1024))).formato,
        'png',
      );
    });

    test('rechaza formatos no permitidos', () {
      expect(
        storage.validar(imagen('animacion.gif', 1024)),
        throwsA(isA<AgendaException>()),
      );
      expect(
        storage.validar(imagen('documento.pdf', 1024)),
        throwsA(isA<AgendaException>()),
      );
    });

    test('rechaza imágenes de más de 10 MB', () {
      expect(
        storage.validar(imagen('pizarra.jpg', 11 * 1024 * 1024)),
        throwsA(isA<AgendaException>()),
      );
    });

    test('nombre de la fotografía obligatorio y de al menos 3 caracteres', () {
      expect(Validadores.nombreMaterial('Ejercicio de listas'), isNull);
      expect(Validadores.nombreMaterial(''), isNotNull);
      expect(Validadores.nombreMaterial('ab'), isNotNull);
    });

    test('fecha de entrega corta (corrección Semana 7)', () {
      final hoy = DateTime.now();
      expect(Formato.entrega(hoy), 'Hoy');
      expect(
        Formato.entrega(DateTime(hoy.year, hoy.month, hoy.day + 1)),
        'Mañana',
      );
      // Una fecha lejana del mismo año se muestra sin el año.
      final lejana = DateTime(hoy.year, hoy.month, hoy.day + 20);
      if (lejana.year == hoy.year) {
        expect(Formato.entrega(lejana), isNot(contains('/${hoy.year}')));
      }
      expect(
        Formato.entrega(DateTime(hoy.year + 1, 3, 5)),
        '05/03/${hoy.year + 1}',
      );
    });

    test('tamaño legible', () {
      expect(Formato.tamano(845), '845 KB');
      expect(Formato.tamano(2560), '2.5 MB');
    });
  });

  group('Validadores', () {
    test('correo', () {
      expect(Validadores.correo('estudiante@correo.com'), isNull);
      expect(Validadores.correo('sin-arroba'), isNotNull);
      expect(Validadores.correo(''), isNotNull);
    });

    test('nombre de usuario (Semana 8): 4 a 20 caracteres, sin espacios', () {
      expect(Validadores.nombreUsuario('reyshell.yana'), isNull);
      expect(Validadores.nombreUsuario('mica_5'), isNull);
      expect(Validadores.nombreUsuario(''), isNotNull);
      expect(Validadores.nombreUsuario('rey'), isNotNull);
      expect(Validadores.nombreUsuario('reyshell yana'), isNotNull);
      expect(Validadores.nombreUsuario('a' * 21), isNotNull);
    });

    test('respuesta de seguridad obligatoria (Semana 8)', () {
      expect(Validadores.respuestaSeguridad('Cochabamba'), isNull);
      expect(Validadores.respuestaSeguridad('  '), isNotNull);
      expect(Validadores.usuarioOCorreo(''), isNotNull);
      expect(Validadores.usuarioOCorreo('mica'), isNull);
    });

    test('contraseña necesita 6 caracteres con letras y números', () {
      expect(Validadores.contrasena('abc123'), isNull);
      expect(Validadores.contrasena('abc12'), isNotNull);
      expect(Validadores.contrasena('abcdef'), isNotNull);
    });

    test('título de tarea obligatorio y de al menos 3 caracteres', () {
      expect(Validadores.tituloTarea('Informe'), isNull);
      expect(Validadores.tituloTarea('  '), isNotNull);
      expect(Validadores.tituloTarea('ab'), isNotNull);
    });

    test(
      'fecha de entrega: obligatoria y no anterior a hoy en tareas nuevas',
      () {
        final hoy = DateTime.now();
        final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
        expect(Validadores.fechaEntrega(null, esNueva: true), isNotNull);
        expect(Validadores.fechaEntrega(hoy, esNueva: true), isNull);
        expect(Validadores.fechaEntrega(ayer, esNueva: true), isNotNull);
        // Al editar una tarea vencida se puede conservar su fecha.
        expect(Validadores.fechaEntrega(ayer, esNueva: false), isNull);
      },
    );

    test('rango de horas: el fin debe ser mayor que el inicio', () {
      expect(Validadores.rangoHoras('08:00', '09:30'), isNull);
      expect(Validadores.rangoHoras('09:30', '09:30'), isNotNull);
      expect(Validadores.rangoHoras('10:00', '09:00'), isNotNull);
      expect(Validadores.rangoHoras(null, '09:00'), isNotNull);
    });
  });

  group('Estados de tarea', () {
    final hoy = DateTime.now();
    final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);

    test('una tarea no completada con fecha pasada se muestra vencida', () {
      final t = Tarea(idMateria: 1, titulo: 'T', fechaEntrega: ayer);
      expect(t.estadoVisible, EstadoTarea.vencida);
    });

    test('una tarea completada nunca está vencida', () {
      final t = Tarea(
        idMateria: 1,
        titulo: 'T',
        fechaEntrega: ayer,
        estado: EstadoTarea.completada,
      );
      expect(t.estadoVisible, EstadoTarea.completada);
    });

    test('una tarea que vence hoy no está vencida', () {
      final t = Tarea(idMateria: 1, titulo: 'T', fechaEntrega: hoy);
      expect(t.estadoVisible, EstadoTarea.pendiente);
    });
  });

  group('Horario', () {
    Horario clase(int dia, String inicio, String fin) =>
        Horario(idMateria: 1, dia: dia, horaInicio: inicio, horaFin: fin);

    test('detecta cruces de horario (ejemplo de la Semana 3)', () {
      final programacion = clase(1, '08:00', '09:30');
      expect(clase(1, '09:00', '10:00').seCruzaCon(programacion), isTrue);
      expect(clase(1, '09:30', '11:00').seCruzaCon(programacion), isFalse);
      expect(clase(2, '08:00', '09:30').seCruzaCon(programacion), isFalse);
    });

    test(
      'buscarCruce encuentra la clase que se cruza e ignora la propia al editar',
      () {
        final programacion = Horario(
          idHorario: 1,
          idMateria: 1,
          dia: 1,
          horaInicio: '08:00',
          horaFin: '09:30',
          nombreMateria: 'Programación',
        );
        final baseDatos = Horario(
          idHorario: 2,
          idMateria: 2,
          dia: 1,
          horaInicio: '09:45',
          horaFin: '11:15',
        );
        final existentes = [programacion, baseDatos];

        final redes = Horario(
          idMateria: 3,
          dia: 1,
          horaInicio: '09:00',
          horaFin: '10:00',
        );
        expect(redes.buscarCruce(existentes)?.nombreMateria, 'Programación');

        // Editar Programación sin cambiar sus horas no debe chocar consigo misma.
        final editada = Horario(
          idHorario: 1,
          idMateria: 1,
          dia: 1,
          horaInicio: '08:00',
          horaFin: '09:40',
        );
        expect(editada.buscarCruce(existentes), isNull);
      },
    );

    test('resumen semanal: 5 clases suman 7 h 30 min', () {
      final minutos = List.generate(
        5,
        (_) => clase(1, '08:00', '09:30'),
      ).fold<int>(0, (s, c) => s + c.minutos);
      expect(Formato.duracion(minutos), '7 h 30 min');
    });
  });
}
