"""Mezcladora detallada (P3.5b), 2×2 casillas. Agua + reactivo → 2 bolsas de suero.
Garrafa invertida en su cuna y frasco de reactivo con bomba que vierten (chorros) en un vaso de vidrio con remolino
y hélice; puente con motor; tubería con válvulas de pinza hacia dos bolsas colgadas que se llenan y una selladora
que baja y se pone al rojo; manómetro con aguja, consola con pantalla viva, piezas pequeñas.
Uso: blender -b -P tools/blender/mezcladora.py -- <salida.glb> <carpeta_texturas>
Nodos animados (scripts/maquina.gd): vaciar_*, chorro_*, nivel_vaso, gira_*, agitador, llenar_*, sellar_*, aguja_*,
pantalla, baliza_v/a/r.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun, objetos
importlib.reload(comun); importlib.reload(objetos)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["mezcladora.glb", "."]
SALIDA, TEX = args[0], args[1]
objetos.TEX = os.path.join(TEX, "etiquetas")
CAL = os.path.join(TEX, "calcomanias")
ESC = 2.5

limpiar(); comun._mats.clear()
r = vacio("mezcladora")
ch, chos, gr, me, ac = mat("chasis"), mat("chasis_osc"), mat("grafito"), mat("metal"), mat("acento_procesado")
inox = mat("inox", color=(0.74, 0.76, 0.78), metal=1.0, rug=0.22)
inox_osc = mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)
cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.12)
C_AGUA = (0.55, 0.8, 0.95)
C_REAC = (0.35, 0.15, 0.75)
C_MEZCLA = (0.92, 0.78, 0.4)

ZH = base_maquina(r, 2.0, CAL)

# ------------------------------------------------------------ mesa-armario
ZM = 0.62
caja("armario", (1.7, 1.5, ZM - ZH), (0, 0, (ZH + ZM) / 2), ch, bisel=0.05, segmentos=4, padre=r)
caja("franja_familia", (1.712, 1.512, 0.05), (0, 0, ZM - 0.09), ac, bisel=0.012, padre=r)
caja("mesa", (1.66, 1.46, 0.025), (0, 0, ZM + 0.0125), inox, bisel=0.006, padre=r)
ZM += 0.025
FY = -0.752
# frontal: consola con pantalla, seta, botones, rejilla, placa y pegatinas
cons = vacio("consola", (0.35, FY - 0.03, ZM - 0.2), padre=r)
cons.rotation_euler = (math.radians(-12), 0, 0)
caja("consola_cuerpo", (0.62, 0.06, 0.3), (0, 0, 0), gr, bisel=0.015, padre=cons)
pantalla_plano("pantalla", 0.4, 0.22, (-0.07, -0.036, 0.01), padre=cons)
caja("pantalla_bisel", (0.43, 0.004, 0.25), (-0.07, -0.031, 0.01), negro, bisel=0.002, padre=cons)
cilindro("seta_aro", 0.035, 0.01, (0.22, -0.033, 0.06), mat("amarillo"), lados=24, bisel=0.002, padre=cons, giro=(math.radians(90), 0, 0))
esfera("seta", 0.028, (0.22, -0.045, 0.06), mat("seta_roja", color=(0.75, 0.04, 0.04), rug=0.35), padre=cons)
for k, c in enumerate(((0.1, 0.65, 0.25), (0.15, 0.15, 0.16), (0.95, 0.75, 0.15))):
    cilindro(f"boton{k}", 0.013, 0.014, (0.18 + k * 0.035 - 0.01, -0.036, -0.06), mat(f"boton_{k}", color=c, rug=0.4), lados=16,
             bisel=0.003, padre=cons, giro=(math.radians(90), 0, 0))
estriado("mando", 0.022, 0.025, 16, 0.002, mat("mando", color=(0.15, 0.16, 0.17), rug=0.5), padre=cons, pos=(0.22, -0.03, -0.1), bisel=0.002).rotation_euler = (math.radians(90), 0, 0)
for k in range(4):
    c = [(0.2, 1.0, 0.4), (0.2, 1.0, 0.4), (1.0, 0.7, 0.1), (0.3, 0.6, 1.0)][k]
    cilindro(f"led{k}", 0.006, 0.006, (-0.25 + k * 0.022, -0.034, -0.125), mat(f"led_{k}", color=c, emision=c, fuerza=2.0),
             lados=10, padre=cons, giro=(math.radians(90), 0, 0))
caja("rejilla_marco", (0.42, 0.012, 0.12), (-0.45, FY - 0.004, ZH + 0.12), gr, bisel=0.006, padre=r)
for i in range(7):
    caja(f"rejilla_lama{i}", (0.38, 0.016, 0.008), (-0.45, FY - 0.008, ZH + 0.075 + i * 0.016), negro, bisel=0.002, padre=r,
         giro=(math.radians(25), 0, 0))
calcomania("placa_logo", 0.18, 0.09, (-0.45, FY - 0.006, ZH + 0.33), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=r)
calcomania("aviso_bio", 0.09, 0.09, (-0.24, FY - 0.006, ZH + 0.33), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r)
for sx in (-1, 1):
    for sz in (-1, 1):
        tornillo(f"torn_frente{sx}{sz}", (-0.45 + sx * 0.25, FY - 0.004, ZH + 0.26 + sz * 0.14), r, r=0.009)
for s in (-1, 1):
    for y in (-0.3, 0.3):
        caja(f"junta_lat{s}{y}", (0.006, 0.008, ZM - ZH - 0.14), (s * 0.851, y, (ZH + ZM) / 2 - 0.03), negro, bisel=0.0, padre=r)

# ------------------------------------------------------------ vaso de mezcla con remolino
VX, VY = -0.08, 0.12
RV = 0.3
Z0, Z1 = ZM + 0.1, ZM + 0.62
torneado("vaso_base", [(0, ZM), (RV + 0.06, ZM), (RV + 0.06, ZM + 0.06), (RV + 0.03, Z0 + 0.01), (0, Z0 + 0.01)], inox, lados=64,
         padre=r, pos=(VX, VY, 0))
for k in range(16):
    a = k * math.tau / 16
    tornillo(f"vaso_base_t{k}", (VX + math.cos(a) * (RV + 0.045), VY + math.sin(a) * (RV + 0.045), ZM + 0.06), r, r=0.009, normal="+Z")
cilindro("vaso", RV, Z1 - Z0, (VX, VY, (Z0 + Z1) / 2), cristal, lados=64, bisel=0.0, padre=r)
torneado("vaso_aro", [(RV - 0.01, Z1 - 0.02), (RV + 0.03, Z1 - 0.02), (RV + 0.03, Z1 + 0.02), (RV - 0.01, Z1 + 0.02)], inox, lados=64,
         padre=r, pos=(VX, VY, 0), cerrar=True)
for k in range(5):
    z = Z0 + 0.06 + k * 0.09
    caja(f"vaso_marca{k}", (0.004, 0.05 if k % 2 == 0 else 0.03, 0.005), (VX + RV * math.cos(-1.2) + 0.002, VY + RV * math.sin(-1.2), z),
         negro, bisel=0.0, padre=r, giro=(0, 0, -1.2))
# líquido: cuerpo que sube y baja (nivel_vaso, origen en el fondo) y superficie con remolino que gira
niv = vacio("nivel_vaso", (VX, VY, Z0 + 0.01), padre=r)
mezcla = mat("caldo_mezcla", color=C_MEZCLA, rug=0.15, emision=C_MEZCLA, fuerza=0.25, alfa=0.7)
H_LIQ = 0.36
torneado("mezcla", [(0, 0), (RV - 0.012, 0), (RV - 0.012, H_LIQ), (RV * 0.6, H_LIQ - 0.03), (RV * 0.25, H_LIQ - 0.09), (0, H_LIQ - 0.13)],
         mezcla, lados=48, padre=niv)
rem = vacio("gira_remolino", (0, 0, 0), padre=niv)
espiral = mat("espuma", color=(0.98, 0.95, 0.85), rug=0.3, alfa=0.7)
for k in range(3):
    pts = []
    for i in range(14):
        u = i / 13
        a = k * math.tau / 3 + u * 4.5
        rr = RV * 0.92 - u * (RV * 0.85)
        z = H_LIQ + 0.002 - (0.13 * (1 - rr / (RV - 0.012)) ** 1.3) if rr < RV * 0.6 else H_LIQ + 0.002 - 0.03 * (1 - (rr - RV * 0.6) / (RV * 0.4))
        pts.append((math.cos(a) * rr, math.sin(a) * rr, z + 0.004))
    tubo_curvo(f"espiral{k}", pts, 0.006, espiral, padre=rem)
# puente con motor y hélice
for s in (-1, 1):
    caja(f"puente_pilar{s}", (0.06, 0.06, 0.32), (VX + s * (RV + 0.1), VY, Z1 + 0.14), inox_osc, bisel=0.01, padre=r)
caja("puente", (2 * RV + 0.3, 0.1, 0.07), (VX, VY, Z1 + 0.31), inox_osc, bisel=0.012, padre=r)
cilindro("motor", 0.09, 0.2, (VX, VY, Z1 + 0.45), ac, lados=32, bisel=0.012, padre=r)
for k in range(12):
    a = k * math.tau / 12
    caja(f"motor_aleta{k}", (0.012, 0.025, 0.15), (VX + math.cos(a) * 0.093, VY + math.sin(a) * 0.093, Z1 + 0.45), ac, bisel=0.003,
         padre=r, giro=(0, 0, a))
cilindro("motor_tapa", 0.085, 0.04, (VX, VY, Z1 + 0.57), gr, lados=32, bisel=0.008, padre=r)
caja("motor_bornes", (0.07, 0.05, 0.06), (VX + 0.1, VY, Z1 + 0.46), gr, bisel=0.008, padre=r)
ag = vacio("agitador", (VX, VY, 0), padre=r)
cilindro("eje", 0.016, Z1 + 0.31 - (Z0 + 0.06), (0, 0, (Z1 + 0.31 + Z0 + 0.06) / 2), inox, lados=12, padre=ag)
for b in range(3):
    a = b * math.tau / 3
    caja(f"helice{b}", (0.11, 0.035, 0.006), (math.cos(a) * 0.06, math.sin(a) * 0.06, Z0 + 0.08), inox, bisel=0.002, padre=ag,
         giro=(math.radians(30), 0, a))
cilindro("helice_cubo", 0.022, 0.03, (0, 0, Z0 + 0.08), inox, lados=12, padre=ag)
manometro("manometro", (VX + RV + 0.07, VY - 0.12, ZM + 0.2), r, r=0.05, normal_giro=(math.radians(90), 0, math.radians(30)))
cilindro("manometro_tubo", 0.008, 0.08, (VX + RV + 0.06, VY - 0.1, ZM + 0.12), inox, lados=8, padre=r)

# ------------------------------------------------------------ dispensador de agua: garrafa invertida en su cuna
GX, GY = -0.6, -0.3
caja("cuna_columna", (0.06, 0.06, 0.62), (GX - 0.12, GY - 0.1, ZM + 0.31), inox_osc, bisel=0.01, padre=r)
caja("cuna_base", (0.26, 0.2, 0.03), (GX, GY, ZM + 0.66), inox_osc, bisel=0.008, padre=r)
for s in (-1, 1):
    for t in (-1, 1):
        caja(f"cuna_barra{s}{t}", (0.018, 0.018, 0.34), (GX + 0.04 + s * 0.11, GY + t * 0.07, ZM + 0.84), inox_osc, bisel=0.004, padre=r)
    caja(f"cuna_aro{s}", (0.24, 0.16, 0.015), (GX + 0.04, GY, ZM + 0.7 + (s + 1) * 0.15), inox_osc, bisel=0.004, padre=r) if s < 0 else None
caja("cuna_aro_sup", (0.25, 0.16, 0.015), (GX + 0.04, GY, ZM + 1.0), inox_osc, bisel=0.004, padre=r)
garr = objetos.garrafa("garrafa", padre=r, pos=(GX + 0.04, GY, ZM + 0.68 + 0.36))
garr.scale = (ESC, ESC, ESC)
garr.rotation_euler = (math.pi, 0, 0)
for ob in list(garr.children):
    if ob.name.startswith("liquido"):
        bpy.data.objects.remove(ob)
# agua propia con el origen abajo (en la boca), para que baje al vaciarse
agua = mat("liq_agua_dep", color=(0.35, 0.65, 0.95), rug=0.15, emision=(0.3, 0.6, 1.0), fuerza=0.25, alfa=0.85)
vac = vacio("vaciar_agua", (GX + 0.04, GY, ZM + 0.72), padre=r)
caja("agua", (0.17, 0.11, 0.24), (0, 0, 0.12), agua, bisel=0.02, segmentos=3, padre=vac)
cilindro("grifo", 0.02, 0.06, (GX + 0.0, GY, ZM + 0.64), inox, lados=16, padre=r)
tubo_curvo("tubo_agua", [(GX, GY, ZM + 0.62), (GX + 0.05, GY - 0.05, ZM + 0.56), (VX - 0.15, VY - 0.08, Z1 + 0.12), (VX - 0.12, VY - 0.08, Z1 + 0.06)],
           0.014, inox, padre=r)
cilindro("caño_agua", 0.016, 0.05, (VX - 0.12, VY - 0.08, Z1 + 0.04), inox, lados=12, padre=r)
cilindro("chorro_agua", 0.008, Z1 - Z0 - 0.2, (VX - 0.12, VY - 0.08, (Z1 + Z0 + 0.25) / 2), mat("chorro_agua_m", color=C_AGUA, rug=0.1, alfa=0.7), lados=10, padre=r)

# ------------------------------------------------------------ dispensador de reactivo: frasco con bomba peristáltica
RX, RY = -0.62, 0.45
caja("estante_reac", (0.3, 0.26, 0.02), (RX, RY, ZM + 0.01), inox_osc, bisel=0.006, padre=r)
fr = objetos.frasco_reactivo("frasco", padre=r, pos=(RX - 0.05, RY, ZM + 0.02))
fr.scale = (ESC, ESC, ESC)
for ob in fr.children:
    if ob.name.startswith("liquido"):
        ob.name = "vaciar_reactivo"
caja("bomba_reac", (0.12, 0.1, 0.14), (RX + 0.1, RY - 0.06, ZM + 0.09), gr, bisel=0.01, padre=r)
gb = vacio("gira_bomba_reac", (RX + 0.1, RY - 0.115, ZM + 0.1), padre=r)
gb.rotation_euler = (math.radians(90), 0, 0)
cilindro("bomba_rotor", 0.04, 0.018, (0, 0, 0), me, lados=20, bisel=0.003, padre=gb)
for j in range(3):
    a = j * math.tau / 3
    cilindro(f"bomba_rodillo{j}", 0.012, 0.026, (math.cos(a) * 0.033, math.sin(a) * 0.033, 0), inox, lados=10, padre=gb)
caja("bomba_tapa", (0.1, 0.008, 0.11), (RX + 0.1, RY - 0.115, ZM + 0.1), mat("cristal_bomba", color=(0.8, 0.88, 0.9), rug=0.1, alfa=0.3), bisel=0.003, padre=r)
silic = mat("silicona", color=(0.9, 0.85, 0.75), rug=0.4, alfa=0.85)
tubo_curvo("tubo_reac_in", [(RX - 0.05, RY, ZM + 0.27), (RX - 0.03, RY - 0.05, ZM + 0.32), (RX + 0.06, RY - 0.12, ZM + 0.16)], 0.007, silic, padre=r)
tubo_curvo("tubo_reac", [(RX + 0.14, RY - 0.12, ZM + 0.14), (RX + 0.25, RY - 0.05, ZM + 0.5), (VX - 0.12, VY + 0.14, Z1 + 0.12), (VX - 0.1, VY + 0.12, Z1 + 0.05)],
           0.007, silic, padre=r)
cilindro("chorro_reactivo", 0.005, Z1 - Z0 - 0.22, (VX - 0.1, VY + 0.12, (Z1 + Z0 + 0.25) / 2), mat("chorro_reac_m", color=C_REAC, rug=0.1, alfa=0.8), lados=8, padre=r)

# ------------------------------------------------------------ llenado de bolsas (delante a la derecha, mirando al frente)
BY = -0.32
for s_ in (-1, 1):
    caja(f"bastidor_poste{s_}", (0.05, 0.05, 0.62), (0.5 + s_ * 0.36, BY + 0.1, ZM + 0.31), inox_osc, bisel=0.008, padre=r)
caja("bastidor_barra", (0.8, 0.05, 0.05), (0.5, BY + 0.1, ZM + 0.62), inox_osc, bisel=0.008, padre=r)
caja("riel_ganchos", (0.66, 0.03, 0.02), (0.5, BY, ZM + 0.6), inox, bisel=0.004, padre=r)
for s_ in (-1, 1):
    caja(f"riel_soporte{s_}", (0.03, 0.12, 0.02), (0.5 + s_ * 0.32, BY + 0.05, ZM + 0.6), inox, bisel=0.004, padre=r)
for k, x in enumerate((0.34, 0.66)):
    cilindro(f"gancho{k}", 0.006, 0.05, (x, BY, ZM + 0.57), inox, lados=8, padre=r)
    toro(f"gancho{k}_curva", 0.012, 0.004, (x, BY, ZM + 0.54), inox, padre=r)
    b = objetos.bolsa_suero(f"bolsa{k}", padre=r, pos=(x, BY, ZM + 0.54 - 0.165 * ESC), lleno=1.0)
    b.scale = (ESC, ESC, ESC)
    for ob in b.children:
        if ob.name.startswith("llenado"):
            ob.name = f"llenar_bolsa{k}"
    zp = ZM + 0.54 - 0.165 * ESC - 0.03
    tubo_curvo(f"tubo_bolsa{k}", [(VX + RV * 0.7, VY - RV * 0.7, ZM + 0.07), (x - 0.06, BY + 0.12, ZM + 0.05), (x - 0.035, BY + 0.02, zp - 0.04), (x - 0.035, BY, zp + 0.02)],
               0.008, silic, padre=r)
    caja(f"pinza{k}", (0.05, 0.05, 0.04), (x - 0.06, BY + 0.12, ZM + 0.05), gr, bisel=0.008, padre=r)
    cilindro(f"pinza{k}_led", 0.006, 0.004, (x - 0.06, BY + 0.094, ZM + 0.06), mat("led_0", color=(0.2, 1.0, 0.4), emision=(0.2, 1.0, 0.4), fuerza=2.0),
             lados=10, padre=r, giro=(math.radians(90), 0, 0))
# selladora: mordaza que baja sobre la soldadura superior y se pone al rojo
sell = vacio("sellar_barra", (0.5, BY, ZM + 0.5), padre=r)
caja("selladora_cuerpo", (0.62, 0.07, 0.05), (0, 0.0, 0.03), gr, bisel=0.01, padre=sell)
caja("selladora_resistencia", (0.6, 0.03, 0.01), (0, 0, 0.0), mat("resistencia", color=(0.3, 0.1, 0.08), rug=0.4, emision=(1.0, 0.25, 0.05), fuerza=0.0), bisel=0.002, padre=sell)
for s_ in (-1, 1):
    cilindro(f"selladora_piston{s_}", 0.012, 0.1, (s_ * 0.28, 0.0, 0.1), inox, lados=12, padre=sell)
calcomania("selladora_aviso", 0.06, 0.06, (0.5, BY + 0.124, ZM + 0.62), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r,
           giro=(math.radians(90), 0, math.radians(180)))
# bandeja de bolsas terminadas junto a la salida
caja("bandeja_salida", (0.34, 0.4, 0.04), (0.6, 0.42, ZM + 0.02), inox, bisel=0.008, padre=r)
for s_ in (-1, 1):
    caja(f"bandeja_borde{s_}", (0.012, 0.4, 0.05), (0.6 + s_ * 0.17, 0.42, ZM + 0.045), inox, bisel=0.003, padre=r)
b2 = objetos.bolsa_suero("bolsa_hecha", padre=r, pos=(0.6, 0.42 - 0.15, ZM + 0.07))
b2.scale = (ESC, ESC, ESC)
b2.rotation_euler = (math.radians(-90), 0, 0)

# ------------------------------------------------------------ trasera, torre y bocas
tubo_curvo("cable_red", [(-0.3, 0.76, ZH + 0.1), (-0.3, 0.82, ZH + 0.04), (-0.4, 0.8, 0.02), (-0.6, 0.66, 0.012)], 0.01, negro, padre=r)
torre_luces((0.18, 0.68, ZM), r, poste=0.24)
puerto_lamas("entrada", -1, -0.85, ZH + 0.25, r, ancho=0.3, alto=0.22, y=-0.1, z_flecha=ZH + 0.002, x_flecha=-0.93)
puerto_lamas("salida", 1, 0.85, ZH + 0.25, r, ancho=0.3, alto=0.22, y=0.4, z_flecha=ZH + 0.002, x_flecha=0.93)

exportar(SALIDA)
print("MEZCLADORA OK")
