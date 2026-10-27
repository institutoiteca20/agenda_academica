// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/login_screen.dart
// Función  : Inicio de sesión con usuario o correo y contraseña (RF02, RF03).
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/rutas.dart';
import '../../utils/validadores.dart';
import 'encabezado_auth.dart';
import '../perfil/respaldo_screen.dart';
import 'recuperar_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    final error = await AuthService.instancia.iniciarSesion(
      _correo.text,
      _contrasena.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _cargando = false;
        _error = error;
      });
      return;
    }
    // Después de la contraseña, la huella (obligatoria).
    Navigator.pushReplacementNamed(context, Rutas.bloqueo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // En pantallas grandes el formulario no se estira demasiado.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EncabezadoAuth(
                      titulo: 'Iniciar sesión',
                      subtitulo: 'Organiza tus materias, tareas y apuntes',
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Usuario o correo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validadores.usuarioOCorreo,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contrasena,
                      obscureText: _ocultar,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _ingresar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultar ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Ingresa tu contraseña'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecuperarScreen(),
                          ),
                        ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _cargando ? null : _ingresar,
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingresar'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes una cuenta?'),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, Rutas.registro),
                          child: const Text('Regístrate'),
                        ),
                      ],
                    ),
                    // Celular nuevo: recuperar la información de otro celular.
                    TextButton.icon(
                      onPressed: () => restaurarRespaldo(context),
                      icon: const Icon(Icons.phonelink_setup, size: 20),
                      label: const Text(
                        '¿Cambiaste de celular? Restaurar respaldo',
                      ),
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
