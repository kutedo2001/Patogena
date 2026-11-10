"""Centrífuga de paso del rediseño 2.0 (estilo Two Point + Alchemy Factory, R1.2c), 2×2 casillas.
La cinta ATRAVIESA la máquina por la fila delantera (y = +0,5): la gradilla entra por el agujero de -X, avanza por
rodillos internos que se ven por una ventana alargada, un brazo cargador la mete en el tambor de atrás, gira, vuelve
a la línea, un cabezal de agujas le saca el plasma (sube por un tubo transparente hasta la brida ámbar de atrás) y la
misma gradilla, ya solo con hematíes, sale por el agujero de +X a la cinta de salida. Mismo eje, misma altura.
Nodos animados: rotor (gira Z), cesto0..5, cupula (bisagra), brazo_carga (gira Z) y pinza (Z), cabezal_agujas (Z),
plasma_subiendo (escala Z), gradilla_dentro0/1 (el juego las mueve por el túnel), pantalla, aguja_mano, baliza_v/a/r.
Uso: blender -b -P tools/blender/tp_centrifuga.py -- <salida.glb> <carpeta_texturas>
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["tp_centrifuga.glb", "assets/texturas"]
SALIDA, TEX = args[0], args[1]
CAL = os.path.join(TEX, "calcomanias")
Z = 0.38          # superficie de la cinta
YL = 0.5          # fila de la línea
LAN = 0.8         # ancho de la cinta

limpiar(); comun._mats.clear()
r = vacio("tp_centrifuga")
menta = mat("tp_menta", color=(0.46, 0.78, 0.68), rug=0.38)
menta_osc = mat("tp_menta_osc", color=(0.26, 0.55, 0.5), rug=0.45)
crema = mat("tp_crema", color=(0.97, 0.95, 0.88), rug=0.42)
naranja = mat("tp_naranja", color=(0.98, 0.52, 0.14), rug=0.35)
grafito = mat("grafito")
cromo = mat("cromo", color=(0.86, 0.87, 0.89), metal=1.0, rug=0.2)
goma = mat("goma")
vid = mat("cristal_cupula", color=(0.78, 0.92, 0.96), rug=0.03, alfa=0.2)
negro = mat("negro_mate", color=(0.04, 0.045, 0.05), rug=0.7)
ambar = mat("plasma_ambar", color=(0.98, 0.72, 0.22), rug=0.25, alfa=0.85)
sangre = mat("sangre_tubo", color=(0.55, 0.03, 0.05), rug=0.2)
blanco = mat("gradilla_plastico", color=(0.96, 0.96, 0.93), rug=0.5)
tapon = mat("tapon_rojo", color=(0.82, 0.12, 0.12), rug=0.45)
rojo = mat("rojo_zona", color=(0.85, 0.1, 0.1), rug=0.45)
amarillo = mat("amarillo")


def gradilla(nombre, pos, padre, giro=0.0):
    v = vacio(nombre, pos, padre)
    v.rotation_euler = (0, 0, giro)
    caja(nombre + "_base", (0.34, 0.16, 0.02), (0, 0, 0.01), blanco, bisel=0.006, padre=v)
    caja(nombre + "_tabla", (0.34, 0.16, 0.018), (0, 0, 0.1), blanco, bisel=0.006, padre=v)
    for s in (-1, 1):
        caja(nombre + f"_lado{s}", (0.018, 0.16, 0.1), (s * 0.161, 0, 0.055), blanco, bisel=0.005, padre=v)
    for i in range(3):
        for j in range(2):
            x, y = -0.1 + i * 0.1, -0.04 + j * 0.08
            cilindro(nombre + f"_t{i}{j}", 0.0185, 0.13, (x, y, 0.085), sangre, lados=16, bisel=0.003, padre=v)
            cilindro(nombre + f"_p{i}{j}", 0.025, 0.035, (x, y, 0.2), tapon, lados=16, bisel=0.005, padre=v)
    return v


# ------------------------------------------------------------ base
for sx in (-1, 1):
    for sy in (-1, 1):
        cilindro(f"pie{sx}{sy}", 0.07, 0.03, (sx * 0.78, sy * 0.78, 0.015), goma, lados=24, bisel=0.008, padre=r)
caja("zocalo", (1.96, 1.96, 0.1), (0, 0, 0.08), grafito, bisel=0.05, segmentos=3, padre=r)
fp = mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5)
calcomania("franja_atras", 1.5, 0.05, (0, -0.985, 0.08), fp, padre=r, giro=(math.radians(90), 0, 0))

# ------------------------------------------------------------ túnel de la línea (fila delantera): la cinta pasa por dentro
yl0, yl1 = YL - 0.47, YL + 0.47
caja("tunel_suelo", (2.0, 0.94, 0.25), (0, YL, 0.255), menta_osc, bisel=0.03, segmentos=3, padre=r)
# techo del túnel: remates macizos en los extremos y tapa de cristal en medio para ver el proceso
for sx in (-1, 1):
    caja(f"tunel_remate{sx}", (0.22, 0.94, 0.16), (sx * 0.89, YL, Z + 0.33), menta, bisel=0.07, segmentos=5, padre=r)
for sy in (-1, 1):
    caja(f"tunel_larguero{sy}", (1.6, 0.07, 0.07), (0, YL + sy * 0.435, Z + 0.37), crema, bisel=0.025, segmentos=3, padre=r)
caja("tunel_tapa", (1.58, 0.82, 0.015), (0, YL, Z + 0.39), vid, bisel=0.0, padre=r)
for x in (-0.4, 0.4):
    caja(f"tunel_costilla{x}", (0.04, 0.86, 0.03), (x, YL, Z + 0.4), crema, bisel=0.01, padre=r)
caja("tunel_trasera", (2.0, 0.08, 0.36), (0, yl0 + 0.04, Z + 0.15), menta, bisel=0.03, padre=r)
# frente: ventana alargada por la que se ve pasar la gradilla
caja("tunel_frente_bajo", (2.0, 0.08, 0.06), (0, yl1 - 0.04, Z + 0.02), menta, bisel=0.02, padre=r)
caja("tunel_ventana", (1.7, 0.02, 0.2), (0, yl1 - 0.03, Z + 0.15), vid, bisel=0.0, padre=r)
for x in (-0.92, 0.0, 0.92):
    caja(f"tunel_montante{x}", (0.12 if x == 0.0 else 0.16, 0.09, 0.26), (x, yl1 - 0.04, Z + 0.14), naranja, bisel=0.02, padre=r)
caja("tunel_marco_ventana", (1.84, 0.1, 0.03), (0, yl1 - 0.04, Z + 0.265), crema, bisel=0.012, padre=r)
for x in [-0.8 + k * 0.16 for k in range(11)]:
    tornillo(f"torn_marco{x:.2f}", (x, yl1 + 0.012, Z + 0.265), r, r=0.007, normal="+Y")
# rodillos internos en la misma línea y altura que la cinta
for k in range(19):
    x = -0.95 + k * 0.105
    cilindro(f"rodillo{k}", 0.022, LAN - 0.1, (x, YL, Z - 0.022), cromo, lados=16, padre=r, giro=(math.radians(90), 0, 0))
for s in (-1, 1):
    caja(f"guia{s}", (2.0, 0.02, 0.05), (0, YL + s * (LAN / 2 - 0.04), Z + 0.02), amarillo, bisel=0.004, padre=r)
# agujeros de entrada (-X) y salida (+X): marco con franja de color y cortina de lamas
for lado, nombre, col in ((-1, "entrada", (0.25, 0.9, 0.4)), (1, "salida", (1.0, 0.55, 0.12))):
    xf = lado * 0.995
    caja(f"{nombre}_marco_sup", (0.05, LAN + 0.1, 0.07), (xf, YL, Z + 0.3), grafito, bisel=0.015, padre=r)
    for s in (-1, 1):
        caja(f"{nombre}_marco_lat{s}", (0.05, 0.06, 0.32), (xf, YL + s * (LAN / 2 + 0.02), Z + 0.13), grafito, bisel=0.012, padre=r)
    caja(f"{nombre}_franja", (0.055, LAN + 0.1, 0.022), (xf, YL, Z + 0.345),
         mat(f"franja_{nombre}", color=col, rug=0.35, emision=col, fuerza=0.9), bisel=0.004, padre=r)
    for k in range(9):
        caja(f"{nombre}_lama{k}", (0.004, LAN / 9 - 0.006, 0.13), (xf + lado * 0.01, YL - LAN / 2 + LAN / 9 * (k + 0.5), Z + 0.2),
             mat("lama", color=(0.18, 0.2, 0.22), rug=0.5, alfa=0.65), bisel=0.0, padre=r)
    for sz in (-1, 1):
        for s in (-1, 1):
            tornillo(f"{nombre}_torn{s}{sz}", (xf + lado * 0.027, YL + s * (LAN / 2 + 0.02), Z + 0.13 + sz * 0.12), r, r=0.007,
                     normal="+X" if lado > 0 else "-X")
# dos gradillas dentro del túnel (el juego las mueve)
gradilla("gradilla_dentro0", (-0.25, YL, Z + 0.03), r)
gradilla("gradilla_dentro1", (0.5, YL, Z), r)

# ------------------------------------------------------------ cuerpo trasero con el tambor
caja("cuerpo", (2.0, 1.0, 0.5), (0, -0.5, 0.38), menta, bisel=0.16, segmentos=5, padre=r)
caja("cinto", (2.03, 1.03, 0.06), (0, -0.5, 0.6), naranja, bisel=0.03, segmentos=3, padre=r)
for k in range(8):
    caja(f"rejilla{k}", (0.012, 0.36, 0.018), (-1.0, -0.5, 0.2 + k * 0.034), menta_osc, bisel=0.004, padre=r)
    caja(f"rejilla_d{k}", (0.012, 0.36, 0.018), (1.0, -0.5, 0.2 + k * 0.034), menta_osc, bisel=0.004, padre=r)
cilindro("tambor", 0.56, 0.32, (0, -0.42, 0.78), crema, lados=64, bisel=0.06, segmentos=5, padre=r)
toro("tambor_aro", 0.56, 0.035, (0, -0.42, 0.94), naranja, padre=r)
cilindro("cuba", 0.5, 0.02, (0, -0.42, 0.94), cromo, lados=64, padre=r)
for k in range(18):
    a = k / 18 * math.tau
    tornillo(f"torn_aro{k}", (math.cos(a) * 0.585, -0.42 + math.sin(a) * 0.585, 0.9), r, r=0.009, normal="+Z")
rot = vacio("rotor", (0, -0.42, 0.96), r)
cilindro("rotor_eje", 0.07, 0.1, (0, 0, 0.03), cromo, lados=32, bisel=0.01, padre=rot)
for k in range(6):
    a = k / 6 * math.tau
    caja(f"brazo{k}", (0.36, 0.05, 0.03), (math.cos(a) * 0.18, math.sin(a) * 0.18, 0.03), cromo, bisel=0.008, padre=rot, giro=(0, 0, a))
    ces = vacio(f"cesto{k}", (math.cos(a) * 0.36, math.sin(a) * 0.36, 0.04), rot)
    ces.rotation_euler = (0, 0, a + math.pi / 2)
    caja(f"cesto{k}_cuerpo", (0.19, 0.11, 0.12), (0, 0, -0.02), menta_osc, bisel=0.02, padre=ces)
    for i in range(3):
        cilindro(f"cesto{k}_tubo{i}", 0.016, 0.11, (-0.055 + i * 0.055, 0, 0.05), sangre, lados=12, padre=ces)
        cilindro(f"cesto{k}_tapon{i}", 0.02, 0.022, (-0.055 + i * 0.055, 0, 0.11), tapon, lados=12, padre=ces)
cup = vacio("cupula", (0, -0.98, 0.96), r)
esfera("cupula_vidrio", 0.56, (0, 0.56, 0.0), vid, padre=cup, media=True, escala=(1, 1, 0.42))
toro("cupula_aro", 0.56, 0.028, (0, 0.56, 0.005), naranja, padre=cup)
for s in (-1, 1):
    cilindro(f"bisagra{s}", 0.03, 0.1, (s * 0.22, 0.0, 0.02), cromo, lados=16, padre=cup, giro=(0, math.radians(90), 0))

# ------------------------------------------------------------ brazo cargador: coge la gradilla de la línea y la mete en el tambor
caja("brazo_base", (0.22, 0.12, 0.3), (-0.25, YL - 0.4, Z + 0.15), grafito, bisel=0.03, padre=r)
bc = vacio("brazo_carga", (-0.25, YL - 0.4, Z + 0.3), r)
cilindro("brazo_giro", 0.07, 0.06, (0, 0, 0.0), naranja, lados=32, bisel=0.02, padre=bc)
caja("brazo_tramo", (0.08, 0.42, 0.06), (0, 0.2, 0.0), naranja, bisel=0.025, padre=bc)
cilindro("brazo_codo", 0.04, 0.08, (0, 0.4, 0.0), cromo, lados=24, padre=bc)
pz = vacio("pinza", (0, 0.4, 0.0), bc)
cilindro("pinza_vastago", 0.015, 0.08, (0, 0, -0.04), cromo, lados=12, padre=pz)
caja("pinza_barra", (0.34, 0.04, 0.03), (0, 0, -0.08), grafito, bisel=0.008, padre=pz)
for s_ in (-1, 1):
    caja(f"pinza_dedo{s_}", (0.025, 0.12, 0.09), (s_ * 0.17, 0, -0.12), grafito, bisel=0.008, padre=pz)

# ------------------------------------------------------------ cabezal de agujas: saca el plasma de la gradilla que vuelve a la línea
caja("puente", (0.1, 0.5, 0.06), (0.5, YL - 0.2, Z + 0.33), crema, bisel=0.02, padre=r)
ca = vacio("cabezal_agujas", (0.5, YL, Z + 0.29), r)
caja("cabezal_cuerpo", (0.3, 0.18, 0.08), (0, 0, 0.0), naranja, bisel=0.025, padre=ca)
for i in range(3):
    for j in range(2):
        cilindro(f"aguja{i}{j}", 0.004, 0.08, (-0.1 + i * 0.1, -0.04 + j * 0.08, -0.07), cromo, lados=8, padre=ca)
tubo_curvo("tubo_plasma_vidrio", [(0.5, YL, Z + 0.33), (0.55, YL - 0.4, Z + 0.36), (0.6, -0.3, Z + 0.45), (0.62, -0.85, Z + 0.4), (0.62, -0.95, 0.18)],
           0.02, vid, padre=r)
ps = vacio("plasma_subiendo", (0.6, -0.3, Z + 0.45), r)
cilindro("plasma_columna", 0.013, 0.5, (0, -0.25, 0), ambar, lados=12, padre=ps, giro=(math.radians(90), 0, 0))

# ------------------------------------------------------------ brida de plasma atrás (-Y) con mirilla y volante
cilindro("brida", 0.09, 0.05, (0.62, -1.0, 0.12), cromo, lados=32, bisel=0.006, padre=r, giro=(math.radians(90), 0, 0))
cilindro("brida_color", 0.095, 0.02, (0.62, -0.975, 0.12), ambar, lados=32, padre=r, giro=(math.radians(90), 0, 0))
for k in range(8):
    a = k / 8 * math.tau
    tornillo(f"torn_brida{k}", (0.62 + math.cos(a) * 0.07, -1.03, 0.12 + math.sin(a) * 0.07), r, r=0.008, normal="-Y")
caja("mirilla_marco", (0.12, 0.03, 0.24), (0.3, -1.0, 0.36), cromo, bisel=0.01, padre=r)
caja("mirilla_vidrio", (0.08, 0.034, 0.2), (0.3, -1.0, 0.36), vid, bisel=0.0, padre=r)
niv = vacio("mirilla_nivel", (0.3, -1.0, 0.26), r)
caja("mirilla_plasma", (0.07, 0.03, 0.14), (0, 0, 0.07), ambar, bisel=0.0, padre=niv)
vol = vacio("volante", (0.85, -1.01, 0.32), r)
toro("volante_aro", 0.065, 0.012, (0, 0, 0), rojo, padre=vol).rotation_euler = (math.radians(90), 0, 0)
for k in range(3):
    caja(f"volante_radio{k}", (0.13, 0.012, 0.012), (0, 0, 0), rojo, bisel=0.0, padre=vol, giro=(0, math.radians(k * 60), 0))

# ------------------------------------------------------------ consola encima del túnel, mirando al frente (+Y)
caja("consola", (0.22, 0.5, 0.1), (-0.89, YL + 0.05, Z + 0.45), crema, bisel=0.04, segmentos=3, padre=r, giro=(math.radians(-20), 0, 0))
pantalla_plano("pantalla", 0.17, 0.26, (-0.89, YL + 0.1, Z + 0.505), padre=r, giro=(math.radians(70), 0, math.pi))
cilindro("seta", 0.035, 0.035, (-0.89, YL + 0.33, Z + 0.47), rojo, lados=32, bisel=0.012, padre=r)
cols = [(0.3, 0.95, 0.4), (1, 0.7, 0.2), (0.3, 0.6, 1)]
for k in range(3):
    cilindro(f"boton{k}", 0.014, 0.012, (-0.94 + k * 0.05, YL - 0.17, Z + 0.43),
             mat(f"led{k}", color=cols[k], emision=cols[k], fuerza=2.5), lados=12, padre=r)
manometro("mano", (0.25, YL + 0.47, Z + 0.06), r, r=0.045, normal_giro=(math.radians(90), 0, math.pi))
bio = mat_calcomania("aviso_biorriesgo", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, recorte=True)
calcomania("bio", 0.13, 0.13, (-0.6, YL + 0.475, Z - 0.06), bio, padre=r, giro=(math.radians(90), 0, math.pi))
placa = mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.4)
calcomania("placa", 0.2, 0.07, (0.6, YL + 0.475, Z - 0.06), placa, padre=r, giro=(math.radians(90), 0, math.pi))
torre_luces((-0.85, -0.85, 0.63), r)
tubo_curvo("cable", [(-0.85, -0.85, 0.63), (-0.95, -0.95, 0.4), (-0.95, -0.98, 0.1)], 0.016, negro, padre=r)

exportar(SALIDA)
print("hecho:", SALIDA)
