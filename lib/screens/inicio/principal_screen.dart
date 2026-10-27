// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/inicio/principal_screen.dart
// Función  : Contenedor con la barra inferior: Inicio, Horario y Perfil.
// ============================================================

import 'package:flutter/material.dart';

import '../../state/agenda_state.dart';
import '../horarios/horario_general_screen.dart';
import '../perfil/perfil_screen.dart';
import 'inicio_screen.dart';

/// Contenedor con la barra de navegación inferior: Inicio, Horario y Perfil.
class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    // Carga las materias, tareas y horarios del usuario que inició sesión.
    AgendaState.instancia.cargar();
  }

  @override
  Widget build(BuildContext context) {
    final pestanas = <Widget>[
      InicioScreen(alAbrirHorario: () => setState(() => _indice = 1)),
      const HorarioGeneralScreen(),
      const PerfilScreen(),
    ];

    return Scaffold(
      body: pestanas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Horario',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
