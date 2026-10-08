"""Vehículos, naturaleza, comida y objetos."""
import math

import numpy as np

from formas import (Forma, asa_j, banda_arco, circulo, contorno, corazon, creciente,
                    curva, elipse, en_circulo, en_elipse, en_forma, en_poligono,
                    en_rect, espejo, estrella, fondo, gota, hoja, interseccion,
                    linea, lineas_dentro, nube, ondas, poligono, punto, rect,
                    relleno_negro, segmentos, sonrisa, suelo, union)


# ---------------------------------------------------------------- vehículos

def carro():
    r = [
        ("fondo", fondo()),
        ("sol", circulo(810, 180, 85)),
        ("nube", nube(220, 200, 260)),
        ("camino", suelo(790)),
        ("cabina", poligono([(290, 560), (370, 390), (630, 390), (720, 560)])),
        ("ventana_izq", poligono([(335, 545), (385, 435), (485, 435), (485, 545)])),
        ("ventana_der", poligono([(515, 435), (615, 435), (665, 545), (515, 545)])),
        ("cuerpo", rect(150, 560, 700, 170, 60, 60, 40, 40)),
        ("rueda_izq", circulo(330, 740, 95)),
        ("rueda_der", circulo(670, 740, 95)),
    ]
    d = [
        linea(circulo(330, 740, 45), 8), punto(330, 740, 14),
        linea(circulo(670, 740, 45), 8), punto(670, 740, 14),
        linea(circulo(800, 625, 28), 8),
        linea(segmentos((500, 572, 500, 712), (535, 612, 590, 612)), 8),
    ]
    return "carro", "Carro", r, d


def barco():
    casco = (Forma().M(190, 640).L(810, 640).C(780, 790, 710, 830, 600, 830)
             .L(400, 830).C(290, 830, 220, 790, 190, 640).Z())
    r = [
        ("fondo", fondo()),
        ("sol", circulo(170, 170, 80)),
        ("nube", nube(780, 200, 270)),
        ("vela_grande", poligono([(525, 150), (525, 610), (300, 610)])),
        ("vela_chica", poligono([(575, 260), (575, 610), (745, 610)])),
        ("casco", casco),
        ("mar", ondas(750, 22, 6)),
    ]
    d = [
        linea(segmentos((550, 110, 550, 645)), 16),
        relleno_negro(poligono([(550, 110), (665, 150), (550, 190)])),
    ]
    for x in (300, 380, 460, 540, 620, 700):
        d.append(linea(circulo(x, 695, 20), 7))
    return "barco", "Barco", r, d


def avion():
    r = [
        ("fondo", fondo()),
        ("nube1", nube(200, 170, 260)),
        ("nube2", nube(780, 820, 300)),
        ("cola", poligono([(190, 480), (140, 290), (270, 290), (340, 450)])),
        ("fuselaje", elipse(500, 500, 350, 105)),
    ]
    for i, x in enumerate((280, 380, 480, 580, 680)):
        r.append(("ventana%d" % (i + 1), circulo(x, 495, 46)))
    r.append(("ala", poligono([(430, 545), (590, 545), (470, 790), (340, 790)])))
    return "avion", "Avión", r, []


def cohete():
    cuerpo = (Forma().M(500, 100).C(650, 210, 710, 420, 685, 650).L(315, 650)
              .C(290, 420, 350, 210, 500, 100).Z())
    dentro = en_forma(cuerpo)
    punta = contorno(interseccion(dentro, en_rect(0, 0, 1000, 255)), 500, 190, rmax=400)
    medio = contorno(interseccion(dentro, en_rect(0, 255, 1000, 545)), 500, 400, rmax=400)
    franja = contorno(interseccion(dentro, en_rect(0, 545, 1000, 660)), 500, 600, rmax=400)
    aleta = [(345, 500), (195, 740), (205, 830), (345, 740)]
    llama_ext = Forma().M(400, 650).C(380, 800, 450, 880, 500, 950).C(550, 880, 620, 800, 600, 650).Z()
    llama_int = Forma().M(450, 660).C(440, 760, 480, 810, 500, 860).C(520, 810, 560, 760, 550, 660).Z()
    r = [
        ("espacio", fondo()),
        ("estrella1", estrella(150, 200, 60)),
        ("estrella2", estrella(850, 240, 60)),
        ("estrella3", estrella(120, 650, 55)),
        ("estrella4", estrella(880, 700, 55)),
        ("llama", llama_ext),
        ("llama_centro", llama_int),
        ("aleta_izq", poligono(aleta)),
        ("aleta_der", poligono(espejo(aleta))),
        ("punta", punta),
        ("cuerpo", medio),
        ("franja", franja),
        ("ventana", circulo(500, 390, 85)),
    ]
    d = [linea(circulo(500, 390, 62), 8)]
    return "cohete", "Cohete", r, d


