#!/usr/bin/env python3
"""Ajusta la carpeta android/ que crea Flutter (lo usa GitHub Actions).

- Pone el nombre "ARVI" bajo el ícono.
- Agrega el permiso de consulta al motor de "texto a voz" del celular
  (Android 11 o más nuevo lo exige para que la voz de los colores funcione).

Uso:  python3 tools/preparar_android.py
"""
import re

RUTA = "android/app/src/main/AndroidManifest.xml"

with open(RUTA, encoding="utf-8") as f:
    texto = f.read()

texto = re.sub(r'android:label="[^"]*"', 'android:label="ARVI"', texto, count=1)

if "android.intent.action.TTS_SERVICE" not in texto:
    bloque = ("        <intent>\n"
              "            <action android:name=\"android.intent.action.TTS_SERVICE\" />\n"
              "        </intent>\n")
    if "<queries>" in texto:
        texto = texto.replace("<queries>", "<queries>\n" + bloque, 1)
    else:
        texto = texto.replace("</manifest>", "    <queries>\n" + bloque + "    </queries>\n</manifest>", 1)

with open(RUTA, "w", encoding="utf-8") as f:
    f.write(texto)

print(texto)
