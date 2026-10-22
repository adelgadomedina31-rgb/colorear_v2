import 'package:colorear_ninos/juegos/burbujas/burbujas_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ayuda_juegos.dart';
import 'ayuda_pintar.dart';

// Cada prueba de pantalla va en su propio archivo: así cada una empieza con
// la app "recién abierta".
void main() {
  setUp(prepararPrueba);

  testWidgets(
      'Burbujas: salen de a poco por los lados, flotan sin salirse, con un '
      'toque revientan, y al reventar todas hay un festejo corto y el nivel 2 '
      'empieza enseguida (y queda guardado)', (tester) async {
    sinAvisosDeSonido();
    await tester.binding.setSurfaceSize(const Size(420, 860));
    await tester.pumpWidget(const MaterialApp(home: BurbujasJuego(semilla: 7)));
    await tester.pump(const Duration(milliseconds: 100));

    // Nunca jugó: empieza en el nivel 1.
    final juego = juegoBurbujas(tester);
    expect(juego.nivel, 1);
    final total = juego.total;
    expect(total, AjustesBurbujas.burbujasAlEmpezar);
    expect(frases.last, AjustesBurbujas.vozInicio);
    expect(find.text('NIVEL 1'), findsOneWidget);
    expect(burbujasFaltan(tester), total);
    expect(juego.burbujas, isEmpty);

    // Van saliendo de a una, desde afuera de la pantalla.
    await avanzar(tester, const Duration(milliseconds: 680));
    expect(juego.burbujas, hasLength(1));
    expect(estaAdentro(tester, juego.burbujas.first), isFalse,
        reason: 'sale desde afuera de la pantalla');

    // El cartel del nivel se va rápido (en 1 segundo).
    await avanzar(tester, const Duration(milliseconds: 400));
    expect(find.text('NIVEL 1'), findsNothing);

    // Nunca hay más de las que dice el nivel, y las que ya entraron no se
    // salen (rebotan en los bordes).
    final aLaVez = juego.plan!.aLaVez;
    final tam = zonaBurbujas(tester).size;
    final lados = <String>{};
    for (var s = 0; s < 40; s++) {
      await avanzar(tester, const Duration(milliseconds: 500));
      expect(juego.burbujas.length, lessThanOrEqualTo(aLaVez));
      for (final b in juego.burbujas) {
        final c = b.centro;
        if (c.dx < 0) lados.add('izquierda');
        if (c.dx > tam.width) lados.add('derecha');
        if (c.dy < 0) lados.add('arriba');
        if (c.dy > tam.height) lados.add('abajo');
        if (b.adentro) {
          expect((Offset.zero & tam).contains(c), isTrue,
              reason: 'las que entraron no se salen');
        }
      }
    }
    expect(juego.burbujas.length, aLaVez);
    expect(burbujasAdentro(tester).length, aLaVez,
        reason: 'después de 20 segundos todas están adentro');
    expect(lados.length, greaterThanOrEqualTo(2),
        reason: 'salen por distintos lados: $lados');

    // Se mueven.
    final una = juego.burbujas.first;
    final antes = una.centro;
    await avanzar(tester, const Duration(seconds: 1));
    expect((una.centro - antes).distance, greaterThan(10));

    // Tocar el cielo (lejos de todas) no hace nada.
    Offset? vacio;
    for (var y = 10.0; y < tam.height && vacio == null; y += 20) {
      for (var x = 10.0; x < tam.width && vacio == null; x += 20) {
        final p = Offset(x, y);
        if (juego.burbujas
            .every((b) => (b.centro - p).distance > b.radio * 1.15 + 30)) {
          vacio = p;
        }
      }
    }
    await tester.tapAt(zonaBurbujas(tester).topLeft + vacio!);
    await tester.pump(const Duration(milliseconds: 40));
    expect(burbujasHechas(tester), 0);

    // Un toque: revienta y gana una estrella.
    await tocarBurbuja(tester, una);
    expect(juego.burbujas, isNot(contains(una)));
    expect(burbujasHechas(tester), 1);
    expect(burbujasFaltan(tester), total - 1);
    expect(estrellas(tester), 1);

    // Revienta todas: el festejo corto ("¡MUY BIEN!"), sin la celebración
    // grande.
    await reventarTodas(tester);
    expect(estrellas(tester), total);
    expect(burbujasFaltan(tester), 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('burbujas_nivel'), 2,
        reason: 'queda guardado que sigue el nivel 2');
    await avanzar(tester, const Duration(milliseconds: 600));
    expect(celebracion, findsNothing);
    expect(find.text(AjustesBurbujas.festejoCorto), findsOneWidget);
    expect(AjustesBurbujas.vozMuyBien, contains(frases.last));

    // Enseguida, el nivel 2, con más burbujas.
    await avanzar(
        tester,
        Duration(
            milliseconds:
                (AjustesBurbujas.segundosFestejoCorto * 1000).round()));
    expect(juego.nivel, 2);
    expect(frases.last, '¡Nivel 2!');
    expect(find.text('NIVEL 2'), findsOneWidget);
    expect(juego.total, greaterThan(total));
    expect(burbujasFaltan(tester), juego.total);
    expect(burbujasHechas(tester), 0);
    expect(estrellas(tester), total, reason: 'las estrellas siguen');

    // La orejita repite lo que hay que hacer.
    await tester.tap(find.byKey(const ValueKey<String>('repetir')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(frases.last, AjustesBurbujas.vozInicio);
    await cerrarPantalla(tester);
  });
}
