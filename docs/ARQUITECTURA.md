# Arquitectura de LexiEC

Complementa la sección *Arquitectura* del [README](../README.md). El contrato de la API está en
`lexiec_ia/docs/GUIA_API_MOVIL.md`.

## Capas

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ screens/      Widgets. Leen estado con Obx y llaman métodos del controlador.│
│               No importan dio, Hive ni flutter_secure_storage.             │
├────────────────────────────────────────────────────────────────────────────┤
│ controllers/  GetxController. Estado (Rx + ViewStatus), validación y       │
│               traducción de AppException a texto (mensajes_error.dart).     │
├────────────────────────────────────────────────────────────────────────────┤
│ repositories/ Combinan fuentes: API como fuente de verdad + caché local.   │
├────────────────────────────────────────────────────────────────────────────┤
│ datasources/  remote_* (dio)  ·  local_* (Hive cifrado, secure storage)     │
├────────────────────────────────────────────────────────────────────────────┤
│ core/         ApiClient + interceptores, LectorSse, Cancelacion,           │
│               MapeadorErrores → AppException tipadas, AppConfig, Reporte.  │
└────────────────────────────────────────────────────────────────────────────┘
```

Inyección de dependencias:

- `InicialBinding` registra lo que vive toda la app con `permanent`: almacén de tokens, `ApiClient`,
  datasources, repositorios, `SesionController` y `TemaController`.
- Cada ruta tiene su propio binding (`auth_bindings`, `consultas_bindings`, `cuenta_bindings`) para
  sus controladores.

## Navegación y sesión

```text
InicioScreen ─ InicioController
   ├─ 1.ª vez ─────────────▶ /bienvenida ─▶ /login
   ├─ sin tokens ──────────▶ /login  ⇄  /registro        (SoloInvitadoMiddleware)
   └─ tokens válidos ──────▶ /consultas ─▶ /consultas/:id (SesionRequeridaMiddleware)
                                 ├─▶ /normas
                                 └─▶ /perfil ─▶ /perfil/clave · /perfil/eliminar
```

- **Al abrir la app**, `SesionController` valida la sesión con `GET /auth/me`. Si el access token
  venció, el interceptor lo renueva. Sin red, la sesión se mantiene y se trabaja con el historial
  local.
- **Si la sesión expira sin posibilidad de renovarla**, `AuthInterceptor` emite un aviso en
  `EventosSesion`. `SesionController` lo escucha, borra tokens e historial y lleva al login con el
  mensaje "Tu sesión expiró".
- **Al cerrar sesión** se llama a `POST /auth/cerrar-sesion`, que revoca el refresh token en el
  servidor. Después se borran los tokens del almacenamiento seguro y se vacía la caja cifrada del
  historial.
- **Al eliminar la cuenta** no se llama a cerrar-sesión, porque el servidor ya invalidó todo
  (`salirSinRevocar`).

## Renovación del token (decisión principal)

`AuthInterceptor` es un `QueuedInterceptor`:

1. En `onRequest` agrega `Authorization: Bearer <access>` y anota qué token usó la petición.
2. En `onError`, si la respuesta es 401 y la ruta no es pública:
   - Si el token guardado ya cambió, es porque otra petición lo renovó mientras esta esperaba en la
     cola. Entonces solo reintenta con el token nuevo.
   - Si no cambió, llama a `POST /auth/refrescar` con `dioBase`, un cliente sin este interceptor para
     no bloquear la cola. Luego guarda **ambos** tokens, porque el refresh rota, y reintenta una sola
     vez.
   - Si la renovación falla con 401, emite la expiración de la sesión.

Así, N peticiones con 401 simultáneo producen una sola renovación. Reutilizar un refresh token ya
rotado revoca la sesión en el backend, así que este caso es crítico. Está probado en
`test/core/auth_interceptor_test.dart`.

## Chat con respuesta en streaming

```text
ConsultaScreen ─ ConsultaController.enviar()
   │  agrega la pregunta a la lista (optimista) y abre la burbuja provisional
   ▼
ChatRepository ─ RemoteChatDatasource
   │  POST /conversaciones/{id}/mensajes/stream  (ResponseType.stream)
   ▼
LectorSse   bytes → utf8.decoder → líneas → eventos (tolera trozos partidos)
   ▼
