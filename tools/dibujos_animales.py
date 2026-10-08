"""Animales: gato, perro, conejo, pollito, mariposa, tortuga, oso, cerdito, rana,
abeja, pingüino, ballena y pato."""
from formas import (circulo, contorno, curva, elipse, en_elipse, en_rect, fondo,
                    gota, hexagono, hoja, interseccion, linea, ondas, poligono,
                    punto, rect, relleno_negro, segmentos, sonrisa, suelo)


def _oval_negro(cx, cy, rx, ry):
    return relleno_negro(elipse(cx, cy, rx, ry))


def gato():
    r = [
        ("fondo", fondo()),
        ("oreja_izq", poligono([(225, 450), (235, 140), (470, 300)])),
        ("oreja_der", poligono([(775, 450), (765, 140), (530, 300)])),
        ("cabeza", circulo(500, 570, 300)),
        ("hocico", elipse(500, 700, 125, 85)),
    ]
    izq = [(400, 690, 150, 640), (400, 715, 140, 725), (400, 740, 160, 810)]
    der = [(1000 - a, b, 1000 - c, d) for a, b, c, d in izq]
    d = [
        punto(395, 520, 26), punto(605, 520, 26),
        relleno_negro(poligono([(468, 628), (532, 628), (500, 664)])),
        linea(segmentos((500, 664, 500, 700)), 8),
        linea(curva(500, 700, 480, 735, 445, 735, 425, 710), 8),
        linea(curva(500, 700, 520, 735, 555, 735, 575, 710), 8),
        linea(segmentos(*izq, *der), 7),
    ]
    return "gato", "Gato", r, d


def perro():
    r = [
        ("fondo", fondo()),
        ("cabeza", elipse(500, 500, 260, 285)),
        ("oreja_izq", elipse(245, 500, 95, 200, -0.18)),
        ("oreja_der", elipse(755, 500, 95, 200, 0.18)),
        ("lengua", elipse(500, 800, 55, 85)),
        ("hocico", elipse(500, 640, 165, 125)),
    ]
    d = [
        punto(405, 450, 26), punto(595, 450, 26),
        _oval_negro(500, 585, 60, 42),
        linea(segmentos((500, 627, 500, 672)), 8),
        linea(curva(500, 672, 470, 707, 425, 702, 405, 672), 8),
        linea(curva(500, 672, 530, 707, 575, 702, 595, 672), 8),
    ]
    return "perro", "Perro", r, d


def conejo():
    r = [
        ("fondo", fondo()),
        ("oreja_izq", elipse(405, 235, 80, 200, -0.12)),
        ("oreja_der", elipse(595, 235, 80, 200, 0.12)),
        ("interior_izq", elipse(405, 245, 45, 140, -0.12)),
        ("interior_der", elipse(595, 245, 45, 140, 0.12)),
        ("cabeza", circulo(500, 650, 260)),
    ]
    izq = [(390, 700, 160, 650), (390, 725, 150, 735), (390, 750, 170, 820)]
    der = [(1000 - a, b, 1000 - c, d) for a, b, c, d in izq]
    d = [
        punto(415, 620, 24), punto(585, 620, 24),
        relleno_negro(poligono([(478, 690), (522, 690), (500, 718)])),
        linea(segmentos((500, 718, 500, 748)), 8),
        linea(curva(500, 748, 480, 778, 445, 773, 430, 752), 8),
        linea(curva(500, 748, 520, 778, 555, 773, 570, 752), 8),
        linea(rect(472, 752, 56, 66, 0, 0, 12, 12), 8),
        linea(segmentos((500, 752, 500, 818)), 8),
        linea(segmentos(*izq, *der), 7),
    ]
    return "conejo", "Conejo", r, d


