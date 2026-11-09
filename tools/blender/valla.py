"""Valla del corral de pruebas (P3.9): tramo de 1 m con poste, pasamanos, malla electrosoldada,
rodapié con franja de peligro y variante con cartel de riesgo biológico; poste suelto para esquinas.
Uso: blender -b -P tools/blender/valla.py -- <carpeta_salida> <carpeta_texturas>
El tramo va a lo largo de X, centrado, apoyado en el suelo; el poste propio está en x = -0,5."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:]
SALIDA, TEX = args[0], args[1]
CAL = os.path.join(TEX, "calcomanias")
os.makedirs(SALIDA, exist_ok=True)
H = 1.0

def poste(padre, x):
    g = mat("grafito")
    caja(f"poste{x}", (0.05, 0.05, H), (x, 0, H / 2), g, bisel=0.008, padre=padre)
    caja(f"pie{x}", (0.12, 0.12, 0.012), (x, 0, 0.006), g, bisel=0.003, padre=padre)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tornillo(f"tp{x}{sx}{sy}", (x + sx * 0.042, sy * 0.042, 0.012), padre, r=0.006, normal="+Z")
    esfera(f"remate{x}", 0.03, (x, 0, H + 0.005), mat("amarillo"), padre=padre, media=True, escala=(1, 1, 0.6))

def tramo(nombre, aviso=False):
    limpiar(); comun._mats.clear()
    r = vacio(nombre)
    me = mat("metal")
    poste(r, -0.5)
    # pasamanos y travesaños
    caja("pasamanos", (1.0, 0.045, 0.035), (0, 0, H - 0.02), mat("amarillo"), bisel=0.01, padre=r)
    caja("travesano", (1.0, 0.025, 0.025), (0, 0, 0.2), me, bisel=0.005, padre=r)
    # marco de la malla
    for z in (0.22, H - 0.06):
        caja(f"marco_h{z}", (0.92, 0.02, 0.02), (0, 0, z), me, bisel=0.004, padre=r)
    for x in (-0.46, 0.46):
        caja(f"marco_v{x}", (0.02, 0.02, H - 0.28), (x, 0, (0.22 + H - 0.06) / 2), me, bisel=0.004, padre=r)
    # malla electrosoldada 5 cm
    alambre = mat("alambre", color=(0.55, 0.58, 0.6), metal=0.9, rug=0.35)
    k = 0
    x = -0.44
    while x <= 0.44:
        caja(f"mv{k}", (0.006, 0.006, H - 0.3), (x, 0, (0.22 + H - 0.06) / 2), alambre, bisel=0.0, padre=r)
        x += 0.05; k += 1
    z = 0.25
    while z < H - 0.07:
        caja(f"mh{k}", (0.9, 0.006, 0.006), (0, 0, z), alambre, bisel=0.0, padre=r)
        z += 0.05; k += 1
    # rodapié con franja de peligro por las dos caras
    caja("rodapie", (0.96, 0.02, 0.16), (0, 0, 0.09), mat("chasis_osc"), bisel=0.004, padre=r)
    fp = mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5)
    for s in (-1, 1):
        calcomania(f"franja{s}", 0.94, 0.1, (0, s * 0.0115, 0.09), fp, padre=r, giro=(math.radians(90 * -s), 0, 0 if s < 0 else math.pi))
    if aviso:
        cb = mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True)
        caja("cartel_placa", (0.24, 0.008, 0.24), (0, -0.015, 0.62), mat("chasis"), bisel=0.004, padre=r)
        calcomania("cartel", 0.2, 0.2, (0, -0.0195, 0.62), cb, padre=r)
        for sx in (-1, 1):
            for sz in (-1, 1):
                tornillo(f"tc{sx}{sz}", (sx * 0.1, -0.019, 0.62 + sz * 0.1), r, r=0.005)
    exportar(os.path.join(SALIDA, nombre + ".glb"))

tramo("valla")
tramo("valla_aviso", aviso=True)
limpiar(); comun._mats.clear()
r = vacio("valla_poste")
poste(r, 0.0)
exportar(os.path.join(SALIDA, "valla_poste.glb"))
print("VALLA OK")
