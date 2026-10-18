# 15-Puzzle — Rompecabezas deslizante

Microproyecto de **Sistemas de Información**, desarrollado en **Flutter y Dart** por **Mariana Di Buongrazio** y **Alexander Ramírez**.

El objetivo es ordenar las fichas numeradas moviendo únicamente las que están junto al espacio vacío. El juego ofrece tres tamaños de tablero y registra los mejores resultados de cada dificultad en el dispositivo.

**Aplicación web:** https://marianadibuongrazio.github.io/Microproyecto.-Mariana-y-Alexander/

## Funcionalidades implementadas

- Tableros **3 × 3** (8 fichas), **4 × 4** (15 fichas) y **5 × 5** (24 fichas).
- Mezclas aleatorias verificadas como **resolubles**, sin iniciar con el tablero ordenado.
- Movimientos válidos únicamente hacia una casilla libre adyacente (sin diagonales ni saltos entre filas).
- Contador de movimientos, cronómetro desde el primer movimiento válido y reinicio de partida.
- Detección de victoria y almacenamiento automático de récords por **menor tiempo** y **menor cantidad de movimientos**, de forma independiente.
- Menú principal e instrucciones, selector de dificultad, configuración de tema (claro, oscuro o sistema), cuatro estilos de fichas y opción de animaciones.
- Preferencias y récords guardados **localmente** mediante `shared_preferences`.
- Compilación y publicación automáticas de Flutter Web mediante GitHub Actions y GitHub Pages.
- PWA con manifiesto y caché offline. Después de la instalación y carga completa de sus recursos, la aplicación puede recargarse sin Internet en navegadores compatibles.

> **Pendientes de interfaz al 18/10/2026:** la pantalla de consulta/borrado de marcadores y el Splash inicial todavía no están conectados en `main`. El menú muestra un aviso provisional en «Marcadores». Los récords sí se guardan internamente al ganar. El selector de dificultad se presenta al pulsar «Jugar», incluso cuando hay una preferencia previa. Estos puntos se actualizarán cuando se integren sus pantallas.

## Requisitos para desarrollo local

- Flutter **3.47.7** (versión utilizada por el workflow de publicación).
- Dart incluido con Flutter.
- Chrome para ejecutar la versión web.
- Git para clonar el repositorio.

Verifica tu entorno con:

```bash
flutter --version
flutter doctor
flutter devices
```

## Instalación y ejecución

```bash
git clone https://github.com/marianadibuongrazio/Microproyecto.-Mariana-y-Alexander.git
cd Microproyecto.-Mariana-y-Alexander
flutter pub get
flutter run -d chrome
```

El comando anterior abre la aplicación en modo desarrollo. Para ver únicamente la pantalla del juego de manera aislada, también está disponible:

```bash
flutter run -d chrome -t tool/game_preview.dart
```

## Pruebas y análisis

```bash
flutter analyze
flutter test
```

Las pruebas automatizadas cubren reglas del puzzle, solvencia, movimientos, preferencias, récords, victoria y widgets de juego. El workflow ejecuta análisis y pruebas de nuevo en cada actualización fusionada a `main`.

Para construir la versión de producción dirigida a GitHub Pages:

```bash
flutter build web --release \
  --base-href "/Microproyecto.-Mariana-y-Alexander/"
python3 tool/build_pwa.py build/web
```

La ruta indicada en `--base-href` es necesaria porque este proyecto se publica dentro de un subdirectorio de GitHub Pages. El generador crea `build/web/puzzle-sw.js` con la lista versionada de recursos estáticos; excluye archivos ocultos internos de Flutter, que GitHub Pages no sirve.

## Publicación en GitHub Pages

El archivo [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) ejecuta automáticamente los siguientes pasos en GitHub Actions cuando se actualiza `main`:

1. Descarga el código e instala Flutter.
2. Ejecuta `flutter pub get`, `flutter analyze` y `flutter test`.
3. Compila `build/web` con la ruta base correcta.
4. Genera la caché offline y verifica los archivos publicados.
5. Sube el artefacto web y lo despliega en GitHub Pages.

En **Settings → Pages** del repositorio, la fuente de publicación debe ser **GitHub Actions**. El historial y los resultados están disponibles en la pestaña **Actions**.

## Instalación y verificación offline

1. Abre la [aplicación publicada](https://marianadibuongrazio.github.io/Microproyecto.-Mariana-y-Alexander/) con conexión a Internet, preferiblemente en Chrome.
2. Espera a que se instale el *service worker* y termine de guardar los recursos. Recarga una vez de forma normal si es necesario.
3. En DevTools → **Application → Service Workers**, comprueba que el worker esté `activated` y controle la página. En **Cache Storage** debe existir una caché `puzzle-unimet-…`.
4. Desconecta el Wi-Fi y recarga normalmente (`Cmd + R` en Mac; evita la recarga forzada). El juego debe seguir disponible.
5. Regresa a Internet para permitir posteriores actualizaciones.

**Importante:** `flutter run -d chrome` es un servidor de desarrollo y no equivale a una prueba de la PWA publicada. El guardado de récords es local al navegador/dispositivo; no se sincroniza entre dispositivos. Borrar los datos del sitio puede eliminar esas preferencias y puntuaciones.

## Organización del código

```text
lib/
  main.dart                   Menú, navegación y tema
  configuracion.dart          Pantalla de preferencias
  game/
    puzzle_engine.dart        Lógica pura del rompecabezas
    puzzle_game_screen.dart   Tablero, cronómetro, victoria
  models/
    app_settings.dart         Configuración serializable
    high_score.dart           Récords y resultados
  services/
    local_storage.dart        Preferencias y récords locales
test/
  puzzle_engine_test.dart
  puzzle_game_screen_test.dart
  puzzle_victory_test.dart
  local_storage_test.dart
  widget_test.dart
tool/
  game_preview.dart           Entrada aislada para pruebas visuales
  build_pwa.py                Generador del service worker
web/
  index.html
  manifest.json
  flutter_bootstrap.js
.github/workflows/
  deploy.yml
```

## Colaboración y contribuciones

| Integrante | Principales aportes en el historial del repositorio |
|---|---|
| **Mariana Di Buongrazio** | Estructura inicial del proyecto, menú principal, instrucciones, navegación, selector de dificultad, configuración visual y aplicación del tema. |
| **Alexander Ramírez** | Motor y pruebas del puzzle; contratos, modelos y almacenamiento de preferencias y récords; pantalla del tablero; detección de victoria y guardado de resultados; despliegue web, PWA offline y documentación. |

El trabajo se integra mediante ramas independientes y *pull requests* hacia `main`. La atribución de archivos se basa en los commits publicados: ambas personas colaboran en la revisión e integración del proyecto.

## Limitaciones conocidas

- La pantalla visible de «Marcadores» y el Splash inicial están pendientes de integración en `main` a la fecha indicada arriba.
- No existe sincronización de partidas, récords o preferencias entre dispositivos: el almacenamiento es local.
- Para usar la PWA sin red, el navegador debe completar previamente la instalación y caché de los recursos online.
- El modo imagen y la clasificación online no forman parte del alcance implementado.
