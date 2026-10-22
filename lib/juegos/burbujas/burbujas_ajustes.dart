// =============================================================================
//  AJUSTES DEL JUEGO "BURBUJAS" (Revienta las burbujas)
// =============================================================================
//
//  Van saliendo burbujas, de a poco, por todos los lados de la pantalla, y
//  flotan por todas partes. Con un toque revientan ("¡POP!"). Hay que
//  reventarlas TODAS para pasar al nivel siguiente.
//
//  Los niveles no se acaban nunca: cada nivel tiene un poquito más de
//  burbujas, más rápidas y que giran más, y cada pocos niveles aparece un
//  tipo de burbuja nuevo (súper, animalito, mega, rápidas, arcoíris). De vez
//  en cuando, al azar, sale un nivel más tranquilo, para que sienta que
//  mejora sin frustrarse. El juego recuerda en qué nivel va.
//
//  Cómo cambiar algo: cambia el valor que está después del "=" y guarda.
//  Los textos van entre comillas simples. Los decimales llevan punto (0.3).
//
//  Más ayuda en lib/juegos/burbujas/LEEME.md
// =============================================================================

class AjustesBurbujas {
  AjustesBurbujas._();

  // ----------------------------------------------- cómo suben los niveles

  /// Cuántas burbujas normales hay en el nivel 1, cuántas se suman en cada
  /// nivel, y el máximo.
  static const int burbujasAlEmpezar = 6;
  static const int burbujasMasPorNivel = 1;
  static const int burbujasMaximo = 12;

  /// Cuántas puede haber en la pantalla al mismo tiempo: en el nivel 1, y
  /// lo más que llega a haber. Se suma una cada [nivelesParaUnaMasALaVez]
  /// niveles.
  static const int aLaVezAlEmpezar = 3;
  static const int aLaVezMaximo = 7;
  static const int nivelesParaUnaMasALaVez = 3;

  /// Qué tan rápido van: cuánto del ancho de la pantalla (con el teléfono
  /// parado) recorren en un segundo. 10 = cruzan la pantalla en unos 10
  /// segundos. Cada burbuja va un poco más lenta o más rápida que eso.
  static const double velocidadAlEmpezar = 8;
  static const double velocidadMasPorNivel = 0.7;
  static const double velocidadMaxima = 24;

  /// Cuánto cambian de dirección mientras flotan (0 = siempre derecho,
  /// 1 = normal, 2 = el doble).
  static const double girosAlEmpezar = 1.0;
  static const double girosMasPorNivel = 0.08;
  static const double girosMaximo = 2.4;

  /// Nunca más de esta cantidad de burbujas para reventar en un nivel
  /// (contando todas, también las que salen de las mega burbujas).
  static const int totalMaximo = 24;

  // ---------------------------------------------- niveles más tranquilos

  /// De vez en cuando sale un nivel más tranquilo (como uno anterior), así
  /// la dificultad sube "en escalera" y no siempre de golpe.
  /// 0.3 = 3 de cada 10 niveles (más o menos). 0 = nunca.
  static const double probabilidadNivelTranquilo = 0.3;

  /// Cuántos niveles más fácil puede ser un nivel tranquilo (de 1 a este).
  static const int nivelesMasFacil = 3;

  /// En cada nivel (desde el 2), un tipo de burbuja (al azar, de los que
  /// ya salieron) viene con esta cantidad extra, para que cada nivel sea
  /// distinto. 0 = nunca.
  static const int extraSorpresa = 2;

  // ------------------------------------------------ los tipos de burbuja
  //
  // Desde qué nivel sale cada tipo (0 = no sale nunca). La primera vez,
  // la voz lo presenta. Desde que aparece, cada [nivelesParaUnaMas] niveles
  // hay una más de ese tipo (hasta su máximo).

  static const int nivelesParaUnaMas = 5;

  /// SÚPER BURBUJA: grande, dorada, con una estrella. Hay que tocarla
  /// varias veces (los puntitos blancos dicen cuántas faltan).
  static const int superDesdeNivel = 3;
  static const int superMaximo = 4;
  static const int toquesSuper = 3;

  /// ANIMALITO: una burbuja con un animalito adentro. Al reventarla, el
  /// animalito sale volando contento.
  static const int animalitoDesdeNivel = 5;
  static const int animalitoMaximo = 3;
  static const List<String> animalitos = <String>[
    '🐥', '🐟', '🐸', '🐞', '🦋', '🐱', '🐶', '🐰', '🐢', '🐝', //
  ];

  /// MEGA BURBUJA: enorme, con burbujitas adentro. Con [toquesMega] toques
  /// explota y salen [hijasMega] burbujitas que también hay que reventar.
  static const int megaDesdeNivel = 7;
  static const int megaMaximo = 2;
  static const int toquesMega = 2;
  static const int hijasMega = 4;

