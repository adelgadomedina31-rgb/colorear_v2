#!/usr/bin/env python3
"""Genera todos los dibujos de la app en assets/drawings/*.json (y el indice.json).

Cada dibujo es un cuadrado de 1000 x 1000 unidades hecho de:
  - "regiones": zonas que se pueden pintar. Se dibujan en orden, así que las
    últimas quedan encima de las primeras (como capas).
  - "detalles": puntos o líneas decorativas (ojos, sonrisas...) que no se pintan.

Los dibujos están definidos en dibujos_base.py, dibujos_animales.py y dibujos_cosas.py,
y las herramientas para armarlos en formas.py.

Uso:  python3 tools/generar_dibujos.py
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import dibujos_animales as an  # noqa: E402
import dibujos_base as ba  # noqa: E402
import dibujos_cosas as co  # noqa: E402

# El orden de esta lista es el orden del menú de la app.
# (se alternan animales, comida, vehículos... para que el menú sea variado)
ORDEN = [
    ba.sol, ba.flor, ba.pez, ba.casa,
    an.gato, co.globos, co.manzana, an.mariposa, an.perro, co.corazon_grande,
    co.helado, an.pollito, co.carro, co.arbol, an.conejo, co.cupcake,
    co.nube_lluvia, an.tortuga, co.barco, co.fresa, an.oso, co.luna,
    an.pato, co.regalo, an.cerdito, co.cohete, co.hongo, an.rana,
    co.arcoiris, an.abeja, co.paraguas, an.pinguino, co.avion, an.ballena,
]


def a_json(dibujo):
    id_, nombre, regiones, detalles = dibujo
    return {
        "id": id_,
        "nombre": nombre,
        "lado": 1000,
        "regiones": [{"id": rid, "path": f.d()} for rid, f in regiones],
        "detalles": detalles,
    }


def main():
    carpeta = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "drawings")
    carpeta = os.path.normpath(carpeta)
    os.makedirs(carpeta, exist_ok=True)
    for viejo in os.listdir(carpeta):
        if viejo.endswith(".json"):
            os.remove(os.path.join(carpeta, viejo))
    archivos = []
    for fabrica in ORDEN:
        datos = a_json(fabrica())
        nombre_archivo = datos["id"] + ".json"
        assert nombre_archivo not in archivos, "id repetido: " + datos["id"]
        with open(os.path.join(carpeta, nombre_archivo), "w", encoding="utf-8") as f:
            json.dump(datos, f, ensure_ascii=False, indent=1)
            f.write("\n")
        archivos.append(nombre_archivo)
    with open(os.path.join(carpeta, "indice.json"), "w", encoding="utf-8") as f:
        json.dump(archivos, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("listo: %d dibujos" % len(archivos))


if __name__ == "__main__":
    main()