# ---------------------------------------------------------------- naturaleza

def arbol():
    copa = union(en_circulo(500, 300, 150), en_circulo(355, 410, 125),
                 en_circulo(645, 410, 125), en_circulo(500, 440, 135))
    r = [
        ("fondo", fondo()),
        ("sol", circulo(150, 160, 80)),
        ("nube", nube(780, 180, 260)),
        ("tronco", rect(430, 500, 140, 380)),
        ("copa", contorno(copa, 500, 400, rmax=400)),
        ("manzana1", circulo(430, 330, 50)),
        ("manzana2", circulo(580, 300, 50)),
        ("manzana3", circulo(610, 420, 50)),
        ("manzana4", circulo(390, 460, 50)),
        ("manzana5", circulo(510, 500, 50)),
        ("pasto", suelo(800)),
    ]
    d = [linea(segmentos((470, 620, 470, 720), (530, 650, 530, 745)), 8)]
    return "arbol", "Árbol", r, d


def nube_lluvia():
    r = [("fondo", fondo()), ("nube", nube(500, 300, 640))]
    for i, (x, y) in enumerate([(300, 620), (500, 620), (700, 620), (400, 810), (600, 810)]):
        r.append(("gota%d" % (i + 1), gota(x, y, 100, 150)))
    d = [
        punto(440, 335, 24), punto(560, 335, 24),
        linea(sonrisa(500, 385, 110, 28), 9),
    ]
    return "nube_lluvia", "Nube con lluvia", r, d


def luna():
    r = [
        ("cielo", fondo()),
        ("luna", creciente((450, 450), 260, (580, 400), 215)),
        ("estrella1", estrella(740, 220, 75)),
        ("estrella2", estrella(810, 560, 70)),
        ("estrella3", estrella(640, 830, 70)),
        ("estrella4", estrella(230, 840, 60)),
    ]
    d = [
        linea(curva(255, 445, 275, 485, 305, 485, 325, 445), 9),
        linea(curva(250, 560, 275, 600, 315, 600, 340, 565), 9),
    ]
    for x, y in ((560, 90), (900, 380), (880, 840), (120, 110), (90, 560)):
        d.append(punto(x, y, 10))
    return "luna", "Luna y estrellas", r, d


def arcoiris():
    cx, cy = 500, 740
    r = [("cielo", fondo())]
    for i, (R, rr) in enumerate([(440, 345), (345, 250), (250, 155), (155, 60)]):
        r.append(("banda%d" % (i + 1), banda_arco(cx, cy, R, rr, math.pi, 2 * math.pi)))
    r.append(("nube_izq", nube(250, 720, 420)))
    r.append(("nube_der", nube(750, 720, 420)))
    return "arcoiris", "Arcoíris", r, []


def hongo():
    gorro = Forma().M(120, 560).C(120, 300, 300, 170, 500, 170).C(700, 170, 880, 300, 880, 560).Z()
    tallo = (Forma().M(400, 540).L(600, 540).C(590, 650, 640, 760, 700, 840).L(300, 840)
             .C(360, 760, 410, 650, 400, 540).Z())
    r = [
        ("fondo", fondo()),
        ("tallo", tallo),
        ("gorro", gorro),
        ("mancha1", circulo(330, 400, 70)),
        ("mancha2", circulo(520, 310, 80)),
        ("mancha3", circulo(700, 420, 65)),
        ("pasto", suelo(820)),
    ]
    d = [punto(460, 650, 16), punto(540, 650, 16), linea(sonrisa(500, 700, 70, 22), 9)]
    return "hongo", "Hongo", r, d


