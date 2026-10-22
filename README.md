# ARVI — juegos para Arleth, sin anuncios

App Android hecha con Flutter para una niña de 3 años. No tiene anuncios, no usa internet y no pide
cuentas. En el celular se llama **ARVI**.

Al abrirla sale una presentación con estrellas (**PINTEMOS ARLETH**) y después el **menú de juegos**:
tarjetas grandes, una por juego. Al tocar una, la voz dice su nombre y el juego empieza.

| Juego | Qué aprende | Cómo se juega | Su carpeta |
|---|---|---|---|
| 🎨 **Pintar** | Colores, motricidad | Elige un color y pinta los dibujos con toques. Dos modos de pintar. | `lib/juegos/pintar/` |
| 🎈 **Colores** | Nombres de los colores | La voz dice "¡Toca el globo rojo!" y ella toca ese globo, que revienta con estrellitas. | `lib/juegos/colores/` |
| 🐶 **Animales** | Animales y sus sonidos | La voz pregunta "¿Quién hace guau guau?" y ella toca al perro. Cada animal hace su sonido. | `lib/juegos/animales/` |
| 🫧 **Burbujas** | Motricidad, puntería | Salen burbujas por todos los lados y flotan; con un toque revientan ("¡POP!"). Hay que reventarlas todas. Niveles sin fin (recuerda el nivel), con súper burbujas, animalitos, mega burbujas que explotan en burbujitas, burbujitas rápidas y la arcoíris que revienta todas. | `lib/juegos/burbujas/` |
| 🍎 **¿Cuántos hay?** | Contar del 1 al 5 | Toca cada cosa y la voz cuenta; después elige el número correcto (con puntitos de ayuda). | `lib/juegos/contar/` |

En todos los juegos:
- La **casita** azul vuelve al menú.
- La **orejita** morada repite lo que dijo la voz.
- Cada acierto da una **estrella**, y cada 5 aciertos sale la **celebración grande** (en Burbujas, cada burbuja da
  una estrella; al terminar cada nivel hay un festejo corto, y cada 5 niveles la celebración grande).
- Si se equivoca, no hay castigo. La voz le dice qué tocó y, si se equivoca varias veces, el correcto **brilla** para ayudarla.
- Empieza fácil y se pone más difícil sola si acierta seguido (más opciones, o más cosas para contar). Si le cuesta,
  vuelve a ser fácil. En Burbujas la dificultad sube con los niveles (con niveles más tranquilos de vez en cuando).

En el menú, el **botón rojo** cierra la app y el **engranaje** gris abre los **Ajustes** (zona de papás). En Ajustes se puede:
- Apagar o encender cada juego del menú.
- Elegir el modo de pintar.
- Agregar o borrar dibujos.
- Ver en qué nivel va Burbujas y volver al nivel 1.

## Cómo está ordenado el proyecto

```
colorear_ninos/
├── README.md ............ este archivo
├── lib/ ................. el código de la app  →  mapa completo en lib/LEEME.md
│   ├── main.dart ........ arranca la app (no hace falta tocarlo)
│   ├── app/ ............. lo de toda la app: menú, presentación, Ajustes
│   │   ├── ajustes_app.dart ... ⭐ ajustes generales (voz, colores, textos)
│   │   └── lista_juegos.dart .. ⭐ qué juegos salen en el menú y en qué orden
│   ├── comun/ ........... piezas que usan todos los juegos (voz, sonidos, celebración...)
│   └── juegos/ .......... UN JUEGO POR CARPETA, cada una con su LEEME.md
│       ├── pintar/ ...... pintar_ajustes.dart ⭐
│       ├── colores/ ..... colores_ajustes.dart ⭐
│       ├── animales/ .... animales_ajustes.dart ⭐
│       ├── burbujas/ .... burbujas_ajustes.dart ⭐
│       └── contar/ ...... contar_ajustes.dart ⭐
├── assets/
│   ├── sonidos/ ......... los sonidos, un grupo por carpeta (ver su LEEME.txt)
│   ├── voces/ ........... tus voces grabadas (opcional, ver su LEEME.txt)
│   └── drawings/ ........ los dibujos de Pintar
├── mis_dibujos/ ......... tus imágenes para pintar (ver su LEEME.txt)
├── tools/ ............... programas de ayuda en Python (sonidos, dibujos, ícono)
├── icono/ ............... el ícono de la app
└── signing/ ............. la firma del APK (no borrar)
```

⭐ = **los archivos que más vas a tocar**. Cada juego tiene un archivo `..._ajustes.dart` con todo lo que se puede
cambiar sin saber programar: textos de la voz, cuántas opciones, cada cuánto sale la celebración, etc. Cada valor
tiene un comentario en español que explica qué hace.

## Cómo hacer un cambio