EventoChat (sealed)
   ├─ EventoDelta  → se va mostrando como texto provisional ("Verificando las fuentes…")
   ├─ EventoFinal  → REEMPLAZA el provisional por la respuesta verificada + citas
   ├─ EventoError  → el turno no se guardó: se quita la pregunta y vuelve al cuadro de texto
   └─ desconocido  → se ignora (compatibilidad con versiones futuras del backend)
```

- El backend verifica la respuesta contra los fragmentos recuperados antes de emitir `final`. Por eso
  el texto provisional se muestra en gris y nunca se guarda: solo se persiste lo que llega en `final`.
- Las citas se agrupan por documento en `BurbujaMensaje`. Cada una muestra el artículo, la página y el
  texto literal en una hoja inferior.
- Ante 429 o 503 "ocupado" con `Retry-After`, el compositor muestra una cuenta regresiva y deshabilita el envío.
- Si se sale de la pantalla en mitad de la respuesta, `Cancelacion` cierra la conexión.
- La primera respuesta asigna un título automático a la consulta. `ConversacionesController` la sube
  al inicio de **Mis consultas** sin recargar la lista.

## Persistencia local

| Dato | Dónde | Por qué |
|---|---|---|
| Access y refresh token | `flutter_secure_storage` (Android Keystore) | Nunca en Hive sin cifrar ni en logs |
| Clave AES-256 de la caché | `flutter_secure_storage` | Se genera una vez en el dispositivo |
| Lista y detalle de consultas | Caja Hive `conversaciones` **cifrada** | Pueden contener datos personales y se pueden leer sin conexión |
| Tema y "ya vio la bienvenida" | Caja Hive de preferencias | No son datos sensibles |

La caché guarda a qué usuario pertenece. Si inicia sesión otra cuenta en el mismo teléfono, la caché
se vacía antes de usarla.

## Errores

- `MapeadorErrores` convierte un `DioException` en una excepción tipada (`AppException` sellada):
  - `BadRequestException` (400)
  - `UnauthorizedException` (401)
  - `ForbiddenException` (403)
  - `NotFoundException` (404)
  - `ConflictException` (409)
  - `ValidationException` (422, con errores por campo)
  - `RateLimitException` (429, con segundos de espera)
  - `ServiceBusyException` (503 "ocupado", con `Retry-After`)
  - `RequestTimeoutException` (504 o timeout)
  - `ServerException` (otros 5xx)
  - `NetworkException` (sin red)
  - `CancelledException` y `UnknownException`
- El cuerpo de error se lee tanto en JSON de la API como en las páginas HTML de Nginx (429, 502, 503).
- Solo los controladores convierten esas excepciones en texto, con `mensajes_error.dart`.
- `ReporteErrores.instalar()` captura los errores no controlados para que la app no se cierre. Una
  sección que falla muestra `ErrorDeSeccion` en lugar de la pantalla roja o gris. En release solo se
  registra el tipo de error, nunca tokens ni contenido de las consultas.

## Tema y accesibilidad

- `app/theme/` es el único lugar con colores, tipografía y espaciado.
- Paleta: azul marino institucional con ámbar de acento, en modo claro y oscuro. Los colores propios
  de la marca están en la extensión `ColoresMarca`.
- `test/app/contraste_test.dart` verifica un contraste mínimo de 4.5:1 en los pares texto/fondo.
- `test/app/texto_grande_test.dart` recorre las pantallas con la letra al 160 % en un teléfono de
  360 dp de ancho para detectar desbordamientos.

## Pruebas

```bash
flutter test -j 2
```

- `core/`: interceptor de token, lector SSE, mapeo de errores y configuración.
- `data/`: modelos, repositorios y caché cifrada.
- `screens/`: flujos completos con un backend simulado (`test/helpers/red_falsa.dart`):
  - login, registro y cierre de sesión;
  - lista, detalle y eliminación con deshacer;
  - chat en streaming;
  - Mi cuenta.

## Release

`.github/workflows/release-apk.yml`:

1. Se dispara con una etiqueta `v*`.
2. Ejecuta `analyze` y `test`.
3. Prepara la firma desde *secrets*, si existen.
4. Compila con `API_BASE_URL=https://lexiec.katarisoft.com/api/v1`.
5. Publica `lexiec-<tag>.apk` en Releases.
