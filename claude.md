# CLAUDE.md

Instrucciones para Claude Code (y cualquier agente de código) que trabaje en este repositorio.
Léelas completas antes de escribir o modificar código.

> **Completa los campos marcados con `<…>`** con los datos de tu proyecto. Este archivo debe
> describir **tu** app, no ExploraEC.

---

## 1. Contexto del proyecto

- **Nombre de la app:** `LexiEC`
- **Dominio / tema:** `Agente de IA para consultas juridicas`
- **Qué hace en una frase:** `Consulta de la legislación ecuatoriana mediante chat de IA`
- **Backend:** `leer @GUIA-API-MOVIL`
- **Fuente de datos de la lista principal:** `API propia`
- **Persistencia local:** `historial` con `Hive`
- **Funcionalidad remota:** `chat con IA`
- **Asistente de IA:** `preguntas sobre los datos`, servido por `url`

Es el **Proyecto Final** del curso *Desarrolla Aplicaciones Móviles Robustas con Flutter e IA*.
Se evalúa revisando el repositorio, instalando el APK del Release y siguiendo el README.
No hay demo en vivo: todo lo que no se pueda observar, no cuenta.

**No copies ExploraEC.** Puedes usarla como referencia de patrones, pero el código y el dominio son propios.

---

## 2. Stack obligatorio

- Flutter y Dart con las versiones usadas en el curso (`Flutter 3.44.0 `). No actualices el SDK ni cambies
  versiones mayores de paquetes sin que te lo pida.
- **GetX** para estado, inyección de dependencias y navegación.
- **flutter_secure_storage** para el token. Nunca guardes el token en `shared_preferences`, Hive sin cifrar ni logs.
- **Hive** o **shared_preferences** para la persistencia local.
- **http** o **dio** para el backend HTTP, o los SDK de Firebase si se usa Firebase.
- Variables de entorno con `flutter_dotenv` o `--dart-define`; solo valores no secretos (URLs base).

Antes de añadir una dependencia nueva, justifícala y pregunta. Menos dependencias es mejor.

---

## 3. Arquitectura en capas (regla estricta)

```
screens/ (UI)  →  controllers/ (GetX)  →  services/ o repositories/  →  data sources (HTTP, Firestore, Hive)
```

Estructura de carpetas esperada:

```
lib/
├── main.dart
├── app/
│   ├── routes/          # GetPage y nombres de rutas
│   ├── bindings/        # Bindings de GetX
│   └── theme/           # Colores, tipografía, espaciado (único lugar)
├── core/
│   ├── config/          # Lectura de entorno (URL base, flags)
│   ├── errors/          # AppException y subclases, mapeo de códigos HTTP
│   └── network/         # Cliente HTTP, interceptor de token
├── data/
│   ├── models/          # Modelos con fromJson/toJson
│   ├── datasources/     # remote_*.dart, local_*.dart
│   └── repositories/    # Implementaciones que combinan fuentes
├── controllers/         # GetxController por funcionalidad
├── screens/             # Una carpeta por pantalla
└── widgets/             # Widgets reutilizables (LoadingView, EmptyView, ErrorView…)
```

Reglas:

1. **Ninguna pantalla** importa `http`, `dio`, `cloud_firestore`, `hive` ni `flutter_secure_storage`.
   Las pantallas solo hablan con controladores.
2. Los controladores no construyen URLs ni parsean JSON: delegan en repositorios/servicios.
3. El estado compartido entre pantallas vive en un `GetxController` (`Rx`, `Obx`, `GetX`).
   `setState` solo se permite para estado efímero y local de un widget (p. ej. una animación).
4. Registra dependencias en `Bindings`, no con `Get.put` disperso dentro de los `build`.
5. Colores, tipografía y espaciado salen siempre de `app/theme/`. Nada de colores literales en pantallas.

---

## 4. Requisitos funcionales que el código debe cumplir

| # | Requisito | Cómo verificarlo |
|---|-----------|------------------|
| 1 | Registro, inicio y cierre de sesión; token en almacenamiento seguro | Cerrar sesión borra el token; una ruta protegida redirige al login sin token |
| 2 | Lista principal desde fuente real o ≥ 15-20 registros en backend/Firestore/Hive | Ningún listado escrito a mano en el código Dart |
| 3 | Persistencia local que sobrevive al cierre completo de la app | Matar la app y reabrir: el dato sigue ahí |
| 4 | Crear, ver y eliminar contenido remoto con autorización real (JWT o reglas de seguridad) | Sin token o con otro usuario, la API/reglas rechazan la operación |
| 5 | Asistente de IA vía servidor propio | La app solo conoce la URL del servidor; nunca la clave del proveedor |
| 6 | Estado centralizado con GetX | Al menos un `GetxController` compartido entre pantallas |

Si es colaborativo, los cambios de un usuario deben ser visibles para otro.
Mapa y geolocalización **no** son requisito; no los añadas salvo que el dominio lo pida.

---

## 5. Estados de UI y manejo de errores

Toda pantalla que carga datos debe tener **cuatro estados distintos y visibles**:
`loading`, `empty`, `error` y `success`. Ninguna pantalla queda en blanco.

Patrón sugerido en el controlador:

```dart
enum ViewStatus { loading, empty, error, success }

final status = ViewStatus.loading.obs;
final errorMessage = ''.obs;
```

