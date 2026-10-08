#!/usr/bin/env python3
"""Dibuja una imagen de vista previa de los dibujos de assets/drawings/*.json

Sirve para revisar un dibujo nuevo antes de pasarlo al celular.
Necesita matplotlib (pip install matplotlib). Solo entiende trazos con
comandos absolutos M, L, C y Z (los que genera generar_dibujos.py).

Uso:  python3 tools/vista_previa.py [salida.png] [archivo1.json archivo2.json ...]
"""
import json
import math
import os
import re
import sys

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import PathPatch
from matplotlib.path import Path


def leer_d(d):
    fichas = re.findall(r"[MLCZ]|-?\d+(?:\.\d+)?", d)
    vertices, codigos = [], []
    inicio = (0.0, 0.0)
    i = 0
    while i < len(fichas):
        c = fichas[i]
        i += 1
        if c == "M":
            inicio = (float(fichas[i]), float(fichas[i + 1]))
            vertices.append(inicio)
            codigos.append(Path.MOVETO)
            i += 2
        elif c == "L":
            vertices.append((float(fichas[i]), float(fichas[i + 1])))
            codigos.append(Path.LINETO)
            i += 2
        elif c == "C":
            for k in range(3):
                vertices.append((float(fichas[i + 2 * k]), float(fichas[i + 2 * k + 1])))
                codigos.append(Path.CURVE4)
            i += 6
        elif c == "Z":
            vertices.append(inicio)
            codigos.append(Path.CLOSEPOLY)
        else:
            raise ValueError("comando no soportado: " + c)
    return Path(vertices, codigos)


def dibujar(ax, dib, ancho_pulgadas):
    lado = dib.get("lado", 1000)
    ax.set_xlim(0, lado)
    ax.set_ylim(lado, 0)
    ax.set_aspect("equal")
    ax.axis("off")
    pt = ancho_pulgadas * 72.0 / lado  # puntos de pantalla por unidad del dibujo
    for r in dib["regiones"]:
        ax.add_patch(PathPatch(leer_d(r["path"]), facecolor="white", edgecolor="black",
                               linewidth=10 * pt, joinstyle="round", capstyle="round"))
    for d in dib.get("detalles", []):
        relleno = d.get("relleno")
        grosor = d.get("grosor", 0)
        ax.add_patch(PathPatch(leer_d(d["path"]),
                               facecolor=relleno if relleno else "none",
                               edgecolor="black" if grosor > 0 else "none",
                               linewidth=max(grosor, 0) * pt, joinstyle="round", capstyle="round"))


def main():
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "drawings")
    salida = sys.argv[1] if len(sys.argv) > 1 else "vista_previa.png"
    archivos = sys.argv[2:]
    if not archivos:
        with open(os.path.join(base, "indice.json"), encoding="utf-8") as f:
            archivos = [os.path.join(base, n) for n in json.load(f)]
    dibujos = []
    for a in archivos:
        with open(a, encoding="utf-8") as f:
            dibujos.append(json.load(f))

    # Hojas de 6 dibujos (3 columnas x 2 filas). Si hay más de 6 se crean varias imágenes.
    por_hoja = 6
    columnas = 3
    lado_pulg = 3.5
    hojas = [dibujos[i:i + por_hoja] for i in range(0, len(dibujos), por_hoja)]
    base, ext = os.path.splitext(salida)
    for n, grupo in enumerate(hojas, start=1):
        filas = math.ceil(len(grupo) / columnas)
        fig, ejes = plt.subplots(filas, columnas, figsize=(columnas * lado_pulg, filas * (lado_pulg + 0.35)),
                                 squeeze=False)
        fig.patch.set_facecolor("#FFF4D6")
        lista = list(ejes.flat)
        for ax, dib in zip(lista, grupo):
            dibujar(ax, dib, lado_pulg * 0.88)
            ax.set_title(dib.get("nombre", dib["id"]), fontsize=12, pad=4)
        for ax in lista[len(grupo):]:
            ax.axis("off")
        fig.tight_layout()
        destino = salida if len(hojas) == 1 else "%s_%d%s" % (base, n, ext)
        fig.savefig(destino, dpi=100, facecolor=fig.get_facecolor())
        plt.close(fig)
        print("imagen guardada en", destino)


if __name__ == "__main__":
    main()
