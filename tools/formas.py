"""Herramientas para dibujar las formas de los dibujos (trazos SVG).

Los dibujos son cuadrados de 1000 x 1000 unidades. Aquí hay:
  - Forma: un trazo SVG con comandos absolutos M, L, C y Z.
  - Figuras listas: circulo, elipse, rect, poligono, hoja, estrella, corazon, gota, nube...
  - contorno(): saca el borde de una figura armada con "dentro" (unión, intersección o
    resta de figuras simples). Sirve para nubes, copas de árboles, rayas de la abeja, etc.
"""
import math

import numpy as np
from matplotlib.path import Path as _RutaMpl

K = 0.5522847498307936  # constante para dibujar círculos con curvas Bézier


class Forma:
    """Un trazo SVG que usa solo comandos absolutos: M, L, C y Z."""

    def __init__(self):
        self.partes = []

    def M(self, x, y):
        self.partes.append(("M", x, y))
        return self

    def L(self, x, y):
        self.partes.append(("L", x, y))
        return self

    def C(self, x1, y1, x2, y2, x, y):
        self.partes.append(("C", x1, y1, x2, y2, x, y))
        return self

    def Z(self):
        self.partes.append(("Z",))
        return self

    def d(self):
        return " ".join(
            " ".join([p[0]] + ["%.1f" % v for v in p[1:]]) for p in self.partes
        )

    def puntos(self, pasos=24):
        """Lista de puntos (x, y) que siguen el contorno de la forma."""
        pts = []
        actual = (0.0, 0.0)
        for p in self.partes:
            if p[0] in ("M", "L"):
                actual = (p[1], p[2])
                pts.append(actual)
            elif p[0] == "C":
                x0, y0 = actual
                for i in range(1, pasos + 1):
                    t = i / pasos
                    u = 1 - t
                    x = u**3 * x0 + 3 * u * u * t * p[1] + 3 * u * t * t * p[3] + t**3 * p[5]
                    y = u**3 * y0 + 3 * u * u * t * p[2] + 3 * u * t * t * p[4] + t**3 * p[6]
                    pts.append((x, y))
                actual = (p[5], p[6])
        return pts


# ------------------------------------------------------------ figuras básicas

def elipse(cx, cy, rx, ry, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)

    def T(x, y):
        return (cx + x * c - y * s, cy + x * s + y * c)

    f = Forma()
    f.M(*T(rx, 0))
    tramos = [
        ((rx, K * ry), (K * rx, ry), (0, ry)),
        ((-K * rx, ry), (-rx, K * ry), (-rx, 0)),
        ((-rx, -K * ry), (-K * rx, -ry), (0, -ry)),
        ((K * rx, -ry), (rx, -K * ry), (rx, 0)),
    ]
    for a, b, fin in tramos:
        f.C(*T(*a), *T(*b), *T(*fin))
    return f.Z()


def circulo(cx, cy, r):
    return elipse(cx, cy, r, r)


def rect(x, y, w, h, tl=0, tr=0, br=0, bl=0):
    """Rectángulo con esquinas redondeadas opcionales (arriba-izq, arriba-der, abajo-der, abajo-izq)."""
    f = Forma()
    f.M(x + tl, y)
    f.L(x + w - tr, y)
    if tr:
        f.C(x + w - tr + K * tr, y, x + w, y + tr - K * tr, x + w, y + tr)
    f.L(x + w, y + h - br)
    if br:
        f.C(x + w, y + h - br + K * br, x + w - br + K * br, y + h, x + w - br, y + h)
    f.L(x + bl, y + h)
    if bl:
        f.C(x + bl - K * bl, y + h, x, y + h - bl + K * bl, x, y + h - bl)
    f.L(x, y + tl)
    if tl:
        f.C(x, y + tl - K * tl, x + tl - K * tl, y, x + tl, y)
    return f.Z()


def poligono(puntos):
    f = Forma()
    for i, (x, y) in enumerate(puntos):
        f.M(x, y) if i == 0 else f.L(x, y)
    return f.Z()


def espejo(puntos):
    """Refleja una lista de puntos de izquierda a derecha (x -> 1000 - x)."""
    return [(1000 - x, y) for x, y in puntos]


def hoja(bx, by, px, py, ancho):
    """Hoja con punta en los dos extremos: de (bx,by) a (px,py)."""
    dx, dy = px - bx, py - by
    largo = math.hypot(dx, dy)
    nx, ny = -dy / largo, dx / largo
    f = Forma()
    f.M(bx, by)
    f.C(bx + dx * 0.30 + nx * ancho, by + dy * 0.30 + ny * ancho,
        bx + dx * 0.70 + nx * ancho, by + dy * 0.70 + ny * ancho, px, py)
    f.C(bx + dx * 0.70 - nx * ancho, by + dy * 0.70 - ny * ancho,
        bx + dx * 0.30 - nx * ancho, by + dy * 0.30 - ny * ancho, bx, by)
    return f.Z()


