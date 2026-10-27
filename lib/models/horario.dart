// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/models/horario.dart
// Función  : Modelo Horario: clase de una materia y detección de cruces de horario.
// ============================================================

import '../utils/formato.dart';

class Horario {
  final int? idHorario;
  final int idMateria;

  /// 1 = lunes … 7 = domingo
  final int dia;

  /// Formato 24 h "HH:mm"
  final String horaInicio;
  final String horaFin;
  final String? aula;

  // Datos de la materia (se obtienen con JOIN).
  final String? nombreMateria;
  final int? colorMateria;

  Horario({
    this.idHorario,
    required this.idMateria,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    this.aula,
    this.nombreMateria,
    this.colorMateria,
  });

  int get minutos => Formato.aMinutos(horaFin) - Formato.aMinutos(horaInicio);

  /// Dos clases se cruzan si inicioA < finB y inicioB < finA (mismo día).
  bool seCruzaCon(Horario otro) =>
      dia == otro.dia &&
      Formato.aMinutos(horaInicio) < Formato.aMinutos(otro.horaFin) &&
      Formato.aMinutos(otro.horaInicio) < Formato.aMinutos(horaFin);

  /// Devuelve la primera clase de [existentes] que se cruza con esta,
  /// ignorando la propia clase cuando se está editando.
  Horario? buscarCruce(List<Horario> existentes) => existentes
      .where((h) => idHorario == null || h.idHorario != idHorario)
      .where(seCruzaCon)
      .firstOrNull;

  Map<String, Object?> toMap() => {
    'idHorario': idHorario,
    'idMateria': idMateria,
    'dia': dia,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'aula': aula,
  };

  factory Horario.fromMap(Map<String, Object?> m) => Horario(
    idHorario: m['idHorario'] as int,
    idMateria: m['idMateria'] as int,
    dia: m['dia'] as int,
    horaInicio: m['horaInicio'] as String,
    horaFin: m['horaFin'] as String,
    aula: m['aula'] as String?,
    nombreMateria: m['nombreMateria'] as String?,
    colorMateria: m['colorMateria'] as int?,
  );
}
