"""Centrífuga del rediseño 2.0 (estilo Two Point, R1.2), 2×2 casillas.
Bocas fijas con sentido:
  - Entrada de gradillas por -X, a la altura de la cinta (0,38): boca con cortina de lamas y una tolva inclinada
    donde se ven las gradillas que esperan; un empujador las mete en el tambor.
  - Salida de bolsas de hematíes por +X: rampa con rodillos que deja la bolsa en la cinta.
  - Salida de plasma por -Y (atrás): brida ámbar con mirilla de nivel y volante de válvula.
El tambor tiene cúpula de vidrio con bisagra atrás; dentro, rotor con 6 cestillos oscilantes con gradillas.
Consola delante (+Y) con pantalla viva, seta, palancas y manómetro. Torre de luces.
Nodos animados: rotor (gira Z), cesto0..5 (oscilan), cupula (bisagra X), empujador (X), pantalla, aguja_mano,
baliza_v/a/r, gradilla_tolva0..2 (el juego las enseña según lo que espera), mirilla_nivel (escala Z).
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
Z_CINTA = 0.38

limpiar(); comun._mats.clear()
r = vacio("tp_centrifuga")
menta = mat("tp_menta", color=(0.5, 0.8, 0.7), rug=0.45)
menta_osc = mat("tp_menta_osc", color=(0.32, 0.6, 0.54), rug=0.5)
crema = mat("tp_crema", color=(0.96, 0.94, 0.87), rug=0.5)
naranja = mat("tp_naranja", color=(0.98, 0.56, 0.18), rug=0.4)
grafito = mat("grafito")
cromo = mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.22)
goma = mat("goma")
vid = mat("cristal_cupula", color=(0.78, 0.92, 0.96), rug=0.04, alfa=0.22)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)
ambar = mat("plasma_ambar", color=(0.98, 0.72, 0.22), rug=0.3, alfa=0.85)
sangre = mat("sangre_tubo", color=(0.55, 0.03, 0.05), rug=0.25)
blanco = mat("gradilla_plastico", color=(0.95, 0.95, 0.92), rug=0.55)
tapon = mat("tapon_rojo", color=(0.8, 0.12, 0.12), rug=0.5)


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
            cilindro(nombre + f"_t{i}{j}", 0.0185, 0.13, (x, y, 0.085), sangre, lados=12, bisel=0.003, padre=v)
            cilindro(nombre + f"_p{i}{j}", 0.025, 0.035, (x, y, 0.2), tapon, lados=12, bisel=0.005, padre=v)
    return v


# ------------------------------------------------------------ base y cuerpo redondeado
for sx in (-1, 1):
    for sy in (-1, 1):
        cilindro(f"pie{sx}{sy}", 0.07, 0.03, (sx * 0.72, sy * 0.72, 0.015), goma, lados=24, bisel=0.008, padre=r)
caja("zocalo", (1.86, 1.86, 0.1), (0, 0, 0.08), grafito, bisel=0.05, padre=r)
fp = mat_calcomania("franja_peligro", os.path.join(CAL, "franja_peligro.png"), 0.5)
for s in (-1, 1):
    calcomania(f"franja{s}", 1.4, 0.05, (0, s * 0.935, 0.08), fp, padre=r, giro=(math.radians(90), 0, 0 if s < 0 else math.pi))
caja("cuerpo", (1.36, 1.72, 0.42), (0.17, 0, 0.34), menta, bisel=0.16, segmentos=5, padre=r)
caja("cinto", (1.4, 1.76, 0.07), (0.17, 0, 0.5), naranja, bisel=0.05, segmentos=4, padre=r)
caja("cuerpo_lado", (0.5, 0.86, 0.42), (-0.6, 0.43, 0.34), menta, bisel=0.12, segmentos=4, padre=r)
# rejillas de ventilación y paneles atornillados en los costados
for s in (-1, 1):
    for k in range(7):
        caja(f"rejilla{s}{k}", (0.28, 0.01, 0.018), (0.35, s * 0.862, 0.22 + k * 0.034), menta_osc, bisel=0.004, padre=r)
    caja(f"panel{s}", (0.42, 0.012, 0.26), (-0.35, s * 0.864, 0.33), crema, bisel=0.01, padre=r)
    for sx in (-1, 1):
        for sz in (-1, 1):
            tornillo(f"torn_panel{s}{sx}{sz}", (-0.35 + sx * 0.18, s * 0.872, 0.33 + sz * 0.1), r, r=0.009, normal="+Y" if s > 0 else "-Y")
bio = mat_calcomania("aviso_biorriesgo", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, recorte=True)
calcomania("bio", 0.16, 0.16, (-0.35, 0.872, 0.33), bio, padre=r, giro=(math.radians(90), 0, math.pi))

# ------------------------------------------------------------ tambor y cúpula
cilindro("tambor", 0.62, 0.36, (0.17, 0, 0.72), crema, lados=48, bisel=0.06, segmentos=4, padre=r)
toro("tambor_aro", 0.62, 0.035, (0.17, 0, 0.9), naranja, padre=r)
cilindro("cuba", 0.56, 0.02, (0.17, 0, 0.9), cromo, lados=48, padre=r)
for k in range(16):
    a = k / 16 * math.tau
    tornillo(f"torn_aro{k}", (0.17 + math.cos(a) * 0.64, math.sin(a) * 0.64, 0.86), r, r=0.01, normal="+Z")
rot = vacio("rotor", (0.17, 0, 0.92), r)
cilindro("rotor_eje", 0.08, 0.1, (0, 0, 0.03), cromo, lados=24, bisel=0.01, padre=rot)
for k in range(6):
    a = k / 6 * math.tau
    caja(f"brazo{k}", (0.42, 0.06, 0.03), (math.cos(a) * 0.2, math.sin(a) * 0.2, 0.03), cromo, bisel=0.008, padre=rot, giro=(0, 0, a))
    ces = vacio(f"cesto{k}", (math.cos(a) * 0.4, math.sin(a) * 0.4, 0.04), rot)
    ces.rotation_euler = (0, 0, a + math.pi / 2)
    caja(f"cesto{k}_cuerpo", (0.2, 0.12, 0.13), (0, 0, -0.02), menta_osc, bisel=0.02, padre=ces)
    for s in (-1, 1):
        cilindro(f"cesto{k}_eje{s}", 0.012, 0.03, (s * 0.105, 0, 0.03), cromo, lados=10, padre=ces, giro=(0, math.radians(90), 0))
    for i in range(3):
        cilindro(f"cesto{k}_tubo{i}", 0.017, 0.12, (-0.06 + i * 0.06, 0, 0.05), sangre, lados=12, padre=ces)
        cilindro(f"cesto{k}_tapon{i}", 0.021, 0.025, (-0.06 + i * 0.06, 0, 0.115), tapon, lados=12, padre=ces)
cup = vacio("cupula", (0.17, -0.6, 0.92), r)
esfera("cupula_vidrio", 0.6, (0, 0.6, 0.0), vid, padre=cup, media=True, escala=(1, 1, 0.45))
toro("cupula_aro", 0.6, 0.03, (0, 0.6, 0.005), naranja, padre=cup)
caja("cupula_asa", (0.24, 0.05, 0.05), (0, 1.2, 0.07), naranja, bisel=0.02, padre=cup)
for s in (-1, 1):
    cilindro(f"bisagra{s}", 0.035, 0.12, (s * 0.25, 0.0, 0.02), cromo, lados=16, padre=cup, giro=(0, math.radians(90), 0))

# ------------------------------------------------------------ entrada de gradillas (-X): boca, tolva y empujador
caja("tolva_suelo", (0.46, 0.48, 0.04), (-0.75, -0.5, Z_CINTA - 0.02), cromo, bisel=0.01, padre=r)
for s in (-1, 1):
    caja(f"tolva_pared{s}", (0.46, 0.04, 0.3), (-0.75, -0.5 + s * 0.26, Z_CINTA + 0.13), menta_osc, bisel=0.015, padre=r)
caja("tolva_fondo", (0.04, 0.56, 0.36), (-0.5, -0.5, Z_CINTA + 0.16), menta_osc, bisel=0.015, padre=r)
for k in range(5):
    cilindro(f"tolva_rodillo{k}", 0.015, 0.44, (-0.95 + k * 0.09, -0.5, Z_CINTA - 0.005), cromo, lados=10, padre=r, giro=(math.radians(90), 0, 0))
for k in range(3):
    gradilla(f"gradilla_tolva{k}", (-0.75, -0.5, Z_CINTA + 0.0 + k * 0.215), r, giro=math.pi / 2 if False else 0.0)
caja("boca_entrada_marco", (0.05, 0.62, 0.06), (-0.99, -0.5, Z_CINTA + 0.33), grafito, bisel=0.012, padre=r)
caja("boca_entrada_franja", (0.055, 0.62, 0.02), (-0.99, -0.5, Z_CINTA + 0.37), mat("franja_entra", color=(0.25, 0.9, 0.4), rug=0.4, emision=(0.25, 0.9, 0.4), fuerza=0.8), bisel=0.003, padre=r)
for k in range(8):
    caja(f"boca_entrada_lama{k}", (0.004, 0.06, 0.12), (-0.99, -0.745 + k * 0.07, Z_CINTA + 0.24), mat("lama", color=(0.2, 0.22, 0.24), rug=0.5, alfa=0.7), bisel=0.0, padre=r)
emp = vacio("empujador", (-0.52, -0.5, Z_CINTA + 0.06), r)
caja("empujador_placa", (0.03, 0.3, 0.12), (-0.04, 0, 0.0), naranja, bisel=0.01, padre=emp)
cilindro("empujador_vastago", 0.02, 0.2, (0.08, 0, 0.0), cromo, lados=12, padre=emp, giro=(0, math.radians(90), 0))
chevron("flecha_entrada", (-0.8, -0.5, 0.004), 0.16, mat("amarillo"), r)

# ------------------------------------------------------------ salida de bolsas (+X): rampa con rodillos
caja("rampa_cuerpo", (0.3, 0.5, 0.2), (0.7, 0.5, 0.62), menta, bisel=0.06, segmentos=3, padre=r)
caja("rampa", (0.36, 0.42, 0.03), (0.84, 0.5, 0.47), cromo, bisel=0.008, padre=r, giro=(0, math.radians(18), 0))
for k in range(5):
    cilindro(f"rampa_rodillo{k}", 0.014, 0.38, (0.7 + k * 0.07, 0.5, 0.52 - k * 0.023), cromo, lados=10, padre=r, giro=(math.radians(90), 0, 0))
for s in (-1, 1):
    caja(f"rampa_guia{s}", (0.36, 0.025, 0.06), (0.84, 0.5 + s * 0.22, 0.5), naranja, bisel=0.008, padre=r, giro=(0, math.radians(18), 0))
caja("boca_salida_franja", (0.04, 0.46, 0.025), (0.6, 0.5, 0.75), mat("franja_sale", color=(1.0, 0.55, 0.12), rug=0.4, emision=(1.0, 0.55, 0.12), fuerza=0.8), bisel=0.004, padre=r)
bolsa = vacio("bolsa_saliendo", (0.86, 0.5, 0.52), r)
bolsa.rotation_euler = (0, math.radians(18), 0)
esfera("bolsa_cuerpo", 0.1, (0, 0, 0.02), mat("bolsa_hematies", color=(0.42, 0.02, 0.05), rug=0.2), padre=bolsa, escala=(1.15, 0.78, 0.25))
chevron("flecha_salida", (0.88, 0.5, 0.004), 0.16, mat("amarillo"), r)

# ------------------------------------------------------------ salida de plasma (-Y): brida, mirilla y válvula
caja("toma_cuerpo", (0.36, 0.16, 0.36), (0.5, -0.8, 0.36), crema, bisel=0.06, segmentos=3, padre=r)
cilindro("brida", 0.09, 0.05, (0.5, -0.95, 0.09), cromo, lados=24, bisel=0.006, padre=r, giro=(math.radians(90), 0, 0))
cilindro("brida_color", 0.095, 0.02, (0.5, -0.925, 0.09), ambar, lados=24, padre=r, giro=(math.radians(90), 0, 0))
cilindro("bajante", 0.045, 0.3, (0.5, -0.9, 0.24), mat("tubo_plasma", color=(0.95, 0.65, 0.2), rug=0.35), lados=20, padre=r)
for k in range(8):
    a = k / 8 * math.tau
    tornillo(f"torn_brida{k}", (0.5 + math.cos(a) * 0.07, -0.98, 0.09 + math.sin(a) * 0.07), r, r=0.008, normal="-Y")
caja("mirilla_marco", (0.12, 0.03, 0.26), (0.5, -0.94, 0.42), cromo, bisel=0.01, padre=r)
caja("mirilla_vidrio", (0.08, 0.034, 0.22), (0.5, -0.94, 0.42), vid, bisel=0.0, padre=r)
niv = vacio("mirilla_nivel", (0.5, -0.94, 0.31), r)
caja("mirilla_plasma", (0.07, 0.03, 0.15), (0, 0, 0.075), ambar, bisel=0.0, padre=niv)
vol = vacio("volante", (0.3, -0.95, 0.45), r)
toro("volante_aro", 0.07, 0.012, (0, 0, 0), mat("rojo_zona", color=(0.8, 0.1, 0.1), rug=0.5), padre=vol).rotation_euler = (math.radians(90), 0, 0)
for k in range(3):
    caja(f"volante_radio{k}", (0.14, 0.012, 0.012), (0, 0, 0), mat("rojo_zona"), bisel=0.0, padre=vol, giro=(0, math.radians(k * 60), 0))

# ------------------------------------------------------------ consola delante (+Y)
caja("consola_pie", (0.3, 0.22, 0.5), (-0.5, 0.85, 0.35), crema, bisel=0.06, segmentos=3, padre=r)
caja("consola_tablero", (0.56, 0.32, 0.08), (-0.5, 0.92, 0.66), menta, bisel=0.04, segmentos=3, padre=r, giro=(math.radians(-35), 0, 0))
pan = pantalla_plano("pantalla", 0.4, 0.2, (-0.5, 0.95, 0.71), padre=r, giro=(math.radians(55), 0, math.pi))
cilindro("seta", 0.045, 0.04, (-0.25, 0.93, 0.72), mat("rojo_zona"), lados=24, bisel=0.012, padre=r, giro=(math.radians(-35), 0, 0))
for k in range(2):
    pal = vacio(f"palanca{k}", (-0.72 + k * 0.06, 0.90, 0.7), r)
    cilindro(f"palanca{k}_barra", 0.008, 0.12, (0, 0, 0.06), cromo, lados=8, padre=pal)
    esfera(f"palanca{k}_pomo", 0.022, (0, 0, 0.12), negro, padre=pal)
manometro("mano", (-0.5, 0.83, 0.5), r, r=0.05, normal_giro=(math.radians(90), 0, math.pi))
for k in range(4):
    cilindro(f"led{k}", 0.012, 0.01, (-0.66 + k * 0.05, 0.97, 0.62), mat("led_verde", color=(0.3, 0.90, 0.4), emision=(0.3, 0.90, 0.4), fuerza=3.0),
             lados=10, padre=r, giro=(math.radians(-35), 0, 0))
placa = mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.4)
calcomania("placa", 0.22, 0.08, (0.3, 0.872, 0.27), placa, padre=r, giro=(math.radians(90), 0, math.pi))

# ------------------------------------------------------------ torre de luces y cableado
torre_luces((-0.75, 0.2, 0.55), r)
tubo_curvo("cable", [(-0.5, 0.95, 0.12), (-0.2, 0.9, 0.06), (0.2, 0.86, 0.06), (0.6, 0.8, 0.12)], 0.018, negro, padre=r)

exportar(SALIDA)
print("hecho:", SALIDA)
