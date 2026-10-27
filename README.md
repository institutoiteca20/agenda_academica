# Agenda Académica y Organizador de Apuntes

Aplicación móvil en Flutter y Dart que organiza la información académica **por materia**
(horario, tareas y material), con autenticación local y base de datos SQLite.

- **Estudiante:** Reyshell Deyna Yana Layme
- **Asignatura:** Programación de Dispositivos Móviles II
- **Docente:** Ing. Alexander Pabon Pabon · Gestión 2026

## Semana 4: desarrollo inicial

| Indicador | Qué se hizo |
|---|---|
| Entorno configurado | Flutter 3.44 / Dart 3.12, Android SDK 37, emulador Pixel 6 (4 GB de RAM), VS Code. El proyecto compila sin errores (`flutter analyze`: sin problemas). |
| Estructura del proyecto | `models/`, `database/`, `services/`, `screens/`, `widgets/` y `utils/`, según la arquitectura de la Semana 3. |
| Aplicación ejecutable | APK instalado y ejecutado en el emulador Android. |
| Pantallas principales | Splash, Login, Registro, Inicio, Materias, Formulario de materia, Detalle de materia, Tareas, Horario general, Perfil y Acerca de. |
| Navegación | Rutas con nombre (`/login`, `/registro`, `/inicio`, `/acerca-de`), `Navigator.push/pop` para detalle y formularios, y barra inferior (Inicio, Horario y Perfil). Al cerrar sesión se borra el historial. |
| Multiplataforma inicial | Android (plataforma objetivo) y Web/Chrome como segunda plataforma de prueba. |

### Funciones ya disponibles
- Registro, inicio de sesión, validación de credenciales, sesión recordada y cierre de sesión.
  Las contraseñas se guardan como hash SHA-256 con un *salt* por usuario.
- Materias: registrar, listar, editar y eliminar (con eliminación en cascada).
- Tareas: lista con filtros por estado (Pendiente, En progreso, Completada y Vencida, que se calcula).
  El estado cambia al tocar la etiqueta o la casilla.
- Horario general: consulta con JOIN, agrupado por día, etiqueta "Hoy" y resumen semanal.
- Perfil → **Cargar datos de ejemplo** (4 materias, 5 clases y 5 tareas) para la demostración.

## Semana 5: funcionalidades principales

| Indicador | Qué se hizo |
|---|---|
| Funcionalidad principal | CRUD completo de tareas (crear, editar, eliminar y cambiar estado) organizado por materia, y gestión completa de materias. |
| Funcionalidades secundarias | CRUD de horarios, filtro de tareas por materia, contadores por materia y color propuesto automáticamente. |
| Formularios y validaciones | Tarea (título, materia, fecha con calendario, estado), clase (materia, día, horas en 24 h, aula) y materia. Campos obligatorios, fecha no anterior a hoy, hora de fin mayor que la de inicio, clases sin cruces y nombres de materia sin repetir. |
| Gestión del estado | `AgendaState` (`ChangeNotifier`) con `ListenableBuilder`: al guardar un cambio, todas las pantallas se actualizan solas. |
| Persistencia de datos | Todo se guarda en SQLite (insertar, actualizar y eliminar) y se mantiene al cerrar la app. |
| Manejo de errores | Mensajes de éxito y error (SnackBar), confirmación antes de eliminar o cerrar sesión, aviso de cambios sin guardar y pantalla de error con "Reintentar". |

## Semana 6: fuente de datos local y material académico

La app es 100 % local (sin internet). Las fuentes de datos son SQLite, la carpeta privada del teléfono, la cámara y la galería.

| Indicador | Qué se hizo |
|---|---|
| Conexión con fuente de datos | `DatabaseHelper` (SQLite) y `StorageService` (cámara y galería con `image_picker`, carpeta privada con `path_provider`). |
| Lectura / consulta | Cuadrícula de fotos por materia con filtros por tipo y visor a pantalla completa con zoom. |
| Registro / envío | Foto de la cámara o de la galería → validación → copia a `materiales/materia_<id>/<tipo>_<ms>.<ext>` y registro en la tabla `material`. |
| Actualización / eliminación | Editar nombre y tipo; eliminar borra el registro y el archivo; eliminar una materia borra su carpeta. |
| Manejo de errores | Formato no permitido (solo JPG/PNG), más de 10 MB, permiso de cámara o galería denegado, archivo borrado del teléfono ("Archivo no encontrado"), error al guardar (se borra el archivo copiado). |
| Integración con la interfaz | Materia → Material → Agregar → Ver → Editar o eliminar; contadores de fotos en Materias y en la pestaña. |

