// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/campos_seguridad.dart
// Función  : Campos compartidos de pregunta y respuesta de seguridad.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/validadores.dart';

/// Pregunta y respuesta de seguridad (registro y completar cuenta).
/// Sirven para recuperar la contraseña sin internet.
class CamposSeguridad extends StatelessWidget {
  const CamposSeguridad({
    super.key,
    required this.pregunta,
    required this.onPregunta,
    required this.respuesta,
  });

  final String? pregunta;
  final ValueChanged<String?> onPregunta;
  final TextEditingController respuesta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: pregunta,
          decoration: const InputDecoration(
            labelText: 'Pregunta de seguridad',
            prefixIcon: Icon(Icons.help_outline),
          ),
          items: [
            for (final p in AuthService.preguntas)
              DropdownMenuItem(
                value: p,
                child: Text(p, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onPregunta,
          validator: (v) => v == null ? 'Elige una pregunta' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: respuesta,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Respuesta',
            helperText: 'La usarás si olvidas tu contraseña',
            prefixIcon: Icon(Icons.question_answer_outlined),
          ),
          validator: Validadores.respuestaSeguridad,
        ),
      ],
    );
  }
}
