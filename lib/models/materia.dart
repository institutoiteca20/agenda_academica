// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/models/materia.dart
// Función  : Modelo Materia: nombre, docente, descripción y color.
// ============================================================

import 'package:flutter/material.dart';

class Materia {
  final int? idMateria;
  final int idUsuario;

  /// Gestión (periodo académico) a la que pertenece. Al registrar una materia
  /// nueva se asigna la gestión activa.
  final int? idGestion;
  final String nombre;
  final String? docente;
  final String? descripcion;
  final int color;

  Materia({
    this.idMateria,
    required this.idUsuario,
    this.idGestion,
    required this.nombre,
    this.docente,
    this.descripcion,
    required this.color,
  });

  Color get colorMateria => Color(color);

  Map<String, Object?> toMap() => {
    'idMateria': idMateria,
    'idUsuario': idUsuario,
    // Al editar no se cambia la gestión de la materia.
    if (idGestion != null) 'idGestion': idGestion,
    'nombre': nombre,
    'docente': docente,
    'descripcion': descripcion,
    'color': color,
  };

  factory Materia.fromMap(Map<String, Object?> m) => Materia(
    idMateria: m['idMateria'] as int,
    idUsuario: m['idUsuario'] as int,
    idGestion: m['idGestion'] as int?,
    nombre: m['nombre'] as String,
    docente: m['docente'] as String?,
    descripcion: m['descripcion'] as String?,
    color: m['color'] as int,
  );
}
