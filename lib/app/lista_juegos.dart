import 'package:flutter/material.dart';

import 'package:colorear_ninos/juegos/animales/animales_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/burbuja.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_juego.dart';
import 'package:colorear_ninos/juegos/burbujas/burbujas_papas.dart';
import 'package:colorear_ninos/juegos/colores/colores_juego.dart';
import 'package:colorear_ninos/juegos/contar/contar_juego.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_menu.dart';
import 'package:colorear_ninos/juegos/pintar/pintar_papas.dart';

// =============================================================================
//  LISTA DE JUEGOS DEL MENÚ
// =============================================================================
//
//  Cada bloque Juego(...) de abajo es una tarjeta del menú, en ese orden.
//
//   - QUITAR un juego del menú: borra su bloque completo, desde "Juego(" hasta
//     su "),". (Los papás también pueden ocultarlo desde el engranaje, sin
//     tocar código.)
//   - CAMBIAR EL ORDEN: mueve el bloque completo más arriba o más abajo.
//   - CAMBIAR la tarjeta: cambia nombre, dibujo (un emoji), color o voz.
//   - AGREGAR un juego nuevo: su carpeta va en lib/juegos/<juego>/, se
//     importa arriba (las líneas "import") y se agrega aquí un bloque igual
//     a los otros.
// =============================================================================

/// Una tarjeta del menú de juegos.
class Juego {
  const Juego({
    required this.id,
    required this.nombre,
    required this.dibujo,
    required this.color,
    required this.voz,
    required this.abrir,
    this.papas,
    this.dibujoPintado,
  });

  /// Nombre interno, sin espacios ni tildes. No lo cambies: con él se
  /// recuerda si los papás lo ocultaron.
  final String id;

  /// Lo que se ve en la tarjeta.
  final String nombre;

  /// El dibujo grande de la tarjeta (un emoji: 🎨 🎈 🐶 ...).
  final String dibujo;

  /// El color de la tarjeta.
  final Color color;

  /// Lo que dice la voz al tocar la tarjeta.
  final String voz;

  /// La primera pantalla del juego.
  final Widget Function() abrir;

  /// (Opcional) La parte de este juego en la pantalla de Ajustes (engranaje).
  final Widget Function()? papas;

  /// (Opcional) Un dibujo hecho con código para la tarjeta, en vez del
  /// emoji (para los dibujos que no hay como emoji en todos los teléfonos).
  final Widget Function()? dibujoPintado;
}

/// Los juegos del menú, en orden.
final List<Juego> listaJuegos = <Juego>[
  Juego(
    id: 'pintar',
    nombre: 'Pintar',
    dibujo: '🎨',
    color: const Color(0xFFFB8C00),
    voz: '¡A pintar!',
    abrir: () => const PintarMenu(),
    papas: () => const PintarPapas(),
  ),
  Juego(
    id: 'colores',
    nombre: 'Colores',
    dibujo: '🎈',
    color: const Color(0xFFEC407A),
    voz: '¡Los colores!',
    abrir: () => const ColoresJuego(),
  ),
  Juego(
    id: 'animales',
    nombre: 'Animales',
    dibujo: '🐶',
    color: const Color(0xFF7CB342),
    voz: '¡Los animales!',
    abrir: () => const AnimalesJuego(),
  ),
  Juego(
    id: 'burbujas',
    nombre: 'Burbujas',
    dibujo: '🫧',
    dibujoPintado: () => const DibujoBurbujas(),
    color: const Color(0xFF29B6F6),
    voz: '¡A reventar burbujas!',
    abrir: () => const BurbujasJuego(),
    papas: () => const BurbujasPapas(),
  ),
  Juego(
    id: 'contar',
    nombre: '¿Cuántos hay?',
    dibujo: '🍎',
    color: const Color(0xFF8E24AA),
    voz: '¡A contar!',
    abrir: () => const ContarJuego(),
  ),
];
