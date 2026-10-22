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
      'Nivel 7: la mega burbuja es enorme, y con 2 toques explota en '
      'burbujitas que también hay que reventar', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(
        const MaterialApp(home: BurbujasJuego(nivelInicial: 7, semilla: 11)));
    await tester.pump(const Duration(milliseconds: 100));
    final juego = juegoBurbujas(tester);
    final plan = juego.plan!;
    expect(plan.cuantas(TipoBurbuja.mega), 1);
    expect(
        juego.total,
        greaterThanOrEqualTo(
            plan.cuantas(TipoBurbuja.normal) + 1 + AjustesBurbujas.hijasMega),
        reason: 'las burbujitas de adentro también cuentan');
    expect(frases.last, AjustesBurbujas.vozMega);

    final mega = await esperarBurbuja(tester, TipoBurbuja.mega);
    final lado = zonaBurbujas(tester).size.shortestSide;
    expect(mega.radio * 2 / lado, greaterThan(0.4), reason: 'es enorme');
    final antes = juego.reventadas;

    await tocarBurbuja(tester, mega);
    expect(juego.burbujas, contains(mega));
    expect(juego.reventadas, antes);
    await tocarBurbuja(tester, mega);
    expect(juego.burbujas, isNot(contains(mega)));
    expect(juego.reventadas, antes + 1);

    // Salieron las burbujitas, chiquitas, alrededor de donde estaba.
    final chicas =
        juego.burbujas.where((b) => b.tipo == TipoBurbuja.chica).toList();
    expect(chicas, hasLength(AjustesBurbujas.hijasMega));
    for (final c in chicas) {
      expect(c.radio, lessThan(mega.radio / 2));
      expect((c.centro - mega.centro).distance, lessThan(mega.radio * 1.5));
      expect(estaAdentro(tester, c), isTrue);
    }
    // Se separan para todos lados.
    await avanzar(tester, const Duration(milliseconds: 600));
    for (final c in chicas) {
      expect((c.centro - mega.centro).distance, greaterThan(mega.radio * 0.4));
    }

    // Se revientan con un toque.
    for (final c in chicas) {
      await tocarBurbuja(tester, c);
      expect(juego.burbujas, isNot(contains(c)));
    }
    expect(juego.reventadas, antes + 1 + AjustesBurbujas.hijasMega);

    await reventarTodas(tester);
    await avanzar(tester, const Duration(seconds: 3));
    expect(juego.nivel, 8);
    await cerrarPantalla(tester);
  });
}