## Semana 7: pruebas, corrección de errores y documentación

| Criterio | Qué se hizo |
|---|---|
| Pruebas funcionales | 11 casos (CP01–CP11) automáticos en `integration_test/app_test.dart` + 17 pruebas unitarias en `test/widget_test.dart`. |
| Pruebas de interfaz | 12 pantallas en 5 configuraciones (normal, pequeño 720x1280, tablet 1600x2560, letra 130 %, horizontal) con `integration_test/capturas_test.dart`; capturas en `capturas/`. |
| Multiplataforma | Android (emulador Pixel 6, API 37, y APK release) y web (Chrome). |
| Errores corregidos | E5 fecha de entrega cortada · E6 texto de Inicio cortado · E7 "7 h 30 min" partido con letra grande · E8 la app giraba en horizontal (ahora vertical fija) · E9 "Nueva tarea" sin materias ofrece "Registrar materia". |
| Regresión | Todas las pruebas repetidas después de las correcciones: todas pasan. |

Pruebas funcionales en el emulador (desinstalan la app al terminar; respalda los datos antes):

```bash
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5554
```

## Semana 8: seguridad de la cuenta y acceso directo a las fotos

| Mejora | Detalle |
|---|---|
| Nombre de usuario | Obligatorio al registrarse (4–20 caracteres, sin espacios). Se inicia sesión con usuario **o** correo + contraseña. |
| Huella digital obligatoria | `local_auth` con `biometricOnly: true` (sin internet). Se pide al registrarse, después de la contraseña, al abrir la app con sesión guardada y al volver tras más de 1 minuto en segundo plano. Sin huella registrada en el teléfono no se puede entrar. |
| Recuperar contraseña | "¿Olvidaste tu contraseña?": correo → pregunta de seguridad → huella → contraseña nueva. La respuesta se guarda con hash SHA-256 + salt. |
| Base de datos v2 | Columnas `usuario`, `preguntaSeguridad`, `respuestaHash`. Las cuentas anteriores se migran sin perder datos y deben completar su pregunta de seguridad al entrar. |
| Fotos desde Inicio | Tarjeta "Fotos": todas las fotos con filtro por materia; se toma la foto primero y luego se elige la materia. También siguen en Materias → Material. |
| Gestiones académicas | Base de datos v3 (tabla `gestion`). Perfil > Gestión académica > Nueva gestión: la agenda empieza vacía y las gestiones anteriores quedan guardadas y se pueden volver a abrir. |
| Respaldo (cambio de celular) | Perfil > Respaldo: exporta un .zip con la base de datos y las fotos; en el celular nuevo, Iniciar sesión > Restaurar respaldo. Sin internet (`archive` + `file_picker`). |

Pruebas: 16 casos funcionales (CP01–CP16) en tamaño normal y pequeño, 19 unitarias y capturas `capturas/s8_*`.

### Entrega final
- Carpeta `AGENDA ACADEMICA FLUTTER\07_ENTREGA_FINAL\AgendaAcademica_ReyshellYana.rar` (01_Documentacion, 02_CodigoFuente, 03_APK_o_Build, 04_Recursos, 05_Presentacion).
- Cada archivo `.dart` tiene un encabezado con proyecto, autora, archivo y función.
- Pendiente: demostración en vivo en el celular (con una huella registrada).

## Cómo ejecutar

```bash
flutter pub get
flutter emulators --launch Pixel_6
flutter run
```

En VS Code: pulsa **F5** y elige "Agenda Académica (Android)" o "Agenda Académica (Chrome)".

Pruebas unitarias: `flutter test`

### Cuenta de prueba (solo local)
- Correo: `demo@agenda.test`
- Contraseña: `demo1234`

Cada dispositivo tiene su propia base de datos, así que en un emulador nuevo primero debes registrarte.
