# TrackEdge

Aplicación nativa y local de barra de menús para macOS 13 o posterior. Esta compilación es para Apple Silicon. Sin servidores, cuentas, telemetría, suscripción ni dependencias descargadas. Implementación independiente de las funciones de uso descritas en https://edgebar.xyz/ el 1 de noviembre de 2026.

Iconos actualizados: dos barras verticales, naranja a la izquierda y verde a la derecha en el icono de la aplicación; versión monocroma con ambos bordes en la barra de menús.

## Interfaz 0.2.0

Menú y ajustes reorganizados a partir de las capturas oficiales https://edgebar.xyz/menubar-main.png y https://edgebar.xyz/menubar-settings.png. Se mantienen el nombre TrackEdge, la versión local y los colores naranja y verde solicitados por el usuario. Los textos y la disposición de los controles siguen las capturas en inglés.

El menú presenta brillo y volumen en sus bordes, selector háptico Off/Light/Medium/Strong, Quick Mute, Media Strip con el toque de reproducción desplegable y deslizadores con valores. Settings abre dentro del mismo panel las secciones Edge Gestures, While Sliding y General; Back regresa al menú. El menú de puntos contiene Pause/Resume Gestures y Setup & Diagnostics. Require Fn or Option admite cualquiera de esas dos teclas. La apariencia tiene las opciones Light y Dark visibles en la referencia.

Se han comprobado en la app abierta la navegación Settings/Back y la presencia de los controles; también se han renderizado las vistas claras y oscuras para su revisión visual.

## Abrir y usar

Abre `TrackEdge.app`. Su icono aparece en la barra superior; no tiene icono en el Dock. Desde el menú puedes cambiar volumen y brillo, controlar la reproducción, pausar los gestos, ajustar sensibilidad y anchura del borde, y abrir los ajustes avanzados. El dibujo del trackpad muestra los valores actuales; sus laterales también admiten clic y arrastre.

Concede Accesibilidad a **TrackEdge** en Ajustes del Sistema → Privacidad y seguridad. Si macOS pide Monitorización de entrada, concede también ese permiso. Tras actualizar una compilación firmada localmente puede ser necesario desactivar y reactivar Accesibilidad y reiniciar TrackEdge.

Cierra el menú y los ajustes para usar gestos. Empieza con un solo dedo en el borde correspondiente:

- Derecha, arriba/abajo: volumen.
- Izquierda, arriba/abajo: brillo de la pantalla integrada.
- Dos toques rápidos en la esquina superior derecha: silencio.
- Borde inferior, deslizar derecha/izquierda: siguiente/anterior pista.
- Toque en el borde inferior: reproducir/pausar, si se activa en Ajustes (desactivado inicialmente para evitar pausas accidentales).
- Mantén ⇧⌥ para pasos de un cuarto del incremento normal.

Los ajustes permiten intercambiar los lados, limitar los laterales al cuarto inferior, exigir Opción o Fn, activar/desactivar el bloqueo del cursor, elegir intensidad háptica, apariencia e inicio de sesión. Para apagar temporalmente los gestos desmarca «Activar gestos». «Salir» termina la aplicación.

## Cobertura y comprobación

| Función de la referencia | Implementación | Verificación realizada |
|---|---|---|
| Volumen lateral derecho | Teclas multimedia del sistema | Confirmada con el trackpad por el usuario |
| Brillo lateral izquierdo | Teclas de brillo; control directo desde el menú | Confirmada con el trackpad por el usuario |
| Indicador de volumen/brillo | Eventos de teclado gestionados por macOS para su indicador nativo | Ruta implementada; aspecto del indicador depende de macOS |
| Silencio con doble toque | Detección temporal en esquina superior derecha | Prueba del motor de gestos |
| Franja multimedia | Anterior/siguiente; toque opcional para reproducción | Pruebas del motor; envío de teclas implementado |
| Respuesta háptica | Actuador del trackpad localizado por IOKit; respaldo AppKit | Confirmada físicamente por el usuario |
| Intensidad háptica | Suave / normal / firme | Panel revisado; sensaciones por nivel pendientes de comparación física |
| Control fino ⇧⌥ | Cuartos de paso mediante modificadores de teclado | Prueba del motor |
| Cursor fijo | Posición anclada y deltas anulados en filtro HID; desacoplamiento auxiliar | Confirmada físicamente por el usuario tras corregir dos intentos anteriores |
| Solo cuarto inferior | Restricción del inicio del gesto lateral | Prueba del motor |
| Intercambiar lados | Asignación invertida de volumen/brillo | Prueba del motor |
| Solo barra de menús | NSStatusItem, LSUIElement; sin Dock | App abierta y menú inspeccionado |
| Sensibilidad y anchura | Deslizadores persistentes | Motor probado; controles inspeccionados |
| Exigir Opción / Fn | Modificador seleccionado al reconocer contactos | Pruebas del motor y panel inspeccionado |
| Apariencia clara / oscura / sistema | NSAppearance | Control implementado y panel inspeccionado |
| Abrir al iniciar sesión | SMAppService.mainApp | Implementado; no se activó ni se probó reiniciando la sesión del usuario |
| Preferencias persistentes | UserDefaults del bundle | Implementado |
| Guía inicial y diagnóstico | Permisos, trackpad conectado, contactos y filtro HID | Abierta e inspeccionada |

Se han superado **38 comprobaciones automáticas** del motor y de la fijación/restauración de eventos del cursor. También se ha verificado fuera del entorno restringido la lectura real de volumen y brillo y la apertura del trackpad de este Mac. Las pruebas automáticas no sustituyen la reproducción real de multimedia, el reinicio de sesión ni la comparación de sensaciones hápticas.

La distribución comercial de la referencia (pago, claves de licencia y descarga automática de actualizaciones desde sus servidores) no forma parte de esta aplicación privada. Las actualizaciones de TrackEdge se realizan reemplazando su app local.

## Límites

La lectura de contactos y los hápticos utilizan interfaces internas de macOS cargadas dinámicamente. Una actualización del sistema puede exigir adaptaciones. La compatibilidad comprobada corresponde al trackpad integrado del Mac del usuario; otros dispositivos requieren prueba. El brillo está pensado para la pantalla integrada; no se implementa DDC para monitores externos. Las salidas de audio con volumen fijo no admiten cambios por software. Las teclas multimedia actúan sobre el reproductor elegido por macOS.

El cursor se libera al terminar/cancelar el gesto, pausar los controles o salir; un temporizador recupera el estado si dejan de llegar contactos. Los gestos que empiezan en el centro y los contactos múltiples se dejan fuera de los controles de borde.

## Compilar y probar

Con las herramientas de Xcode instaladas:

```sh
./build.sh
./test.sh
./TrackEdge.app/Contents/MacOS/TrackEdge --self-check
```

`build.sh` compila sin descargar paquetes, firma ad hoc, comprueba la firma y crea `../TrackEdge.zip`. La firma local no equivale a notarización con una cuenta de Apple Developer. Compila para la arquitectura del Mac donde se ejecute el script.

## Referencias técnicas

- https://developer.apple.com/documentation/coregraphics/cgassociatemouseandmousecursorposition(_:)
- https://developer.apple.com/documentation/servicemanagement/smappservice
- https://github.com/lauschue/Remotastic/blob/main/MultitouchSupport.h (referencia de la ABI privada)
- https://gist.github.com/niw/b120b460e854ec10cefeeb60784f5dbb (interfaz del actuador)

El código fuente de esta carpeta es la implementación local entregada con la app.
