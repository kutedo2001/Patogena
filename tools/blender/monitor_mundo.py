"""Monitor del mundo (P3.9a): pantalla grande de pared con carcasa blanca de la casa, marco oscuro,
franja verde con placa y leds, rejillas, tornillería, brazos a la pared, sensor, baliza giratoria
y canaleta de cable hasta el suelo con caja de empalme.
Uso: blender -b -P tools/blender/monitor_mundo.py -- <salida.glb> <carpeta_texturas>
Origen: pie de la pared (suelo), la pantalla mira a -Y (= +Z en Godot).
Nodos: pantalla (textura viva), gira_baliza (gira), led_0..2."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:]
SALIDA, TEX = args[0], args[1]
CAL = os.path.join(TEX, "calcomanias")
limpiar(); comun._mats.clear()
r = vacio("monitor_mundo")
blanco = mat("carcasa", color=(0.86, 0.87, 0.86), rug=0.45)
verde = mat("franja_verde", color=(0.29, 0.58, 0.54), rug=0.5)
graf = mat("grafito", color=(0.13, 0.145, 0.155), rug=0.5)
gris = mat("gris", color=(0.42, 0.45, 0.47), metal=0.6, rug=0.35)
negro = mat("marco", color=(0.035, 0.04, 0.045), rug=0.3)

W, H, ZC = 3.7, 1.8, 2.15          # carcasa
Y0 = -0.06                          # separación de la pared (brazos)
D = 0.12                            # fondo de la carcasa
YF = Y0 - D                         # cara delantera

# placa de pared y brazos
caja("placa_pared", (1.2, 0.02, 0.5), (0, -0.01, ZC), graf, bisel=0.006, padre=r)
for x in (-0.45, 0.45):
    for z in (ZC - 0.17, ZC + 0.17):
        tornillo(f"tp{x}{z}", (x, -0.021, z), r, r=0.012)
for x in (-0.35, 0.35):
    caja(f"brazo{x}", (0.06, 0.07, 0.9), (x, Y0 / 2 - 0.01, ZC), gris, bisel=0.01, padre=r)
# carcasa
caja("carcasa", (W, D, H), (0, Y0 - D / 2, ZC), blanco, bisel=0.035, segmentos=4, padre=r)
caja("carcasa_trasera", (W - 0.2, 0.04, H - 0.2), (0, Y0 + 0.01, ZC), graf, bisel=0.02, padre=r)
# marco oscuro y pantalla
MW, MH = W - 0.14, H - 0.36
ZM = ZC + 0.08
caja("marco", (MW, 0.02, MH), (0, YF - 0.005, ZM), negro, bisel=0.012, segmentos=3, padre=r)
pantalla_plano("pantalla", MW - 0.08, MH - 0.08, (0, YF - 0.017, ZM), padre=r)
vid = mat("vidrio_frontal", color=(0.8, 0.9, 0.95), rug=0.02, alfa=0.06)
for i, (x, z) in enumerate(((-1, -1), (1, -1), (-1, 1), (1, 1))):
    tornillo(f"tm{i}", (x * (MW / 2 + 0.035), YF - 0.002, ZM + z * (MH / 2 + 0.03)), r, r=0.011)
# franja verde inferior con placa de la casa, leds y altavoz
ZB = ZC - H / 2 + 0.1
caja("franja", (W - 0.06, 0.012, 0.13), (0, YF - 0.002, ZB), verde, bisel=0.004, padre=r)
calcomania("placa_logo", 0.22, 0.11, (-W / 2 + 0.25, YF - 0.009, ZB), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=r)
for i, c in enumerate(((0.2, 0.95, 0.35), (1.0, 0.65, 0.08), (0.95, 0.12, 0.1))):
    m = mat(f"led_m{i}", color=tuple(v * 0.4 for v in c), rug=0.2, emision=c, fuerza=2.0 if i == 0 else 0.0)
    cilindro(f"led_{i}", 0.014, 0.01, (W / 2 - 0.42 + i * 0.05, YF - 0.012, ZB), m, lados=12, bisel=0.002, padre=r, giro=(math.radians(90), 0, 0))
for k in range(9):
    caja(f"altavoz{k}", (0.012, 0.006, 0.07), (W / 2 - 0.22 + k * 0.022, YF - 0.009, ZB), negro, bisel=0.002, padre=r)
cilindro("boton_on", 0.018, 0.012, (W / 2 - 0.55, YF - 0.012, ZB), gris, lados=16, bisel=0.003, padre=r, giro=(math.radians(90), 0, 0))
# rejillas laterales
for s in (-1, 1):
    for k in range(7):
        caja(f"rejilla{s}{k}", (0.006, 0.07, 0.012), (s * (W / 2 + 0.001), Y0 - D / 2, ZC - 0.25 + k * 0.08), graf, bisel=0.002, padre=r)
# sensor arriba y baliza giratoria
ZT = ZC + H / 2
caja("sensor_base", (0.16, 0.06, 0.03), (0, YF + 0.03, ZT + 0.012), graf, bisel=0.008, padre=r)
esfera("sensor", 0.025, (0, YF + 0.01, ZT + 0.03), negro, padre=r, escala=(1, 1, 0.8))
xb = W / 2 - 0.2
cilindro("baliza_base", 0.05, 0.03, (xb, Y0 - D / 2, ZT + 0.015), graf, lados=24, bisel=0.006, padre=r)
cilindro("baliza_cupula", 0.042, 0.08, (xb, Y0 - D / 2, ZT + 0.07), mat("vidrio_ambar", color=(1.0, 0.6, 0.1), rug=0.1, alfa=0.5), lados=24, bisel=0.02, padre=r)
g = vacio("gira_baliza", (xb, Y0 - D / 2, ZT + 0.07), r)
caja("reflector", (0.06, 0.012, 0.04), (0, 0, 0), mat("luz_ambar", color=(1.0, 0.6, 0.1), emision=(1.0, 0.55, 0.05), fuerza=4.0), bisel=0.004, padre=g)
# canaleta de cable hasta el suelo, con caja de empalme
xc = W / 2 - 0.3
caja("canaleta", (0.07, 0.03, ZC - H / 2), (xc, -0.015, (ZC - H / 2) / 2), blanco, bisel=0.006, padre=r)
caja("empalme", (0.16, 0.05, 0.2), (xc, -0.025, 0.85), blanco, bisel=0.01, padre=r)
calcomania("empalme_franja", 0.14, 0.03, (xc, -0.051, 0.92), mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5), padre=r)
for z in (0.77, 0.93):
    for x in (-0.06, 0.06):
        tornillo(f"te{z}{x}", (xc + x, -0.051, z), r, r=0.007)
for z in (0.3, 1.5):
    caja(f"abrazadera{z}", (0.09, 0.035, 0.02), (xc, -0.017, z), gris, bisel=0.004, padre=r)
exportar(SALIDA)
print("MONITOR OK")