def pollito():
    r = [
        ("fondo", fondo()),
        ("pasto", suelo(880)),
        ("cresta", poligono([(410, 345), (425, 200), (485, 290), (520, 165),
                             (560, 290), (610, 215), (590, 350)])),
        ("pata_izq", poligono([(340, 930), (480, 930), (410, 790)])),
        ("pata_der", poligono([(520, 930), (660, 930), (590, 790)])),
        ("cuerpo", circulo(500, 560, 270)),
        ("ala_izq", elipse(270, 610, 70, 150, 0.2)),
        ("ala_der", elipse(730, 610, 70, 150, -0.2)),
        ("pico", poligono([(430, 520), (570, 520), (500, 612)])),
    ]
    d = [punto(415, 440, 22), punto(585, 440, 22)]
    return "pollito", "Pollito", r, d


def mariposa():
    r = [
        ("fondo", fondo()),
        ("ala_inf_izq", elipse(355, 650, 150, 115, -0.5)),
        ("ala_inf_der", elipse(645, 650, 150, 115, 0.5)),
        ("ala_sup_izq", elipse(315, 380, 200, 140, 0.45)),
        ("ala_sup_der", elipse(685, 380, 200, 140, -0.45)),
        ("mancha_sup_izq", circulo(280, 370, 55)),
        ("mancha_sup_der", circulo(720, 370, 55)),
        ("mancha_inf_izq", circulo(330, 660, 50)),
        ("mancha_inf_der", circulo(670, 660, 50)),
        ("cuerpo", elipse(500, 520, 46, 215)),
        ("cabeza", circulo(500, 300, 52)),
    ]
    d = [
        linea(curva(480, 262, 470, 200, 440, 170, 400, 160), 9),
        linea(curva(520, 262, 530, 200, 560, 170, 600, 160), 9),
        punto(400, 160, 14), punto(600, 160, 14),
        punto(484, 292, 9), punto(516, 292, 9),
    ]
    return "mariposa", "Mariposa", r, d


def tortuga():
    r = [
        ("fondo", fondo()),
        ("pasto", suelo(830)),
        ("cola", poligono([(210, 470), (80, 545), (210, 620)])),
        ("pata_izq", rect(230, 650, 120, 190, 0, 0, 40, 40)),
        ("pata_der", rect(600, 650, 120, 190, 0, 0, 40, 40)),
        ("cabeza", elipse(810, 515, 105, 85)),
        ("caparazon", elipse(470, 500, 290, 215)),
        ("hex_izq", hexagono(305, 500, 85)),
        ("hex_centro", hexagono(470, 500, 85)),
        ("hex_der", hexagono(635, 500, 85)),
    ]
    d = [
        punto(850, 490, 18),
        linea(curva(830, 555, 855, 578, 885, 572, 905, 548), 8),
    ]
    return "tortuga", "Tortuga", r, d


def oso():
    r = [
        ("fondo", fondo()),
        ("oreja_izq", circulo(270, 300, 100)),
        ("oreja_der", circulo(730, 300, 100)),
        ("interior_izq", circulo(270, 300, 55)),
        ("interior_der", circulo(730, 300, 55)),
        ("cabeza", circulo(500, 560, 290)),
        ("hocico", elipse(500, 660, 125, 95)),
    ]
    d = [
        punto(400, 510, 24), punto(600, 510, 24),
        _oval_negro(500, 625, 46, 32),
        linea(segmentos((500, 657, 500, 700)), 8),
        linea(curva(500, 700, 470, 735, 430, 730, 415, 705), 8),
        linea(curva(500, 700, 530, 735, 570, 730, 585, 705), 8),
    ]
    return "oso", "Oso", r, d


def cerdito():
    r = [
        ("fondo", fondo()),
        ("oreja_izq", poligono([(265, 340), (200, 140), (440, 255)])),
        ("oreja_der", poligono([(735, 340), (800, 140), (560, 255)])),
        ("cabeza", elipse(500, 540, 315, 285)),
        ("hocico", elipse(500, 620, 150, 110)),
    ]
    d = [
        punto(385, 470, 26), punto(615, 470, 26),
        _oval_negro(450, 620, 17, 30), _oval_negro(550, 620, 17, 30),
        linea(sonrisa(500, 765, 190, 30), 9),
    ]
    return "cerdito", "Cerdito", r, d