# ---------------------------------------------------------------- comida

def manzana():
    dentro = union(en_elipse(405, 545, 235, 265), en_elipse(595, 545, 235, 265))
    r = [
        ("fondo", fondo()),
        ("mesa", suelo(800)),
        ("manzana", contorno(dentro, 500, 560, rmax=500)),
        ("hoja", hoja(525, 310, 700, 215, 65)),
    ]
    d = [
        linea(curva(500, 335, 500, 285, 515, 240, 540, 205), 26),
        linea(curva(275, 480, 285, 430, 315, 395, 360, 380), 12),
    ]
    return "manzana", "Manzana", r, d


def helado():
    cono_pts = [(330, 520), (670, 520), (500, 925)]
    dentro_cono = en_poligono(cono_pts)
    rayas = []
    for k in range(-6, 8):
        rayas.append((300 + k * 60, 500, 300 + k * 60 + 500, 1000))
        rayas.append((700 - k * 60, 500, 700 - k * 60 - 500, 1000))
    r = [
        ("fondo", fondo()),
        ("cono", poligono(cono_pts)),
        ("bola_baja", elipse(500, 500, 220, 115)),
        ("bola_alta", circulo(500, 335, 155)),
        ("cereza", circulo(500, 165, 55)),
    ]
    d = [
        linea(lineas_dentro(dentro_cono, rayas), 6),
        linea(curva(500, 112, 510, 80, 540, 60, 580, 50), 8),
        linea(segmentos((440, 300, 462, 288), (540, 280, 525, 303), (480, 375, 505, 387),
                        (405, 370, 425, 350), (565, 365, 585, 345), (500, 245, 500, 270)), 9),
    ]
    return "helado", "Helado", r, d


def cupcake():
    r = [
        ("fondo", fondo()),
        ("mesa", suelo(880)),
        ("papel", poligono([(280, 560), (720, 560), (650, 880), (350, 880)])),
        ("crema_baja", elipse(500, 520, 265, 100)),
        ("crema_media", elipse(500, 405, 205, 90)),
        ("crema_alta", elipse(500, 305, 140, 80)),
        ("cereza", circulo(500, 215, 55)),
    ]
    rayas = []
    for t in (0.2, 0.4, 0.6, 0.8):
        # las rayas empiezan debajo de la crema (y = 630) y bajan hasta la mesa
        rayas.append((295.3 + 409.4 * t, 630, 350 + 300 * t, 880))
    d = [
        linea(segmentos(*rayas), 7),
        linea(curva(500, 162, 510, 130, 540, 112, 580, 105), 8),
        linea(segmentos((350, 505, 372, 492), (610, 545, 632, 530), (450, 565, 470, 580),
                        (540, 500, 562, 512), (420, 410, 440, 398), (560, 440, 580, 452),
                        (470, 300, 490, 290), (545, 335, 561, 348)), 9),
    ]
    return "cupcake", "Cupcake", r, d


def fresa():
    cuerpo = (Forma().M(500, 900).C(300, 800, 200, 600, 230, 440).C(260, 300, 420, 270, 500, 320)
              .C(580, 270, 740, 300, 770, 440).C(800, 600, 700, 800, 500, 900).Z())
    dentro = en_forma(cuerpo)
    semillas = []
    for fila, y in enumerate(range(520, 860, 75)):
        desplazo = 0 if fila % 2 == 0 else 40
        for x in range(330 + desplazo, 700, 80):
            ok = all(dentro(np.array([x + dx]), np.array([y + dy]))[0]
                     for dx, dy in ((50, 0), (-50, 0), (0, 50), (0, -50)))
            if ok:
                semillas.append(relleno_negro(elipse(x, y, 9, 14)))
    r = [
        ("fondo", fondo()),
        ("fresa", cuerpo),
        ("hojas", estrella(500, 320, 140, 70, 5)),
    ]
    d = semillas + [linea(curva(500, 300, 505, 240, 520, 195, 548, 160), 24)]
    return "fresa", "Fresa", r, d


