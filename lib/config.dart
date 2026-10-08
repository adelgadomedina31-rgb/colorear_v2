import 'package:flutter/material.dart';

/// Un color de la paleta y el nombre que dice la voz al elegirlo.
class ColorConNombre {
  const ColorConNombre(this.color, this.nombre);

  final Color color;
  final String nombre;
}

/// Ajustes de la app. Cambia estos valores para afinar cómo se siente.
///
/// Los dibujos se definen en un cuadrado de 1000 x 1000 unidades; las medidas
/// de abajo usan esas mismas unidades (100 = un 10% del ancho del dibujo).
class Ajustes {
  Ajustes._();

  // ---------------------------------------------------------------- pintura

  /// Las zonas con un área visible menor a esta se pintan completas con un
  /// solo toque. 30000 equivale a un cuadrado de unos 173 x 173.
  static const double areaUnToque = 30000;

  /// Cuántos toques, más o menos, hacen falta para llenar una zona que apenas
  /// pasa el tamaño de "un toque" y una zona enorme (el cielo, el fondo).
  /// Las zonas intermedias quedan entre esos dos números.
  /// Más toques = manchas más chicas.
  static const double toquesZonaChica = 3;
  static const double toquesZonaGrande = 10;

  /// Área que se considera "zona enorme" (casi todo el dibujo).
  static const double areaZonaGrande = 700000;

  /// Límites para el tamaño (radio) de cada mancha.
  static const double radioMinimo = 70;
  static const double radioMaximo = 260;

  /// Al arrastrar el dedo se pinta una franja; su ancho es el radio de la
  /// mancha multiplicado por este número.
  static const double anchoArrastre = 1.2;

  /// Grosor de la línea negra de los contornos.
  static const double grosorContorno = 10;

  /// Color de fondo de las pantallas (el "papel" de los dibujos es blanco).
  static const Color fondoApp = Color(0xFFFFF4D6);

  // ------------------------------------------------------------------- voz

  /// true = al elegir un color, una voz dice su nombre.
  static const bool vozActiva = true;

  /// Tono de la voz: 1.0 es normal; más alto suena más infantil (máximo 2.0).
  static const double vozTono = 1.5;

  /// Velocidad de la voz: 0.5 es normal; más bajo = más lento y claro.
  static const double vozVelocidad = 0.42;

  /// Pausa mínima (milisegundos) antes de poder elegir otro color, aunque la
  /// voz termine antes. La paleta también espera a que la voz termine.
  static const int pausaMinimaColor = 700;

  // ---------------------------------------------------------------- colores

  /// Colores del menú de pintura con el nombre que dice la voz.
  /// El último (blanco) sirve de borrador.
  /// Puedes agregar o quitar colores; conviene dejar una cantidad par.
  static const List<ColorConNombre> paleta = <ColorConNombre>[
    ColorConNombre(Color(0xFFE53935), 'Rojo'),
    ColorConNombre(Color(0xFFFB8C00), 'Naranja'),
    ColorConNombre(Color(0xFFFDD835), 'Amarillo'),
    ColorConNombre(Color(0xFF7CB342), 'Verde'),
    ColorConNombre(Color(0xFF00ACC1), 'Celeste'),
    ColorConNombre(Color(0xFF1E88E5), 'Azul'),
    ColorConNombre(Color(0xFF8E24AA), 'Morado'),
    ColorConNombre(Color(0xFFEC407A), 'Rosado'),
    ColorConNombre(Color(0xFF8D6E63), 'Marrón'),
    ColorConNombre(Color(0xFFFFFFFF), 'Blanco'),
  ];
}
