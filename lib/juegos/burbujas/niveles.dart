import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';

/// Los tipos de burbuja.
enum TipoBurbuja {
  /// La de siempre: un toque y revienta.
  normal,

  /// Grande y dorada: varios toques.
  superBurbuja,

  /// Con un animalito adentro, que sale volando.
  animalito,

  /// Enorme: con 2 toques explota en burbujitas.
  mega,

  /// Chiquita y muy rápida.
  rapida,

  /// Revienta todas las de la pantalla.
  arcoiris,

  /// Las burbujitas que salen de una mega.
  chica,
}

/// Cómo es un nivel: cuántas burbujas de cada tipo, qué tan rápido van...
/// Se arma con [PlanNivel.para], a partir de los números de
/// burbujas_ajustes.dart.
class PlanNivel {
  PlanNivel._({
    required this.numero,
    required this.dificultad,
    required this.tranquilo,
    required this.cantidades,
    required this.aLaVez,
    required this.velocidad,
    required this.giros,
    required this.nuevos,
  });

  /// El número del nivel (1, 2, 3...).
  final int numero;

  /// Qué tan difícil es (igual al número, o menos si es un nivel
  /// tranquilo).
  final int dificultad;

  /// true = es un nivel más tranquilo que el anterior.
  final bool tranquilo;

  /// Cuántas burbujas de cada tipo salen (sin contar las chicas de las
  /// mega).
  final Map<TipoBurbuja, int> cantidades;

  /// Cuántas puede haber en la pantalla al mismo tiempo.
  final int aLaVez;

  /// Qué tan rápido van (parte del ancho de la pantalla por segundo; 0.1 =
  /// el 10%).
  final double velocidad;

  /// Cuánto cambian de dirección.
  final double giros;

  /// Los tipos que aparecen por primera vez en este nivel.
  final List<TipoBurbuja> nuevos;

  int cuantas(TipoBurbuja tipo) => cantidades[tipo] ?? 0;

  /// Cuántas hay que reventar en total (con las chicas de las mega).
  int get total {
    var suma = 0;
    cantidades.forEach((tipo, n) => suma += n);
    return suma + cuantas(TipoBurbuja.mega) * AjustesBurbujas.hijasMega;
  }

  /// Desde qué nivel sale cada tipo.
  static int desdeNivel(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.normal => 1,
        TipoBurbuja.superBurbuja => AjustesBurbujas.superDesdeNivel,
        TipoBurbuja.animalito => AjustesBurbujas.animalitoDesdeNivel,
        TipoBurbuja.mega => AjustesBurbujas.megaDesdeNivel,
        TipoBurbuja.rapida => AjustesBurbujas.rapidaDesdeNivel,
        TipoBurbuja.arcoiris => AjustesBurbujas.arcoirisDesdeNivel,
        TipoBurbuja.chica => 0,
      };

  static int _maximo(TipoBurbuja tipo) => switch (tipo) {
        TipoBurbuja.normal => AjustesBurbujas.burbujasMaximo,
        TipoBurbuja.superBurbuja => AjustesBurbujas.superMaximo,
        TipoBurbuja.animalito => AjustesBurbujas.animalitoMaximo,
        TipoBurbuja.mega => AjustesBurbujas.megaMaximo,
        TipoBurbuja.rapida => AjustesBurbujas.rapidaMaximo,
        TipoBurbuja.arcoiris => 1,
        TipoBurbuja.chica => 0,
      };

  static const List<TipoBurbuja> especiales = <TipoBurbuja>[
    TipoBurbuja.superBurbuja,
    TipoBurbuja.animalito,
    TipoBurbuja.mega,
    TipoBurbuja.rapida,
    TipoBurbuja.arcoiris,
  ];

