/// Ayudas para las pruebas de los juegos (Colores, Animales, Burbujas y
/// ¿Cuántos hay?).
library;

import 'package:colorear_ninos/juegos/animales/animales_ajustes.dart';
import 'package:colorear_ninos/juegos/burbujas/burbuja.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/niveles.dart';
import 'package:colorear_ninos/juegos/colores/colores_ajustes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda_pintar.dart';

/// Lo que se ve con una clave que empieza con [prefijo] ('globo_', 'animal_').
Finder conClave(String prefijo) => find.byWidgetPredicate((w) {
      final clave = w.key;
      return clave is ValueKey<String> && clave.value.startsWith(prefijo);
    });

/// Los nombres (lo que va después del prefijo) de lo que se ve.
List<String> nombresCon(WidgetTester tester, String prefijo) => <String>[
      for (final w in tester.widgetList(conClave(prefijo)))
        (w.key! as ValueKey<String>).value.substring(prefijo.length),
    ];

/// Las estrellas que muestra la barra de arriba.
int estrellas(WidgetTester tester) => int.parse(
    tester.widget<Text>(find.byKey(const ValueKey<String>('estrellas'))).data!);

// ------------------------------------------------------------------ Colores

/// Lo que dice la voz para pedir el globo de color [nombre] ('Rojo').
String pedirGlobo(String nombre) =>
    AjustesColores.vozBusca.replaceAll('{color}', nombre.toLowerCase());

/// El color que pidió la voz por última vez, como en las claves ('Rojo').
String globoPedido() {
  final pedidos = <String, String>{
    for (final c in AjustesColores.colores) pedirGlobo(c): c,
  };
  return pedidos[frases.lastWhere(pedidos.containsKey)]!;
}

/// Toca el globo de color [nombre] ('Rojo').
Future<void> tocarGlobo(WidgetTester tester, String nombre) async {
  await tester.tap(find.byKey(ValueKey<String>('globo_$nombre')));
  await esperar(tester, vueltas: 3);
}

/// Toca el globo correcto y espera a que empiece la siguiente ronda.
Future<void> acertarGlobo(WidgetTester tester) async {
  await tocarGlobo(tester, globoPedido());
  await tester.pump(const Duration(milliseconds: 4600));
  await esperar(tester, vueltas: 3);
}

// ----------------------------------------------------------------- Animales

/// La pregunta de la voz por el animal [a].
String preguntaPor(Animal a) =>
    AjustesAnimales.vozPregunta.replaceAll('{sonido}', a.sonido);

/// El animal por el que preguntó la voz por última vez.
Animal animalPedido() {
  final preguntas = <String, Animal>{
    for (final a in AjustesAnimales.animales) preguntaPor(a): a,
  };
  return preguntas[frases.lastWhere(preguntas.containsKey)]!;
}

/// Toca al animal [id] ('perro').
Future<void> tocarAnimal(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(ValueKey<String>('animal_$id')));
  await esperar(tester, vueltas: 3);
}

/// Toca al animal correcto y espera a que empiece la siguiente ronda (en la
/// prueba la voz nunca avisa que terminó: se espera lo más que espera la
/// app).
Future<void> acertarAnimal(WidgetTester tester) async {
  await tocarAnimal(tester, animalPedido().id);
  await tester.pump(const Duration(milliseconds: 4600));
  await esperar(tester, vueltas: 3);
}

// ----------------------------------------------------------------- Burbujas

/// El juego de Burbujas que está en la pantalla (para mirar sus burbujas).
EstadoBurbujasJuego juegoBurbujas(WidgetTester tester) =>
    tester.state<EstadoBurbujasJuego>(find.byType(BurbujasJuego));

/// Cuántas burbujas del nivel ya reventó (las estrellas de la fila de
/// arriba) y cuántas le faltan.
int burbujasHechas(WidgetTester tester) =>
    find.byKey(const ValueKey<String>('hecha')).evaluate().length;
int burbujasFaltan(WidgetTester tester) =>
    find.byKey(const ValueKey<String>('falta')).evaluate().length;

/// La zona donde flotan las burbujas.
Rect zonaBurbujas(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey<String>('zona')));

/// Dónde está la burbuja [b] en la pantalla.
Offset dondeEsta(WidgetTester tester, Burbuja b) =>
    zonaBurbujas(tester).topLeft + b.centro;

