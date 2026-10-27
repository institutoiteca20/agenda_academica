// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/acerca_de/acerca_de_screen.dart
// Función  : Pantalla Acerca de: información del proyecto, la estudiante y la versión.
// ============================================================

import 'package:flutter/material.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget dato(IconData icono, String titulo, String valor) => ListTile(
      leading: Icon(icono),
      title: Text(titulo),
      subtitle: Text(valor),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Image.asset('assets/icono.png', width: 96, height: 96),
              ),
              const SizedBox(height: 8),
              Text(
                'Agenda Académica y Organizador de Apuntes',
                style: tema.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                'Versión 1.1.0',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aplicación móvil que reúne en un solo lugar las materias, horarios, '
                'tareas y apuntes del estudiante, organizando toda la información por materia.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    dato(
                      Icons.person_outline,
                      'Estudiante',
                      'Reyshell Deyna Yana Layme',
                    ),
                    dato(
                      Icons.school_outlined,
                      'Asignatura',
                      'Programación de Dispositivos Móviles II',
                    ),
                    dato(
                      Icons.co_present_outlined,
                      'Docente',
                      'Ing. Alexander Pabon Pabon',
                    ),
                    dato(
                      Icons.workspace_premium_outlined,
                      'Carrera',
                      'Técnico Superior – Sistemas Informáticos',
                    ),
                    dato(
                      Icons.account_balance_outlined,
                      'Institución',
                      'Instituto Técnico de Educación Comercial Americano "ITECA"',
                    ),
                    dato(Icons.calendar_today_outlined, 'Gestión', '2026'),
                  ],
                ),
              ),
              Card(
                child: Column(
                  children: [
                    dato(
                      Icons.flutter_dash,
                      'Tecnologías',
                      'Flutter · Dart · SQLite',
                    ),
                    dato(
                      Icons.storage_outlined,
                      'Almacenamiento',
                      'Local en el dispositivo, sin conexión a Internet',
                    ),
                    dato(
                      Icons.fingerprint,
                      'Seguridad',
                      'Contraseña cifrada, huella digital y pregunta de seguridad',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
