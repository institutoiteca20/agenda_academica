// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/horarios/horario_general_screen.dart
// Función  : Horario general de la semana agrupado por día (RF12).
// ============================================================

import 'package:flutter/material.dart';

import '../../models/horario.dart';
import '../../state/agenda_state.dart';
import '../../utils/formato.dart';
import '../../widgets/error_vista.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/horario_tile.dart';
import 'horario_form_screen.dart';

/// Horario general: clases de todas las materias agrupadas por día
/// y ordenadas por hora (Semana 3, sección 9).
class HorarioGeneralScreen extends StatelessWidget {
  const HorarioGeneralScreen({super.key});

  void _abrirFormulario(BuildContext context, [Horario? horario]) =>
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HorarioFormScreen(horario: horario)),
      );

  @override
  Widget build(BuildContext context) {
    final estado = AgendaState.instancia;
    return Scaffold(
      appBar: AppBar(title: const Text('Horario general')),
      floatingActionButton: ListenableBuilder(
        listenable: estado,
        // Solo se puede agregar una clase si existe al menos una materia.
        builder: (context, _) => estado.materias.isEmpty
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                heroTag: 'nueva-clase',
                onPressed: () => _abrirFormulario(context),
                icon: const Icon(Icons.more_time),
                label: const Text('Clase'),
              ),
      ),
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
          final clases = estado.horarios;
          if (clases.isEmpty) {
            return EstadoVacio(
              icono: Icons.calendar_view_week,
              titulo: 'Tu horario está vacío',
              mensaje: estado.materias.isEmpty
                  ? 'Primero registra tus materias.'
                  : 'Toca "+ Clase" para registrar tus clases de la semana.',
            );
          }
          return RefreshIndicator(
            onRefresh: estado.cargar,
            child: _lista(context, clases),
          );
        },
      ),
    );
  }

  Widget _lista(BuildContext context, List<Horario> clases) {
    final tema = Theme.of(context);
    final hoy = DateTime.now().weekday;
    final dias = clases.map((c) => c.dia).toSet().toList()..sort();
    final minutos = clases.fold<int>(0, (s, c) => s + c.minutos);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Card(
          color: tema.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _Resumen(valor: '${clases.length}', etiqueta: 'clases'),
                _Resumen(valor: '${dias.length}', etiqueta: 'días'),
                _Resumen(
                  valor: Formato.duracion(minutos),
                  etiqueta: 'por semana',
                ),
              ],
            ),
          ),
        ),
        for (final dia in dias) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Row(
              children: [
                Text(Formato.nombreDia(dia), style: tema.textTheme.titleMedium),
                if (dia == hoy) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Hoy'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: tema.colorScheme.primary,
                    labelStyle: TextStyle(color: tema.colorScheme.onPrimary),
                  ),
                ],
              ],
            ),
          ),
          for (final c in clases.where((c) => c.dia == dia))
            HorarioTile(horario: c, onTap: () => _abrirFormulario(context, c)),
        ],
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          // Se reduce si no cabe (con letra grande "7 h 30 min" se partía).
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
          ),
          Text(etiqueta, style: tema.textTheme.bodySmall),
        ],
      ),
    );
  }
}
