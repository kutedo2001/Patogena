"""Mobiliario (P3.7): banco de espera de pacientes (3 plazas) con brazos, patas de acero, tornillería y número de turno.
Uso: blender -b -P tools/blender/mobiliario.py -- <carpeta_salida> <carpeta_texturas>"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *
args = sys.argv[sys.argv.index("--") + 1:]
SALIDA, TEX = args[0], args[1]
os.makedirs(SALIDA, exist_ok=True)
limpiar(); comun._mats.clear()
r = vacio("banco_espera")
inox = mat("inox", color=(0.74, 0.76, 0.78), metal=1.0, rug=0.25)
asiento = mat("asiento", color=(0.22, 0.26, 0.32), rug=0.55)
L = 1.5
ZS = 0.29          # altura del asiento (para personajes de 0,9)
caja("viga", (L, 0.05, 0.04), (0, 0.02, ZS - 0.06), inox, bisel=0.008, padre=r)
for x in (-L / 2 + 0.12, L / 2 - 0.12):
    caja(f"pata{x}", (0.04, 0.04, ZS - 0.08), (x, 0.02, (ZS - 0.08) / 2), inox, bisel=0.006, padre=r)
    caja(f"pie{x}", (0.06, 0.36, 0.02), (x, 0.02, 0.01), inox, bisel=0.005, padre=r)
    for s in (-1, 1):
        cilindro(f"taco{x}{s}", 0.018, 0.01, (x, 0.02 + s * 0.16, 0.003), mat("goma"), lados=12, padre=r)
for k in range(3):
    x = -L / 3 + k * L / 3
    caja(f"asiento{k}", (0.44, 0.32, 0.035), (x, 0.0, ZS - 0.02), asiento, bisel=0.012, segmentos=3, padre=r)
    caja(f"respaldo{k}", (0.44, 0.03, 0.3), (x, 0.17, ZS + 0.15), asiento, bisel=0.012, segmentos=3, padre=r, giro=(math.radians(-10), 0, 0))
    caja(f"soporte_resp{k}", (0.05, 0.03, 0.14), (x, 0.15, ZS + 0.02), inox, bisel=0.005, padre=r)
    for s in (-1, 1):
        tornillo(f"t{k}{s}", (x + s * 0.12, 0.155, ZS + 0.12), r, r=0.008, normal="+Y")
for x in (-L / 2 + 0.01, -L / 6, L / 6, L / 2 - 0.01):
    caja(f"brazo{x:.2f}", (0.03, 0.26, 0.025), (x, 0.0, ZS + 0.14), inox, bisel=0.006, padre=r)
    caja(f"brazo_pie{x:.2f}", (0.025, 0.025, 0.14), (x, -0.08, ZS + 0.07), inox, bisel=0.005, padre=r)
exportar(os.path.join(SALIDA, "banco_espera.glb"))
print("MOBILIARIO OK")
