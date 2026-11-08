"""Secuenciador detallado (P3.4d), 2×2 casillas.
Armario con cajones; mesa de trabajo de acero con placas de Petri (entrada), placa de 96 pocillos sobre bloque
térmico, caja de puntas, gradilla de eppendorf de ADN (salida) y cubeta de residuos; pórtico cartesiano
(puente en Y, carro en X, cabezal de 8 pipetas en Z) con raíles, cadena portacables y motores; cerramiento de
perfiles de aluminio y cristal con puerta abatible; módulo trasero con pantalla viva, frascos de reactivo A/C/G/T
y torre de luces.
Uso: blender -b -P tools/blender/secuenciador.py -- <salida.glb> <carpeta_texturas>
Nodos animados: puente (se mueve en Y de Blender), carro (X), pipeta (Z), estacion_0..2 (destinos), tapa (puerta),
pantalla, baliza_v/a/r.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun, objetos
importlib.reload(comun); importlib.reload(objetos)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["secuenciador.glb", "."]
SALIDA, TEX = args[0], args[1]
objetos.TEX = os.path.join(TEX, "etiquetas")
CAL = os.path.join(TEX, "calcomanias")
ESC = 2.5
random.seed(11)

limpiar(); comun._mats.clear()
r = vacio("secuenciador")
ch, chos, gr, me, ac = mat("chasis"), mat("chasis_osc"), mat("grafito"), mat("metal"), mat("acento_procesado")
goma = mat("goma")
inox = mat("inox", color=(0.72, 0.74, 0.76), metal=1.0, rug=0.25)
alu = mat("aluminio", color=(0.78, 0.8, 0.82), metal=1.0, rug=0.35)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)
cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.12)

# ------------------------------------------------------------ base
for sx in (-1, 1):
    for sy in (-1, 1):
        x, y = sx * 0.85, sy * 0.85
        cilindro(f"pata{sx}{sy}", 0.05, 0.014, (x, y, 0.007), goma, lados=20, bisel=0.003, padre=r)
        cilindro(f"pata_rosca{sx}{sy}", 0.014, 0.03, (x, y, 0.026), me, lados=12, padre=r)
        cilindro(f"pata_tuerca{sx}{sy}", 0.026, 0.015, (x, y, 0.036), me, lados=6, bisel=0.002, padre=r)
caja("zocalo", (1.96, 1.96, 0.07), (0, 0, 0.075), gr, bisel=0.025, padre=r)
caja("zocalo_goma", (1.97, 1.97, 0.012), (0, 0, 0.044), goma, bisel=0.004, padre=r)
ZH = 0.11
fp = mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5)
for s in (-1, 1):
    calcomania(f"franja{s}", 1.5, 0.04, (0, s * 0.955, ZH + 0.0015), fp, padre=r)

# ------------------------------------------------------------ armario inferior con cajones
AX = 1.6
Y0, Y1 = -0.95, 0.35          # fondo del armario delantero
ZA = 0.78                      # altura de la mesa
caja("armario", (AX, Y1 - Y0, ZA - ZH), (0, (Y0 + Y1) / 2, (ZH + ZA) / 2), ch, bisel=0.05, segmentos=4, padre=r)
caja("franja_familia", (AX + 0.012, Y1 - Y0 + 0.012, 0.05), (0, (Y0 + Y1) / 2, ZA - 0.09), ac, bisel=0.012, padre=r)
FY = Y0 - 0.002
for k, (z, h) in enumerate(((ZH + 0.39, 0.16), (ZH + 0.21, 0.16))):
    caja(f"cajon{k}", (1.1, 0.012, h), (-0.12, FY - 0.004, z), chos, bisel=0.006, padre=r)
    caja(f"cajon{k}_asa", (0.3, 0.03, 0.022), (-0.12, FY - 0.03, z + h / 2 - 0.04), alu, bisel=0.008, padre=r)
    for s in (-1, 1):
        caja(f"cajon{k}_asa_pie{s}", (0.02, 0.03, 0.02), (-0.12 + s * 0.14, FY - 0.016, z + h / 2 - 0.04), alu, bisel=0.004, padre=r)
caja("rejilla_marco", (0.36, 0.012, 0.13), (0.55, FY - 0.004, ZH + 0.12), gr, bisel=0.006, padre=r)
for i in range(7):
    caja(f"rejilla_lama{i}", (0.32, 0.016, 0.008), (0.55, FY - 0.008, ZH + 0.075 + i * 0.016), negro, bisel=0.002, padre=r,
         giro=(math.radians(25), 0, 0))
calcomania("placa_logo", 0.2, 0.1, (0.55, FY - 0.006, ZH + 0.42), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=r)
calcomania("aviso_bio", 0.1, 0.1, (0.55, FY - 0.006, ZH + 0.28), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r)
for sx in (-1, 1):
    for sz in (-1, 1):
        tornillo(f"torn_frente{sx}{sz}", (0.55 + sx * 0.16, FY - 0.004, ZH + 0.35 + sz * 0.13), r, r=0.009)
for s in (-1, 1):
    for y in (-0.5, -0.05):
        caja(f"junta_lat{s}{y}", (0.006, 0.008, ZA - ZH - 0.12), (s * (AX / 2 + 0.001), y, (ZH + ZA) / 2), negro, bisel=0.0, padre=r)

# ------------------------------------------------------------ mesa de trabajo
caja("mesa", (AX - 0.04, Y1 - Y0 - 0.04, 0.025), (0, (Y0 + Y1) / 2, ZA + 0.0125), inox, bisel=0.006, padre=r)
ZM = ZA + 0.025
# rejilla de posiciones grabada en la mesa
for i in range(-3, 4):
    caja(f"mesa_ranura_x{i}", (AX - 0.12, 0.004, 0.002), (0, (Y0 + Y1) / 2 + i * 0.17, ZM + 0.001), mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4), bisel=0.0, padre=r)

# placas de Petri apiladas (entrada)
PX, PY = -0.48, -0.55
for k in range(3):
    p = objetos.petri(f"petri{k}", padre=r, pos=(PX, PY, ZM + k * 0.0145 * ESC), semilla=k + 3)
    p.scale = (ESC, ESC, ESC)
caja("petri_soporte", (0.3, 0.3, 0.012), (PX, PY, ZM + 0.006), gr, bisel=0.004, padre=r)

# bloque térmico con placa de 96 pocillos
BX, BY = 0.0, -0.5
caja("bloque_termico", (0.38, 0.27, 0.06), (BX, BY, ZM + 0.03), alu, bisel=0.008, padre=r)
for i in range(6):
    caja(f"bloque_aleta{i}", (0.39, 0.006, 0.04), (BX, BY - 0.12 + i * 0.048, ZM + 0.02), mat("inox_osc"), bisel=0.0, padre=r)
caja("placa96", (0.33, 0.22, 0.035), (BX, BY, ZM + 0.077), mat("placa_blanca", color=(0.92, 0.93, 0.92), rug=0.4), bisel=0.006, padre=r)
cols_bases = [(0.2, 0.85, 0.35), (0.25, 0.55, 1.0), (1.0, 0.78, 0.15), (1.0, 0.3, 0.3)]
for i in range(12):
    for j in range(8):
        x = BX - 0.33 / 2 + 0.025 + i * 0.0255
        y = BY - 0.22 / 2 + 0.022 + j * 0.0252
        cilindro(f"pozo{i}_{j}", 0.009, 0.01, (x, y, ZM + 0.093), negro, lados=10, bisel=0.0, padre=r)
        if i < 9:
            c = cols_bases[(i + j * 3) % 4]
            m = mat(f"pozo_liq{(i + j * 3) % 4}", color=c, rug=0.2, emision=c, fuerza=0.5)
            cilindro(f"pozo_liq{i}_{j}", 0.0085, 0.004, (x, y, ZM + 0.0975), m, lados=10, bisel=0.0, padre=r)

# caja de puntas de pipeta
TX, TY = 0.48, -0.55
caja("caja_puntas", (0.3, 0.21, 0.07), (TX, TY, ZM + 0.035), mat("caja_puntas", color=(0.2, 0.45, 0.8), rug=0.4), bisel=0.008, padre=r)
caja("caja_puntas_rejilla", (0.29, 0.2, 0.006), (TX, TY, ZM + 0.072), mat("placa_blanca"), bisel=0.002, padre=r)
punta = mat("punta", color=(0.88, 0.9, 0.86), rug=0.35)
for i in range(12):
    for j in range(8):
        if i < 3 and j < 8:
            continue   # ya usadas
        x = TX - 0.29 / 2 + 0.02 + i * 0.0228
        y = TY - 0.2 / 2 + 0.018 + j * 0.0235
        torneado(f"punta{i}_{j}", [(0, 0.0), (0.0025, 0.0), (0.0075, 0.04), (0.009, 0.042), (0.009, 0.05), (0, 0.05)], punta,
                 lados=8, padre=r, pos=(x, y, ZM + 0.05))

# gradilla de eppendorf de ADN (salida)
EX, EY = 0.48, -0.1
caja("gradilla_epp", (0.32, 0.17, 0.05), (EX, EY, ZM + 0.025), mat("gradilla_azul", color=(0.18, 0.42, 0.78), rug=0.45), bisel=0.008, padre=r)
for i in range(5):
    for j in range(2):
        x = EX - 0.12 + i * 0.06
        y = EY - 0.035 + j * 0.07
        cilindro(f"epp_hueco{i}{j}", 0.022, 0.004, (x, y, ZM + 0.051), negro, lados=16, bisel=0.0, padre=r)
        if (i + j) % 3 != 2:
            e = objetos.eppendorf(f"epp{i}{j}", padre=r, pos=(x, y, ZM + 0.015))
            e.scale = (ESC * 0.85, ESC * 0.85, ESC * 0.85)

# cubeta de residuos
caja("residuos", (0.2, 0.2, 0.02), (-0.48, -0.08, ZM + 0.01), gr, bisel=0.006, padre=r)
caja("residuos_boca", (0.15, 0.15, 0.022), (-0.48, -0.08, ZM + 0.012), negro, bisel=0.0, padre=r)
calcomania("residuos_aviso", 0.07, 0.07, (-0.48, -0.2, ZM + 0.0015), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r, giro=(0, 0, 0))

# destinos del cabezal (el juego los lee)
ZP = 1.18   # altura de los raíles
for k, (x, y) in enumerate(((PX, PY), (BX, BY), (EX, EY))):
    vacio(f"estacion_{k}", (x, y, ZM), padre=r)

# ------------------------------------------------------------ pórtico cartesiano
for s in (-1, 1):
    x = s * 0.7
    caja(f"riel{s}", (0.05, Y1 - Y0 - 0.1, 0.04), (x, (Y0 + Y1) / 2, ZP), alu, bisel=0.008, padre=r)
    caja(f"riel{s}_guia", (0.02, Y1 - Y0 - 0.12, 0.012), (x, (Y0 + Y1) / 2, ZP + 0.026), inox, bisel=0.002, padre=r)
    for y in (Y0 + 0.08, Y1 - 0.08):
        caja(f"riel{s}_soporte{y:.2f}", (0.05, 0.05, ZP - ZM - 0.02), (x, y, (ZP + ZM) / 2 - 0.01), alu, bisel=0.006, padre=r)
    # bandeja con cadena portacables
    caja(f"bandeja{s}", (0.06, Y1 - Y0 - 0.2, 0.03), (x + s * 0.06, (Y0 + Y1) / 2, ZP - 0.02), gr, bisel=0.004, padre=r)
    n = 22
    for k in range(n):
        y = Y0 + 0.15 + k * (Y1 - Y0 - 0.3) / (n - 1)
        caja(f"cadena{s}_{k}", (0.045, 0.04, 0.028), (x + s * 0.06, y, ZP + 0.008), mat("cadena", color=(0.12, 0.13, 0.14), rug=0.6),
             bisel=0.006, padre=r)
# motores en el extremo trasero de los raíles
for s in (-1, 1):
    caja(f"motor_y{s}", (0.09, 0.09, 0.09), (s * 0.7, Y1 - 0.02, ZP + 0.02), negro, bisel=0.012, padre=r)
    cilindro(f"motor_y{s}_tapa", 0.03, 0.01, (s * 0.7, Y1 + 0.03, ZP + 0.02), me, lados=16, padre=r, giro=(math.radians(90), 0, 0))

puente = vacio("puente", (0, 0, ZP + 0.04), padre=r)
caja("puente_viga", (1.5, 0.08, 0.07), (0, 0, 0.035), alu, bisel=0.01, padre=puente)
for k in range(-6, 7):
    caja(f"puente_ranura{k}", (0.004, 0.082, 0.04), (k * 0.11, 0, 0.035), mat("inox_osc"), bisel=0.0, padre=puente)
for s in (-1, 1):
    caja(f"puente_patin{s}", (0.08, 0.1, 0.04), (s * 0.7, 0, -0.005), negro, bisel=0.008, padre=puente)
caja("puente_motor", (0.08, 0.08, 0.08), (-0.78, 0, 0.05), negro, bisel=0.012, padre=puente)
caja("puente_franja", (1.0, 0.084, 0.012), (0, 0, 0.068), ac, bisel=0.003, padre=puente)

carro = vacio("carro", (0, 0, 0), padre=puente)
caja("carro_cuerpo", (0.16, 0.14, 0.14), (0, -0.09, 0.02), ch, bisel=0.02, segmentos=3, padre=carro)
caja("carro_frente", (0.12, 0.01, 0.08), (0, -0.162, 0.03), gr, bisel=0.004, padre=carro)
cilindro("carro_led", 0.008, 0.006, (0.04, -0.168, 0.05), mat("led_0", color=(0.2, 1.0, 0.4), emision=(0.2, 1.0, 0.4), fuerza=2.0),
         lados=10, padre=carro, giro=(math.radians(90), 0, 0))
tubo_curvo("carro_cable", [(0.06, -0.02, 0.09), (0.12, 0.02, 0.15), (0.3, 0.03, 0.1)], 0.008, negro, padre=carro)

pipeta = vacio("pipeta", (0, -0.09, -0.06), padre=carro)
caja("pipeta_cuerpo", (0.2, 0.06, 0.1), (0, 0, 0.0), chos, bisel=0.012, padre=pipeta)
caja("pipeta_franja", (0.202, 0.062, 0.015), (0, 0, 0.03), ac, bisel=0.003, padre=pipeta)
for k in range(8):
    x = -0.0875 + k * 0.025
    cilindro(f"canal{k}", 0.006, 0.07, (x, 0, -0.085), inox, lados=10, padre=pipeta)
    torneado(f"canal_punta{k}", [(0, -0.2), (0.0025, -0.2), (0.0075, -0.16), (0.009, -0.158), (0.009, -0.12), (0, -0.12)],
             punta, lados=8, padre=pipeta)
    cilindro(f"canal_liq{k}", 0.004, 0.02, (x, 0, -0.18), mat(f"pozo_liq{k % 4}"), lados=8, padre=pipeta)
# reposicionar las puntas en X (torneado las crea centradas)
for k in range(8):
    ob = bpy.data.objects[f"canal_punta{k}"]
    ob.location.x = -0.0875 + k * 0.025
    bpy.data.objects[f"canal_liq{k}"].location.x = -0.0875 + k * 0.025

# ------------------------------------------------------------ cerramiento de aluminio y cristal
ZC = 1.36       # techo del cerramiento
xs, ys = (-AX / 2 + 0.015, AX / 2 - 0.015), (Y0 + 0.015, Y1 - 0.015)
perfil = 0.03
def barra(n, a, b):
    a, b = Vector(a), Vector(b)
    c = (a + b) / 2
    d = b - a
    tam = (abs(d.x) + perfil, abs(d.y) + perfil, abs(d.z) + perfil)
    caja(n, tam, tuple(c), alu, bisel=0.004, padre=r)
for x in xs:
    for y in ys:
        barra(f"perfil_v{x:.2f}{y:.2f}", (x, y, ZM), (x, y, ZC))
for y in ys:
    barra(f"perfil_sup_x{y:.2f}", (xs[0], y, ZC), (xs[1], y, ZC))
for x in xs:
    barra(f"perfil_sup_y{x:.2f}", (x, ys[0], ZC), (x, ys[1], ZC))
    barra(f"perfil_med_y{x:.2f}", (x, ys[0], ZM + 0.26), (x, ys[1], ZM + 0.26))
# esquineras
for x in xs:
    for y in ys:
        caja(f"esquinera{x:.2f}{y:.2f}", (0.045, 0.045, 0.045), (x, y, ZC), negro, bisel=0.008, padre=r)
# cristales laterales y techo (el frontal es la puerta)
for x in xs:
    caja(f"cristal_lat{x:.2f}", (0.006, ys[1] - ys[0] - perfil, ZC - ZM - perfil), (x, (ys[0] + ys[1]) / 2, (ZM + ZC) / 2), cristal, bisel=0.0, padre=r)
caja("cristal_techo", (xs[1] - xs[0] - perfil, ys[1] - ys[0] - perfil, 0.006), (0, (ys[0] + ys[1]) / 2, ZC), cristal, bisel=0.0, padre=r)
# puerta frontal abatible hacia arriba (bisagra en el canto superior delantero)
tapa = vacio("tapa", (0, ys[0], ZC), padre=r)
alto_p = ZC - ZM - perfil
caja("puerta_cristal", (xs[1] - xs[0] - perfil, 0.006, alto_p), (0, -0.012, -alto_p / 2 - perfil / 2), cristal, bisel=0.0, padre=tapa)
for z in (-perfil / 2 - 0.012, -alto_p - perfil / 2 + 0.012):
    caja(f"puerta_perfil_h{z:.2f}", (xs[1] - xs[0] - perfil, 0.025, 0.025), (0, -0.018, z), alu, bisel=0.004, padre=tapa)
for x in (xs[0] + perfil, xs[1] - perfil):
    caja(f"puerta_perfil_v{x:.2f}", (0.025, 0.025, alto_p), (x, -0.018, -alto_p / 2 - perfil / 2), alu, bisel=0.004, padre=tapa)
cilindro("puerta_asa", 0.012, 0.5, (0, -0.06, -alto_p + 0.05), negro, lados=16, bisel=0.004, padre=tapa, giro=(0, math.radians(90), 0))
for s in (-1, 1):
    caja(f"puerta_asa_pie{s}", (0.02, 0.05, 0.02), (s * 0.23, -0.04, -alto_p + 0.05), alu, bisel=0.004, padre=tapa)
for x in (-0.55, 0.55):
    cilindro(f"bisagra_puerta{x}", 0.012, 0.08, (x, ys[0] - 0.012, ZC), alu, lados=12, padre=r, giro=(0, math.radians(90), 0))
calcomania("puerta_aviso", 0.09, 0.09, (0.6, -0.016, -0.12), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=tapa)

# ------------------------------------------------------------ módulo trasero con pantalla y reactivos
YB0, YB1 = Y1, 0.92
ZB = 1.9
caja("modulo", (AX, YB1 - YB0, ZB - ZH), (0, (YB0 + YB1) / 2, (ZH + ZB) / 2), ch, bisel=0.06, segmentos=4, padre=r)
caja("modulo_franja", (AX + 0.012, YB1 - YB0 + 0.012, 0.05), (0, (YB0 + YB1) / 2, ZA - 0.09), ac, bisel=0.012, padre=r)
caja("modulo_techo", (AX + 0.02, YB1 - YB0 + 0.02, 0.04), (0, (YB0 + YB1) / 2, ZB + 0.02), ac, bisel=0.015, padre=r)
for s in (-1, 1):
    caja(f"modulo_junta{s}", (0.006, 0.008, ZB - ZA - 0.2), (s * (AX / 2 + 0.001), (YB0 + YB1) / 2, (ZA + ZB) / 2), negro, bisel=0.0, padre=r)
# pantalla grande inclinada sobre el cerramiento
pr = vacio("pantalla_raiz", (-0.12, YB0 - 0.02, 1.62), padre=r)
pr.rotation_euler = (math.radians(-14), 0, 0)
caja("pantalla_marco", (1.12, 0.06, 0.46), (0, 0, 0), gr, bisel=0.025, padre=pr)
caja("pantalla_visera", (1.14, 0.1, 0.02), (0, -0.03, 0.235), gr, bisel=0.006, padre=pr)
pantalla_plano("pantalla", 1.04, 0.38, (0, -0.032, 0), padre=pr)
for k in range(4):
    c = [(0.2, 1.0, 0.4), (0.2, 1.0, 0.4), (1.0, 0.7, 0.1), (0.3, 0.6, 1.0)][k]
    cilindro(f"led{k}", 0.007, 0.006, (-0.5 + k * 0.03, -0.034, -0.205), mat(f"led_{k}", color=c, emision=c, fuerza=2.0),
             lados=12, padre=pr, giro=(math.radians(90), 0, 0))
# pulsadores al lado de la pantalla
for k, c in enumerate(((0.1, 0.65, 0.25), (0.75, 0.04, 0.04))):
    cilindro(f"boton_aro{k}", 0.022, 0.01, (0.62, YB0 - 0.005, 1.66 - k * 0.09), me, lados=20, padre=r, giro=(math.radians(90), 0, 0))
    cilindro(f"boton{k}", 0.016, 0.016, (0.62, YB0 - 0.012, 1.66 - k * 0.09), mat(f"boton_{k}", color=c, rug=0.4), lados=20,
             bisel=0.004, padre=r, giro=(math.radians(90), 0, 0))
# frascos de reactivo A/C/G/T en la balda superior con tubos hacia dentro
for k in range(4):
    x = -0.55 + k * 0.17
    c = cols_bases[k]
    torneado(f"frasco{k}", [(0, 0), (0.05, 0), (0.055, 0.005), (0.055, 0.15), (0.03, 0.18), (0.03, 0.2), (0, 0.2)],
             mat("vidrio_frasco", color=(0.8, 0.9, 0.95), rug=0.05, alfa=0.25), lados=24, padre=r, pos=(x, 0.65, ZB + 0.04))
    torneado(f"frasco_liq{k}", [(0, 0.004), (0.048, 0.004), (0.052, 0.008), (0.052, 0.11), (0, 0.11)],
             mat(f"reactivo{k}", color=c, rug=0.2, emision=c, fuerza=0.35), lados=24, padre=r, pos=(x, 0.65, ZB + 0.04))
    cilindro(f"frasco_tapon{k}", 0.034, 0.03, (x, 0.65, ZB + 0.255), mat(f"tapon_reac{k}", color=tuple(v * 0.7 for v in c), rug=0.4), lados=20, bisel=0.004, padre=r)
    tubo_curvo(f"reactivo_tubo{k}", [(x, 0.65, ZB + 0.27), (x, 0.62, ZB + 0.33), (x + 0.02, 0.5, ZB + 0.12), (x + 0.02, 0.48, ZB + 0.04)],
               0.006, mat(f"tubo_reac{k}", color=c, rug=0.3, alfa=0.8), padre=r)
caja("balda_reactivos", (0.75, 0.2, 0.02), (-0.3, 0.65, ZB + 0.05), gr, bisel=0.005, padre=r)
for k in range(5):
    caja(f"balda_tope{k}", (0.01, 0.2, 0.04), (-0.675 + k * 0.17 + 0.085 * 0, 0.65, ZB + 0.07), gr, bisel=0.002, padre=r) if k in (0, 4) else None
# rejilla de ventilación lateral del módulo y cable
for i in range(8):
    caja(f"modulo_rejilla{i}", (0.012, 0.3, 0.012), (AX / 2 + 0.004, 0.64, 1.1 + i * 0.03), negro, bisel=0.002, padre=r)
tubo_curvo("cable_red", [(-0.4, YB1 + 0.01, ZH + 0.12), (-0.4, YB1 + 0.07, ZH + 0.05), (-0.5, YB1 + 0.04, 0.02), (-0.7, YB1 - 0.1, 0.012)],
           0.01, negro, padre=r)
torre_luces((AX / 2 - 0.08, 0.82, ZB + 0.04), r, poste=0.22)

# ------------------------------------------------------------ bocas
puerto_lamas("entrada", -1, -AX / 2, ZH + 0.25, r, ancho=0.3, alto=0.22, y=-0.3, z_flecha=ZH + 0.002, x_flecha=-0.92)
puerto_lamas("salida", 1, AX / 2, ZH + 0.25, r, ancho=0.3, alto=0.22, y=-0.3, z_flecha=ZH + 0.002, x_flecha=0.88)

exportar(SALIDA)
print("SECUENCIADOR OK")
