// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/perfil/perfil_screen.dart
// Función  : Perfil del usuario, datos de ejemplo y cierre de sesión.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/datos_ejemplo_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';
import '../../utils/rutas.dart';
import 'gestiones_screen.dart';
import 'respaldo_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  Future<void> _cargarEjemplo(BuildContext context) async {
    final estado = AgendaState.instancia;
    if (estado.materias.isNotEmpty) {
      Mensajes.error(
        context,
        'Los datos de ejemplo solo se cargan si no tienes materias',
      );
      return;
    }
    await Mensajes.ejecutar(context, () async {
      await DatosEjemploService.cargar(
        AuthService.instancia.usuarioActual.idUsuario!,
        estado.gestion!.idGestion!,
      );
      await estado.cargar();
    }, exito: 'Se cargaron 4 materias, 5 clases y 5 tareas');
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await Mensajes.confirmar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres salir de tu cuenta?',
      accion: 'Salir',
    );
    if (!confirmar || !context.mounted) return;
    // Se borra el historial para que "Atrás" no vuelva a la información del usuario.
    Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (_) => false);
    await AuthService.instancia.cerrarSesion();
    AgendaState.instancia.limpiar();
  }

  @override
  Widget build(BuildContext context) {
    // Durante la animación de salida tras cerrar sesión ya no hay usuario.
    if (!AuthService.instancia.haySesion) return const Scaffold();
    final usuario = AuthService.instancia.usuarioActual;
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: tema.colorScheme.primaryContainer,
              child: Text(
                usuario.iniciales,
                style: tema.textTheme.headlineMedium?.copyWith(
                  color: tema.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            usuario.nombre,
            style: tema.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (usuario.usuario != null)
            Text(
              '@${usuario.usuario}',
              style: tema.textTheme.titleSmall?.copyWith(
                color: tema.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            usuario.correo,
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: const Text('Miembro desde'),
                  subtitle: Text(Formato.fecha(usuario.fechaRegistro)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined),
                  title: const Text('Gestión académica'),
                  subtitle: Text(
                    '${AgendaState.instancia.gestion?.nombre ?? ''} · '
                    'iniciar una nueva o ver anteriores',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GestionesScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phonelink_setup),
                  title: const Text('Respaldo y cambio de celular'),
                  subtitle: const Text('Exportar o restaurar tu información'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RespaldoScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Cargar datos de ejemplo'),
                  subtitle: const Text(
                    'Materias, horario y tareas para probar la app',
                  ),
                  onTap: () => _cargarEjemplo(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pushNamed(context, Rutas.acercaDe),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: tema.colorScheme.error,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _cerrarSesion(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
