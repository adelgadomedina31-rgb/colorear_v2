# ARVI v12: Burbujas sin fin y arreglo de Pintar

## Qué trae

- **Pintar ya no falla al entrar.** El error venía de una librería que se actualizó sola el 17 de octubre
  (`shared_preferences_android 2.5`). El `pubspec.yaml` de este zip ya trae las 2 líneas que dejan la versión
  anterior, así que si ya las habías puesto a mano no pasa nada: quedan una sola vez.
- **Burbujas recuerda el nivel.** Al volver a entrar sigue donde quedó. En Ajustes (el engranaje) dice en qué
  nivel va y tiene el botón **"Volver al nivel 1"**.
- **Más rápido entre niveles.** El cartel "NIVEL 3" dura 1 segundo. Al terminar un nivel hay un festejo corto
  (fuegos artificiales de burbujas y "¡MUY BIEN!") y el siguiente empieza enseguida. La celebración grande sale
  cada 5 niveles.
- **Niveles sin fin, medio progresivos.** Cada nivel tiene un poquito más de burbujas, más rápidas. Más o menos 3 de
  cada 10 niveles son "tranquilos" (como uno anterior), así siente que mejora sin frustrarse. Y en cada nivel un
  tipo de burbuja al azar viene con más, para que ninguno sea igual.
- **Burbujas nuevas** (la voz presenta cada una la primera vez, y cada 5 niveles hay una más de cada tipo):

  | Desde el nivel | Burbuja |
  |---|---|
  | 3 | ⭐ **Súper burbuja**: dorada, 3 toques |
  | 5 | 🐥 **Animalito**: al reventarla, el animalito sale volando |
  | 7 | 🟣 **Mega burbuja**: enorme; con 2 toques explota en 4 burbujitas |
  | 9 | ⚡ **Burbujitas rápidas**: chiquitas y muy rápidas (se atrapan aunque el dedo no caiga justo encima) |
  | 11 | 🌈 **Burbuja arcoíris**: al reventarla revientan todas las de la pantalla |

- **Más fluido:** las burbujas se dibujan todas juntas en un solo dibujo, sin rehacer la pantalla en cada
  momento, y sin los efectos de desenfoque que son lentos en el celular.

## Cómo copiarla (igual que la v11: NO borres nada)

Este zip trae **solo los archivos nuevos y los que cambiaron**. Tus archivos de ajustes de Pintar, Colores,
Animales y de la app **no vienen**, así que tus cambios quedan como están.

1. **No borres ninguna carpeta.** Descomprime el zip y copia la carpeta `colorear_ninos` encima de tu proyecto.
   Cuando Windows pregunte, elige **Reemplazar**.
2. En la Terminal de VS Code:

   ```
   git add .
   git commit -m "Version 12: Burbujas sin fin y arreglo de Pintar"
   git push
   ```

3. En GitHub, pestaña **Actions**, espera el check verde y descarga el APK.

Ojo con dos archivos que vienen nuevos:
- `lib/juegos/burbujas/burbujas_ajustes.dart` cambió entero (los niveles ya no son una lista, ahora suben solos).
  Si le habías cambiado algo, vuelve a hacerlo con los nombres nuevos (están explicados en el mismo archivo y en
  `lib/juegos/burbujas/LEEME.md`).
- `lib/app/lista_juegos.dart` (solo se le agregó la parte de Burbujas en Ajustes). Si le habías cambiado el orden o
  el color de una tarjeta, vuelve a hacerlo.

## Archivos del zip

Nuevos:
- `lib/juegos/burbujas/niveles.dart` (arma cada nivel) y `burbujas_papas.dart` (guarda el nivel; la parte de Ajustes)
- Pruebas nuevas en `test/` (`burbujas_*_test.dart`)

Cambiados:
- `pubspec.yaml` (versión 12 y el arreglo de Pintar)
- `lib/juegos/burbujas/`: `burbujas_ajustes.dart`, `burbujas_juego.dart`, `burbuja.dart`, `LEEME.md`
- `lib/comun/celebracion.dart` (cada juego puede decir cuántos segundos dura su celebración)
- `lib/app/lista_juegos.dart`
- `README.md`, `lib/LEEME.md`, `assets/sonidos/LEEME.txt`, `test/ayuda_juegos.dart`, `test/burbujas_test.dart`,
  `test/burbujas_super_test.dart`
