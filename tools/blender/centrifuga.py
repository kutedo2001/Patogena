"""Centrífuga detallada (P3.4c), 1×1 casilla. Rotor de ángulo fijo con 6 tubos de sangre (a escala de juego 2,5×),
tapa con ventana y bisagra, consola con pantalla viva, seta de emergencia, botonera, rejillas, tornillería,
pegatinas, puertos con cortina de lamas, cable de red y torre de luces.
Uso: blender -b -P tools/blender/centrifuga.py -- <salida.glb> <carpeta_texturas>
Nodos animados: rotor (gira en Z), tapa (gira en X sobre la bisagra), baliza_v/a/r, pantalla, leds.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun, objetos
importlib.reload(comun); importlib.reload(objetos)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["centrifuga.glb", "."]
SALIDA, TEX = args[0], args[1]
objetos.TEX = os.path.join(TEX, "etiquetas")
CAL = os.path.join(TEX, "calcomanias")
ESC = 2.5   # escala de juego de los productos

limpiar(); comun._mats.clear()
r = vacio("centrifuga")
ch, chos, gr, me, ac = mat("chasis"), mat("chasis_osc"), mat("grafito"), mat("metal"), mat("acento_procesado")
goma = mat("goma")
inox = mat("inox", color=(0.72, 0.74, 0.76), metal=1.0, rug=0.22)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)

# ------------------------------------------------------------ base, patas y zócalo
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * 0.4, sy * 0.4
        cilindro(f"pata{sx}{sy}", 0.04, 0.012, (x, y, 0.006), goma, lados=20, bisel=0.003, padre=r)
        cilindro(f"pata_rosca{sx}{sy}", 0.012, 0.03, (x, y, 0.025), me, lados=12, padre=r)
        cilindro(f"pata_tuerca{sx}{sy}", 0.022, 0.014, (x, y, 0.035), me, lados=6, bisel=0.002, padre=r)
caja("zocalo", (0.96, 0.96, 0.07), (0, 0, 0.075), gr, bisel=0.02, padre=r)
caja("zocalo_goma", (0.97, 0.97, 0.012), (0, 0, 0.044), goma, bisel=0.004, padre=r)
ZH = 0.11
# franjas de peligro junto a las bocas
fp = mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5)
for s in (-1, 1):   # franja de peligro en el canto delantero y trasero del zócalo
    calcomania(f"franja{s}", 0.7, 0.035, (0, s * 0.475, ZH + 0.0015), fp, padre=r, giro=(0, 0, 0))

# ------------------------------------------------------------ armario
AX, AY, AZ = 0.74, 0.86, 0.55          # medidas del armario
Z0 = ZH
caja("armario", (AX, AY, AZ), (0, 0, Z0 + AZ / 2), ch, bisel=0.05, segmentos=4, padre=r)
# juntas de los paneles laterales (ranuras oscuras)
for s in (-1, 1):
    for y in (-0.2, 0.2):
        caja(f"junta_lat{s}{y}", (0.006, 0.008, AZ - 0.1), (s * (AX / 2 + 0.001), y, Z0 + AZ / 2), negro, bisel=0.0, padre=r)
# franja de color de familia alrededor
caja("franja_familia", (AX + 0.012, AY + 0.012, 0.05), (0, 0, Z0 + AZ - 0.11), ac, bisel=0.012, padre=r)
caja("franja_filo", (AX + 0.014, AY + 0.014, 0.006), (0, 0, Z0 + AZ - 0.083), gr, bisel=0.0, padre=r)
# frontal: rejilla de ventilación, panel de servicio con tornillos, placa y pegatinas
FY = -AY / 2 - 0.002
caja("rejilla_marco", (0.5, 0.012, 0.12), (0, FY - 0.004, Z0 + 0.1), gr, bisel=0.006, padre=r)
for i in range(7):
    caja(f"rejilla_lama{i}", (0.46, 0.016, 0.008), (0, FY - 0.008, Z0 + 0.05 + i * 0.016), negro, bisel=0.002, padre=r,
         giro=(math.radians(25), 0, 0))
caja("panel_servicio", (0.56, 0.006, 0.24), (0, FY - 0.001, Z0 + 0.32), chos, bisel=0.004, padre=r)
for sx in (-1, 1):
    for sz in (-1, 1):
        tornillo(f"tornillo_serv{sx}{sz}", (sx * 0.25, FY - 0.004, Z0 + 0.32 + sz * 0.1), r, r=0.009, normal="-Y")
calcomania("placa_logo", 0.16, 0.08, (-0.14, FY - 0.006, Z0 + 0.34), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=r)
calcomania("aviso_bio", 0.09, 0.09, (0.09, FY - 0.006, Z0 + 0.34), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r)
calcomania("aviso_rotor", 0.09, 0.09, (0.2, FY - 0.006, Z0 + 0.34), mat_calcomania("aviso_rotor", os.path.join(CAL, "aviso_rotor.png"), 0.5, True), padre=r)

# ------------------------------------------------------------ cubierta y cuba
ZT = Z0 + AZ                            # 0.66
caja("cubierta", (AX + 0.02, AY + 0.02, 0.035), (0, 0, ZT + 0.0175), gr, bisel=0.012, padre=r)
CY = 0.07                               # centro de la cuba (algo hacia atrás: delante va la consola)
RC = 0.37
# cuba de acero: pared exterior crema con aro azul, interior inox profundo
torneado("cuba_carcasa", [(RC - 0.01, ZT + 0.035), (RC + 0.03, ZT + 0.035), (RC + 0.03, ZT + 0.32),
                          (RC + 0.015, ZT + 0.34), (RC - 0.005, ZT + 0.34)], ch, lados=64, padre=r, pos=(0, CY, 0), cerrar=True)
toro("cuba_aro", RC + 0.031, 0.014, (0, CY, ZT + 0.2), ac, padre=r)
toro("cuba_aro2", RC + 0.031, 0.008, (0, CY, ZT + 0.06), gr, padre=r)
torneado("cuba_interior", [(RC - 0.005, ZT + 0.34), (RC - 0.03, ZT + 0.31), (RC - 0.03, ZT + 0.08), (RC - 0.06, ZT + 0.05),
                           (0, ZT + 0.05)], inox, lados=64, padre=r, pos=(0, CY, 0))
# junta tórica de la tapa
toro("cuba_junta", RC + 0.005, 0.01, (0, CY, ZT + 0.342), goma, padre=r)

# ------------------------------------------------------------ rotor de ángulo fijo con 6 tubos
rot = vacio("rotor", (0, CY, ZT + 0.15), padre=r)
torneado("rotor_cuerpo", [(0, -0.09), (0.27, -0.09), (0.3, -0.07), (0.29, -0.02), (0.18, 0.06), (0.09, 0.075), (0, 0.075)],
         mat("rotor_aluminio", color=(0.6, 0.63, 0.67), metal=1.0, rug=0.3), lados=64, padre=rot)
cilindro("rotor_eje", 0.04, 0.06, (0, 0, 0.1), inox, lados=24, padre=rot)
estriado("rotor_tuerca", 0.055, 0.04, 14, 0.005, me, padre=rot, pos=(0, 0, 0.075), bisel=0.002)
cilindro("rotor_tuerca_tapa", 0.03, 0.012, (0, 0, 0.12), mat("tapon_tuerca", color=(0.13, 0.5, 0.75), rug=0.4), lados=24, padre=rot)
INC = math.radians(22)
for i in range(6):
    a = i * math.tau / 6
    # hueco del tubo (anillo oscuro donde entra) y tubo inclinado hacia el centro
    rr = 0.225
    hx, hy = math.cos(a) * rr, math.sin(a) * rr
    hueco = vacio(f"hueco{i}", (hx, hy, 0.03), padre=rot)
    hueco.rotation_euler = (0, -INC, a)
    cilindro(f"hueco_aro{i}", 0.038, 0.012, (0, 0, 0.0), negro, lados=24, bisel=0.002, padre=hueco)
    tipo = "sangre" if i % 2 == 0 else "plasma"
    t = objetos.tubo(f"tubo{i}", padre=hueco, pos=(0, 0, -0.07), tipo=tipo, con_etiqueta=True)
    t.scale = (ESC, ESC, ESC)

# ------------------------------------------------------------ tapa con bisagra
HY, HZ = CY + RC + 0.05, ZT + 0.35      # eje de la bisagra (detrás)
tapa = vacio("tapa", (0, HY, HZ), padre=r)
TZ = 0.0
# aro metálico de la tapa y cúpula de cristal
torneado("tapa_aro", [(RC - 0.035, -0.006), (RC + 0.04, -0.006), (RC + 0.045, 0.025), (RC + 0.02, 0.045), (RC - 0.035, 0.045)],
         gr, lados=64, padre=tapa, pos=(0, CY - HY, 0), cerrar=True)
esfera("tapa_cupula", RC - 0.03, (0, CY - HY, 0.04), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.12),
       padre=tapa, media=True, escala=(1, 1, 0.38))
toro("tapa_junta_cristal", RC - 0.033, 0.01, (0, CY - HY, 0.044), negro, padre=tapa)
# asa delantera
for s in (-1, 1):
    caja(f"asa_pie{s}", (0.025, 0.03, 0.04), (s * 0.09, CY - HY - RC - 0.02, 0.03), gr, bisel=0.006, padre=tapa)
cilindro("asa", 0.014, 0.2, (0, CY - HY - RC - 0.035, 0.05), mat("goma_asa", color=(0.12, 0.13, 0.14), rug=0.6),
         lados=16, bisel=0.004, padre=tapa, giro=(0, math.radians(90), 0))
# pestillo
caja("pestillo", (0.06, 0.025, 0.03), (0, CY - HY - RC - 0.008, -0.01), me, bisel=0.006, padre=tapa)
# brazos de la bisagra en la tapa
for s in (-1, 1):
    caja(f"brazo_bisagra{s}", (0.04, 0.09, 0.02), (s * 0.18, -0.045, 0.012), chos, bisel=0.006, padre=tapa)
# bisagra fija: nudillos y pasador
for k, x in enumerate((-0.24, -0.12, 0.12, 0.24)):
    cilindro(f"bisagra_nudillo{k}", 0.018, 0.06, (x, HY, HZ), gr if k % 3 == 0 else me, lados=16, bisel=0.003,
             padre=r, giro=(0, math.radians(90), 0))
    caja(f"bisagra_soporte{k}", (0.06, 0.04, 0.05), (x, HY + 0.01, HZ - 0.03), gr, bisel=0.006, padre=r)
cilindro("bisagra_pasador", 0.008, 0.52, (0, HY, HZ), inox, lados=12, padre=r, giro=(0, math.radians(90), 0))
# amortiguador de gas al lado derecho
tubo_curvo("amortiguador_cuerpo", [(0.36, HY - 0.06, ZT + 0.06), (0.36, HY - 0.03, ZT + 0.3)], 0.012, gr, padre=r)

# ------------------------------------------------------------ consola delantera
cons = vacio("consola", (0, -AY / 2 + 0.07, ZT + 0.035), padre=r)
cons.rotation_euler = (math.radians(32), 0, 0)
caja("consola_cuerpo", (0.64, 0.14, 0.04), (0, 0, 0.02), gr, bisel=0.012, padre=cons)
caja("consola_bisel", (0.36, 0.11, 0.008), (-0.1, 0, 0.042), negro, bisel=0.003, padre=cons)
pantalla_plano("pantalla", 0.33, 0.1, (-0.1, 0, 0.047), padre=cons, giro=(0, 0, 0))
# seta de emergencia sobre aro amarillo
cilindro("seta_aro", 0.04, 0.008, (0.21, 0.005, 0.044), mat("amarillo"), lados=24, bisel=0.002, padre=cons)
cilindro("seta_cuello", 0.016, 0.02, (0.21, 0.005, 0.055), gr, lados=16, padre=cons)
esfera("seta", 0.032, (0.21, 0.005, 0.062), mat("seta_roja", color=(0.75, 0.04, 0.04), rug=0.35), padre=cons,
       media=True, escala=(1, 1, 0.55))
# botones de marcha y paro, mando moleteado y leds
for k, (x, c) in enumerate(((0.1, (0.1, 0.65, 0.25)), (0.14, (0.15, 0.15, 0.16)))):
    cilindro(f"boton_aro{k}", 0.016, 0.006, (x, -0.03, 0.043), me, lados=20, bisel=0.001, padre=cons)
    cilindro(f"boton{k}", 0.012, 0.012, (x, -0.03, 0.05), mat(f"boton_{k}", color=c, rug=0.4), lados=20, bisel=0.003, padre=cons)
estriado("mando", 0.02, 0.022, 16, 0.002, mat("mando", color=(0.15, 0.16, 0.17), rug=0.5), padre=cons, pos=(0.12, 0.035, 0.04), bisel=0.002)
cilindro("mando_marca", 0.003, 0.004, (0.12, 0.05, 0.063), mat("amarillo"), lados=8, padre=cons)
for k in range(4):
    c = [(0.2, 1.0, 0.4), (0.2, 1.0, 0.4), (1.0, 0.7, 0.1), (1.0, 0.2, 0.15)][k]
    cilindro(f"led{k}", 0.006, 0.006, (-0.27 + k * 0.024, 0.045, 0.044), mat(f"led_{k}", color=c, emision=c, fuerza=2.0 if k < 2 else 0.2),
             lados=12, padre=cons)

# ------------------------------------------------------------ bocas con cortina de lamas
bocas_estandar(r, 1, (0,), 0)

# ------------------------------------------------------------ trasera: ventilador, cable y torre de luces
BY = AY / 2 + 0.002
toro("ventilador_aro", 0.09, 0.01, (0.15, BY, Z0 + 0.3), gr, padre=r).rotation_euler = (math.radians(90), 0, 0)
for k in range(4):
    caja(f"ventilador_reja{k}", (0.17, 0.006, 0.008), (0.15, BY + 0.004, Z0 + 0.3), gr, bisel=0.0, padre=r,
         giro=(0, k * math.pi / 4, 0))
caja("enchufe_caja", (0.08, 0.03, 0.06), (-0.2, BY + 0.012, Z0 + 0.12), gr, bisel=0.008, padre=r)
tubo_curvo("cable_red", [(-0.2, BY + 0.03, Z0 + 0.12), (-0.2, BY + 0.1, Z0 + 0.05), (-0.25, BY + 0.06, 0.02), (-0.4, BY - 0.1, 0.012)],
           0.009, negro, padre=r)
torre_luces((AX / 2 - 0.06, AY / 2 - 0.06, ZT + 0.035), r, poste=0.2)

exportar(SALIDA)
print("CENTRIFUGA OK")
