// ============================================================
// Proyecto : Agenda Académica y Organizador de Apuntes
// Autor    : Reyshell Deyna Yana Layme
// Archivo  : lib/services/biometria_service.dart
// Función  : Verificación obligatoria con huella digital usando el sensor del teléfono (local_auth).
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Huella digital obligatoria (Semana 8). Usa el sensor del teléfono a
/// través de local_auth: no necesita internet y la huella nunca sale del
/// teléfono ni se guarda en la base de datos de la app.
class BiometriaService {
  BiometriaService._();
  static final BiometriaService instancia = BiometriaService._();

  final _auth = LocalAuthentication();

  /// Solo para las pruebas automáticas, que no pueden tocar el sensor.
  @visibleForTesting
  Future<ResultadoHuella> Function(String motivo)? simulacion;

  /// En la web no existe sensor de huella: se entra solo con la contraseña.
  bool get disponibleEnPlataforma => !kIsWeb;

  /// Muestra el diálogo del sistema para poner el dedo en el sensor.
  Future<ResultadoHuella> verificar(String motivo) async {
    if (simulacion != null) return simulacion!(motivo);
    if (!disponibleEnPlataforma) return ResultadoHuella.correcta;
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) {
        return ResultadoHuella.sinSensor;
      }
      if ((await _auth.getAvailableBiometrics()).isEmpty) {
        return ResultadoHuella.sinHuellaRegistrada;
      }
      final ok = await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: true, // solo huella: no se acepta el PIN del teléfono
        persistAcrossBackgrounding: true,
      );
      return ok ? ResultadoHuella.correcta : ResultadoHuella.cancelada;
    } on LocalAuthException catch (e) {
      debugPrint('Huella: ${e.code}');
      return switch (e.code) {
        LocalAuthExceptionCode.noBiometricHardware => ResultadoHuella.sinSensor,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          ResultadoHuella.sinHuellaRegistrada,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => ResultadoHuella.bloqueada,
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => ResultadoHuella.cancelada,
        _ => ResultadoHuella.error,
      };
    } catch (e) {
      debugPrint('Huella: $e');
      return ResultadoHuella.error;
    }
  }
}

enum ResultadoHuella {
  correcta(''),
  cancelada(
    'Verificación cancelada. Toca "Usar huella" para intentar otra vez.',
  ),
  sinHuellaRegistrada(
    'Este teléfono no tiene una huella registrada. Regístrala en '
    'Ajustes > Seguridad > Huella digital y vuelve a intentarlo.',
  ),
  sinSensor(
    'Este teléfono no tiene sensor de huella. La app necesita la huella '
    'para proteger tu información.',
  ),
  bloqueada(
    'Demasiados intentos fallidos. Espera unos segundos o desbloquea el '
    'teléfono e inténtalo otra vez.',
  ),
  error('No se pudo leer la huella. Inténtalo otra vez.');

  const ResultadoHuella(this.mensaje);
  final String mensaje;

  bool get ok => this == ResultadoHuella.correcta;
}
