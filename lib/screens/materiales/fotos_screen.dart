// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/materiales/fotos_screen.dart
// Función  : Pantalla Fotos de Inicio: todas las fotos con filtro por materia.
// ============================================================

import 'package:flutter/material.dart';

import '../../state/agenda_state.dart';
import '../../utils/mensajes.dart';
import '../../widgets/estado_vacio.dart';
import '../materias/materia_form_screen.dart';
import 'agregar_foto.dart';
import 'material_form_screen.dart';
import 'materiales_tab.dart';

/// Acceso directo a las fotos desde Inicio (Semana 8): el estudiante toma la
/// foto primero y después elige la materia. También se ven desde Materias.
class FotosScreen extends StatefulWidget {
  const FotosScreen({super.key});

  @override
  State<FotosScreen> createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  int? _idMateria; // null = todas las materias

  Future<void> _agregar() async {
    if (AgendaState.instancia.materias.isEmpty) {
      final registrar = await Mensajes.confirmar(
        context,
        titulo: 'Primero registra una materia',
        mensaje: 'Cada foto se guarda dentro de una materia.',
        accion: 'Registrar materia',
      );
      if (registrar && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MateriaFormScreen()),
        );
      }
      return;
    }
    final imagen = await elegirFotografia(context);
    if (imagen == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        // Sin idMateria: el formulario pide elegir la materia.
        builder: (_) =>
            MaterialFormScreen(idMateria: _idMateria, imagen: imagen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    return Scaffold(
      appBar: AppBar(title: const Text('Fotos')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fotos-inicio',
        onPressed: _agregar,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Foto'),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          final todas = estado.materiales;
          final filtradas = todas
              .where((m) => _idMateria == null || m.idMateria == _idMateria)
              .toList();
          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('Todas (${todas.length})'),
                        selected: _idMateria == null,
                        onSelected: (_) => setState(() => _idMateria = null),
                      ),
                    ),
                    for (final materia in estado.materias)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: materia.colorMateria,
                            radius: 6,
                          ),
                          label: Text(
                            '${materia.nombre} '
                            '(${estado.materialesDe(materia.idMateria!).length})',
                          ),
                          selected: _idMateria == materia.idMateria,
                          onSelected: (_) =>
                              setState(() => _idMateria = materia.idMateria),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtradas.isEmpty
                    ? const EstadoVacio(
                        icono: Icons.photo_library_outlined,
                        titulo: 'Sin fotos guardadas',
                        mensaje:
                            'Toca "Foto" para fotografiar apuntes, ejercicios '
                            'o la pizarra y luego elige la materia.\n'
                            'Formatos permitidos: JPG y PNG · Máximo 10 MB',
                      )
                    : GridView.extent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 0.8,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        children: [
                          for (final m in filtradas)
                            MiniaturaMaterial(
                              material: m,
                              mostrarMateria: true,
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