1. Abre la carpeta del proyecto en VS Code.
2. Busca el archivo: **Ctrl+P** y escribe su nombre (por ejemplo `colores_ajustes`).
3. Busca el ajuste dentro del archivo: **Ctrl+F** y escribe su nombre (por ejemplo `aciertosParaCelebrar`).
4. Cambia el valor que está **después del `=`** y guarda (**Ctrl+S**).
5. En la Terminal de VS Code:

   ```
   git add .
   git commit -m "Cambié tal cosa"
   git push
   ```

6. En GitHub, pestaña **Actions**, espera el check verde y descarga el APK (ver "Cómo sacar el APK").

Para no romper nada:
- Los textos van entre **comillas simples**: `'¡Muy bien!'`. Si el texto lleva un apóstrofo, mejor no lo uses.
- Los decimales van con **punto**: `0.95`, no `0,95`.
- No borres el `;` del final de la línea ni las comas `,` que separan los elementos de una lista.
- Si VS Code subraya algo en **rojo**, hay un error: deshaz con **Ctrl+Z**.

Si quieres algo que no está en los ajustes, pregúntale a Claude: "en el juego X quiero que pase Y". Te dirá qué
archivo abrir y qué texto poner.

## Cómo pasar a una versión nueva (cuando te llega un zip)

1. Lee el `LEEME` que viene en el zip: dice si hay que borrar algo antes.
   - Si el zip trae **el proyecto completo**: borra de tu proyecto las carpetas `lib`, `test` y `assets/sonidos`,
     así no quedan archivos viejos. Tus voces (`assets/voces/`) y tus imágenes (`mis_dibujos/`) no se tocan.
   - Si el zip trae **solo algunos archivos** (los que cambiaron): **no borres nada**, así se conservan tus cambios
     en los archivos que no vienen en el zip.
2. Descomprime el zip y copia su contenido encima de tu proyecto (reemplaza lo que pregunte).
3. En la Terminal: `git add .`, `git commit -m "Versión nueva"` y `git push`.

Lo que Arleth ya pintó y los dibujos agregados desde el celular se conservan, porque están guardados en el celular.

## Sonidos y voces

- **Sonidos:** están en `assets/sonidos/`, un grupo por carpeta:
  - `comunes/`: la fiesta, el acierto y el "boing".
  - `pintar/`: las gotas y el pincel.
  - `colores/`: el globo que revienta.
  - `animales/`: aquí puedes poner sonidos de verdad de los animales (por ejemplo `perro.mp3`).
  - `burbujas/`: las burbujas que revientan, las súper y las mega burbujas.
  - `contar/`: las notitas al contar.

  Para cambiar un sonido, pon otro archivo con **el mismo nombre** en la misma carpeta. La lista completa está en
  `assets/sonidos/LEEME.txt`.
- **Voz:** es la del propio celular ("texto a voz"). Funciona sin internet. Si quieres que suene más natural,
  puedes **grabar tu voz** y poner los archivos en `assets/voces/` (ver `assets/voces/LEEME.txt`).

### Si la voz no suena

1. Sube el volumen multimedia.
2. En el celular: **Ajustes → Accesibilidad (o Sistema) → Salida de texto a voz**. Elige el motor de Google y en su configuración descarga la voz **Español (Estados Unidos)** o **Español (España)**.
3. Cierra y vuelve a abrir ARVI.

### Para que la voz suene más natural

- En **Salida de texto a voz → Motor de Google → Instalar datos de voz → Español**, cada idioma trae varias voces (Voz I, Voz II...). Escúchalas con el botón de prueba y elige la que más te guste: ARVI usa la voz que tenga el celular.
- Actualiza la app **"Servicios de voz de Google"** desde la Play Store: las versiones nuevas traen voces más naturales.
- Las voces "de internet" suenan todavía mejor, pero sin internet se callan. Si el celular siempre tiene internet, pon `vozPermitirInternet = true` en `lib/app/ajustes_app.dart`.
- Lo más natural de todo: **grabar tu voz** (ver `assets/voces/LEEME.txt`).

## Dónde cambiar cosas de toda la app

Todo esto está en `lib/app/ajustes_app.dart`, salvo donde se indica otro archivo:

