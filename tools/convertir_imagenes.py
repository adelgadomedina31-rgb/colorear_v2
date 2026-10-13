#!/usr/bin/env python3
"""Convierte tus imágenes de la carpeta mis_dibujos/ en dibujos para pintar.

Funciona con láminas para colorear: líneas negras sobre fondo blanco
(PNG o JPG). Cada zona blanca encerrada por líneas se vuelve una zona que se
puede pintar con toques, igual que los dibujos que trae la app.

Por cada imagen crea en assets/drawings/:
  - foto_<nombre>.json   (las zonas para pintar)
  - foto_<nombre>.png    (las líneas originales, que se ven encima)
y las agrega al principio del menú (indice.json).

GitHub Actions lo corre solo al compilar. Para probarlo en tu computadora:
  pip install opencv-python-headless numpy
  python3 tools/convertir_imagenes.py
"""
import json
import os
import re
import sys
import unicodedata

import cv2
import numpy as np

LADO = 1000          # tamaño del dibujo en la app (1000 x 1000)
MARGEN = 40          # espacio libre alrededor de la imagen
AREA_MINIMA = 300    # zonas más chicas que esto no se pintan (puntitos, letras)
MAX_ZONAS = 150      # como mucho esta cantidad de zonas por dibujo
EXTENSIONES = (".png", ".jpg", ".jpeg", ".webp", ".bmp")

RAIZ = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
ENTRADA = os.path.join(RAIZ, "mis_dibujos")
SALIDA = os.path.join(RAIZ, "assets", "drawings")


def limpiar_nombre(texto):
    """'Gato Feliz (1).png' -> ('foto_gato_feliz_1', 'Gato feliz 1')."""
    base = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode()
    slug = re.sub(r"[^a-zA-Z0-9]+", "_", base).strip("_").lower() or "dibujo"
    bonito = re.sub(r"[_\-]+", " ", texto).strip()
    bonito = re.sub(r"\s+", " ", re.sub(r"[()\[\]]", "", bonito))
    return "foto_" + slug, (bonito[:1].upper() + bonito[1:]) if bonito else "Dibujo"


def leer_gris(ruta):
    datos = np.fromfile(ruta, dtype=np.uint8)  # funciona con nombres con tildes
    img = cv2.imdecode(datos, cv2.IMREAD_UNCHANGED)
    if img is None:
        raise ValueError("no se pudo leer la imagen")
    if img.ndim == 2:
        return img
    if img.shape[2] == 4:  # con transparencia: se pone sobre blanco
        alfa = img[:, :, 3:4].astype(np.float32) / 255.0
        rgb = img[:, :, :3].astype(np.float32) * alfa + 255.0 * (1 - alfa)
        img = rgb.astype(np.uint8)
    return cv2.cvtColor(img[:, :, :3], cv2.COLOR_BGR2GRAY)


def encuadrar(gris):
    """Achica/agranda la imagen para que entre en el cuadrado de 1000 x 1000."""
    alto, ancho = gris.shape
    escala = (LADO - 2 * MARGEN) / max(alto, ancho)
    nuevo = cv2.resize(gris, (max(1, round(ancho * escala)), max(1, round(alto * escala))),
                       interpolation=cv2.INTER_AREA if escala < 1 else cv2.INTER_CUBIC)
    lienzo = np.full((LADO, LADO), 255, np.uint8)
    y0 = (LADO - nuevo.shape[0]) // 2
    x0 = (LADO - nuevo.shape[1]) // 2
    lienzo[y0:y0 + nuevo.shape[0], x0:x0 + nuevo.shape[1]] = nuevo
    return lienzo


def trazo_svg(contorno):
    puntos = contorno.reshape(-1, 2)
    if len(puntos) < 3:
        return ""
    partes = ["M %d %d" % tuple(puntos[0])]
    partes += ["L %d %d" % tuple(p) for p in puntos[1:]]
    return " ".join(partes) + " Z"


