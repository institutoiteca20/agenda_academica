// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/registro_screen.dart
// Función  : Registro de usuario con nombre, usuario, correo, contraseña y pregunta de seguridad (RF01).
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/rutas.dart';
import '../../utils/validadores.dart';
import 'campos_seguridad.dart';
import 'encabezado_auth.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _usuario = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmar = TextEditingController();
  final _respuesta = TextEditingController();
  String? _pregunta;
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _usuario.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmar.dispose();
    _respuesta.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await AuthService.instancia.registrar(
      nombre: _nombre.text,
      usuario: _usuario.text,
      correo: _correo.text,
      contrasena: _contrasena.text,
      pregunta: _pregunta!,
      respuesta: _respuesta.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _cargando = false;
        _error = error;
      });
      return;
    }
    // Se borra el historial para que "Atrás" no regrese a Login/Registro.
    // Antes de entrar se confirma la huella (obligatoria).
    Navigator.pushNamedAndRemoveUntil(context, Rutas.bloqueo, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                      titulo: 'Registro',
                      subtitulo:
                          'Crea tu cuenta para guardar tu información académica',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nombre,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validadores.nombre,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usuario,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de usuario',
                        helperText: 'Ej.: reyshell.yana (sin espacios)',
                        prefixIcon: Icon(Icons.alternate_email),
                      ),
                      validator: Validadores.nombreUsuario,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: Validadores.correo,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contrasena,
                      obscureText: _ocultar,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 6 caracteres, con letras y números',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultar ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: Validadores.contrasena,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmar,
                      obscureText: _ocultar,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                      validator: (v) => v != _contrasena.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    CamposSeguridad(
                      pregunta: _pregunta,
                      onPregunta: (v) => setState(() => _pregunta = v),
                      respuesta: _respuesta,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.fingerprint,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Al crear la cuenta se te pedirá tu huella digital.',
                          ),
                        ),
                      ],
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
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Ya tengo una cuenta'),
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