/// true si la burbuja [b] está entera dentro de la zona de juego.
bool estaAdentro(WidgetTester tester, Burbuja b) {
  final tam = zonaBurbujas(tester).size;
  final r = b.radio * 0.9;
  return b.centro.dx >= r &&
      b.centro.dy >= r &&
      b.centro.dx <= tam.width - r &&
      b.centro.dy <= tam.height - r;
}

/// Las burbujas que ya están enteras dentro de la pantalla.
List<Burbuja> burbujasAdentro(WidgetTester tester) => <Burbuja>[
      for (final b in juegoBurbujas(tester).burbujas)
        if (estaAdentro(tester, b)) b,
    ];

/// Avanza el juego de a poquito (como la pantalla de verdad).
Future<void> avanzar(WidgetTester tester, Duration tiempo) async {
  final cuadros = tiempo.inMilliseconds ~/ 40;
  for (var k = 0; k < cuadros; k++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

/// Toca en el medio de la burbuja [b].
Future<void> tocarBurbuja(WidgetTester tester, Burbuja b) async {
  await tester.tapAt(dondeEsta(tester, b));
  await tester.pump(const Duration(milliseconds: 40));
}

/// Espera hasta que haya una burbuja del tipo [tipo] entera en la pantalla.
/// Mientras tanto revienta las de otros tipos (para que haya lugar).
Future<Burbuja> esperarBurbuja(WidgetTester tester, TipoBurbuja tipo,
    {int segundos = 60}) async {
  for (var k = 0; k < segundos * 25; k++) {
    final adentro = burbujasAdentro(tester);
    for (final b in adentro) {
      if (b.tipo == tipo) return b;
    }
    final otra = adentro.where((b) => b.tipo != TipoBurbuja.arcoiris);
    if (otra.isNotEmpty) {
      await tocarBurbuja(tester, otra.first);
    } else {
      await tester.pump(const Duration(milliseconds: 40));
    }
  }
  fail('No salió ninguna burbuja $tipo');
}

/// Revienta burbujas (las que estén enteras en la pantalla, tocándolas las
/// veces que haga falta) hasta llevar [cuantas] en el nivel. Las que
/// [salvo] diga que no, no se tocan.
Future<void> reventarBurbujas(WidgetTester tester, int cuantas,
    {bool Function(Burbuja b)? salvo}) async {
  for (var vuelta = 0; vuelta < 4000; vuelta++) {
    if (juegoBurbujas(tester).reventadas >= cuantas) return;
    final listas = burbujasAdentro(tester)
        .where((b) => salvo == null || !salvo(b))
        .toList();
    if (listas.isEmpty) {
      await tester.pump(const Duration(milliseconds: 40));
      continue;
    }
    await tocarBurbuja(tester, listas.first);
  }
  fail('No alcanzó a reventar $cuantas burbujas');
}

/// Revienta todas las burbujas del nivel.
Future<void> reventarTodas(WidgetTester tester) =>
    reventarBurbujas(tester, juegoBurbujas(tester).total);

// ------------------------------------------------------------------- Contar

/// Cuántas cosas hay para contar en la ronda.
int cosasParaContar(WidgetTester tester) => conClave('cosa_').evaluate().length;

/// Los números que se ven en los botones de respuesta.
List<int> botonesContar(WidgetTester tester) =>
    nombresCon(tester, 'respuesta_').map(int.parse).toList();

/// Cuenta todas las cosas (tocándolas en orden) y espera la pregunta.
Future<void> contarTodas(WidgetTester tester) async {
  final n = cosasParaContar(tester);
  for (var i = 0; i < n; i++) {
    await tester.tap(find.byKey(ValueKey<String>('cosa_$i')));
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.pump(const Duration(milliseconds: 1000));
  await esperar(tester, vueltas: 2);
}

/// Toca el botón con el número [n].
Future<void> responder(WidgetTester tester, int n) async {
  await tester.tap(find.byKey(ValueKey<String>('respuesta_$n')));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Cuenta y responde bien; espera a que empiece la ronda siguiente.
Future<void> acertarContar(WidgetTester tester) async {
  final n = cosasParaContar(tester);
  await contarTodas(tester);
  await responder(tester, n);
  await tester.pump(const Duration(milliseconds: 4000));
  await esperar(tester, vueltas: 4);
}
