#!/usr/bin/env python3
"""Genera los sonidos de la app en assets/sonidos/ (archivos .wav).

  - plop1.wav, plop2.wav, plop3.wav: el "plop" de burbuja al pintar
    (tres tonos distintos para que no suene siempre igual).

Todo se sintetiza con matemáticas (no se descarga nada).
Necesita numpy.  Uso:  python3 tools/generar_sonidos.py
"""
import os
import wave

import numpy as np

FS = 22050  # muestras por segundo


def guardar(ruta, senal):
    senal = np.clip(senal, -1.0, 1.0)
    datos = (senal * 32000).astype("<i2")
    with wave.open(ruta, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(FS)
        w.writeframes(datos.tobytes())


def plop(f0, f1, dur=0.13):
    """Burbuja: un tono que sube rápido y se apaga."""
    t = np.arange(int(FS * dur)) / FS
    frec = f0 + (f1 - f0) * (1 - np.exp(-t / 0.025))
    fase = 2 * np.pi * np.cumsum(frec) / FS
    env = (1 - np.exp(-t / 0.004)) * np.exp(-t / 0.035)
    s = np.sin(fase) + 0.25 * np.sin(2 * fase)
    return 0.8 * s * env / np.max(np.abs(s * env))


def campanita(frec, dur, vol=1.0):
    """Nota tipo xilófono / campanita."""
    t = np.arange(int(FS * dur)) / FS
    env = (1 - np.exp(-t / 0.003)) * np.exp(-t / (0.18 + 60.0 / frec))
    s = (np.sin(2 * np.pi * frec * t)
         + 0.35 * np.sin(2 * np.pi * 2 * frec * t) * np.exp(-t / 0.08)
         + 0.15 * np.sin(2 * np.pi * 3.01 * frec * t) * np.exp(-t / 0.05))
    return vol * s * env


def nota(nombre):
    tabla = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    letra, octava = nombre[0], int(nombre[-1])
    semitonos = tabla[letra] + (octava - 4) * 12
    return 440.0 * 2 ** (semitonos / 12.0)


def presentacion():
    total = 3.2
    pista = np.zeros(int(FS * total))

    def poner(inicio, senal):
        i = int(inicio * FS)
        fin = min(len(pista), i + len(senal))
        pista[i:fin] += senal[: fin - i]

    # Melodía alegre (Do mayor), corchetes rápidos y final largo.
    melodia = [
        (0.00, "C5"), (0.15, "E5"), (0.30, "G5"), (0.45, "C6"),
        (0.75, "G5"), (0.90, "A5"), (1.05, "B5"), (1.20, "C6"),
        (1.50, "E6"), (1.65, "D6"), (1.80, "C6"), (2.05, "G6"),
    ]
    for inicio, n in melodia:
        poner(inicio, campanita(nota(n), 0.9, 0.55))
    # Acorde final.
    for n in ("C5", "E5", "G5", "C6"):
        poner(2.05, campanita(nota(n), 1.1, 0.25))
    # Bajo suave.
    for inicio, n in [(0.0, "C3"), (0.75, "F3"), (1.5, "G3"), (2.05, "C3")]:
        poner(inicio, campanita(nota(n), 0.8, 0.35))
    # Destellos (estrellitas).
    azar = np.random.default_rng(7)
    for _ in range(14):
        inicio = azar.uniform(0.1, 2.6)
        poner(inicio, campanita(azar.uniform(2600, 4200), 0.25, 0.10))

    pista *= 0.85 / np.max(np.abs(pista))
    # Que termine suavecito.
    cola = int(0.4 * FS)
    pista[-cola:] *= np.linspace(1, 0, cola)
    return pista


def main():
    carpeta = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                            "..", "assets", "sonidos"))
    os.makedirs(carpeta, exist_ok=True)
    guardar(os.path.join(carpeta, "plop1.wav"), plop(260, 820))
    guardar(os.path.join(carpeta, "plop2.wav"), plop(320, 980))
    guardar(os.path.join(carpeta, "plop3.wav"), plop(220, 700))
    for f in sorted(os.listdir(carpeta)):
        print(f, os.path.getsize(os.path.join(carpeta, f)), "bytes")


if __name__ == "__main__":
    main()
