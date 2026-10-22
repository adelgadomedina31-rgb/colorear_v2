# Mapa del código (carpeta `lib`)

Aquí está todo el código de ARVI. Está ordenado para que cada juego viva en **su propia carpeta**: si quieres
cambiar algo de un juego, solo abres los archivos de esa carpeta.

⭐ = **los archivos que más vas a tocar**. Tienen solo valores (números, textos, listas) con comentarios en español.

```
lib/
├── main.dart .................. arranca la app (no hace falta tocarlo)
│
├── app/ ....................... LO DE TODA LA APP
│   ├── ajustes_app.dart ....... ⭐ ajustes generales: voz, volumen, colores, presentación, título del menú
│   ├── lista_juegos.dart ...... ⭐ los juegos del menú: quitar, ordenar, cambiar nombre/dibujo/color
│   ├── menu_juegos.dart ....... la pantalla del menú (tarjetas, botón de apagar, engranaje)
│   ├── presentacion.dart ...... la presentación con estrellas al abrir la app
│   └── pantalla_ajustes.dart .. el engranaje (zona de papás): mostrar/ocultar juegos y lo de cada juego
│
├── comun/ ..................... PIEZAS QUE USAN TODOS LOS JUEGOS
│   ├── voz.dart ............... la voz que habla (y tus voces grabadas de assets/voces/)
│   ├── sonidos.dart ........... los sonidos (fiesta, acierto, y cualquiera de assets/sonidos/)
│   ├── celebracion.dart ....... el cartel grande con estrellas ("¡FELICIDADES!")
│   ├── estrellitas.dart ....... las estrellitas que salen volando al acertar
│   ├── barra_juego.dart ....... la barra de arriba de los juegos: casita, estrellas y orejita
│   ├── botones.dart ........... los botones redondos grandes
│   ├── dificultad.dart ........ cómo sube y baja la dificultad (2, 3, 4 opciones)
│   ├── repartir.dart .......... cómo se acomodan los globos y tarjetas en la pantalla
│   └── titulo_colores.dart .... los títulos con cada letra de un color
│
└── juegos/ .................... UN JUEGO POR CARPETA (cada una tiene su LEEME.md)
    ├── pintar/ ................ 🎨 Pintar
    │   ├── LEEME.md
    │   ├── pintar_ajustes.dart  ⭐ todo lo que se puede afinar de Pintar
    │   ├── pintar_menu.dart ... la cuadrícula de dibujos
    │   ├── pintar_pantalla.dart la pantalla donde se pinta (y los dos modos)
    │   ├── pintar_papas.dart .. la parte de Pintar en Ajustes (modo y agregar dibujos)
    │   └── partes/ ............ piezas internas de Pintar (normalmente no hace falta tocarlas)
    ├── colores/ ............... 🎈 Colores (encuentra el globo)
    │   ├── LEEME.md
    │   ├── colores_ajustes.dart ⭐
    │   ├── colores_juego.dart . cómo se juega y cómo se ve
    │   └── globo.dart ......... cómo se dibuja un globo
    ├── animales/ .............. 🐶 Animales (¿quién hace este sonido?)
    │   ├── LEEME.md
    │   ├── animales_ajustes.dart ⭐ (aquí está la lista de animales)
    │   └── animales_juego.dart  cómo se juega y cómo se ve
    ├── burbujas/ .............. 🫧 Burbujas (revienta todas las burbujas)
    │   ├── LEEME.md
    │   ├── burbujas_ajustes.dart ⭐ (cómo suben los niveles y los tipos de burbuja)
    │   ├── niveles.dart ....... arma cada nivel (los niveles no se acaban)
    │   ├── burbujas_juego.dart  cómo se juega, cómo se mueven y cómo se ve
    │   ├── burbuja.dart ....... cómo se dibuja cada burbuja y su explosión
    │   └── burbujas_papas.dart  guarda el nivel; "Volver al nivel 1" en Ajustes
    └── contar/ ................ 🍎 ¿Cuántos hay? (contar del 1 al 5)
        ├── LEEME.md
        ├── contar_ajustes.dart  ⭐ (aquí están las cosas para contar)
        └── contar_juego.dart .. cómo se juega y cómo se ve
```

## Cómo se conectan

1. `main.dart` abre la **presentación** (`app/presentacion.dart`) y después el **menú** (`app/menu_juegos.dart`).
2. El menú muestra una tarjeta por cada juego de `app/lista_juegos.dart`.
3. Cada tarjeta dice qué pantalla abrir. Por ejemplo, la de Colores abre `ColoresJuego` (en `juegos/colores/colores_juego.dart`).
4. Cada juego lee sus valores de su propio archivo de ajustes (`colores_ajustes.dart`) y usa las piezas de `comun/`
   (la voz, los sonidos, la celebración...).

Por eso, para cambiar algo de un juego casi siempre basta con **un solo archivo**: su `..._ajustes.dart`.

## Cómo está hecho un juego (Colores, Animales, Burbujas, ¿Cuántos hay?)

Todos tienen la misma forma, para que sea fácil seguirlos:

- **`..._ajustes.dart`**: los valores (qué dice la voz, cuántas opciones, cada cuánto se celebra, qué sonidos usa).
- **`..._juego.dart`**: el juego, dividido en tres partes marcadas con comentarios:
  1. **cada ronda**: elige qué mostrar y qué pedir;
  2. **cuando toca**: qué pasa si acierta y si se equivoca;
  3. **cómo se ve**: la pantalla, los dibujos y las animaciones.

## Cómo agregar un juego nuevo

(Lo normal es pedírselo a Claude, pero así queda armado.)

1. Crea su carpeta: `lib/juegos/<juego>/`, con `<juego>_ajustes.dart`, `<juego>_juego.dart` y un `LEEME.md`.
   Lo más fácil es copiar la carpeta `colores` y cambiarle los nombres.
2. Si tiene sonidos propios, crea `assets/sonidos/<juego>/` y agrega esa carpeta en `pubspec.yaml`, en la lista
   `assets:` (igual que las otras carpetas de sonidos).
3. En `app/lista_juegos.dart`: agrega arriba su `import` y abajo un bloque `Juego(...)` como los otros.

## Pruebas automáticas (carpeta `test/`)

Son programas que juegan solos y revisan que todo funcione (por ejemplo, que al acertar se gane una estrella).
No van dentro del APK. Si tienes Flutter instalado: `flutter test`. Si cambias un texto que una prueba revisa,
la prueba avisará; en ese caso hay que cambiar también la prueba (o pedírselo a Claude).