Usa los widgets comunes `LoadingView`, `EmptyView` (con acción sugerida) y `ErrorView` (con botón **Reintentar**).

Con backend HTTP, mapea los códigos a mensajes distintos para el usuario:

| Código | Mensaje / acción |
|--------|------------------|
| 400 | Datos inválidos en la solicitud |
| 401 | Sesión expirada → borrar token y llevar al login |
| 403 | Sin permisos para esta acción |
| 404 | Recurso no encontrado |
| 422 | Errores de validación (mostrar los del campo si vienen) |
| 5xx | Error del servidor, intenta más tarde |
| Sin red / timeout | Revisa tu conexión |

Lanza excepciones tipadas desde la capa de datos (`UnauthorizedException`, `ValidationException`,
`ServerException`, `NetworkException`) y conviértelas a texto **solo** en el controlador.

Ninguna pantalla es un callejón sin salida: siempre hay forma de volver, reintentar o navegar.

---

## 6. Seguridad (no negociable)

- **Nunca** escribas claves, tokens, contraseñas o API keys reales en ningún archivo del repositorio,
  ni en código, ni en tests, ni en comentarios, ni en ejemplos.
- La clave del proveedor de IA vive **solo** en el servidor propio, nunca en la app.
- `.env` está en `.gitignore`. Mantén actualizado `.env.example` con nombres de variables y valores ficticios.
- `google-services.json`, `GoogleService-Info.plist`, keystores (`*.jks`, `*.keystore`) y `key.properties`
  no se versionan salvo decisión explícita y documentada.
- No imprimas el token ni respuestas con datos sensibles con `print`/`debugPrint`/`log`.
- Antes de proponer un commit, ejecuta la auditoría de secretos:

```bash
git grep -nIE "(api[_-]?key|secret|password|token|sk-[A-Za-z0-9]{10,}|AIza[0-9A-Za-z_-]{20,})" -- . ':!*.md' ':!.env.example'
git ls-files | grep -E "(^|/)\.env$"
```

Si aparece algo real, detente y avísame. No lo "arregles" en silencio en un commit posterior:
una clave que llegó al historial debe rotarse.

---

## 7. Comandos

```bash
flutter pub get
flutter analyze            # debe terminar sin errores
flutter test               # todas las pruebas en verde
flutter run                # emulador/dispositivo
flutter build apk --release
```

Backend (si es propio): `<comandos exactos para levantarlo, p. ej. docker compose up -d>`


Después de cualquier cambio de código ejecuta `flutter analyze` y `flutter test`.
No des una tarea por terminada si alguno falla. **Nunca** desactives ni borres una prueba para que pase.

---

## 8. CI y Release del APK

- Los workflows viven en `.github/workflows/` (`ci.yml` y el de release, basados en la Sesión 10).
- La CI debe estar en verde en la rama principal.
- El Release se genera al subir una etiqueta:

```bash
git tag v1.0.0
git push origin v1.0.0
```

- El APK queda adjunto en la sección **Releases** y debe instalarse en un emulador Android limpio.


---

## 9. Git y forma de trabajar

- Commits pequeños y frecuentes, con mensajes claros en español, por ejemplo:
  `feat(auth): guardar token en secure storage`, `fix(lista): mostrar estado vacío`.
- Un commit por cambio lógico; nunca un único commit gigante.
- No hagas `git push --force` ni reescribas historial.
- Antes de cada commit muéstrame el `git diff` resumido.
- Si una instrucción mía contradice este archivo (sobre todo seguridad o arquitectura), señálalo antes de actuar.
- Si no estás seguro de algo del dominio o del backend, pregunta en lugar de inventar endpoints o campos.

---

## 10. README (lo revisará quien evalúa)

Cuando trabajes en `README.md` (puedes partir de `docs/README-plantilla.md`), debe incluir:

- **Para ejecutar:** qué hace la app, capturas, requisitos, cómo levantar el backend con comandos exactos,
  URLs por entorno y cómo instalar el APK del Release.
- **Para entender:** diagrama de capas y al menos una decisión técnica propia (qué se eligió y qué se descartó).
- **Para confiar:** dónde viven las claves y el token, créditos y licencias de fuentes de datos y paquetes.

La documentación técnica más larga puede ir en `docs/ARQUITECTURA.md`.

---

## 11. Lista de verificación antes del release

- [ ] `flutter analyze` sin errores y `flutter test` en verde.
- [ ] CI en verde en la rama principal.
- [ ] Ninguna pantalla importa HTTP, Firestore, Hive ni secure storage.
- [ ] Cada pantalla con datos muestra carga, vacío y error (probado apagando el backend o la red).
- [ ] Mensajes distintos para 401, 400, 422 y 5xx.
- [ ] La funcionalidad local sobrevive al cierre completo de la app.
- [ ] Una funcionalidad protegida rechaza a un usuario no autenticado.
- [ ] El asistente de IA llama al servidor propio; ninguna clave en la app.
- [ ] Auditoría de secretos limpia, `.env` ignorado, `.env.example` presente.
- [ ] Release con APK generado por GitHub Actions e instalado en un emulador limpio.
- [ ] README seguible sin preguntar nada.
- [ ] `AGENTS.md` y este `CLAUDE.md` describen este proyecto, no ExploraEC.

**Fecha límite de entrega:** lunes 26 de octubre, 8:00 a. m. (enlace del repositorio en Moodle).