def curva(x0, y0, x1, y1, x2, y2, x3, y3):
    """Línea curva abierta (para sonrisas, branquias...)."""
    return Forma().M(x0, y0).C(x1, y1, x2, y2, x3, y3)


def segmentos(*lineas):
    """Varias rayitas sueltas: segmentos((x0,y0,x1,y1), ...)."""
    f = Forma()
    for x0, y0, x1, y1 in lineas:
        f.M(x0, y0).L(x1, y1)
    return f


def sonrisa(cx, cy, ancho, hondo):
    """Sonrisa curva centrada en (cx, cy)."""
    a = ancho / 2.0
    return curva(cx - a, cy, cx - a / 2.0, cy + hondo * 1.33, cx + a / 2.0, cy + hondo * 1.33, cx + a, cy)


def punto(x, y, r):
    """Punto negro relleno (ojos, perillas)."""
    return {"path": circulo(x, y, r).d(), "relleno": "#000000"}


def relleno_negro(forma):
    return {"path": forma.d(), "relleno": "#000000"}


def linea(forma, grosor=10):
    return {"path": forma.d(), "grosor": grosor}


def fondo():
    return rect(10, 10, 980, 980, 60, 60, 60, 60)


def suelo(ytop):
    """Franja de suelo (pasto, hielo, mesa...) pegada al borde de abajo."""
    return rect(10, ytop, 980, 990 - ytop, 0, 0, 60, 60)


def estrella(cx, cy, R, r=None, puntas=5, rot=-math.pi / 2):
    r = r if r is not None else R * 0.45
    pts = []
    for i in range(puntas * 2):
        a = rot + i * math.pi / puntas
        rr = R if i % 2 == 0 else r
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    return poligono(pts)


def hexagono(cx, cy, r):
    """Hexágono con punta arriba."""
    return poligono([(cx + r * math.cos(math.radians(30 + 60 * i)),
                      cy + r * math.sin(math.radians(30 + 60 * i))) for i in range(6)])


def corazon(cx, cy, w):
    """Corazón de ancho w centrado en (cx, cy)."""
    base = [
        ("M", (500, 860)),
        ("C", (160, 600), (90, 430), (150, 300)),
        ("C", (210, 170), (400, 160), (500, 330)),
        ("C", (600, 160), (790, 170), (850, 300)),
        ("C", (910, 430), (840, 600), (500, 860)),
    ]
    muestra = Forma()
    for cmd in base:
        if cmd[0] == "M":
            muestra.M(*cmd[1])
        else:
            muestra.C(*cmd[1], *cmd[2], *cmd[3])
    pts = muestra.puntos(40)
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    mx, my = (min(xs) + max(xs)) / 2.0, (min(ys) + max(ys)) / 2.0
    k = w / (max(xs) - min(xs))

    def T(p):
        return (cx + (p[0] - mx) * k, cy + (p[1] - my) * k)

    f = Forma()
    for cmd in base:
        if cmd[0] == "M":
            f.M(*T(cmd[1]))
        else:
            f.C(*T(cmd[1]), *T(cmd[2]), *T(cmd[3]))
    return f.Z()


def ondas(ytop, amplitud=20, n=6):
    """Agua o mar con la parte de arriba ondulada, hasta el borde de abajo."""
    ancho = 980.0 / n
    f = Forma()
    x = 10.0
    y = ytop
    f.M(x, y)
    for i in range(n):
        x1 = x + ancho
        y1 = ytop + (amplitud if i % 2 == 0 else -amplitud)
        f.C(x + ancho / 2, y, x1 - ancho / 2, y1, x1, y1)
        x, y = x1, y1
    f.L(990, 930)
    f.C(990, 963, 963, 990, 930, 990)
    f.L(70, 990)
    f.C(37, 990, 10, 963, 10, 930)
    return f.Z()


# ------------------------------------------------------------ arcos

def _arco(f, cx, cy, r, a0, a1):
    """Agrega a la forma curvas Bézier que recorren el arco de a0 a a1 (radianes).
    La forma ya debe estar parada en el punto de ángulo a0."""
    n = max(1, int(math.ceil(abs(a1 - a0) / (math.pi / 2) - 1e-9)))
    da = (a1 - a0) / n
    for i in range(n):
        s = a0 + i * da
        e = s + da
        k = 4.0 / 3.0 * math.tan((e - s) / 4.0)
        x0, y0 = cx + r * math.cos(s), cy + r * math.sin(s)
        x3, y3 = cx + r * math.cos(e), cy + r * math.sin(e)
        f.C(x0 - k * r * math.sin(s), y0 + k * r * math.cos(s),
            x3 + k * r * math.sin(e), y3 - k * r * math.cos(e), x3, y3)


