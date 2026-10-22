# 🫧 Juego: Burbujas (revienta las burbujas)

Motricidad fina y puntería: hay que **reventar todas las burbujas** que flotan por la pantalla.

## Cómo se juega

1. Al entrar, el juego **sigue en el nivel donde quedó** (queda guardado en el celular). Sale el cartel
   **"NIVEL 3"** (un segundo) y la voz dice qué hacer.
2. Las burbujas van saliendo **de a poco, por los cuatro lados** de la pantalla, y flotan por todas partes: cada
   una a **su propia velocidad**, cambiando de dirección de a poquito y **rebotando** en los bordes y entre ellas.
3. **Un toque y revientan:** suena un "¡blup!", sale un destello, gotitas, papelitos de colores, estrellitas y la
   palabra **"¡POP!"**. Cada burbuja reventada da una **estrella**.
4. Arriba se ve cuántas lleva y cuántas faltan (una burbujita por cada burbuja del nivel; si son muchas, una barra).
5. Cuando revienta **todas**: un **festejo corto** (fuegos artificiales de burbujas, "¡MUY BIEN!") y el nivel
   siguiente empieza enseguida. **Cada 5 niveles**, la **celebración grande** "¡MUY BIEN! REVENTASTE TODAS".

## Los niveles no se acaban

Cada nivel tiene un poquito más de burbujas, que van un poco más rápido y cambian más de dirección. Además:

- **Cada pocos niveles aparece un tipo de burbuja nuevo** (la voz lo presenta la primera vez), y desde que
  aparece, **cada 5 niveles** hay una más de ese tipo.
- **Niveles tranquilos al azar:** más o menos 3 de cada 10 niveles son como uno de 1 a 3 niveles antes. Así la
  dificultad sube "en escalera": siente que mejora, sin frustrarse.
- **Una sorpresa en cada nivel:** un tipo de burbuja (al azar) viene con más, para que ningún nivel sea igual.
- Nunca hay más de **24** burbujas para reventar en un nivel. Cuando ya se llega a ese número, los niveles
  siguientes cambian burbujas normales por especiales.

| Desde el nivel | Burbuja nueva | Cómo es |
|---|---|---|
| 1 | Normal | Un toque y revienta |
| 3 | ⭐ **Súper burbuja** | Grande y dorada, con una estrella. Hay que tocarla **3 veces** (con cada toque se achica; los puntitos dicen cuántos faltan) |
| 5 | 🐥 **Animalito** | Una burbuja con un animalito adentro. Al reventarla, **el animalito sale volando** |
| 7 | 🟣 **Mega burbuja** | Enorme, con burbujitas adentro. Con **2 toques explota** y salen **4 burbujitas** que también hay que reventar |
| 9 | ⚡ **Burbujitas rápidas** | Chiquitas, brillantes y muy rápidas, con una estela. Se atrapan aunque el dedo no caiga justo encima |
| 11 | 🌈 **Burbuja arcoíris** | Cambia de colores. Al reventarla **revientan todas** las que hay en la pantalla, una tras otra |

Arriba: la **casita** vuelve al menú, en el medio están las **estrellas** ganadas y la **orejita** repite qué hacer.

**Volver al nivel 1:** en Ajustes (el engranaje, zona de papás), en la parte de Burbujas dice en qué nivel va y
tiene el botón **"Volver al nivel 1"**.

## Los archivos de esta carpeta

| Archivo | Qué tiene |
|---|---|
| `burbujas_ajustes.dart` ⭐ | Todo lo que se puede cambiar: cómo suben los niveles, los tipos de burbuja, tamaños, colores, voz y sonidos |
| `niveles.dart` | Arma cada nivel con los números de los ajustes (cuántas de cada tipo, velocidad, niveles tranquilos, sorpresa) |
| `burbujas_juego.dart` | El juego, en cuatro partes: **1. cada nivel**, **2. salen y flotan** (cómo se mueven), **3. cuando toca** (revientan, mega, arcoíris, festejos) y **4. cómo se ve** |
| `burbuja.dart` | Cómo se dibuja cada burbuja, las explosiones, los animalitos que salen volando y el dibujo de la tarjeta del menú |
| `burbujas_papas.dart` | Dónde se guarda el nivel, y la parte de Burbujas en Ajustes ("Volver al nivel 1") |

