// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/main.dart
// Función  : Punto de entrada: configura la base de datos, la orientación, las rutas y el bloqueo con huella al volver de segundo plano.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'database/db_factory.dart';
import 'screens/acerca_de/acerca_de_screen.dart';
import 'screens/auth/bloqueo_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/registro_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/inicio/principal_screen.dart';
import 'services/auth_service.dart';
import 'utils/rutas.dart';
import 'utils/tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Orientación vertical (Semana 3, diseño adaptable). En horizontal el
  // encabezado ocupaba media pantalla (corrección Semana 7).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // En Android se usa SQLite nativo; en web se usa SQLite compilado a WebAssembly.
  configurarBaseDatos();
  runApp(const AgendaAcademicaApp());
}

class AgendaAcademicaApp extends StatefulWidget {
  const AgendaAcademicaApp({super.key});

  @override
  State<AgendaAcademicaApp> createState() => _AgendaAcademicaAppState();
}

class _AgendaAcademicaAppState extends State<AgendaAcademicaApp>
    with WidgetsBindingObserver {
  final _navegador = GlobalKey<NavigatorState>();

  /// Si la app estuvo en segundo plano más de este tiempo, se vuelve a pedir
  /// la huella (Semana 8). Es corto para que nadie la use sin permiso, pero
  /// deja tiempo para tomar una foto con la cámara.
  static const _tiempoBloqueo = Duration(minutes: 1);
  DateTime? _enSegundoPlanDesde;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.paused) {
      _enSegundoPlanDesde = DateTime.now();
    } else if (estado == AppLifecycleState.resumed) {
      final desde = _enSegundoPlanDesde;
      _enSegundoPlanDesde = null;
      if (desde != null &&
          DateTime.now().difference(desde) >= _tiempoBloqueo &&
          AuthService.instancia.haySesion &&
          !BloqueoScreen.visible) {
        _navegador.currentState?.pushNamedAndRemoveUntil(
          Rutas.bloqueo,
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navegador,
      title: 'Agenda Académica',
      debugShowCheckedModeBanner: false,
      theme: Tema.claro,
      // Calendarios, selector de hora y textos del sistema en español.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      initialRoute: Rutas.splash,
      routes: {
        Rutas.splash: (_) => const SplashScreen(),
        Rutas.login: (_) => const LoginScreen(),
        Rutas.registro: (_) => const RegistroScreen(),
        Rutas.bloqueo: (_) => const BloqueoScreen(),
        Rutas.inicio: (_) => const PrincipalScreen(),
        Rutas.acercaDe: (_) => const AcercaDeScreen(),
      },
    );
  }
}