def banda_arco(cx, cy, R, r, a0, a1):
    """Franja curva entre dos radios (por ejemplo, cada color del arcoíris)."""
    f = Forma()
    f.M(cx + R * math.cos(a0), cy + R * math.sin(a0))
    _arco(f, cx, cy, R, a0, a1)
    f.L(cx + r * math.cos(a1), cy + r * math.sin(a1))
    _arco(f, cx, cy, r, a1, a0)
    return f.Z()


def creciente(c1, r1, c2, r2):
    """Luna creciente: el círculo (c1, r1) menos el círculo (c2, r2)."""
    dx, dy = c2[0] - c1[0], c2[1] - c1[1]
    d = math.hypot(dx, dy)
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    gamma = math.acos(a / r1)
    delta = math.acos((d - a) / r2)
    phi = math.atan2(dy, dx)
    q1 = (c1[0] + r1 * math.cos(phi + gamma), c1[1] + r1 * math.sin(phi + gamma))
    q2 = (c1[0] + r1 * math.cos(phi - gamma), c1[1] + r1 * math.sin(phi - gamma))
    f = Forma()
    f.M(*q1)
    _arco(f, c1[0], c1[1], r1, phi + gamma, phi + 2 * math.pi - gamma)
    # de q2 vuelta a q1 por el borde del círculo recortado que queda dentro del primero
    a2 = math.atan2(q2[1] - c2[1], q2[0] - c2[0])
    a1_ = math.atan2(q1[1] - c2[1], q1[0] - c2[0])
    da = (a1_ - a2) % (2 * math.pi)
    centro_deseado = phi + math.pi

    def cerca(m):
        return abs(((m - centro_deseado + math.pi) % (2 * math.pi)) - math.pi)

    if cerca(a2 + da / 2) <= cerca(a2 + (da - 2 * math.pi) / 2):
        _arco(f, c2[0], c2[1], r2, a2, a2 + da)
    else:
        _arco(f, c2[0], c2[1], r2, a2, a2 + da - 2 * math.pi)
    return f.Z()


def asa_j(cx, ancho, y0, y1, radio_ext, radio_int):
    """Mango en forma de J: baja recto desde y0 hasta y1 y se curva hacia la izquierda."""
    # Debe cumplirse ancho == radio_ext - radio_int.
    # Centro del gancho: el lado derecho del mango (cx + ancho/2) es xc + radio_ext.
    xc = cx + ancho / 2.0 - radio_ext
    f = Forma()
    f.M(cx - ancho / 2.0, y0)
    f.L(cx + ancho / 2.0, y0)
    f.L(cx + ancho / 2.0, y1)
    _arco(f, xc, y1, radio_ext, 0.0, math.pi)
    f.L(xc - radio_int, y1)
    _arco(f, xc, y1, radio_int, math.pi, 0.0)
    f.L(cx - ancho / 2.0, y0)
    return f.Z()


# ------------------------------------------------------------ figuras por "dentro"
# Cada función devuelve una prueba vectorizada dentro(x, y) -> máscara de True/False.

def en_circulo(cx, cy, r):
    return lambda x, y: (x - cx) ** 2 + (y - cy) ** 2 <= r * r


def en_elipse(cx, cy, rx, ry, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)

    def f(x, y):
        u = (x - cx) * c + (y - cy) * s
        v = -(x - cx) * s + (y - cy) * c
        return (u / rx) ** 2 + (v / ry) ** 2 <= 1.0

    return f


def en_rect(x0, y0, x1, y1):
    return lambda x, y: (x >= x0) & (x <= x1) & (y >= y0) & (y <= y1)


def en_poligono(puntos):
    ruta = _RutaMpl(list(puntos) + [puntos[0]])

    def f(x, y):
        pts = np.column_stack([np.ravel(x), np.ravel(y)])
        return ruta.contains_points(pts).reshape(np.shape(x))

    return f


def en_forma(forma):
    """Prueba 'dentro' para cualquier Forma cerrada."""
    return en_poligono(forma.puntos(40))


def union(*fs):
    def f(x, y):
        m = fs[0](x, y)
        for g in fs[1:]:
            m = m | g(x, y)
        return m

    return f


def interseccion(*fs):
    def f(x, y):
        m = fs[0](x, y)
        for g in fs[1:]:
            m = m & g(x, y)
        return m

    return f


