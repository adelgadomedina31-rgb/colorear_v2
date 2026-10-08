"""Los 4 dibujos con los que empezó la app: sol, flor, pez y casa."""
import math

from formas import (Forma, circulo, curva, elipse, fondo, hoja, linea, poligono,
                    punto, rect)


def sol():
    cx, cy = 500, 500
    regiones = [("cielo", fondo())]
    for i in range(8):
        a = math.radians(i * 45)
        da = math.radians(17)
        punta = (cx + 420 * math.cos(a), cy + 420 * math.sin(a))
        b1 = (cx + 228 * math.cos(a - da), cy + 228 * math.sin(a - da))
        b2 = (cx + 228 * math.cos(a + da), cy + 228 * math.sin(a + da))
        regiones.append(("rayo%d" % (i + 1), poligono([b1, punta, b2])))
    regiones.append(("cara", circulo(cx, cy, 190)))
    detalles = [
        punto(440, 470, 20),
        punto(560, 470, 20),
        linea(curva(415, 545, 455, 625, 545, 625, 585, 545), 12),
    ]
    return "sol", "Sol", regiones, detalles


def flor():
    cx, cy = 500, 320
    regiones = [
        ("cielo", fondo()),
        ("tallo", rect(455, 320, 90, 540)),
        ("hoja_izq", hoja(455, 740, 262, 650, 70)),
        ("hoja_der", hoja(545, 740, 738, 650, 70)),
    ]
    for i, grados in enumerate([30, 90, 150, 210, 270, 330]):
        a = math.radians(grados)
        px, py = cx + 165 * math.cos(a), cy + 165 * math.sin(a)
        regiones.append(("petalo%d" % (i + 1), elipse(px, py, 105, 82, a)))
    regiones.append(("centro", circulo(cx, cy, 85)))
    regiones.append(("pasto", rect(10, 800, 980, 190, 0, 0, 60, 60)))
    detalles = [
        punto(470, 305, 10),
        punto(530, 305, 10),
        linea(curva(465, 345, 480, 372, 520, 372, 535, 345), 9),
    ]
    return "flor", "Flor", regiones, detalles


def pez():
    regiones = [
        ("agua", fondo()),
        ("burbuja1", circulo(110, 230, 62)),
        ("burbuja2", circulo(225, 108, 55)),
        ("cola", Forma().M(640, 500).L(900, 320).C(855, 430, 855, 570, 900, 680).Z()),
        ("aleta_arriba", Forma().M(300, 360).C(300, 190, 450, 110, 560, 360).Z()),
        ("aleta_abajo", Forma().M(360, 640).C(340, 800, 480, 840, 560, 640).Z()),
        ("cuerpo", elipse(430, 500, 270, 170)),
    ]
    detalles = [
        punto(270, 450, 26),
        linea(curva(190, 535, 215, 565, 245, 565, 265, 540), 10),
        linea(curva(345, 395, 310, 460, 310, 540, 345, 605), 10),
    ]
    return "pez", "Pez", regiones, detalles


def casa():
    regiones = [
        ("cielo", fondo()),
        ("sol", circulo(170, 170, 85)),
        ("pasto", rect(10, 780, 980, 210, 0, 0, 60, 60)),
        ("pared", rect(250, 430, 500, 390)),
        ("chimenea", rect(610, 230, 110, 190)),
        ("techo", poligono([(200, 450), (500, 200), (800, 450)])),
        ("puerta", rect(430, 590, 140, 230, 70, 70, 0, 0)),
        ("ventana_izq", rect(285, 500, 110, 110)),
        ("ventana_der", rect(605, 500, 110, 110)),
    ]
    rayos = Forma()
    for i in range(8):
        a = math.radians(i * 45)
        rayos.M(170 + 108 * math.cos(a), 170 + 108 * math.sin(a))
        rayos.L(170 + 142 * math.cos(a), 170 + 142 * math.sin(a))
    cruces = Forma()
    for x0 in (285, 605):
        cruces.M(x0 + 55, 500).L(x0 + 55, 610)
        cruces.M(x0, 555).L(x0 + 110, 555)
    detalles = [
        linea(rayos, 10),
        linea(cruces, 8),
        punto(535, 715, 13),
    ]
    return "casa", "Casa", regiones, detalles
