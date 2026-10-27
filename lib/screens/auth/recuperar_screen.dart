// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/recuperar_screen.dart
// Función  : Recuperación de la contraseña con pregunta de seguridad y huella.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/biometria_service.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import 'encabezado_auth.dart';

/// Recuperar la contraseña sin internet (Semana 8):
/// 1) correo de la cuenta → 2) respuesta de seguridad y contraseña nueva →
/// 3) huella digital del dueño del teléfono.
class RecuperarScreen extends StatefulWidget {
  const RecuperarScreen({super.key});

  @override
  State<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends State<RecuperarScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _respuesta = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  String? _pregunta; // null = paso 1 (correo)
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _respuesta.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _buscarCuenta() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pregunta = await AuthService.instancia.preguntaDe(_correo.text);
      if (!mounted) return;
      setState(() {
        _pregunta = pregunta;
        _cargando = false;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    }
  }

  Future<void> _cambiar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final auth = AuthService.instancia;
    var error = await auth.verificarRespuesta(_correo.text, _respuesta.text);
    if (error == null) {
      final huella = await BiometriaService.instancia.verificar(
        'Confirma con tu huella para cambiar la contraseña',
      );
      if (!huella.ok) error = huella.mensaje;
    }
    error ??= await auth.restablecerContrasena(
      correo: _correo.text,
      respuesta: _respuesta.text,
      nueva: _nueva.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error;
        _cargando = false;
      });
      return;
    }
    Mensajes.exito(
      context,
      'Contraseña actualizada. Ya puedes iniciar sesión.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paso2 = _pregunta != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
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
                    EncabezadoAuth(
                      titulo: paso2
                          ? 'Crea una contraseña nueva'
                          : '¿Olvidaste tu contraseña?',
                      subtitulo: paso2
                          ? 'Responde tu pregunta de seguridad y confirma con tu huella'
                          : 'Escribe el correo con el que te registraste',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _correo,
                      enabled: !paso2,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validadores.correo,
                    ),
                    if (paso2) ...[
                      const SizedBox(height: 16),
                      Card(
                        color: tema.colorScheme.primaryContainer,
                        child: ListTile(
                          leading: const Icon(Icons.help_outline),
                          title: Text(_pregunta!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _respuesta,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Respuesta',
                          prefixIcon: Icon(Icons.question_answer_outlined),
                        ),
                        validator: Validadores.respuestaSeguridad,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nueva,
                        obscureText: _ocultar,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Contraseña nueva',
                          helperText:
                              'Mínimo 6 caracteres, con letras y números',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _ocultar
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () =>
                                setState(() => _ocultar = !_ocultar),
                          ),
                        ),
                        validator: Validadores.contrasena,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmar,
                        obscureText: _ocultar,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña nueva',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        validator: (v) => v != _nueva.text
                            ? 'Las contraseñas no coinciden'
                            : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: tema.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _cargando
                          ? null
                          : (paso2 ? _cambiar : _buscarCuenta),
                      icon: Icon(paso2 ? Icons.fingerprint : Icons.search),
                      label: Text(paso2 ? 'Cambiar contraseña' : 'Continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