def resta(a, b):
    return lambda x, y: a(x, y) & ~b(x, y)


def _rdp(pts, tol):
    if len(pts) < 3:
        return pts
    (x0, y0), (x1, y1) = pts[0], pts[-1]
    dx, dy = x1 - x0, y1 - y0
    largo = math.hypot(dx, dy)
    mejor, ib = -1.0, 0
    for i in range(1, len(pts) - 1):
        x, y = pts[i]
        d = abs(dy * (x - x0) - dx * (y - y0)) / largo if largo > 0 else math.hypot(x - x0, y - y0)
        if d > mejor:
            mejor, ib = d, i
    if mejor > tol:
        return _rdp(pts[: ib + 1], tol)[:-1] + _rdp(pts[ib:], tol)
    return [pts[0], pts[-1]]


def contorno(dentro, cx, cy, rmax=700, n=540, tol=0.45):
    """Saca el borde de una figura definida con 'dentro'.

    (cx, cy) debe ser un punto dentro de la figura desde el cual se vea todo el borde
    (sirve para nubes, copas, óvalos recortados... pero no para figuras con huecos).
    """
    ang = np.linspace(0, 2 * np.pi, n, endpoint=False)
    c, s = np.cos(ang), np.sin(ang)
    rs = np.arange(0, rmax, 1.0)
    X = cx + np.outer(c, rs)
    Y = cy + np.outer(s, rs)
    M = dentro(X, Y)
    if not M[:, 0].all():
        raise ValueError("el centro (%s, %s) no está dentro de la figura" % (cx, cy))
    ultimo = (M.shape[1] - 1) - np.argmax(M[:, ::-1], axis=1)
    if (ultimo >= M.shape[1] - 1).any():
        raise ValueError("rmax es muy chico para esta figura")
    lo = rs[ultimo].astype(float)
    hi = lo + 1.0
    for _ in range(12):
        mid = (lo + hi) / 2.0
        dentro_mid = dentro(cx + mid * c, cy + mid * s)
        lo = np.where(dentro_mid, mid, lo)
        hi = np.where(dentro_mid, hi, mid)
    pts = [(float(cx + r * ci), float(cy + r * si)) for r, ci, si in zip(lo, c, s)]
    simple = _rdp(pts + [pts[0]], tol)[:-1]
    return poligono(simple)


def lineas_dentro(dentro, lineas, paso=1.0):
    """Recorta rayitas (x0,y0,x1,y1) para que queden solo dentro de la figura."""
    f = Forma()
    for x0, y0, x1, y1 in lineas:
        largo = math.hypot(x1 - x0, y1 - y0)
        n = max(2, int(largo / paso))
        t = np.linspace(0, 1, n)
        xs, ys = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        m = dentro(xs, ys)
        i = 0
        while i < n:
            if m[i]:
                j = i
                while j + 1 < n and m[j + 1]:
                    j += 1
                if j > i:
                    f.M(xs[i], ys[i]).L(xs[j], ys[j])
                i = j + 1
            else:
                i += 1
    return f


# ------------------------------------------------------------ figuras armadas

def gota(cx, cy, w, h):
    """Gota de agua de ancho w y alto h centrada en (cx, cy)."""
    r = w / 2.0
    ccx, ccy = cx, cy + h / 2.0 - r
    tx, ty = cx, cy - h / 2.0
    d = ccy - ty
    beta = math.asin(r / d)
    largo = math.sqrt(d * d - r * r)
    izq = (tx - largo * math.sin(beta), ty + largo * math.cos(beta))
    der = (tx + largo * math.sin(beta), ty + largo * math.cos(beta))
    dentro = union(en_circulo(ccx, ccy, r), en_poligono([(tx, ty), izq, der]))
    return contorno(dentro, ccx, ccy, rmax=int(h) + 10, n=360, tol=0.3)


def _nube_dentro(cx, cy, w):
    return union(
        en_circulo(cx - 0.28 * w, cy + 0.04 * w, 0.20 * w),
        en_circulo(cx - 0.02 * w, cy - 0.08 * w, 0.27 * w),
        en_circulo(cx + 0.27 * w, cy + 0.02 * w, 0.21 * w),
        en_rect(cx - 0.28 * w, cy + 0.0 * w, cx + 0.27 * w, cy + 0.24 * w),
    )


def nube(cx, cy, w):
    """Nube de ancho aproximado w (0.96 * w) con fondo plano. (cx, cy) es el centro de la parte alta."""
    return contorno(_nube_dentro(cx, cy, w), cx - 0.02 * w, cy + 0.02 * w, rmax=int(w), n=540)
