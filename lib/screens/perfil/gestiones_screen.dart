// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/perfil/gestiones_screen.dart
// Función  : Iniciar una nueva gestión académica y consultar las anteriores sin borrar nada.
// ============================================================

import 'package:flutter/material.dart';

import '../../models/gestion.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../utils/mensajes.dart';

/// Gestiones académicas: al empezar un nuevo periodo el estudiante crea una
/// gestión nueva y la app muestra solo sus materias, tareas, horario y fotos.
/// Las gestiones anteriores quedan guardadas y se pueden volver a abrir.
class GestionesScreen extends StatelessWidget {
  const GestionesScreen({super.key});

  Future<void> _nueva(BuildContext context) async {
    final nombre = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogoNuevaGestion(),
    );
    if (nombre == null || !context.mounted) return;
    await Mensajes.ejecutar(
      context,
      () => AgendaState.instancia.nuevaGestion(nombre),
      exito: 'Se inició la gestión "$nombre"',
    );
  }

  Future<void> _abrir(BuildContext context, Gestion g) async {
    final ok = await Mensajes.confirmar(
      context,
      titulo: 'Abrir ${g.nombre}',
      mensaje:
          'La app mostrará las materias, tareas, horario y fotos de '
          '"${g.nombre}". Puedes volver a la otra gestión cuando quieras.',
      accion: 'Abrir',
    );
    if (!ok || !context.mounted) return;
    await Mensajes.ejecutar(
      context,
      () => AgendaState.instancia.cambiarGestion(g),
      exito: 'Ahora estás en "${g.nombre}"',
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gestiones académicas')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nueva-gestion',
        onPressed: () => _nueva(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva gestión'),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            Card(
              color: tema.colorScheme.primaryContainer,
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(
                  'Al iniciar una nueva gestión, tus materias, tareas, horario '
                  'y fotos actuales NO se borran: quedan guardados en su '
                  'gestión y puedes volver a abrirlos cuando quieras.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final g in estado.gestiones)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: g.activa
                        ? tema.colorScheme.primary
                        : tema.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      g.activa ? Icons.school : Icons.inventory_2_outlined,
                      color: g.activa
                          ? tema.colorScheme.onPrimary
                          : tema.colorScheme.outline,
                    ),
                  ),
                  title: Text(g.nombre),
                  subtitle: Text(
                    '${Formato.cantidad(estado.materiasEnGestion(g.idGestion!), 'materia')}'
                    ' · creada el ${Formato.fecha(g.fechaCreacion)}',
                  ),
                  trailing: g.activa
                      ? Chip(
                          label: const Text('Actual'),
                          backgroundColor: tema.colorScheme.primaryContainer,
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: g.activa ? null : () => _abrir(context, g),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogoNuevaGestion extends StatefulWidget {
  const _DialogoNuevaGestion();

  @override
  State<_DialogoNuevaGestion> createState() => _DialogoNuevaGestionState();
}

class _DialogoNuevaGestionState extends State<_DialogoNuevaGestion> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController(
    text: 'Gestión ${DateTime.now().year + 1}',
  );

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva gestión'),
      content: Form(
        key: _formulario,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Empezarás con la agenda vacía. Lo anterior queda guardado.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nombre,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre de la gestión',
                hintText: 'Ej.: Gestión 2027 o 2027 - 1er semestre',
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Escribe un nombre de al menos 3 caracteres'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_formulario.currentState!.validate()) {
              Navigator.pop(context, _nombre.text.trim());
            }
          },
          child: const Text('Iniciar'),
        ),
      ],
    );
  }
}
