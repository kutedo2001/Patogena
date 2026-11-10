"""Biorreactor detallado (P3.4e), 2×2 casillas.
Bancada de rejilla sobre zócalo; vaso de cristal encamisado con fondo toriesférico de acero, bridas atornilladas,
caldo de cultivo del color de la mutación con burbujas, agitador con dos turbinas Rushton; tapa de acero con
corona de tornillos, motorreductor, sondas (pH, O₂, temperatura), filtro de venteo y condensador; armario de
control con pantalla viva, seta, prensaestopas, tres bombas peristálticas y frascos de alimentación; tuberías de
acero con válvulas de volante; dosificadora de viales en la salida.
Uso: blender -b -P tools/blender/biorreactor.py -- <salida.glb> <carpeta_texturas>
Nodos animados: agitador, burbuja0..N, gira_bomba0..2, pantalla, baliza_v/a/r, liquido/caldo.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun, objetos
importlib.reload(comun); importlib.reload(objetos)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["biorreactor.glb", "."]
SALIDA, TEX = args[0], args[1]
objetos.TEX = os.path.join(TEX, "etiquetas")
CAL = os.path.join(TEX, "calcomanias")
ESC = 2.5
random.seed(5)

limpiar(); comun._mats.clear()
r = vacio("biorreactor")
ch, chos, gr, me, ac = mat("chasis"), mat("chasis_osc"), mat("grafito"), mat("metal"), mat("acento_producto")
goma = mat("goma")
inox = mat("inox", color=(0.74, 0.76, 0.78), metal=1.0, rug=0.22)
inox_osc = mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)
cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.12)
COLOR = (0.25, 0.85, 0.1)
caldo = mat("caldo", color=COLOR, rug=0.15, emision=(0.3, 1.0, 0.15), fuerza=0.6, alfa=0.7)
rojo_valv = mat("volante_rojo", color=(0.7, 0.05, 0.05), rug=0.45)

# ------------------------------------------------------------ base y bancada de rejilla
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * 0.85, sy * 0.85
        cilindro(f"pata{sx}{sy}", 0.05, 0.014, (x, y, 0.007), goma, lados=20, bisel=0.003, padre=r)
        cilindro(f"pata_tuerca{sx}{sy}", 0.026, 0.015, (x, y, 0.036), me, lados=6, bisel=0.002, padre=r)
caja("zocalo", (1.96, 1.96, 0.07), (0, 0, 0.075), gr, bisel=0.025, padre=r)
caja("zocalo_goma", (1.97, 1.97, 0.012), (0, 0, 0.044), goma, bisel=0.004, padre=r)
ZH = 0.11
fp = mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5)
for s in (-1, 1):
    calcomania(f"franja{s}", 1.5, 0.04, (0, s * 0.955, ZH + 0.0015), fp, padre=r)
# marco y rejilla tramex
ZG = ZH + 0.05
for s in (-1, 1):
    caja(f"bancada_x{s}", (1.86, 0.05, 0.05), (0, s * 0.905, ZH + 0.025), inox_osc, bisel=0.006, padre=r)
    caja(f"bancada_y{s}", (0.05, 1.86, 0.05), (s * 0.905, 0, ZH + 0.025), inox_osc, bisel=0.006, padre=r)
for i in range(-17, 18):
    caja(f"rejilla_x{i}", (1.78, 0.008, 0.03), (0, i * 0.05, ZH + 0.035), inox_osc, bisel=0.0, padre=r)
for i in range(-8, 9):
    caja(f"rejilla_y{i}", (0.008, 1.78, 0.02), (i * 0.1, 0, ZH + 0.04), inox_osc, bisel=0.0, padre=r)

# ------------------------------------------------------------ vaso
VX, VY = -0.2, 0.15
RV = 0.48
Z_FONDO, Z_C0, Z_C1 = ZG + 0.22, ZG + 0.36, ZG + 1.18     # fondo, inicio y fin del cristal
v = vacio("vaso", (VX, VY, 0), padre=r)
# fondo toriesférico de acero
torneado("fondo", [(0, Z_FONDO), (RV * 0.5, Z_FONDO + 0.02), (RV * 0.85, Z_FONDO + 0.06), (RV + 0.02, Z_C0 - 0.04),
                   (RV + 0.02, Z_C0), (0, Z_C0)], inox, lados=64, padre=v)
cilindro("fondo_salida", 0.05, 0.08, (0, 0, Z_FONDO - 0.03), inox, lados=24, padre=v)
# patas del vaso con riostras
for k in range(4):
    a = k * math.tau / 4 + math.pi / 4
    x, y = math.cos(a) * (RV - 0.02), math.sin(a) * (RV - 0.02)
    caja(f"pata_vaso{k}", (0.05, 0.05, Z_C0 - ZG), (x, y, (ZG + Z_C0) / 2), inox, bisel=0.008, padre=v)
    caja(f"pie_vaso{k}", (0.12, 0.12, 0.015), (x, y, ZG + 0.0075), inox_osc, bisel=0.004, padre=v)
    for s in (-1, 1):
        tornillo(f"pie_torn{k}{s}", (x + s * 0.04, y, ZG + 0.015), v, r=0.008, normal="+Z")
# bridas inferior y superior con tornillos
def brida(nombre, z, n=20):
    torneado(nombre, [(RV - 0.02, z - 0.02), (RV + 0.07, z - 0.02), (RV + 0.07, z + 0.02), (RV - 0.02, z + 0.02)], inox, lados=64,
             padre=v, cerrar=True)
    for k in range(n):
        a = k * math.tau / n
        tornillo(f"{nombre}_t{k}", (math.cos(a) * (RV + 0.045), math.sin(a) * (RV + 0.045), z + 0.02), v, r=0.011, normal="+Z")
brida("brida_inf", Z_C0)
brida("brida_sup", Z_C1)
# camisa de cristal (doble pared) y caldo
cilindro("camisa", RV, Z_C1 - Z_C0 - 0.04, (0, 0, (Z_C0 + Z_C1) / 2), cristal, lados=64, bisel=0.0, padre=v)
cilindro("vaso_interior", RV - 0.035, Z_C1 - Z_C0 - 0.04, (0, 0, (Z_C0 + Z_C1) / 2), cristal, lados=64, bisel=0.0, padre=v)
Z_NIVEL = Z_C0 + 0.6
torneado("caldo", [(0, Z_FONDO + 0.02), (RV * 0.5, Z_FONDO + 0.04), (RV * 0.83, Z_FONDO + 0.08), (RV - 0.04, Z_C0 - 0.02),
                   (RV - 0.04, Z_NIVEL + 0.01), (RV * 0.6, Z_NIVEL), (0, Z_NIVEL - 0.02)], caldo, lados=48, padre=v)
# graduación en el cristal
for k in range(6):
    z = Z_C0 + 0.1 + k * 0.12
    caja(f"marca{k}", (0.004, 0.06 if k % 2 == 0 else 0.035, 0.006), (RV + 0.002, 0, z), negro, bisel=0.0, padre=v,
         giro=(0, 0, math.radians(-60)))
# deflectores verticales dentro
for k in range(4):
    a = k * math.tau / 4
    caja(f"deflector{k}", (0.012, 0.05, 0.7), (math.cos(a) * (RV - 0.07), math.sin(a) * (RV - 0.07), Z_C0 + 0.38), inox, bisel=0.003,
         padre=v, giro=(0, 0, a))
# burbujas (las mueve el juego)
for k in range(14):
    a = random.random() * math.tau
    d = random.random() * (RV - 0.12)
    z = Z_FONDO + 0.12 + random.random() * 0.55
    esfera(f"burbuja{k}", random.choice((0.012, 0.016, 0.022)), (math.cos(a) * d, math.sin(a) * d, z),
           mat("burbuja", color=(0.9, 1.0, 0.85), rug=0.1, alfa=0.55), padre=v)
# difusor anular en el fondo
toro("difusor", 0.18, 0.012, (0, 0, Z_FONDO + 0.09), inox, padre=v)

# ------------------------------------------------------------ tapa, motor y agitador
ZT = Z_C1 + 0.02
cilindro("tapa_placa", RV + 0.075, 0.05, (0, 0, ZT + 0.025), inox, lados=64, bisel=0.008, padre=v)
for k in range(24):
    a = k * math.tau / 24
    tornillo(f"tapa_t{k}", (math.cos(a) * (RV + 0.045), math.sin(a) * (RV + 0.045), ZT + 0.05), v, r=0.011, normal="+Z")
cilindro("reductor", 0.13, 0.12, (0, 0, ZT + 0.11), inox_osc, lados=32, bisel=0.012, padre=v)
cilindro("motor", 0.11, 0.26, (0, 0, ZT + 0.3), ac, lados=32, bisel=0.015, padre=v)
for k in range(16):
    a = k * math.tau / 16
    caja(f"motor_aleta{k}", (0.012, 0.03, 0.2), (math.cos(a) * 0.115, math.sin(a) * 0.115, ZT + 0.3), ac, bisel=0.003, padre=v,
         giro=(0, 0, a))
cilindro("motor_tapa_vent", 0.105, 0.05, (0, 0, ZT + 0.455), gr, lados=32, bisel=0.01, padre=v)
for k in range(8):
    caja(f"motor_rejilla{k}", (0.18, 0.008, 0.01), (0, 0, ZT + 0.482), negro, bisel=0.0, padre=v, giro=(0, 0, k * math.pi / 8))
caja("motor_caja_bornes", (0.08, 0.06, 0.07), (0.12, 0, ZT + 0.32), gr, bisel=0.01, padre=v)
calcomania("motor_placa", 0.05, 0.03, (0, -0.112, ZT + 0.3), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=v)
ag = vacio("agitador", (0, 0, 0), padre=v)
cilindro("eje", 0.022, ZT - (Z_FONDO + 0.16), (0, 0, (ZT + Z_FONDO + 0.16) / 2), inox, lados=16, padre=ag)
for k, z in enumerate((Z_FONDO + 0.2, Z_FONDO + 0.48)):
    cilindro(f"turbina{k}_cubo", 0.04, 0.05, (0, 0, z), inox, lados=16, bisel=0.005, padre=ag)
    cilindro(f"turbina{k}_disco", 0.13, 0.008, (0, 0, z), inox, lados=32, bisel=0.0, padre=ag)
    for b in range(6):
        a = b * math.tau / 6
        caja(f"turbina{k}_pala{b}", (0.06, 0.006, 0.05), (math.cos(a) * 0.12, math.sin(a) * 0.12, z), inox, bisel=0.002, padre=ag,
             giro=(0, 0, a))
# sondas con cabezal de color y cable
sondas = [(1.9, (0.2, 0.5, 0.9)), (2.4, (0.9, 0.6, 0.1)), (2.9, (0.85, 0.15, 0.15))]
for k, (a, c) in enumerate(sondas):
    x, y = math.cos(a) * 0.32, math.sin(a) * 0.32
    cilindro(f"sonda{k}", 0.012, 0.75, (x, y, ZT - 0.3), inox, lados=12, padre=v)
    cilindro(f"sonda{k}_rosca", 0.025, 0.04, (x, y, ZT + 0.07), inox_osc, lados=6, bisel=0.003, padre=v)
    cilindro(f"sonda{k}_cabeza", 0.022, 0.08, (x, y, ZT + 0.13), mat(f"sonda_{k}", color=c, rug=0.4), lados=16, bisel=0.006, padre=v)
    tubo_curvo(f"sonda{k}_cable", [(x, y, ZT + 0.17), (x, y, ZT + 0.3), (x - 0.2, y + 0.25, ZT + 0.35),
                                   (0.68 - VX, 0.68 - VY, ZT + 0.15)], 0.008, negro, padre=v)
# filtro de venteo y condensador
cilindro("filtro", 0.05, 0.2, (0.3, 0.12, ZT + 0.15), mat("filtro_blanco", color=(0.93, 0.93, 0.9), rug=0.6), lados=24, bisel=0.01, padre=v)
cilindro("filtro_tapa", 0.055, 0.03, (0.3, 0.12, ZT + 0.26), mat("tapon_tuerca", color=(0.13, 0.5, 0.75), rug=0.4), lados=24, bisel=0.005, padre=v)
cilindro("condensador", 0.035, 0.18, (0.18, 0.3, ZT + 0.14), inox, lados=16, padre=v)
for k in range(7):
    cilindro(f"condensador_aleta{k}", 0.06, 0.006, (0.18, 0.3, ZT + 0.07 + k * 0.024), inox_osc, lados=20, bisel=0.0, padre=v)
# mirilla con lámpara
cilindro("lampara", 0.03, 0.05, (-0.25, -0.25, ZT + 0.075), mat("lampara", color=(1, 0.95, 0.8), emision=(1, 0.95, 0.8), fuerza=2.0),
         lados=16, bisel=0.006, padre=v)

# ------------------------------------------------------------ armario de control (esquina trasera derecha)
AX0, AX1, AY0, AY1, AZ = 0.42, 0.95, 0.42, 0.95, 1.6
acx, acy = (AX0 + AX1) / 2, (AY0 + AY1) / 2
caja("armario", (AX1 - AX0, AY1 - AY0, AZ - ZG), (acx, acy, (ZG + AZ) / 2), ch, bisel=0.04, segmentos=3, padre=r)
caja("armario_techo", (AX1 - AX0 + 0.02, AY1 - AY0 + 0.02, 0.04), (acx, acy, AZ + 0.02), ac, bisel=0.012, padre=r)
caja("armario_franja", (AX1 - AX0 + 0.012, AY1 - AY0 + 0.012, 0.05), (acx, acy, ZG + 0.62), ac, bisel=0.012, padre=r)
FYA = AY0 - 0.002
caja("puerta_armario", (AX1 - AX0 - 0.06, 0.012, 0.75), (acx, FYA - 0.004, ZG + 1.05), chos, bisel=0.008, padre=r)
for z in (ZG + 0.78, ZG + 1.32):
    cilindro(f"bisagra_arm{z:.2f}", 0.012, 0.06, (AX0 + 0.04, FYA - 0.012, z), me, lados=12, padre=r)
caja("maneta", (0.02, 0.03, 0.12), (AX1 - 0.07, FYA - 0.02, ZG + 1.05), negro, bisel=0.006, padre=r)
pantalla_plano("pantalla", 0.36, 0.26, (acx - 0.01, FYA - 0.016, ZG + 1.18), padre=r)
caja("pantalla_marco", (0.4, 0.008, 0.3), (acx - 0.01, FYA - 0.009, ZG + 1.18), gr, bisel=0.003, padre=r)
cilindro("seta_aro", 0.04, 0.01, (acx + 0.12, FYA - 0.014, ZG + 0.88), mat("amarillo"), lados=24, bisel=0.002, padre=r, giro=(math.radians(90), 0, 0))
esfera("seta", 0.032, (acx + 0.12, FYA - 0.03, ZG + 0.88), mat("seta_roja", color=(0.75, 0.04, 0.04), rug=0.35), padre=r)
for k, c in enumerate(((0.1, 0.65, 0.25), (0.15, 0.15, 0.16))):
    cilindro(f"boton{k}", 0.014, 0.014, (acx - 0.12 + k * 0.05, FYA - 0.018, ZG + 0.88), mat(f"boton_{k}", color=c, rug=0.4), lados=16,
             bisel=0.003, padre=r, giro=(math.radians(90), 0, 0))
calcomania("aviso_bio", 0.09, 0.09, (acx - 0.1, FYA - 0.012, ZG + 0.5), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r)
calcomania("placa_logo", 0.16, 0.08, (acx + 0.08, FYA - 0.012, ZG + 0.5), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=r)
for k in range(4):
    cilindro(f"prensaestopas{k}", 0.018, 0.03, (acx - 0.15 + k * 0.1, acy, AZ + 0.055), negro, lados=6, bisel=0.003, padre=r)
# bombas peristálticas en el frente del armario, bajo la pantalla
for k in range(3):
    x = AX0 + 0.1 + k * 0.165
    z = ZG + 0.3
    caja(f"bomba{k}", (0.14, 0.06, 0.18), (x, FYA - 0.03, z), gr, bisel=0.01, padre=r)
    caja(f"bomba{k}_tapa", (0.12, 0.012, 0.15), (x, FYA - 0.066, z), mat("cristal_bomba", color=(0.8, 0.88, 0.9), rug=0.1, alfa=0.3),
         bisel=0.004, padre=r)
    gb = vacio(f"gira_bomba{k}", (x, FYA - 0.05, z + 0.01), padre=r)
    gb.rotation_euler = (math.radians(90), 0, 0)     # eje de giro hacia -Y
    cilindro(f"bomba{k}_rotor", 0.045, 0.02, (0, 0, 0), me, lados=20, bisel=0.003, padre=gb)
    for j_ in range(3):
        a = j_ * math.tau / 3
        cilindro(f"bomba{k}_rodillo{j_}", 0.014, 0.03, (math.cos(a) * 0.04, math.sin(a) * 0.04, 0.0), inox, lados=12, padre=gb)
    tubo_curvo(f"bomba{k}_tubo", [(x - 0.05, FYA - 0.06, z + 0.09), (x - 0.08, FYA - 0.15, z + 0.4), (VX + 0.3, VY - 0.1, ZT + 0.25),
                                  (VX + 0.25 - k * 0.05, VY - 0.15, ZT + 0.06)],
               0.007, mat("silicona", color=(0.9, 0.85, 0.75), rug=0.4, alfa=0.85), padre=r)
    cilindro(f"bomba{k}_racor", 0.018, 0.04, (VX + 0.25 - k * 0.05, VY - 0.15, ZT + 0.07), inox_osc, lados=6, bisel=0.003, padre=r)
# frascos de alimentación sobre el armario
for k in range(3):
    x = acx - 0.15 + k * 0.15
    c = [(0.9, 0.75, 0.3), (0.3, 0.6, 0.95), (0.95, 0.95, 0.9)][k]
    torneado(f"frasco{k}", [(0, 0), (0.05, 0), (0.055, 0.005), (0.055, 0.14), (0.028, 0.17), (0.028, 0.19), (0, 0.19)],
             mat("vidrio_frasco", color=(0.8, 0.9, 0.95), rug=0.05, alfa=0.25), lados=24, padre=r, pos=(x, acy + 0.12, AZ + 0.04))
    torneado(f"frasco_liq{k}", [(0, 0.004), (0.048, 0.004), (0.052, 0.008), (0.052, 0.1), (0, 0.1)],
             mat(f"alimento{k}", color=c, rug=0.2), lados=24, padre=r, pos=(x, acy + 0.12, AZ + 0.04))
    cilindro(f"frasco_tapon{k}", 0.033, 0.03, (x, acy + 0.12, AZ + 0.245), mat("tapon_tuerca"), lados=20, bisel=0.004, padre=r)
torre_luces((AX1 - 0.08, AY1 - 0.08, AZ + 0.04), r, poste=0.2)
tubo_curvo("cable_red", [(acx, AY1 + 0.01, ZG + 0.1), (acx, AY1 + 0.07, ZG + 0.04), (acx - 0.1, AY1 + 0.04, 0.02), (acx - 0.3, AY1 - 0.1, 0.012)],
           0.01, negro, padre=r)

# ------------------------------------------------------------ tuberías, válvulas y dosificadora de viales (salida +X)
def valvula(nombre, pos, eje="X"):
    x, y, z = pos
    g = (0, math.radians(90), 0) if eje == "X" else (math.radians(90), 0, 0)
    cilindro(nombre + "_cuerpo", 0.04, 0.09, pos, inox, lados=20, bisel=0.008, padre=r, giro=g)
    cilindro(nombre + "_vastago", 0.008, 0.08, (x, y, z + 0.06), inox, lados=8, padre=r)
    toro(nombre + "_volante", 0.045, 0.008, (x, y, z + 0.1), rojo_valv, padre=r)
    for k in range(3):
        caja(f"{nombre}_radio{k}", (0.085, 0.008, 0.006), (x, y, z + 0.1), rojo_valv, bisel=0.0, padre=r, giro=(0, 0, k * math.pi / 3))
ZD = Z_FONDO - 0.07
DX, DY = 0.6, -0.55                                     # dosificadora delante a la derecha, junto a la salida
tubo_curvo("tubo_vaciado", [(VX, VY, ZD), (VX, VY, ZD - 0.03), (VX + 0.3, VY - 0.25, ZD - 0.04), (DX - 0.1, DY + 0.25, ZD - 0.02),
                            (DX, DY + 0.18, ZG + 0.45)], 0.025, inox, padre=r)
valvula("valvula_vaciado", (VX + 0.42, VY - 0.36, ZD - 0.035))
caja("dosif_base", (0.36, 0.3, 0.06), (DX, DY, ZG + 0.03), gr, bisel=0.01, padre=r)
caja("dosif_columna", (0.06, 0.06, 0.45), (DX, DY + 0.12, ZG + 0.285), inox_osc, bisel=0.008, padre=r)
caja("dosif_brazo", (0.06, 0.2, 0.06), (DX, DY + 0.03, ZG + 0.48), inox_osc, bisel=0.008, padre=r)
caja("dosif_cabezal", (0.09, 0.08, 0.08), (DX, DY - 0.06, ZG + 0.48), ac, bisel=0.012, padre=r)
tubo_curvo("dosif_manguera", [(DX, DY + 0.18, ZG + 0.45), (DX + 0.03, DY + 0.15, ZG + 0.56), (DX, DY - 0.04, ZG + 0.53)], 0.012,
           mat("silicona", color=(0.9, 0.85, 0.75), rug=0.4, alfa=0.85), padre=r)
# boquilla que baja al llenar, con su gota
boq = vacio("boquilla", (DX, DY - 0.06, ZG + 0.44), padre=r)
cilindro("boquilla_cuerpo", 0.016, 0.05, (0, 0, 0), inox, lados=12, padre=boq)
torneado("boquilla_punta", [(0, -0.06), (0.004, -0.06), (0.012, -0.025), (0, -0.025)], inox, lados=12, padre=boq)
esfera("gota", 0.007, (0, 0, -0.07), mat("liq_gota", color=COLOR, rug=0.1, emision=COLOR, fuerza=0.8), padre=boq,
       escala=(1, 1, 1.4))
# bandeja que avanza para poner cada vial bajo la boquilla
caja("dosif_guia", (0.5, 0.04, 0.012), (DX, DY - 0.06, ZG + 0.066), inox_osc, bisel=0.003, padre=r)
band = vacio("bandeja", (DX, DY - 0.06, ZG + 0.07), padre=r)
caja("dosif_bandeja", (0.36, 0.1, 0.02), (0, 0, 0.0), inox, bisel=0.006, padre=band)
for k in range(4):
    caja(f"bandeja_tope{k}", (0.006, 0.1, 0.03), (-0.15 + k * 0.1, 0, 0.015), inox_osc, bisel=0.002, padre=band)
for k, x in enumerate((-0.1, 0.0, 0.1)):
    vv = objetos.vial(f"vial{k}", padre=band, pos=(x, 0, 0.01), color=COLOR)
    vv.scale = (ESC, ESC, ESC)
    for ob in vv.children:
        if ob.name.startswith("liquido"):
            ob.name = f"llenado{k}"
        for parte in ("goma", "capsula", "flip"):
            if ob.name.startswith(parte):
                ob.name = f"taponado{k}_{parte}"

# ------------------------------------------------------------ bocas
bocas_estandar(r, 2, (0, 1), 1)
caja("entrada_conducto", (0.12, 0.34, 0.26), (-0.86, -0.5, ZH + 0.25), gr, bisel=0.015, padre=r)
caja("salida_conducto", (0.1, 0.34, 0.26), (0.88, -0.2, ZH + 0.25), gr, bisel=0.015, padre=r)
tubo_curvo("tubo_entrada", [(-0.82, -0.5, ZH + 0.32), (-0.65, -0.5, ZH + 0.5), (VX - 0.2, VY - RV - 0.08, Z_C0 + 0.2), (VX - 0.15, VY - RV + 0.01, Z_C0 + 0.22)],
           0.022, inox, padre=r)
valvula("valvula_entrada", (-0.66, -0.5, ZH + 0.48))

exportar(SALIDA)
print("BIORREACTOR OK")
