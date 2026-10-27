// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/screens/auth/splash_screen.dart
// Función  : Pantalla de carga: decide si pedir la huella o mostrar el inicio de sesión.
// ============================================================

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/rutas.dart';

/// Pantalla de carga: revisa si hay una sesión guardada y decide
/// si pedir la huella (BloqueoScreen) o ir a Login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final haySesion = await AuthService.instancia.restaurarSesion();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      haySesion ? Rutas.bloqueo : Rutas.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: esquema.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icono.png', width: 120, height: 120),
            const SizedBox(height: 16),
            Text(
              'Agenda Académica',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: esquema.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: esquema.onPrimary),
          ],
        ),
      ),
    );
  }
}
