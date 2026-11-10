"""Envasadora detallada (P3.5c), 2×2 casillas. ADN + suero → caja de vacunas.
Bolsa de suero colgada y gradilla de eppendorf que alimentan una llenadora de viales con carrusel; brazo SCARA que
lleva cada vial a la caja; cinta con rodillos que trae la caja desde el almacén de cajas plegadas, la deja bajo el
brazo y la saca por la salida; la tapa se cierra y una etiquetadora pega la etiqueta. Pantalla viva, barrera de luz,
resguardo de policarbonato, piezas pequeñas.
Uso: blender -b -P tools/blender/envasadora.py -- <salida.glb> <carpeta_texturas>
Nodos animados: mover_caja, aparecer_0..5, tapa_caja, etiquetar, etiqueta_caja, brazo_hombro, brazo_pinza,
vial_en_pinza, gira_*, pantalla, baliza_v/a/r.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun, objetos
importlib.reload(comun); importlib.reload(objetos)
from comun import *

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["envasadora.glb", "."]
SALIDA, TEX = args[0], args[1]
objetos.TEX = os.path.join(TEX, "etiquetas")
CAL = os.path.join(TEX, "calcomanias")
ESC = 2.5

limpiar(); comun._mats.clear()
r = vacio("envasadora")
ch, chos, gr, me, ac = mat("chasis"), mat("chasis_osc"), mat("grafito"), mat("metal"), mat("acento_producto")
inox = mat("inox", color=(0.74, 0.76, 0.78), metal=1.0, rug=0.22)
inox_osc = mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4)
alu = mat("aluminio", color=(0.78, 0.8, 0.82), metal=1.0, rug=0.35)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)
C_VACUNA = (0.85, 0.92, 0.95)

ZH = base_maquina(r, 2.0, CAL)
ZM = 0.6
caja("armario", (1.7, 1.5, ZM - ZH), (0, 0, (ZH + ZM) / 2), ch, bisel=0.05, segmentos=4, padre=r)
caja("franja_familia", (1.712, 1.512, 0.05), (0, 0, ZM - 0.09), ac, bisel=0.012, padre=r)
caja("mesa", (1.66, 1.46, 0.025), (0, 0, ZM + 0.0125), inox, bisel=0.006, padre=r)
ZM += 0.025
FY = -0.752

# ------------------------------------------------------------ cinta con rodillos (delante, a lo largo de X)
CY = -0.38
ZC = ZM + 0.09
for s in (-1, 1):
    caja(f"cinta_lateral{s}", (1.66, 0.025, 0.09), (0, CY + s * 0.13, ZM + 0.045), alu, bisel=0.006, padre=r)
    caja(f"cinta_guia{s}", (1.6, 0.012, 0.03), (0, CY + s * 0.115, ZC + 0.03), mat("guia_azul", color=(0.15, 0.4, 0.8), rug=0.4), bisel=0.003, padre=r)
for k in range(30):
    x = -0.8 + k * 0.055
    g = vacio(f"gira_rodillo{k}", (x, CY, ZC - 0.012), padre=r)
    g.rotation_euler = (math.radians(90), 0, 0)      # eje del rodillo a lo largo de Y
    cilindro(f"rodillo{k}", 0.022, 0.23, (0, 0, 0), inox, lados=16, bisel=0.003, padre=g)
    caja(f"rodillo{k}_marca", (0.006, 0.006, 0.2), (0, 0.021, 0), negro, bisel=0.0, padre=g)
for x in (-0.82, 0.82):
    caja(f"cinta_pata{x}", (0.04, 0.24, 0.02), (x, CY, ZM + 0.01), alu, bisel=0.004, padre=r)
caja("cinta_motor", (0.12, 0.1, 0.1), (0.8, CY + 0.2, ZM + 0.05), negro, bisel=0.012, padre=r)
# barrera de luz a la entrada de la zona de envasado
for x in (-0.3, 0.32):
    for s in (-1, 1):
        caja(f"barrera{x}{s}", (0.03, 0.03, 0.3), (x, CY + s * 0.16, ZM + 0.15), gr, bisel=0.006, padre=r)
        for k in range(6):
            cilindro(f"barrera_led{x}{s}{k}", 0.005, 0.004, (x, CY + s * 0.16 - s * 0.016, ZM + 0.06 + k * 0.04),
                     mat("led_rojo", color=(1, 0.15, 0.1), emision=(1, 0.15, 0.1), fuerza=2.5), lados=8, padre=r,
                     giro=(math.radians(90), 0, 0))
# almacén de cajas plegadas a la izquierda
for k in range(6):
    caja(f"plegada{k}", (0.27, 0.19, 0.008), (-0.68, CY, ZC + 0.12 + k * 0.01), mat("carton", color=(0.94, 0.94, 0.91), rug=0.85), bisel=0.001, padre=r)
for sx in (-1, 1):
    for sy in (-1, 1):
        caja(f"almacen_guia{sx}{sy}", (0.015, 0.015, 0.2), (-0.68 + sx * 0.145, CY + sy * 0.105, ZC + 0.12), alu, bisel=0.003, padre=r)
# caja que viaja por la cinta, con 6 viales que aparecen, tapa y etiqueta
mov = vacio("mover_caja", (0.0, CY, ZC), padre=r)
cj = objetos.caja_vacunas("caja", padre=mov, pos=(0, 0, 0), abierta=True, con_viales=True)
cj.scale = (ESC, ESC, ESC)
k = 0
for ob in list(cj.children):
    if ob.name.startswith("vacuna"):
        ob.name = f"aparecer_{k}"
        k += 1
etq = calcomania("etiqueta_caja", 0.13, 0.065, (0.0, -0.0865, 0.06), mat_imagen("etq_vacuna", os.path.join(TEX, "etiquetas", "adn.png"), 0.6), padre=mov)

# ------------------------------------------------------------ etiquetadora sobre la zona de envasado
for s in (-1, 1):
    caja(f"etiq_poste{s}", (0.04, 0.04, 0.5), (0.2, CY + s * 0.2, ZM + 0.25), alu, bisel=0.006, padre=r)
caja("etiq_puente", (0.06, 0.46, 0.05), (0.2, CY, ZM + 0.5), alu, bisel=0.008, padre=r)
caja("etiq_cuerpo", (0.2, 0.16, 0.14), (0.2, CY + 0.08, ZM + 0.42), ch, bisel=0.02, segmentos=3, padre=r)
cilindro("etiq_rollo", 0.06, 0.04, (0.2, CY + 0.18, ZM + 0.46), mat("rollo_etiquetas", color=(0.95, 0.95, 0.9), rug=0.6), lados=24, padre=r,
         giro=(math.radians(90), 0, 0))
cilindro("etiq_rollo_nucleo", 0.025, 0.045, (0.2, CY + 0.18, ZM + 0.46), negro, lados=16, padre=r, giro=(math.radians(90), 0, 0))
et = vacio("etiquetar", (0.0, CY, ZM + 0.34), padre=r)
caja("etiq_cabezal", (0.13, 0.08, 0.04), (0, 0, 0), gr, bisel=0.008, padre=et)
caja("etiq_almohadilla", (0.12, 0.07, 0.012), (0, 0, -0.026), mat("goma"), bisel=0.003, padre=et)
cilindro("etiq_piston", 0.012, 0.12, (0, 0, 0.08), inox, lados=12, padre=et)

# ------------------------------------------------------------ alimentación: bolsa de suero colgada y gradilla de eppendorf
pole = (-0.78, 0.62)
cilindro("pie_gotero", 0.012, 0.95, (pole[0], pole[1], ZM + 0.475), inox, lados=12, padre=r)
for k in range(5):
    a = k * math.tau / 5
    caja(f"pie_gotero_pata{k}", (0.12, 0.012, 0.012), (pole[0] + math.cos(a) * 0.06, pole[1] + math.sin(a) * 0.06, ZM + 0.01), inox, bisel=0.002, padre=r,
         giro=(0, 0, a))
caja("gotero_brazo", (0.16, 0.012, 0.012), (pole[0] + 0.07, pole[1], ZM + 0.94), inox, bisel=0.002, padre=r)
b = objetos.bolsa_suero("bolsa", padre=r, pos=(pole[0] + 0.14, pole[1], ZM + 0.93 - 0.165 * ESC))
b.scale = (ESC, ESC, ESC)
for ob in b.children:
    if ob.name.startswith("llenado"):
        ob.name = "vaciar_suero"
caja("gradilla_epp", (0.2, 0.14, 0.05), (-0.72, 0.2, ZM + 0.025), mat("gradilla_azul", color=(0.18, 0.42, 0.78), rug=0.45), bisel=0.008, padre=r)
for i in range(3):
    for j in range(2):
        e = objetos.eppendorf(f"epp{i}{j}", padre=r, pos=(-0.78 + i * 0.06, 0.17 + j * 0.06, ZM + 0.015))
        e.scale = (ESC * 0.8, ESC * 0.8, ESC * 0.8)

# ------------------------------------------------------------ llenadora de viales con carrusel
KX, KY = -0.56, 0.5
cilindro("carrusel_base", 0.22, 0.06, (KX, KY, ZM + 0.03), gr, lados=40, bisel=0.01, padre=r)
car = vacio("gira_carrusel", (KX, KY, ZM + 0.06), padre=r)
torneado("carrusel_estrella", [(0, 0), (0.2, 0), (0.2, 0.025), (0, 0.025)], inox, lados=48, padre=car)
for k in range(8):
    a = k * math.tau / 8
    x, y = math.cos(a) * 0.16, math.sin(a) * 0.16
    cilindro(f"carrusel_hueco{k}", 0.026, 0.004, (x, y, 0.026), negro, lados=16, padre=car)
    v = objetos.vial(f"vial_carrusel{k}", padre=car, pos=(x, y, 0.025), color=C_VACUNA)
    v.scale = (ESC * 0.62, ESC * 0.62, ESC * 0.62)
cilindro("carrusel_eje", 0.03, 0.12, (KX, KY, ZM + 0.12), inox_osc, lados=16, padre=r)
# cabezal de llenado con dos agujas (ADN y suero) sobre el carrusel
caja("llenado_columna", (0.05, 0.05, 0.45), (KX - 0.2, KY + 0.12, ZM + 0.225), alu, bisel=0.006, padre=r)
caja("llenado_brazo", (0.24, 0.05, 0.05), (KX - 0.08, KY + 0.12, ZM + 0.43), alu, bisel=0.006, padre=r)
caja("llenado_cabezal", (0.09, 0.08, 0.1), (KX + 0.04, KY + 0.08, ZM + 0.39), ac, bisel=0.012, padre=r)
for s in (-1, 1):
    cilindro(f"llenado_aguja{s}", 0.005, 0.08, (KX + 0.04 + s * 0.02, KY + 0.08, ZM + 0.31), inox, lados=8, padre=r)
silic = mat("silicona", color=(0.9, 0.85, 0.75), rug=0.4, alfa=0.85)
tubo_curvo("tubo_suero", [(pole[0] + 0.14, pole[1], ZM + 0.93 - 0.165 * ESC - 0.05), (pole[0] + 0.2, pole[1] - 0.05, ZM + 0.5),
                          (KX + 0.02, KY + 0.12, ZM + 0.5), (KX + 0.02, KY + 0.08, ZM + 0.44)], 0.007, silic, padre=r)
tubo_curvo("tubo_adn", [(-0.72, 0.2, ZM + 0.1), (-0.65, 0.25, ZM + 0.35), (KX + 0.06, KY + 0.12, ZM + 0.5), (KX + 0.06, KY + 0.08, ZM + 0.44)],
           0.006, mat("tubo_adn", color=(0.3, 1.0, 0.45), rug=0.3, emision=(0.3, 1.0, 0.45), fuerza=0.5, alfa=0.85), padre=r)

# ------------------------------------------------------------ brazo SCARA
BX, BY = -0.1, 0.1
L = 0.45
cilindro("brazo_base", 0.09, 0.05, (BX, BY, ZM + 0.025), gr, lados=32, bisel=0.01, padre=r)
cilindro("brazo_columna", 0.06, 0.32, (BX, BY, ZM + 0.21), ch, lados=32, bisel=0.012, padre=r)
cilindro("brazo_columna_aro", 0.065, 0.03, (BX, BY, ZM + 0.32), ac, lados=32, bisel=0.006, padre=r)
hom = vacio("brazo_hombro", (BX, BY, ZM + 0.38), padre=r)
cilindro("hombro_motor", 0.07, 0.08, (0, 0, 0), negro, lados=32, bisel=0.01, padre=hom)
caja("brazo_viga", (L, 0.08, 0.06), (L / 2, 0, 0.02), ch, bisel=0.02, segmentos=3, padre=hom)
caja("brazo_franja", (L * 0.7, 0.082, 0.012), (L / 2, 0, 0.045), ac, bisel=0.003, padre=hom)
cilindro("codo", 0.05, 0.08, (L, 0, 0.0), negro, lados=24, bisel=0.008, padre=hom)
tubo_curvo("brazo_cable", [(0.02, 0.03, 0.06), (L * 0.5, 0.05, 0.12), (L - 0.02, 0.03, 0.06)], 0.01, negro, padre=hom)
pin = vacio("brazo_pinza", (L, 0, -0.04), padre=hom)
cilindro("pinza_vastago", 0.012, 0.16, (0, 0, -0.06), inox, lados=12, padre=pin)
caja("pinza_cuerpo", (0.05, 0.04, 0.03), (0, 0, -0.14), gr, bisel=0.006, padre=pin)
for s in (-1, 1):
    caja(f"pinza_dedo{s}", (0.008, 0.015, 0.04), (s * 0.018, 0, -0.17), inox, bisel=0.002, padre=pin)
vp = objetos.vial("vial_en_pinza", padre=pin, pos=(0, 0, -0.24), color=C_VACUNA)
vp.scale = (ESC * 0.62, ESC * 0.62, ESC * 0.62)

# ------------------------------------------------------------ resguardo trasero de policarbonato
for x in (-0.84, 0.84):
    caja(f"resguardo_perfil{x}", (0.03, 0.03, 0.55), (x, 0.73, ZM + 0.275), alu, bisel=0.004, padre=r)
caja("resguardo_perfil_sup", (1.71, 0.03, 0.03), (0, 0.73, ZM + 0.55), alu, bisel=0.004, padre=r)
caja("resguardo", (1.65, 0.008, 0.5), (0, 0.73, ZM + 0.27), mat("cristal_policarbonato", color=(0.8, 0.85, 0.9), rug=0.15, alfa=0.2), bisel=0.0, padre=r)
calcomania("resguardo_aviso", 0.08, 0.08, (0.5, 0.725, ZM + 0.4), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r)

# ------------------------------------------------------------ consola frontal, placa, rejilla
cons = vacio("consola", (0.45, FY - 0.03, ZM - 0.22), padre=r)
cons.rotation_euler = (math.radians(-12), 0, 0)
caja("consola_cuerpo", (0.58, 0.06, 0.28), (0, 0, 0), gr, bisel=0.015, padre=cons)
caja("pantalla_bisel", (0.4, 0.004, 0.23), (-0.06, -0.031, 0.01), negro, bisel=0.002, padre=cons)
pantalla_plano("pantalla", 0.37, 0.2, (-0.06, -0.036, 0.01), padre=cons)
cilindro("seta_aro", 0.033, 0.01, (0.2, -0.033, 0.05), mat("amarillo"), lados=24, bisel=0.002, padre=cons, giro=(math.radians(90), 0, 0))
esfera("seta", 0.026, (0.2, -0.045, 0.05), mat("seta_roja", color=(0.75, 0.04, 0.04), rug=0.35), padre=cons)
for k, c in enumerate(((0.1, 0.65, 0.25), (0.15, 0.15, 0.16))):
    cilindro(f"boton{k}", 0.013, 0.014, (0.18 + k * 0.04, -0.036, -0.06), mat(f"boton_{k}", color=c, rug=0.4), lados=16,
             bisel=0.003, padre=cons, giro=(math.radians(90), 0, 0))
calcomania("placa_logo", 0.18, 0.09, (-0.4, FY - 0.006, ZH + 0.33), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=r)
calcomania("aviso_bio", 0.09, 0.09, (-0.19, FY - 0.006, ZH + 0.33), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r)
calcomania("aviso_rotor", 0.09, 0.09, (-0.08, FY - 0.006, ZH + 0.33), mat_calcomania("aviso_rotor", os.path.join(CAL, "aviso_rotor.png"), 0.5, True), padre=r)
caja("rejilla_marco", (0.42, 0.012, 0.12), (-0.4, FY - 0.004, ZH + 0.12), gr, bisel=0.006, padre=r)
for i in range(7):
    caja(f"rejilla_lama{i}", (0.38, 0.016, 0.008), (-0.4, FY - 0.008, ZH + 0.075 + i * 0.016), negro, bisel=0.002, padre=r, giro=(math.radians(25), 0, 0))
for sx in (-1, 1):
    for sz in (-1, 1):
        tornillo(f"torn_frente{sx}{sz}", (-0.3 + sx * 0.33, FY - 0.004, ZH + 0.26 + sz * 0.15), r, r=0.009)

tubo_curvo("cable_red", [(0.3, 0.76, ZH + 0.1), (0.3, 0.82, ZH + 0.04), (0.4, 0.8, 0.02), (0.6, 0.66, 0.012)], 0.01, negro, padre=r)
torre_luces((0.76, 0.62, ZM), r, poste=0.24)
bocas_estandar(r, 2, (0, 1), 1)

exportar(SALIDA)
print("ENVASADORA OK")