def rana():
    r = [
        ("fondo", fondo()),
        ("nenufar", elipse(500, 830, 400, 115)),
        ("ojo_izq", circulo(345, 370, 115)),
        ("ojo_der", circulo(655, 370, 115)),
        ("cabeza", elipse(500, 600, 340, 235)),
    ]
    d = [
        punto(355, 385, 38), punto(645, 385, 38),
        punto(460, 560, 10), punto(540, 560, 10),
        linea(curva(250, 640, 330, 770, 670, 770, 750, 640), 10),
    ]
    return "rana", "Rana", r, d


def abeja():
    cuerpo = en_elipse(500, 570, 265, 190)
    xs = [235, 375, 500, 625, 765]
    r = [
        ("fondo", fondo()),
        ("ala_izq", elipse(420, 340, 80, 150, -0.35)),
        ("ala_der", elipse(580, 340, 80, 150, 0.35)),
        ("aguijon", poligono([(745, 510), (900, 570), (745, 630)])),
    ]
    for i in range(4):
        franja = interseccion(cuerpo, en_rect(xs[i], 300, xs[i + 1], 840))
        r.append(("banda%d" % (i + 1), contorno(franja, (xs[i] + xs[i + 1]) / 2.0, 570, rmax=400)))
    r.append(("cabeza", circulo(205, 570, 105)))
    d = [
        punto(180, 540, 20),
        linea(curva(150, 612, 170, 642, 210, 642, 232, 612), 9),
        linea(curva(170, 480, 150, 400, 120, 370, 90, 360), 9),
        linea(curva(235, 478, 255, 400, 285, 370, 320, 360), 9),
        punto(90, 360, 14), punto(320, 360, 14),
    ]
    return "abeja", "Abeja", r, d


def pinguino():
    r = [
        ("fondo", fondo()),
        ("hielo", suelo(860)),
        ("pie_izq", elipse(410, 900, 100, 50)),
        ("pie_der", elipse(590, 900, 100, 50)),
        ("cuerpo", elipse(500, 540, 235, 330)),
        ("barriga", elipse(500, 630, 155, 240)),
        ("ala_izq", elipse(260, 580, 58, 170, 0.12)),
        ("ala_der", elipse(740, 580, 58, 170, -0.12)),
        ("pico", poligono([(430, 405), (570, 405), (500, 495)])),
    ]
    d = [punto(435, 350, 22), punto(565, 350, 22)]
    return "pinguino", "Pingüino", r, d


def ballena():
    r = [
        ("fondo", fondo()),
        ("gota1", gota(600, 250, 95, 140)),
        ("gota2", gota(715, 185, 95, 140)),
        ("gota3", gota(820, 280, 95, 140)),
        ("cola_arriba", hoja(285, 585, 90, 380, 70)),
        ("cola_abajo", hoja(285, 620, 90, 730, 70)),
        ("cuerpo", elipse(520, 600, 330, 215)),
        ("aleta", elipse(470, 700, 110, 55, 0.55)),
        ("mar", ondas(850, 22, 7)),
    ]
    d = [
        punto(730, 515, 22),
        linea(curva(690, 620, 740, 670, 800, 665, 835, 610), 9),
    ]
    return "ballena", "Ballena", r, d


def pato():
    r = [
        ("fondo", fondo()),
        ("cola", poligono([(200, 560), (90, 420), (270, 500)])),
        ("cuerpo", elipse(450, 640, 300, 190)),
        ("ala", hoja(585, 650, 265, 600, 75)),
        ("pico", elipse(870, 450, 90, 48, 0.05)),
        ("cabeza", circulo(700, 410, 135)),
        ("agua", ondas(800, 18, 6)),
    ]
    d = [punto(735, 375, 20)]
    return "pato", "Pato", r, d
