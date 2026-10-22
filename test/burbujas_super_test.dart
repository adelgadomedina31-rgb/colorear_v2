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
      'Nivel 3: la voz presenta las súper burbujas, que se revientan con '
      'varios toques (con cada toque se achican)', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 3, semilla: 5)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    expect(juego.nivel, 3);
    expect(juego.plan!.cuantas(TipoBurbuja.superBurbuja), 1);
    expect(frases.last, AjustesBurbujas.vozSuper);

    final dorada = await esperarBurbuja(tester, TipoBurbuja.superBurbuja);
    final normales = juego.burbujas.where((b) => b.tipo == TipoBurbuja.normal);
    for (final b in normales) {
      expect(dorada.radio, greaterThan(b.radio), reason: 'es más grande');
    }
    expect(dorada.toques, AjustesBurbujas.toquesSuper);
    final antes = juego.reventadas;

    for (var k = 1; k < AjustesBurbujas.toquesSuper; k++) {
      final radio = dorada.radio;
      await tocarBurbuja(tester, dorada);
      expect(juego.burbujas, contains(dorada), reason: 'todavía no revienta');
      expect(dorada.toques, AjustesBurbujas.toquesSuper - k);
      expect(dorada.radio, lessThan(radio), reason: 'se achica');
      expect(juego.reventadas, antes);
    }
    await tocarBurbuja(tester, dorada);
    expect(juego.burbujas, isNot(contains(dorada)));
    expect(juego.reventadas, antes + 1);

    // Las demás, y al nivel 4.
    await reventarTodas(tester);
    await avanzar(tester, const Duration(seconds: 3));
    expect(juego.nivel, 4);
    await cerrarPantalla(tester);
  });
}
