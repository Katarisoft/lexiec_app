# AGENTS.md — reglas del proyecto LexiEC

Este archivo lo leen los agentes de código (Claude Code, Codex, Antigravity…) al abrir esta carpeta. Es el **archivo de contexto** del proyecto. Las reglas detalladas están en [`claude.md`](claude.md); la API está documentada en `lexiec_ia/docs/GUIA_API_MOVIL.md`.

## Qué es el proyecto

LexiEC es una app Flutter (Android) para consultar la legislación ecuatoriana mediante un chat de IA que responde **citando el artículo y la página** de la norma. Estado con GetX, datos remotos con `dio` contra el backend propio `lexiec_ia` (FastAPI con JWT y refresh token, prefijo `/api/v1`), caché local cifrada con Hive, tokens en `flutter_secure_storage`. La app solo conoce la URL del servidor: ninguna clave de IA.

## Dónde está cada cosa

- `lib/app/` — rutas (`routes/`), bindings (`bindings/`) y tema (`theme/`: único lugar con colores, tipografía y espaciado).
- `lib/core/` — configuración de entorno (`config/`), errores tipados y manejo global (`errors/`), cliente HTTP e interceptores (`network/`).
- `lib/data/` — modelos (`models/`), fuentes de datos remotas y locales (`datasources/`) y repositorios (`repositories/`).
- `lib/controllers/` — estado compartido (controladores GetX).
- `lib/screens/` — una carpeta por pantalla. `lib/widgets/` — piezas reutilizables (`LoadingView`, `EmptyView`, `ErrorView`…).
- `test/` — pruebas unitarias y de widgets.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
dart format lib test
flutter analyze
flutter test
```

Deben terminar sin errores. Si fallan, corrige el código; no desactives el análisis ni borres pruebas para que pasen.

Backend local para desarrollo: `flutter run --dart-define-from-file=.env` (ver `.env.example`).

## Convenciones

- El estado compartido vive en un controlador GetX; las pantallas no llaman directamente al backend, a Hive ni al almacenamiento seguro.
- Todo texto visible para la persona va en español neutro.
- Cada pantalla con datos cubre cuatro estados: cargando, vacío, error (con Reintentar) y contenido.
- Cambios pequeños y enfocados: una funcionalidad a la vez, con una prueba de widget por cada comportamiento nuevo.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar `.env`.
- Agregar dependencias nuevas sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git push` o crear etiquetas: eso lo hace la persona después de revisar el cambio.

## Reglas del estudiante

- No ejecutar `git commit`.
- No ejecutar `git push`.
