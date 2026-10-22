import 'dart:math' as math;

import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los niveles de Burbujas: no se acaban, suben de a poco (con niveles
/// tranquilos al azar) y cada pocos niveles aparece algo nuevo.
void main() {
  /// Los planes de los niveles 1 a [hasta], jugados con la semilla [semilla].
  List<PlanNivel> jugar(int semilla, int hasta) {
    final azar = math.Random(semilla);
    return <PlanNivel>[
      for (var n = 1; n <= hasta; n++) PlanNivel.para(n, azar),
    ];
  }

  test('El nivel 1 es fácil: pocas burbujas normales, lentas', () {
    for (var semilla = 0; semilla < 20; semilla++) {
      final p = PlanNivel.para(1, math.Random(semilla));
      expect(p.numero, 1);
      expect(p.tranquilo, isFalse);
      expect(p.total, AjustesBurbujas.burbujasAlEmpezar);
      expect(p.cuantas(TipoBurbuja.normal), AjustesBurbujas.burbujasAlEmpezar);
      expect(p.aLaVez, AjustesBurbujas.aLaVezAlEmpezar);
      expect(p.velocidad, AjustesBurbujas.velocidadAlEmpezar / 100);
      expect(p.nuevos, isEmpty);
    }
  });

  test('Los niveles no se acaban y nunca pasan de los máximos', () {
    for (var semilla = 0; semilla < 30; semilla++) {
      for (final p in jugar(semilla, 300)) {
        expect(p.total, lessThanOrEqualTo(AjustesBurbujas.totalMaximo),
            reason: 'nivel ${p.numero}');
        expect(p.cuantas(TipoBurbuja.normal), greaterThanOrEqualTo(3));
        expect(p.aLaVez, lessThanOrEqualTo(AjustesBurbujas.aLaVezMaximo));
        expect(p.velocidad,
            lessThanOrEqualTo(AjustesBurbujas.velocidadMaxima / 100));
        expect(p.giros, lessThanOrEqualTo(AjustesBurbujas.girosMaximo));
        expect(p.cuantas(TipoBurbuja.superBurbuja),
            lessThanOrEqualTo(AjustesBurbujas.superMaximo + 1));
        expect(p.cuantas(TipoBurbuja.mega),
            lessThanOrEqualTo(AjustesBurbujas.megaMaximo + 1));
        expect(p.cuantas(TipoBurbuja.arcoiris), lessThanOrEqualTo(1));
        expect(p.cuantas(TipoBurbuja.chica), 0,
            reason: 'las chicas solo salen de las mega');
        // El orden tiene todas, y las dos primeras son normales.
        final orden = p.orden(math.Random(semilla));
        expect(orden.length,
            p.total - p.cuantas(TipoBurbuja.mega) * AjustesBurbujas.hijasMega);
        expect(orden.take(2), everyElement(TipoBurbuja.normal));
      }
    }
  });

  test('Cada tipo sale desde su nivel, y la primera vez es "nuevo"', () {
    final desde = <TipoBurbuja, int>{
      TipoBurbuja.superBurbuja: AjustesBurbujas.superDesdeNivel,
      TipoBurbuja.animalito: AjustesBurbujas.animalitoDesdeNivel,
      TipoBurbuja.mega: AjustesBurbujas.megaDesdeNivel,
      TipoBurbuja.rapida: AjustesBurbujas.rapidaDesdeNivel,
      TipoBurbuja.arcoiris: AjustesBurbujas.arcoirisDesdeNivel,
    };
    // Uno nuevo a lo más cada 5 niveles (o menos).
    final niveles = desde.values.toList()..sort();
    expect(niveles.first, lessThanOrEqualTo(5));
    for (var k = 1; k < niveles.length; k++) {
      expect(niveles[k] - niveles[k - 1], inInclusiveRange(1, 5));
    }
    for (var semilla = 0; semilla < 30; semilla++) {
      for (final p in jugar(semilla, 40)) {
        desde.forEach((tipo, nivel) {
          if (p.numero < nivel) {
            expect(p.cuantas(tipo), 0, reason: '$tipo en el nivel ${p.numero}');
          } else if (p.numero == nivel) {
            expect(p.cuantas(tipo), 1, reason: 'la primera vez sale una $tipo');
            expect(p.nuevos, <TipoBurbuja>[tipo]);
          } else if (tipo != TipoBurbuja.arcoiris) {
            expect(p.cuantas(tipo), greaterThanOrEqualTo(1),
                reason: 'desde que sale, sale siempre: $tipo, ${p.numero}');
          }
        });
        if (!desde.containsValue(p.numero)) expect(p.nuevos, isEmpty);
      }
    }
  });

  test('Va subiendo de a poco: cada 5 niveles hay más cosas', () {
    // El promedio de muchas partidas.
    const partidas = 200;
    final totales = List<double>.filled(41, 0);
    final rapidez = List<double>.filled(41, 0);
    final especiales = List<double>.filled(41, 0);
    for (var semilla = 0; semilla < partidas; semilla++) {
      for (final p in jugar(semilla, 40)) {
        totales[p.numero] += p.total / partidas;
        rapidez[p.numero] += p.velocidad / partidas;
        for (final t in PlanNivel.especiales) {
          especiales[p.numero] += p.cuantas(t) / partidas;
        }
      }
    }
    // Más burbujas hasta llegar al máximo (nivel 12 más o menos)...
    for (var n = 1; n + 5 <= 12; n++) {
      expect(totales[n + 5], greaterThan(totales[n]),
          reason: 'nivel ${n + 5} con más burbujas que el $n');
    }
    // ... más rápidas hasta el nivel 24...
    for (var n = 1; n + 5 <= 24; n++) {
      expect(rapidez[n + 5], greaterThan(rapidez[n]));
    }
    // ... y cada vez más especiales (en vez de normales) hasta el 21.
    for (var n = AjustesBurbujas.superDesdeNivel; n + 5 <= 21; n++) {
      expect(especiales[n + 5], greaterThan(especiales[n]),
          reason: 'nivel ${n + 5} con más burbujas especiales que el $n');
    }
  });

  test('A veces sale un nivel más tranquilo (nunca en los 3 primeros)', () {
    var tranquilos = 0;
    var niveles = 0;
    for (var semilla = 0; semilla < 100; semilla++) {
      for (final p in jugar(semilla, 30)) {
        if (p.numero <= 3) {
          expect(p.tranquilo, isFalse);
          expect(p.dificultad, p.numero);
          continue;
        }
        niveles++;
        if (p.tranquilo) {
          tranquilos++;
          expect(
              p.dificultad,
              inInclusiveRange(
                  p.numero - AjustesBurbujas.nivelesMasFacil, p.numero - 1));
        } else {
          expect(p.dificultad, p.numero);
        }
      }
    }
    final parte = tranquilos / niveles;
    expect(parte, closeTo(AjustesBurbujas.probabilidadNivelTranquilo, 0.06));
  });

  test('Cada nivel trae una sorpresa distinta (no todos son iguales)', () {
    final distintos = <String>{
      for (var semilla = 0; semilla < 40; semilla++)
        PlanNivel.para(15, math.Random(semilla))
            .cantidades
            .entries
            .map((e) => '${e.key.name}${e.value}')
            .join(','),
    };
    expect(distintos.length, greaterThanOrEqualTo(4));
  });
}
