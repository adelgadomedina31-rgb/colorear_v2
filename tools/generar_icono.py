#!/usr/bin/env python3
"""Dibuja el ícono de ARVI: un arcoíris recién pintado con un pincel, gotas
de pintura y estrellitas, sobre un fondo amarillo-rosado.

Crea en icono/:
  - icono.png            (1024 x 1024, el ícono completo, para verlo)
  - fondo.png            (fondo, para el ícono "adaptable" de Android 8+)
  - frente.png           (dibujo con fondo transparente, para el adaptable)

Luego tools/preparar_android.py los copia a la app en todos los tamaños.
Necesita Pillow (pip install pillow).  Uso:  python3 tools/generar_icono.py
"""
import math
import os

from PIL import Image, ImageDraw, ImageFilter

S = 4  # se dibuja 4 veces más grande y se achica: bordes suaves
L = 1024 * S


def fondo():
    arriba, abajo = (255, 241, 168), (255, 182, 216)
    columna = Image.new("RGB", (1, L))
    for y in range(L):
        t = y / (L - 1)
        columna.putpixel((0, y), tuple(int(arriba[k] + (abajo[k] - arriba[k]) * t) for k in range(3)))
    return columna.resize((L, L))


def estrella(d, cx, cy, r, color, borde=None):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(pts, fill=color, outline=borde, width=int(r * 0.12) if borde else 0)


def frente(escala=1.0):
    """El dibujo (sin fondo). escala < 1 lo achica hacia el centro."""
    capa = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    d = ImageDraw.Draw(capa)
    c = L / 2

    def P(x, y):  # coordenadas 0..1024 -> lienzo, con escala respecto al centro
        return (c + (x * S - c) * escala, c + (y * S - c) * escala)

    def R(r):
        return r * S * escala

    # Arcoíris (bandas gruesas) con contorno oscuro suave.
    colores = [(233, 57, 53), (251, 140, 0), (253, 216, 53), (124, 179, 66), (30, 136, 229)]
    cx, cy = P(470, 600)
    radio_ext, ancho = R(330), R(52)
    for k, col in enumerate(colores):
        r1 = radio_ext - k * ancho
        caja = [cx - r1, cy - r1, cx + r1, cy + r1]
        d.pieslice(caja, 180, 360, fill=(60, 40, 40, 255))
        r2 = r1 - R(6)
        d.pieslice([cx - r2, cy - r2, cx + r2, cy + r2], 180, 360, fill=col + (255,))
    rh = radio_ext - len(colores) * ancho
    d.pieslice([cx - rh, cy - rh, cx + rh, cy + rh], 180, 360, fill=(0, 0, 0, 0))
    # Nubecitas en los extremos del arcoíris.
    for nx in (470 - 330 + 70, 470 + 330 - 70):
        for dx, dy, r in ((-60, 0, 62), (0, -30, 78), (62, 0, 62), (0, 22, 60)):
            x, y = P(nx + dx, 610 + dy)
            rr = R(r)
            d.ellipse([x - rr - R(8), y - rr - R(8), x + rr + R(8), y + rr + R(8)], fill=(60, 40, 40, 255))
    for nx in (470 - 330 + 70, 470 + 330 - 70):
        for dx, dy, r in ((-60, 0, 62), (0, -30, 78), (62, 0, 62), (0, 22, 60)):
            x, y = P(nx + dx, 610 + dy)
            rr = R(r)
            d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=(255, 255, 255, 255))

    # Gotas / salpicaduras de pintura.
    for x, y, r, col in [
        (215, 270, 34, (236, 64, 122)), (765, 240, 28, (142, 36, 170)),
        (835, 420, 22, (0, 172, 193)), (170, 430, 20, (253, 216, 53)),
        (300, 790, 26, (124, 179, 66)), (560, 820, 18, (251, 140, 0)),
    ]:
        xx, yy = P(x, y)
        rr = R(r)
        d.ellipse([xx - rr, yy - rr, xx + rr, yy + rr], fill=col + (255,))
        d.ellipse([xx - rr * 0.45 - rr * 0.25, yy - rr * 0.55, xx - rr * 0.05, yy - rr * 0.15],
                  fill=(255, 255, 255, 150))

    # Estrellitas.
    for x, y, r in [(320, 170, 38), (640, 150, 30), (880, 300, 26), (120, 600, 24)]:
        xx, yy = P(x, y)
        estrella(d, xx, yy, R(r), (255, 255, 255, 255), (255, 193, 7, 255))

    # Pincel (se dibuja acostado y se gira).
    pincel = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    p = ImageDraw.Draw(pincel)
    largo, grueso = R(560), R(70)
    x0, y0 = c - largo / 2, c - grueso / 2
    linea = (60, 40, 40, 255)
    # mango
    p.rounded_rectangle([x0 + R(250), y0, x0 + largo, y0 + grueso], radius=grueso / 2,
                        fill=(255, 112, 67, 255), outline=linea, width=int(R(8)))
    p.rounded_rectangle([x0 + R(300), y0 + grueso * 0.2, x0 + largo - R(40), y0 + grueso * 0.42],
                        radius=grueso * 0.11, fill=(255, 171, 145, 255))
    # virola (metal)
    p.rectangle([x0 + R(170), y0 - R(6), x0 + R(262), y0 + grueso + R(6)],
                fill=(207, 216, 220, 255), outline=linea, width=int(R(8)))
    # punta con pintura rosada
    punta = [(x0 + R(176), y0 - R(4)), (x0 + R(60), y0 + grueso * 0.15),
             (x0, y0 + grueso / 2), (x0 + R(60), y0 + grueso * 0.85),
             (x0 + R(176), y0 + grueso + R(4))]
    p.polygon(punta, fill=(236, 64, 122, 255), outline=linea, width=int(R(8)))
    pincel = pincel.rotate(-40, resample=Image.BICUBIC, center=(c, c))
    # se mueve para que la punta quede pintando el arcoíris
    dx, dy = R(230), R(180)
    capa.alpha_composite(pincel, (int(dx), int(dy)))
    # gotita que cae de la punta
    gx, gy = P(530, 560)
    d2 = ImageDraw.Draw(capa)
    d2.ellipse([gx - R(22), gy - R(22), gx + R(22), gy + R(22)], fill=(236, 64, 122, 255))
    d2.polygon([(gx - R(19), gy - R(10)), (gx, gy - R(52)), (gx + R(19), gy - R(10))],
               fill=(236, 64, 122, 255))
    return capa


