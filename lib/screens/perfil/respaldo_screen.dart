// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/perfil/respaldo_screen.dart
// Función  : Pantalla para exportar y restaurar el respaldo (cambio de celular), sin internet.
// ============================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/respaldo_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/mensajes.dart';
import '../../utils/rutas.dart';

/// Restaura un respaldo elegido por el usuario. Se usa desde Perfil y desde
/// la pantalla de inicio de sesión (celular nuevo, todavía sin cuenta).
Future<void> restaurarRespaldo(BuildContext context) async {
  if (kIsWeb) {
    Mensajes.error(context, 'El respaldo solo está disponible en Android.');
    return;
  }
  final ok = await Mensajes.confirmar(
    context,
    titulo: 'Restaurar respaldo',
    mensaje:
        'Se reemplazarán los datos de este celular por los del respaldo '
        '(cuentas, materias, tareas, horarios y fotos). Después deberás '
        'iniciar sesión con tu cuenta.',
    accion: 'Elegir archivo',
  );
  if (!ok || !context.mounted) return;
  try {
    final restaurado = await RespaldoService.instancia.importar();
    if (!restaurado || !context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (_) => false);
    Mensajes.exito(
      context,
      'Respaldo restaurado. Inicia sesión con tu usuario y contraseña.',
    );
  } on AgendaException catch (e) {
    if (context.mounted) Mensajes.error(context, e.mensaje);
  } catch (e) {
    debugPrint('Error al restaurar: $e');
    if (context.mounted) {
      Mensajes.error(context, 'No se pudo restaurar el respaldo.');
    }
  }
}

class RespaldoScreen extends StatefulWidget {
  const RespaldoScreen({super.key});

  @override
  State<RespaldoScreen> createState() => _RespaldoScreenState();
}

class _RespaldoScreenState extends State<RespaldoScreen> {
  bool _trabajando = false;

  Future<void> _exportar() async {
    if (kIsWeb) {
      Mensajes.error(context, 'El respaldo solo está disponible en Android.');
      return;
    }
    setState(() => _trabajando = true);
    try {
      final guardado = await RespaldoService.instancia.exportar();
      if (guardado && mounted) {
        Mensajes.exito(context, 'Respaldo guardado correctamente');
      }
    } catch (e) {
      debugPrint('Error al exportar: $e');
      if (mounted) Mensajes.error(context, 'No se pudo crear el respaldo.');
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget paso(String n, String texto) => ListTile(
      leading: CircleAvatar(radius: 14, child: Text(n)),
      title: Text(texto),
      dense: true,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Respaldo y cambio de celular')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(
            Icons.phonelink_setup,
            size: 64,
            color: tema.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Tu información se guarda solo en este celular. Para pasarla a '
            'otro celular, crea un respaldo. No se necesita internet.',
            style: tema.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                paso(
                  '1',
                  'En este celular toca "Exportar respaldo" y guárdalo (por ejemplo en Descargas).',
                ),
                paso(
                  '2',
                  'Pasa el archivo .zip al celular nuevo (cable USB, WhatsApp o Drive).',
                ),
                paso(
                  '3',
                  'Instala la app en el celular nuevo y, en Iniciar sesión, toca "Restaurar respaldo".',
                ),
                paso(
                  '4',
                  'Inicia sesión con tu misma cuenta y registra tu huella en ese celular.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _trabajando ? null : _exportar,
            icon: _trabajando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: const Text('Exportar respaldo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _trabajando ? null : () => restaurarRespaldo(context),
            icon: const Icon(Icons.restore),
            label: const Text('Restaurar respaldo'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'El respaldo incluye las cuentas de este celular con sus materias, '
            'tareas, horarios, gestiones y fotos. Las contraseñas van cifradas. '
            'Guárdalo en un lugar seguro.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
