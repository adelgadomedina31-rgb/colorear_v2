import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Nivel 11: la burbuja arcoíris revienta todas las que están en la '
      'pantalla, una tras otra', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 11, semilla: 2)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    expect(juego.plan!.cuantas(TipoBurbuja.arcoiris), 1);
    expect(frases.last, AjustesBurbujas.vozArcoiris);

    // Espera la arcoíris sin tocarla, reventando las otras mientras tanto
    // (pero dejando unas cuantas en la pantalla).
    final arcoiris = await esperarBurbuja(tester, TipoBurbuja.arcoiris);
    for (var k = 0; k < 200 && juego.burbujas.length < 4; k++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    final otras = <Object>[
      for (final b in juego.burbujas)
        if (b != arcoiris) b,
    ];
    expect(otras.length, greaterThanOrEqualTo(3));
    final megas = juego.burbujas.where((b) => b.tipo == TipoBurbuja.mega);
    final antes = juego.reventadas;

    await tocarBurbuja(tester, arcoiris);
    expect(juego.burbujas, isNot(contains(arcoiris)));
    expect(juego.reventadas, antes + 1);

    // Las demás revientan solas, de a una (también las súper y las mega con
    // sus burbujitas).
    await avanzar(tester, const Duration(milliseconds: 200));
    expect(juego.reventadas, lessThan(antes + 1 + otras.length),
        reason: 'no todas de golpe');
    await avanzar(tester, const Duration(milliseconds: 1500));
    for (final b in otras) {
      expect(juego.burbujas, isNot(contains(b)));
    }
    expect(
        juego.reventadas,
        greaterThanOrEqualTo(antes +
            1 +
            otras.length +
            megas.length * AjustesBurbujas.hijasMega));
    expect(juego.burbujas.where((b) => b.tipo == TipoBurbuja.chica), isEmpty);

    await reventarTodas(tester);
    await avanzar(tester, const Duration(seconds: 3));
    expect(juego.nivel, 12);
    await cerrarPantalla(tester);
  });
}