def convertir(ruta):
    gris = encuadrar(leer_gris(ruta))
    # Líneas = lo oscuro. El umbral se calcula solo (Otsu), con límites.
    umbral, _ = cv2.threshold(gris, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    umbral = min(max(umbral, 80), 200)
    lineas = (gris < umbral).astype(np.uint8)
    # Se engrosan un poquito las líneas para cerrar huecos chiquitos.
    lineas = cv2.dilate(lineas, np.ones((3, 3), np.uint8), iterations=1)
    blanco = (1 - lineas).astype(np.uint8)

    cantidad, etiquetas, datos, _ = cv2.connectedComponentsWithStats(blanco, connectivity=4)
    zonas = [k for k in range(1, cantidad) if datos[k, cv2.CC_STAT_AREA] >= AREA_MINIMA]
    zonas.sort(key=lambda k: -datos[k, cv2.CC_STAT_AREA])
    zonas = zonas[:MAX_ZONAS]

    nucleo = np.ones((5, 5), np.uint8)
    regiones = []
    for n, k in enumerate(zonas):
        mascara = (etiquetas == k).astype(np.uint8)
        # Se agranda la zona para que la pintura llegue por debajo de la línea.
        mascara = cv2.dilate(mascara, nucleo, iterations=1)
        contornos, _ = cv2.findContours(mascara, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_SIMPLE)
        partes = []
        for c in contornos:
            if cv2.contourArea(c) < 20:
                continue
            simple = cv2.approxPolyDP(c, 1.2, True)
            texto = trazo_svg(simple)
            if texto:
                partes.append(texto)
        if partes:
            regiones.append({"id": "z%d" % (n + 1), "path": " ".join(partes)})
    if not regiones:
        raise ValueError("no se encontraron zonas cerradas para pintar")

    # Imagen de las líneas: negro, con la transparencia según lo oscuro.
    alfa = np.clip((255.0 - gris.astype(np.float32)) * 1.3, 0, 255).astype(np.uint8)
    alfa[alfa < 25] = 0
    rgba = np.zeros((LADO, LADO, 4), np.uint8)
    rgba[:, :, 3] = alfa
    return regiones, rgba


def main():
    if not os.path.isdir(ENTRADA):
        print("No hay carpeta mis_dibujos/: nada que convertir.")
        return 0
    os.makedirs(SALIDA, exist_ok=True)
    # Se borran los convertidos de antes (se vuelven a crear).
    for viejo in os.listdir(SALIDA):
        if viejo.startswith("foto_") and viejo.endswith((".json", ".png")):
            os.remove(os.path.join(SALIDA, viejo))

    ruta_indice = os.path.join(SALIDA, "indice.json")
    with open(ruta_indice, encoding="utf-8") as f:
        indice = [n for n in json.load(f) if not n.startswith("foto_")]

    nuevos = []
    usados = set()
    for archivo in sorted(os.listdir(ENTRADA)):
        if not archivo.lower().endswith(EXTENSIONES):
            continue
        id_, nombre = limpiar_nombre(os.path.splitext(archivo)[0])
        base_id, k = id_, 2
        while id_ in usados:
            id_ = "%s_%d" % (base_id, k)
            k += 1
        usados.add(id_)
        try:
            regiones, rgba = convertir(os.path.join(ENTRADA, archivo))
        except Exception as e:  # una imagen mala no debe romper la compilación
            print("  OJO: %s no se pudo convertir (%s)" % (archivo, e))
            continue
        ok, png = cv2.imencode(".png", rgba, [cv2.IMWRITE_PNG_COMPRESSION, 9])
        if not ok:
            print("  OJO: %s no se pudo guardar" % archivo)
            continue
        png.tofile(os.path.join(SALIDA, id_ + ".png"))
        dibujo = {
            "id": id_,
            "nombre": nombre,
            "lado": LADO,
            "capas": False,
            "relleno": "evenodd",
            "lineas": id_ + ".png",
            "regiones": regiones,
            "detalles": [],
        }
        with open(os.path.join(SALIDA, id_ + ".json"), "w", encoding="utf-8") as f:
            json.dump(dibujo, f, ensure_ascii=False, separators=(",", ":"))
        nuevos.append(id_ + ".json")
        print("  %s -> %s (%d zonas)" % (archivo, id_, len(regiones)))

    # Tus dibujos van primero en el menú.
    with open(ruta_indice, "w", encoding="utf-8") as f:
        json.dump(nuevos + indice, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("listo: %d imagen(es) convertida(s)" % len(nuevos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