  /// Arma el nivel [numero]. Usa [azar] para los niveles tranquilos y la
  /// sorpresa de cada nivel.
  factory PlanNivel.para(int numero, math.Random azar) {
    final n = math.max(1, numero);

    // A veces, un nivel más tranquilo (nunca en los primeros).
    var d = n;
    var tranquilo = false;
    if (n > 3 &&
        AjustesBurbujas.nivelesMasFacil > 0 &&
        azar.nextDouble() < AjustesBurbujas.probabilidadNivelTranquilo) {
      d = math.max(1, n - 1 - azar.nextInt(AjustesBurbujas.nivelesMasFacil));
      tranquilo = d < n;
    }

    final cantidades = <TipoBurbuja, int>{
      TipoBurbuja.normal: math.min(
        AjustesBurbujas.burbujasMaximo,
        AjustesBurbujas.burbujasAlEmpezar +
            (d - 1) * AjustesBurbujas.burbujasMasPorNivel,
      ),
    };
    final nuevos = <TipoBurbuja>[];
    final saliendo = <TipoBurbuja>[];
    for (final tipo in especiales) {
      final desde = desdeNivel(tipo);
      if (desde <= 0 || n < desde) continue; // todavía no sale
      saliendo.add(tipo);
      if (n == desde) nuevos.add(tipo);
      var cuantas = 1 +
          math.max(0, d - desde) ~/
              math.max(1, AjustesBurbujas.nivelesParaUnaMas);
      if (tipo == TipoBurbuja.arcoiris) {
        // La arcoíris no sale siempre (salvo la primera vez).
        cuantas = (n == desde ||
                azar.nextDouble() < AjustesBurbujas.probabilidadArcoiris)
            ? 1
            : 0;
      }
      cantidades[tipo] = math.min(_maximo(tipo), cuantas);
    }

    // La sorpresa (desde el nivel 2): un tipo viene con más (si no es el
    // nuevo del nivel), así cada nivel es un poco distinto.
    if (n > 1 && AjustesBurbujas.extraSorpresa > 0) {
      final paraSorpresa = <TipoBurbuja>[
        TipoBurbuja.normal,
        for (final t in saliendo)
          if (t != TipoBurbuja.arcoiris && !nuevos.contains(t)) t,
      ];
      final sorpresa = paraSorpresa[azar.nextInt(paraSorpresa.length)];
      final extra =
          sorpresa == TipoBurbuja.mega ? 1 : AjustesBurbujas.extraSorpresa;
      cantidades[sorpresa] = math.min(
          _maximo(sorpresa) + (sorpresa == TipoBurbuja.normal ? 0 : 1),
          (cantidades[sorpresa] ?? 0) + extra);
    }

    final plan = PlanNivel._(
      numero: n,
      dificultad: d,
      tranquilo: tranquilo,
      cantidades: cantidades,
      aLaVez: math.min(
        AjustesBurbujas.aLaVezMaximo,
        AjustesBurbujas.aLaVezAlEmpezar +
            (d - 1) ~/ math.max(1, AjustesBurbujas.nivelesParaUnaMasALaVez),
      ),
      velocidad: math.min(
            AjustesBurbujas.velocidadMaxima,
            AjustesBurbujas.velocidadAlEmpezar +
                (d - 1) * AjustesBurbujas.velocidadMasPorNivel,
          ) /
          100,
      giros: math.min(
        AjustesBurbujas.girosMaximo,
        AjustesBurbujas.girosAlEmpezar +
            (d - 1) * AjustesBurbujas.girosMasPorNivel,
      ),
      nuevos: nuevos,
    );
    // Primero se sacan normales (quedan al menos 3) y, si todavía sobran,
    // de a una especial (queda al menos una de cada tipo).
    final sobra = plan.total - AjustesBurbujas.totalMaximo;
    if (sobra > 0) {
      cantidades[TipoBurbuja.normal] =
          math.max(3, plan.cuantas(TipoBurbuja.normal) - sobra);
    }
    const turnos = <TipoBurbuja>[
      TipoBurbuja.rapida,
      TipoBurbuja.animalito,
      TipoBurbuja.superBurbuja,
      TipoBurbuja.mega,
    ];
    var sinSacar = 0;
    for (var k = 0;
        plan.total > AjustesBurbujas.totalMaximo && sinSacar < turnos.length;
        k++) {
      final tipo = turnos[k % turnos.length];
      final hay = plan.cuantas(tipo);
      if (hay > 1) {
        cantidades[tipo] = hay - 1;
        sinSacar = 0;
      } else {
        sinSacar++;
      }
    }
    return plan;
  }

  /// El orden en que salen: las dos primeras siempre normales; las demás,
  /// mezcladas.
  List<TipoBurbuja> orden(math.Random azar) {
    final normales = cuantas(TipoBurbuja.normal);
    final primeras = math.min(2, normales);
    final resto = <TipoBurbuja>[
      for (var i = primeras; i < normales; i++) TipoBurbuja.normal,
      for (final tipo in especiales)
        for (var i = 0; i < cuantas(tipo); i++) tipo,
    ]..shuffle(azar);
    return <TipoBurbuja>[
      for (var i = 0; i < primeras; i++) TipoBurbuja.normal,
      ...resto,
    ];
  }
}