# ---------------------------------------------------------------- objetos

def globos():
    ry = 135
    r = [
        ("fondo", fondo()),
        ("estrella1", estrella(140, 170, 60)),
        ("estrella2", estrella(870, 200, 60)),
    ]
    posiciones = [("globo1", 310, 370), ("globo3", 690, 380), ("globo2", 500, 270)]
    d = []
    for nombre, cx, cy in posiciones:
        r.append((nombre, elipse(cx, cy, 105, ry)))
        d.append(relleno_negro(poligono([(cx - 15, cy + ry + 24), (cx + 15, cy + ry + 24), (cx, cy + ry)])))
        d.append(linea(curva(cx, cy + ry + 24, cx, 560, 500, 700, 500, 900), 6))
        d.append(linea(curva(cx - 62, cy - 55, cx - 55, cy - 88, cx - 35, cy - 105, cx - 8, cy - 112), 9))
    return "globos", "Globos", r, d


def corazon_grande():
    r = [
        ("fondo", fondo()),
        ("corazon", corazon(500, 500, 720)),
        ("interior", corazon(500, 480, 370)),
        ("mini_izq", corazon(170, 150, 170)),
        ("mini_der", corazon(830, 150, 170)),
    ]
    d = [linea(curva(225, 335, 230, 285, 265, 250, 315, 238), 12)]
    return "corazon", "Corazón", r, d


def regalo():
    r = [
        ("fondo", fondo()),
        ("mesa", suelo(850)),
        ("caja", rect(230, 470, 540, 380)),
        ("tapa", rect(190, 380, 620, 120, 20, 20, 20, 20)),
        ("cinta", rect(455, 380, 90, 470)),
        ("lazo_izq", elipse(405, 310, 105, 62, 0.5)),
        ("lazo_der", elipse(595, 310, 105, 62, -0.5)),
        ("nudo", circulo(500, 345, 50)),
        ("estrella1", estrella(140, 180, 62)),
        ("estrella2", estrella(860, 200, 62)),
    ]
    return "regalo", "Regalo", r, []


def paraguas():
    apice = (500, 140)
    base_y = 520
    pasos = 32
    # bordes de cada gajo: de la punta hasta la base
    izq = [(500 - 400 * math.sin(t), base_y - 380 * math.cos(t))
           for t in np.linspace(0, math.pi / 2, pasos)]
    der = [(1000 - x, y) for x, y in izq]

    def costilla(xb):
        if xb == 500:
            return [(500, 140 + (base_y - 140) * t) for t in np.linspace(0, 1, pasos)]
        c = (xb, 170)
        pts = []
        for t in np.linspace(0, 1, pasos):
            u = 1 - t
            pts.append((u * u * apice[0] + 2 * u * t * c[0] + t * t * xb,
                        u * u * apice[1] + 2 * u * t * c[1] + t * t * base_y))
        return pts

    bordes = [izq, costilla(280), costilla(500), costilla(720), der]
    r = [("cielo", fondo())]
    for i, (x, y, w, h) in enumerate([(150, 700, 95, 140), (860, 700, 95, 140), (730, 850, 95, 140)]):
        r.append(("gota%d" % (i + 1), gota(x, y, w, h)))
    r.append(("mango", asa_j(500, 90, 480, 770, 135, 45)))
    for i in range(4):
        izq_b, der_b = bordes[i], bordes[i + 1]
        xl, xr = izq_b[-1][0], der_b[-1][0]
        scallop = [(xl + (xr - xl) * t, base_y - 45 * math.sin(math.pi * t))
                   for t in np.linspace(0, 1, 24)]
        pts = list(izq_b) + scallop[1:] + list(reversed(der_b))[1:]
        r.append(("gajo%d" % (i + 1), poligono(pts)))
    d = [linea(segmentos((500, 140, 500, 95)), 14)]
    return "paraguas", "Paraguas", r, d
