// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/bloqueo_screen.dart
// Función  : Bloqueo con huella digital obligatorio antes de entrar a la agenda.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/biometria_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/rutas.dart';
import 'completar_seguridad_screen.dart';

/// Huella obligatoria (Semana 8): después de la contraseña, del registro y
/// cada vez que se abre la app con la sesión guardada. Sin huella no se entra.
class BloqueoScreen extends StatefulWidget {
  const BloqueoScreen({super.key});

  /// Para no abrir otra pantalla de bloqueo encima de esta.
  static bool visible = false;

  @override
  State<BloqueoScreen> createState() => _BloqueoScreenState();
}

class _BloqueoScreenState extends State<BloqueoScreen> {
  bool _verificando = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    BloqueoScreen.visible = true;
    // El diálogo de la huella se abre solo al llegar a esta pantalla.
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  @override
  void dispose() {
    BloqueoScreen.visible = false;
    super.dispose();
  }

  Future<void> _verificar() async {
    if (_verificando) return;
    setState(() {
      _verificando = true;
      _mensaje = null;
    });
    final resultado = await BiometriaService.instancia.verificar(
      'Pon tu dedo en el sensor para entrar a tu agenda',
    );
    if (!mounted) return;
    if (!resultado.ok) {
      setState(() {
        _verificando = false;
        _mensaje = resultado.mensaje;
      });
      return;
    }
    // Las cuentas creadas antes de la Semana 8 deben completar su seguridad.
    if (!AuthService.instancia.usuarioActual.tienePreguntaSeguridad) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CompletarSeguridadScreen()),
      );
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, Rutas.inicio, (_) => false);
  }

  Future<void> _otraCuenta() async {
    await AuthService.instancia.cerrarSesion();
    AgendaState.instancia.limpiar();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final usuario = AuthService.instancia.haySesion
        ? AuthService.instancia.usuarioActual
        : null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: tema.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.fingerprint,
                      size: 72,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    usuario == null
                        ? 'Verifica tu identidad'
                        : 'Hola, ${usuario.nombre.split(' ').first}',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por seguridad, usa tu huella digital para entrar.',
                    style: tema.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (usuario?.usuario != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${usuario!.usuario}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_mensaje != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: tema.colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: tema.colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_mensaje!)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _verificando ? null : _verificar,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Usar huella'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _verificando ? null : _otraCuenta,
                    child: const Text('Entrar con otra cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