## Qué cambiar (todo en `burbujas_ajustes.dart`)

| Quiero… | Cambia |
|---|---|
| Más o menos burbujas | `burbujasAlEmpezar`, `burbujasMasPorNivel`, `burbujasMaximo`, `totalMaximo` |
| Cuántas hay en la pantalla al mismo tiempo | `aLaVezAlEmpezar`, `aLaVezMaximo`, `nivelesParaUnaMasALaVez` |
| Que vayan más lento o más rápido | `velocidadAlEmpezar`, `velocidadMasPorNivel`, `velocidadMaxima` (10 = cruza la pantalla en unos 10 segundos) |
| Que cambien más o menos de dirección | `girosAlEmpezar`, `girosMasPorNivel`, `girosMaximo` |
| Más o menos niveles tranquilos | `probabilidadNivelTranquilo` (0 = nunca) y `nivelesMasFacil` |
| Quitar la sorpresa de cada nivel | `extraSorpresa = 0` |
| Que un tipo salga antes, después o nunca | `superDesdeNivel`, `animalitoDesdeNivel`, `megaDesdeNivel`, `rapidaDesdeNivel`, `arcoirisDesdeNivel` (0 = nunca) |
| Cada cuántos niveles hay una más de cada tipo | `nivelesParaUnaMas` |
| Cuántas de cada tipo como máximo | `superMaximo`, `animalitoMaximo`, `megaMaximo`, `rapidaMaximo` |
| Cuántos toques necesitan | `toquesSuper`, `toquesMega` |
| Cuántas burbujitas salen de la mega | `hijasMega` |
| Qué tan rápidas son las rápidas | `velocidadRapidas` (2.2 = el doble y un poco más) |
| Qué animalitos salen | `animalitos` |
| Que la arcoíris salga más o menos | `probabilidadArcoiris` |
| El tamaño de cada burbuja | `tamanoMinimo`, `tamanoMaximo`, `tamanoSuper`, `tamanoAnimalito`, `tamanoMega`, `tamanoChica`, `tamanoArcoiris` |
| Que salgan más seguido o más espaciadas | `segundosEntreBurbujasMinimo`, `segundosEntreBurbujasMaximo` |
| Cuánto se ve el cartel "NIVEL 3" | `segundosCartelNivel` |
| Cuánto dura el festejo corto | `segundosFestejoCorto` |
| Cada cuántos niveles la celebración grande, y cuánto dura | `celebracionGrandeCada`, `segundosCelebracionGrande` |
| Los colores de las burbujas | `colores` (con los nombres de la lista de colores de `lib/app/ajustes_app.dart`) |
| Quitar la palabra "¡POP!" | `mostrarPop = false` |
| Lo que dice la voz | `vozInicio`, `vozNivel` (`{nivel}` = el número), `vozSuper`, `vozAnimalito`, `vozMega`, `vozRapida`, `vozArcoiris`, `vozMuyBien` |
| Los textos de los festejos | `festejoCorto`, `celebracionLinea1`, `celebracionLinea2`, `vozCelebracion` |

Cosas que están en otro archivo:
- **Cómo se ve cada burbuja o la explosión:** `burbuja.dart`.
- **El cielo y las nubes:** en `burbujas_juego.dart`, busca `// El cielo, con nubes`.
- **El volumen y apagar sonidos o voz:** `lib/app/ajustes_app.dart`.

## Sonidos

- `assets/sonidos/burbujas/pop1.wav` ... `pop4.wav`: la burbuja que revienta (van turnándose).
- `assets/sonidos/burbujas/super_toque.wav`: cada toque a la súper burbuja o a la mega.
- `assets/sonidos/burbujas/super_pop.wav`: la súper, la mega o la arcoíris que revientan.
- `assets/sonidos/comunes/acierto.wav`: el animalito que sale volando y el festejo corto.
- `assets/sonidos/comunes/felicidades.wav`: la fiesta de la celebración grande.

Para cambiar uno, pon otro archivo con el **mismo nombre** en la misma carpeta.

## Para que vaya fluido

Todas las burbujas, explosiones y animalitos se dibujan juntos en **un solo dibujo** que se repinta en cada cuadro
(sin rehacer la pantalla), las letras y los emojis se preparan una sola vez, y los brillos se hacen con degradados
en vez de desenfoques (que son lentos en los celulares).
