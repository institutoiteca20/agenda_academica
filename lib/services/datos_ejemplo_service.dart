// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/services/datos_ejemplo_service.dart
// Función  : Carga materias, horarios y tareas de ejemplo para demostrar la aplicación.
// ============================================================

import '../database/database_helper.dart';
import '../models/horario.dart';
import '../models/materia.dart';
import '../models/tarea.dart';
import '../utils/tema.dart';

/// Carga materias, horarios y tareas de ejemplo para demostrar la aplicación.
/// Los horarios son los del ejemplo de la Semana 3 (sección 9.4).
class DatosEjemploService {
  static Future<void> cargar(int idUsuario, int idGestion) async {
    final db = DatabaseHelper.instancia;
    final hoy = DateTime.now();
    DateTime dia(int desplazamiento) =>
        DateTime(hoy.year, hoy.month, hoy.day + desplazamiento);

    Future<int> materia(String nombre, String docente, int color) =>
        db.insertarMateria(
          Materia(
            idUsuario: idUsuario,
            idGestion: idGestion,
            nombre: nombre,
            docente: docente,
            color: Tema.coloresMateria[color].toARGB32(),
          ),
        );

    final programacion = await materia(
      'Programación',
      'Ing. Alexander Pabon',
      0,
    );
    final baseDatos = await materia('Base de Datos', 'Ing. María López', 1);
    final matematicas = await materia('Matemáticas', 'Lic. Carlos Rojas', 2);
    final redes = await materia('Redes', 'Ing. Ana Quispe', 3);

    for (final h in [
      Horario(
        idMateria: programacion,
        dia: 1,
        horaInicio: '08:00',
        horaFin: '09:30',
        aula: 'Aula 12',
      ),
      Horario(
        idMateria: baseDatos,
        dia: 1,
        horaInicio: '09:45',
        horaFin: '11:15',
        aula: 'Lab. 2',
      ),
      Horario(
        idMateria: matematicas,
        dia: 2,
        horaInicio: '08:00',
        horaFin: '09:30',
        aula: 'Aula 5',
      ),
      Horario(
        idMateria: redes,
        dia: 2,
        horaInicio: '10:00',
        horaFin: '11:30',
        aula: 'Lab. 1',
      ),
      Horario(
        idMateria: programacion,
        dia: 3,
        horaInicio: '08:00',
        horaFin: '09:30',
        aula: 'Aula 12',
      ),
    ]) {
      await db.insertarHorario(h);
    }

    for (final t in [
      Tarea(
        idMateria: programacion,
        titulo: 'Práctica de listas en Dart',
        fechaEntrega: dia(1),
        estado: EstadoTarea.enProgreso,
      ),
      Tarea(
        idMateria: baseDatos,
        titulo: 'Diagrama entidad-relación',
        fechaEntrega: dia(3),
      ),
      Tarea(
        idMateria: matematicas,
        titulo: 'Ejercicios de derivadas',
        fechaEntrega: dia(-2),
      ),
      Tarea(
        idMateria: redes,
        titulo: 'Informe de subredes',
        fechaEntrega: dia(6),
      ),
      Tarea(
        idMateria: programacion,
        titulo: 'Instalar Flutter y crear proyecto',
        fechaEntrega: dia(-4),
        estado: EstadoTarea.completada,
      ),
    ]) {
      await db.insertarTarea(t);
    }
  }
}
