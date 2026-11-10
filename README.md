# Track Edge

Herramienta nativa de macOS que convierte los bordes del trackpad en controles de volumen, brillo y reproducción. Vive en la barra de menús y funciona en local, sin cuentas, servidores ni suscripciones.

## Inspiración y atribución

**Track Edge está basado en la idea y la interfaz de [EdgeBar](https://edgebar.xyz/), creada por Shashank Bhardwaj ([@bhardwajshash](https://x.com/bhardwajshash)).** Este proyecto surgió tras conocer la herramienta a través de [su publicación en X](https://x.com/bhardwajshash/status/2116878227335778610).

EdgeBar es la referencia original de los gestos y de la distribución del menú y sus ajustes. Track Edge es una implementación independiente en Swift y Objective-C, creada para ejecutarse y compilarse en local. No es el código fuente oficial de EdgeBar ni está afiliado a su autor. El nombre del ejecutable y de la aplicación compilada es **TrackEdge**.

## Funciones

- **Volumen:** desliza arriba o abajo por el borde derecho.
- **Brillo:** desliza arriba o abajo por el borde izquierdo.
- **Silencio rápido:** doble toque en la esquina superior derecha.
- **Reproducción:** desliza por el borde inferior para cambiar de pista; el toque para reproducir o pausar se puede activar por separado.
- **Respuesta háptica:** desactivada, suave, media o fuerte, según el trackpad.
- **Control fino:** mantén Mayúsculas + Opción para incrementos de un cuarto del paso normal.
- **Cursor fijo:** mantiene el puntero en su sitio durante el gesto y lo libera al levantar el dedo.
- **Personalización:** intercambia los laterales, limita su zona al cuarto inferior o exige Fn u Opción.
- **Menú:** niveles de volumen y brillo, sensibilidad, anchura del borde, pausa de gestos y diagnóstico.
- **Ajustes:** apariencia clara/oscura, opciones de gestos e inicio de sesión.

Los gestos que comienzan en el centro del trackpad y los contactos con varios dedos no activan los controles de borde. Los gestos se pausan mientras el panel está abierto. El icono de la app tiene una barra naranja y otra verde; el icono de la barra de menús tiene ambos laterales en monocromo.

## Requisitos

- macOS 13 o posterior.
- Trackpad compatible. La prueba física realizada corresponde al trackpad integrado de un MacBook Pro con Apple Silicon.
- Xcode o sus herramientas de desarrollo, con `swiftc`, `clang`, `iconutil` y `codesign` disponibles.
- Permiso de **Accesibilidad** para TrackEdge. Si macOS solicita Monitorización de entrada, también debe concederse.

## Compilar

Clona este repositorio, entra en su carpeta y ejecuta:

```sh
./build.sh
```

El script compila para la arquitectura del Mac actual, genera los iconos y crea `TrackEdge.app` en la carpeta del proyecto. También crea `TrackEdge.zip` en la carpeta superior. Firma la app de forma local (ad hoc); no usa una cuenta de Apple Developer ni realiza notarización. No descarga dependencias.

Abre `TrackEdge.app` desde Finder. Aparecerá en la barra de menús, sin icono en el Dock.

## Configuración inicial

1. Abre Ajustes del Sistema → Privacidad y seguridad → Accesibilidad y permite el acceso a **TrackEdge**.
2. Si el sistema lo solicita, habilita Monitorización de entrada y reinicia la app.
3. Cierra el menú de TrackEdge y prueba los laterales con un solo dedo.
4. Abre **Settings** para configurar los gestos. **Back** vuelve al menú principal. El botón de puntos contiene **Pause/Resume Gestures** y **Setup & Diagnostics**; el botón de encendido sale de la app.

Tras recompilar o reemplazar una app firmada localmente, macOS puede pedir que se vuelva a conceder Accesibilidad. Las preferencias se guardan mediante `UserDefaults` en el dominio `local.trackedge.app`.

## Pruebas y diagnóstico

```sh
./test.sh
./TrackEdge.app/Contents/MacOS/TrackEdge --self-check
```

Hay **54 comprobaciones automáticas** del reconocimiento de gestos y del bloqueo/restauración de eventos del cursor. Volumen, brillo, hápticos y cursor fijo se comprobaron además físicamente durante el desarrollo. La reproducción multimedia, cada nivel háptico y el inicio automático requieren comprobarse en cada entorno.

Se pueden renderizar los paneles de la app sin iniciar el lector de gestos:

```sh
./TrackEdge.app/Contents/MacOS/TrackEdge --render-panels Preview
```

El detalle de la comprobación inicial está en [docs/VALIDATION.md](docs/VALIDATION.md). Las correcciones y pruebas de esta revisión están en [docs/AUDIT-2026-11-10.md](docs/AUDIT-2026-11-10.md).

## Estructura

- `Sources/`: aplicación AppKit, panel de controles, motor de gestos, bloqueo del cursor y controles del sistema.
- `Sources/Bridge.m` y `Bridge.h`: acceso dinámico a MultitouchSupport y al actuador háptico.
- `Sources/TrackpadPreview.swift`: vista conservada de la primera interfaz; el panel actual usa `ControlPanel.swift`.
- `Assets/`: dibujo del icono y generador de los tamaños de macOS.
- `Tests/`: comprobaciones del motor y del cursor, sin publicar eventos al sistema.
- `Info.plist`: metadatos de la app.
- `build.sh` y `test.sh`: compilación y pruebas reproducibles.

## Compatibilidad y límites

La lectura de contactos y el actuador háptico usan interfaces internas de macOS cargadas dinámicamente. Una actualización del sistema puede requerir adaptar la implementación. El brillo está pensado para la pantalla integrada; no incluye DDC para monitores externos. Algunas salidas de audio tienen volumen fijo y no permiten ajustarlo por software. Las teclas multimedia actúan sobre el reproductor seleccionado por macOS.

El proyecto no incluye pagos, claves de licencia ni el servicio de actualización de EdgeBar. Las actualizaciones de Track Edge se hacen recompilando o reemplazando la aplicación local.

## Referencias técnicas

- [Apple: CGAssociateMouseAndMouseCursorPosition](https://developer.apple.com/documentation/coregraphics/cgassociatemouseandmousecursorposition(_:))
- [Apple: SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice)
- [Referencia de la ABI de MultitouchSupport](https://github.com/lauschue/Remotastic/blob/main/MultitouchSupport.h)
- [Interfaz del actuador háptico, por niw](https://gist.github.com/niw/b120b460e854ec10cefeeb60784f5dbb)
