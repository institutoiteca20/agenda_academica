// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/models/tarea.dart
// Función  : Modelo Tarea y sus estados (pendiente, en progreso, completada, vencida).
// ============================================================

import 'package:flutter/material.dart';

/// Estados de una tarea (Semana 3, sección 7).
/// "vencida" no se guarda en SQLite: se calcula con la fecha de entrega.
enum EstadoTarea {
  pendiente('pendiente', 'Pendiente', Color(0xFFF9A825)),
  enProgreso('en_progreso', 'En progreso', Color(0xFF1E88E5)),
  completada('completada', 'Completada', Color(0xFF43A047)),
  vencida('vencida', 'Vencida', Color(0xFFE53935));

  const EstadoTarea(this.valor, this.etiqueta, this.color);

  final String valor;
  final String etiqueta;
  final Color color;

  static EstadoTarea desdeValor(String valor) =>
      EstadoTarea.values.firstWhere((e) => e.valor == valor);

  /// Orden al tocar la etiqueta: pendiente → en progreso → completada → pendiente.
  EstadoTarea get siguiente => switch (this) {
    EstadoTarea.pendiente => EstadoTarea.enProgreso,
    EstadoTarea.enProgreso => EstadoTarea.completada,
    _ => EstadoTarea.pendiente,
  };
}

class Tarea {
  final int? idTarea;
  final int idMateria;
  final String titulo;
  final String? descripcion;
  final DateTime fechaEntrega;

  /// Estado guardado: pendiente, en_progreso o completada.
  final EstadoTarea estado;

  // Datos de la materia (se obtienen con JOIN).
  final String? nombreMateria;
  final int? colorMateria;

  Tarea({
    this.idTarea,
    required this.idMateria,
    required this.titulo,
    this.descripcion,
    required this.fechaEntrega,
    this.estado = EstadoTarea.pendiente,
    this.nombreMateria,
    this.colorMateria,
  });

  bool get estaVencida {
    if (estado == EstadoTarea.completada) return false;
    final hoy = DateTime.now();
    return fechaEntrega.isBefore(DateTime(hoy.year, hoy.month, hoy.day));
  }

  /// Estado que se muestra en pantalla (incluye "vencida").
  EstadoTarea get estadoVisible => estaVencida ? EstadoTarea.vencida : estado;

  Map<String, Object?> toMap() => {
    'idTarea': idTarea,
    'idMateria': idMateria,
    'titulo': titulo,
    'descripcion': descripcion,
    'fechaEntrega': fechaEntrega.toIso8601String().substring(0, 10),
    'estado': estado.valor,
  };

  factory Tarea.fromMap(Map<String, Object?> m) => Tarea(
    idTarea: m['idTarea'] as int,
    idMateria: m['idMateria'] as int,
    titulo: m['titulo'] as String,
    descripcion: m['descripcion'] as String?,
    fechaEntrega: DateTime.parse(m['fechaEntrega'] as String),
    estado: EstadoTarea.desdeValor(m['estado'] as String),
    nombreMateria: m['nombreMateria'] as String?,
    colorMateria: m['colorMateria'] as int?,
  );
}
