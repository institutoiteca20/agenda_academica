// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/completar_seguridad_screen.dart
// Función  : Completar el usuario y la pregunta de seguridad en cuentas anteriores.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../state/agenda_state.dart';
import '../../utils/rutas.dart';
import '../../utils/validadores.dart';
import 'campos_seguridad.dart';
import 'encabezado_auth.dart';

/// Obligatoria para las cuentas creadas antes de la Semana 8: elegir el
/// nombre de usuario y la pregunta de seguridad antes de usar la app.
class CompletarSeguridadScreen extends StatefulWidget {
  const CompletarSeguridadScreen({super.key});

  @override
  State<CompletarSeguridadScreen> createState() =>
      _CompletarSeguridadScreenState();
}

class _CompletarSeguridadScreenState extends State<CompletarSeguridadScreen> {
  final _formulario = GlobalKey<FormState>();
  late final _usuario = TextEditingController(
    text: AuthService.instancia.usuarioActual.usuario,
  );
  final _respuesta = TextEditingController();
  String? _pregunta;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _usuario.dispose();
    _respuesta.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    final error = await AuthService.instancia.completarSeguridad(
      usuario: _usuario.text,
      pregunta: _pregunta!,
      respuesta: _respuesta.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, Rutas.inicio, (_) => false);
  }

  Future<void> _salir() async {
    await AuthService.instancia.cerrarSesion();
    AgendaState.instancia.limpiar();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Rutas.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // no se puede saltar este paso
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formulario,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EncabezadoAuth(
                        titulo: 'Protege tu cuenta',
                        subtitulo:
                            'Elige tu nombre de usuario y una pregunta de '
                            'seguridad para recuperar tu contraseña',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usuario,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: Validadores.nombreUsuario,
                      ),
                      const SizedBox(height: 16),
                      CamposSeguridad(
                        pregunta: _pregunta,
                        onPregunta: (v) => setState(() => _pregunta = v),
                        respuesta: _respuesta,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _guardando ? null : _guardar,
                        child: const Text('Guardar y continuar'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _guardando ? null : _salir,
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