def sombra(capa):
    a = capa.split()[3].filter(ImageFilter.GaussianBlur(10 * S))
    s = Image.new("RGBA", capa.size, (120, 60, 90, 0))
    s.putalpha(a.point(lambda v: int(v * 0.35)))
    out = Image.new("RGBA", capa.size, (0, 0, 0, 0))
    out.alpha_composite(s, (0, int(10 * S)))
    out.alpha_composite(capa)
    return out


def main():
    carpeta = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "icono"))
    os.makedirs(carpeta, exist_ok=True)
    f = fondo()
    completo = f.convert("RGBA")
    completo.alpha_composite(sombra(frente(1.0)))
    completo.resize((1024, 1024), Image.LANCZOS).save(os.path.join(carpeta, "icono.png"))
    f.resize((1024, 1024), Image.LANCZOS).save(os.path.join(carpeta, "fondo.png"))
    # En el ícono adaptable, Android recorta los bordes: el dibujo va más chico.
    sombra(frente(0.68)).resize((1024, 1024), Image.LANCZOS).save(os.path.join(carpeta, "frente.png"))
    exportar_android(carpeta)
    print("listo:", carpeta)


def exportar_android(carpeta):
    """Archivos listos para Android en icono/android/res (los copia
    tools/preparar_android.py al compilar)."""
    icono = Image.open(os.path.join(carpeta, "icono.png"))
    fondo_img = Image.open(os.path.join(carpeta, "fondo.png"))
    frente_img = Image.open(os.path.join(carpeta, "frente.png"))
    res = os.path.join(carpeta, "android", "res")
    densidades = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for nombre, f in densidades.items():
        dir_ = os.path.join(res, "mipmap-" + nombre)
        os.makedirs(dir_, exist_ok=True)
        icono.resize((int(48 * f), int(48 * f)), Image.LANCZOS).save(os.path.join(dir_, "ic_launcher.png"))
        lado = int(108 * f)
        frente_img.resize((lado, lado), Image.LANCZOS).save(os.path.join(dir_, "ic_launcher_foreground.png"))
        fondo_img.resize((lado, lado), Image.LANCZOS).save(os.path.join(dir_, "ic_launcher_background.png"))
    dir_ = os.path.join(res, "mipmap-anydpi-v26")
    os.makedirs(dir_, exist_ok=True)
    with open(os.path.join(dir_, "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
                '</adaptive-icon>\n')


if __name__ == "__main__":
    main()