  /// BURBUJITAS RÁPIDAS: chiquitas, brillantes y muy rápidas (dejan una
  /// estela). [velocidadRapidas] = cuántas veces más rápido que las demás.
  static const int rapidaDesdeNivel = 9;
  static const int rapidaMaximo = 6;
  static const double velocidadRapidas = 2.2;

  /// BURBUJA ARCOÍRIS: cambia de colores. Al reventarla revientan TODAS las
  /// que están en la pantalla. Sale como mucho una por nivel, y no siempre
  /// ([probabilidadArcoiris]: 0.6 = en 6 de cada 10 niveles).
  static const int arcoirisDesdeNivel = 11;
  static const double probabilidadArcoiris = 0.6;

  // -------------------------------------------------------------- tamaños
  //
  // Cuánto del ancho de la pantalla mide cada burbuja de lado a lado
  // (0.22 = el 22%).

  static const double tamanoMinimo = 0.19;
  static const double tamanoMaximo = 0.26;
  static const double tamanoSuper = 0.34;
  static const double tamanoAnimalito = 0.27;
  static const double tamanoMega = 0.46;
  static const double tamanoChica = 0.13; // rápidas y las de la mega
  static const double tamanoArcoiris = 0.28;

  /// Cada cuánto sale una burbuja nueva (en segundos, al azar entre estos
  /// dos números), mientras haya lugar en la pantalla.
  static const double segundosEntreBurbujasMinimo = 0.6;
  static const double segundosEntreBurbujasMaximo = 1.4;

  /// Los colores de las burbujas (se escriben igual que en la lista de
  /// colores de lib/app/ajustes_app.dart).
  static const List<String> colores = <String>[
    'Celeste',
    'Rosado',
    'Morado',
    'Amarillo',
    'Verde',
    'Azul',
    'Naranja',
  ];

  /// true = al reventar sale la palabra "¡POP!" de colores.
  static const bool mostrarPop = true;

  // ------------------------------------------------------- entre niveles

  /// Cuánto se ve el cartel "NIVEL 3" (segundos).
  static const double segundosCartelNivel = 1.0;

  /// Cuánto dura el festejo corto al terminar cada nivel (segundos).
  static const double segundosFestejoCorto = 1.6;

  /// Cada cuántos niveles sale la celebración grande (con el cartel de
  /// estrellas), y cuántos segundos se queda (también se quita tocándola).
  static const int celebracionGrandeCada = 5;
  static const int segundosCelebracionGrande = 4;

  // ------------------------------------------------------------------- voz

  /// Lo que dice la voz al entrar (y con la orejita).
  static const String vozInicio = '¡Revienta todas las burbujas!';

  /// Al empezar cada nivel ({nivel} = el número).
  static const String vozNivel = '¡Nivel {nivel}!';

  /// Cuando aparece un tipo de burbuja por primera vez.
  static const String vozSuper = '¡Súper burbujas! ¡Tócalas muchas veces!';
  static const String vozAnimalito = '¡Burbujas con animalitos!';
  static const String vozMega = '¡Mega burbujas! ¡Tienen burbujitas adentro!';
  static const String vozRapida = '¡Burbujitas rápidas! ¡Atrápalas!';
  static const String vozArcoiris =
      '¡La burbuja arcoíris revienta todas las burbujas!';

  /// Al terminar un nivel (una al azar).
  static const List<String> vozMuyBien = <String>[
    '¡Muy bien!',
    '¡Bravo!',
    '¡Genial!',
    '¡Lo lograste!',
  ];

  /// El texto grande del festejo corto.
  static const String festejoCorto = '¡MUY BIEN!';

  /// La celebración grande (cada [celebracionGrandeCada] niveles).
  static const String celebracionLinea1 = '¡MUY BIEN!';
  static const String celebracionLinea2 = 'REVENTASTE TODAS';
  static const String vozCelebracion =
      '¡Muy bien! ¡Reventaste todas las burbujas!';

  // -------------------------------------------------------------- sonidos
  //
  // Están en assets/sonidos/. Para cambiarlos, pon otro archivo con el
  // mismo nombre (o cambia aquí el nombre).

  /// Al reventar una burbuja suena uno de estos (van turnándose).
  static const List<String> sonidosPop = <String>[
    'burbujas/pop1.wav',
    'burbujas/pop2.wav',
    'burbujas/pop3.wav',
    'burbujas/pop4.wav',
  ];

  /// Cada toque a una súper burbuja o a una mega (antes de reventar).
  static const String sonidoSuperToque = 'burbujas/super_toque.wav';

  /// La súper burbuja, la mega o la arcoíris que revientan.
  static const String sonidoSuperPop = 'burbujas/super_pop.wav';

  /// El animalito que sale volando.
  static const String sonidoAnimalito = 'comunes/acierto.wav';
}