| Quiero… | Cambia |
|---|---|
| Quitar, ordenar o cambiar las tarjetas del menú | `lib/app/lista_juegos.dart` |
| El título del menú ("JUEGOS DE ARLETH") | `tituloMenu` |
| Que la voz no diga el nombre del juego al tocarlo | `decirNombreDelJuego = false` |
| Quitar o cambiar la presentación | `mostrarPresentacion`, `presentacionLinea1/2` |
| Color de fondo de las pantallas | `fondoApp` |
| Voz más aguda o más grave | `vozTono` (1.0 normal, hasta 2.0; muy alta suena a robot) |
| Voz más lenta o más rápida | `vozVelocidad` |
| Apagar la voz | `vozActiva = false` |
| Usar (o no) tus voces grabadas | `usarVocesGrabadas` |
| Quitar o bajar los sonidos de los juegos | `sonidosJuegos`, `volumenJuegos` |
| Quitar o bajar la fiesta de las celebraciones | `sonidoCelebracion`, `volumenCelebracion` |
| Cuánto dura la celebración | `segundosCelebracion` |
| Agregar colores o cambiar sus nombres | la lista `colores` |
| Nombre de la app bajo el ícono | `.github/workflows/compilar-apk.yml` (busca `android:label`) |
| Lo de cada juego | el `LEEME.md` de su carpeta, en `lib/juegos/` |

## Cómo sacar el APK

### Camino A — con GitHub (no instalas nada)

1. Crea una cuenta en github.com y un repositorio nuevo, privado (por ejemplo `colorear`).
2. Abre esta carpeta en VS Code, abre la Terminal y ejecuta (cambia `TU_USUARIO`):

   ```
   git init
   git add .
   git commit -m "Primera versión"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/colorear.git
   git push -u origin main
   ```

3. En GitHub entra a la pestaña **Actions**. El trabajo "Compilar APK" arranca solo y demora unos 5-10 minutos.
4. Cuando termine con el check verde, ábrelo y abajo, en **Artifacts**, descarga `colorear-apk`. Es un zip que contiene `app-release.apk`.
5. Pasa el APK al celular (cable, Drive, WhatsApp, correo) y ábrelo. Android te pedirá permitir instalar apps de fuentes desconocidas para la app desde la que lo abras.

Cada vez que cambies algo y hagas `git push`, se genera un APK nuevo. También puedes lanzarlo a mano desde Actions → Compilar APK → Run workflow.

**Instalar una versión nueva encima de la anterior:** la carpeta `signing/` contiene una firma fija
(`debug.keystore`). Gracias a ella, todos los APK tienen la misma firma y se instalan **encima** del anterior,
sin desinstalar. Mantén esa carpeta en el repositorio.

### Camino B — en tu computadora

1. Instala Flutter (docs.flutter.dev/get-started/install), Android Studio (trae el SDK de Android) y la extensión *Flutter* de VS Code. Verifica con `flutter doctor`.
2. En esta carpeta, **solo la primera vez**, crea la parte Android (no toca tu código):

   ```
   flutter create --platforms=android --project-name colorear_ninos --org com.arvi .
   ```

3. Descarga las librerías y prueba en el celular (conectado por USB con depuración activada):

   ```
   flutter pub get
   flutter run
   ```

4. Para el APK: `flutter build apk --release`. Queda en `build/app/outputs/flutter-apk/app-release.apk`.
5. Para que el nombre bajo el ícono sea "ARVI" y funcione la voz, corre una vez `python3 tools/preparar_android.py`
   (en GitHub Actions esto se hace solo).

Con Flutter instalado también puedes revisar que todo esté bien antes de subir:
`flutter analyze` (busca errores) y `flutter test` (prueba los juegos solo).

## Agregar dibujos para pintar

Hay tres formas: poner tus imágenes en `mis_dibujos/`, pegar el texto de un dibujo desde el engranaje, o
agregar archivos a `assets/drawings/`. Todo está explicado en `lib/juegos/pintar/LEEME.md`.

## Consejo para que ella no se salga de la app

En Android puedes **fijar la pantalla** (en Ajustes busca "Fijar app" o "Fijar pantalla", según el celular). Con la app fijada no se puede salir sin el gesto o el código de desbloqueo.

## Programas de ayuda (carpeta `tools/`)

Son opcionales y se corren con Python en tu computadora:

- `generar_sonidos.py` crea los sonidos de `assets/sonidos/` (necesita `pip install numpy`). Ojo: vuelve a crear
  los sonidos de fábrica, así que si reemplazaste alguno por el tuyo, guárdalo antes.
- `generar_dibujos.py` crea los 34 dibujos de fábrica y el `indice.json` (borra y vuelve a crear los `.json` de
  `assets/drawings/`). Los dibujos están definidos en `dibujos_base.py`, `dibujos_animales.py` y
  `dibujos_cosas.py`; las formas (círculos, óvalos, curvas...) en `formas.py`.
- `vista_previa.py` (necesita `pip install matplotlib`) hace imágenes para revisar los dibujos:
  `python3 tools/vista_previa.py vista.png`.
- `convertir_imagenes.py` convierte las imágenes de `mis_dibujos/` en dibujos (GitHub lo hace solo al compilar).
- `generar_icono.py` crea el ícono (carpeta `icono/`).
- `preparar_android.py` pone el nombre "ARVI" y el permiso de la voz (GitHub lo hace solo).
