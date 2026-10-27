// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/inicio/inicio_screen.dart
// Función  : Pantalla Inicio: saludo, menú principal y próximas actividades (RF15).
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/rutas.dart';
import '../../widgets/error_vista.dart';
import '../../widgets/tarea_tile.dart';
import '../materiales/fotos_screen.dart';
import '../materias/materias_screen.dart';
import '../perfil/gestiones_screen.dart';
import '../tareas/tarea_form_screen.dart';
import '../tareas/tareas_screen.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key, required this.alAbrirHorario});

  /// Cambia a la pestaña "Horario" de la barra inferior.
  final VoidCallback alAbrirHorario;

  void _abrir(BuildContext context, Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.instancia.usuarioActual;
    final estado = AgendaState.instancia;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda Académica')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva-tarea-inicio',
        onPressed: () => _abrir(context, const TareaFormScreen()),
        icon: const Icon(Icons.add_task),
        label: const Text('Tarea'),
      ),
      // Se reconstruye solo cuando cambia el estado (gestión del estado).
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          if (estado.error != null && !estado.cargado) {
            return ErrorVista(
              mensaje: estado.error!,
              onReintentar: estado.cargar,
            );
          }
          if (!estado.cargado) {
            return const Center(child: CircularProgressIndicator());
          }

          final proximas = estado.proximas.take(5).toList();
          final tarjetas = [
            _TarjetaMenu(
              icono: Icons.class_outlined,
              titulo: 'Materias',
              detalle: Formato.cantidad(estado.materias.length, 'registrada'),
              color: const Color(0xFF1E88E5),
              onTap: () => _abrir(context, const MateriasScreen()),
            ),
            _TarjetaMenu(
              icono: Icons.task_alt,
              titulo: 'Tareas',
              detalle: Formato.cantidad(estado.proximas.length, 'pendiente'),
              color: const Color(0xFF43A047),
              onTap: () => _abrir(context, const TareasScreen()),
            ),
            _TarjetaMenu(
              icono: Icons.schedule,
              titulo: 'Horarios',
              detalle: Formato.cantidad(estado.horarios.length, 'clase'),
              color: const Color(0xFFFB8C00),
              onTap: alAbrirHorario,
            ),
            // Acceso directo a las fotos (Semana 8): primero la foto y
            // después se elige la materia.
            _TarjetaMenu(
              icono: Icons.photo_library_outlined,
              titulo: 'Fotos',
              detalle: Formato.cantidad(estado.materiales.length, 'guardada'),
              color: const Color(0xFFE53935),
              onTap: () => _abrir(context, const FotosScreen()),
            ),
            _TarjetaMenu(
              icono: Icons.info_outline,
              titulo: 'Acerca de',
              detalle: 'Información del proyecto',
              color: const Color(0xFF8E24AA),
              onTap: () => Navigator.pushNamed(context, Rutas.acercaDe),
            ),
          ];

          return RefreshIndicator(
            onRefresh: estado.cargar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Text(
                  'Hola, ${usuario.nombre.split(' ').first}',
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formato.fechaLarga(DateTime.now()),
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: tema.colorScheme.outline,
                  ),
                ),
                // Gestión académica que se está mostrando (se cambia en Perfil).
                if (estado.gestion != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      avatar: const Icon(Icons.school_outlined, size: 18),
                      label: Text(estado.gestion!.nombre),
                      onPressed: () => _abrir(context, const GestionesScreen()),
                    ),
                  ),
                const SizedBox(height: 12),
                // 2 columnas en teléfonos y 4 en pantallas anchas.
                LayoutBuilder(
                  builder: (context, c) {
                    final columnas = c.maxWidth >= 600 ? 4 : 2;
                    final ancho = (c.maxWidth - 12 * (columnas - 1)) / columnas;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final t in tarjetas)
                          SizedBox(width: ancho, child: t),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text('Próximas actividades', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (proximas.isEmpty)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.celebration_outlined),
                      title: const Text('No tienes tareas pendientes'),
                      subtitle: Text(
                        estado.materias.isEmpty
                            ? 'Empieza registrando tus materias'
                            : 'Todo al día',
                      ),
                    ),
                  )
                else
                  for (final t in proximas) TareaTile(tarea: t),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaMenu extends StatelessWidget {
  const _TarjetaMenu({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.color,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icono, color: color),
              ),
              const SizedBox(height: 12),
              Text(titulo, style: tema.textTheme.titleMedium),
              Text(
                detalle,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.outline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
