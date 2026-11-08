"""Lote 1 de máquinas (P3.4): centrífuga 1×1, secuenciador 2×2, biorreactor 2×2.
Uso: blender -b -P tools/blender/maquinas_lote1.py -- <carpeta_salida>
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

salida = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."
os.makedirs(salida, exist_ok=True)


def zocalo(raiz, w, d, h=0.12):
    """Zócalo grafito que ocupa la huella entera, con biselado y franja de goma."""
    caja("zocalo", (w - 0.04, d - 0.04, h), (0, 0, h / 2), mat("grafito"), bisel=0.03, padre=raiz)
    caja("zocalo_goma", (w - 0.02, d - 0.02, 0.025), (0, 0, 0.0125), mat("goma"), bisel=0.008, padre=raiz)
    return h


# ---------------------------------------------------------------- centrífuga
def centrifuga():
    limpiar(); comun._mats.clear()
    r = vacio("centrifuga")
    zh = zocalo(r, 1.0, 1.0)
    ch, gr, me, ac = mat("chasis"), mat("grafito"), mat("metal"), mat("acento_procesado")
    bx = 0.66  # anchura del cuerpo en X (deja sitio a las bocas)
    # cuerpo de dos piezas: base más ancha y tambor
    caja("cuerpo", (bx, 0.84, 0.5), (0, 0, zh + 0.25), ch, bisel=0.07, segmentos=3, padre=r)
    caja("banda", (bx + 0.02, 0.86, 0.1), (0, 0, zh + 0.45), gr, bisel=0.02, padre=r)
    cilindro("tambor", 0.33, 0.3, (0, 0.02, zh + 0.6), ac, lados=40, bisel=0.05, segmentos=3, padre=r)
    toro("aro_tapa", 0.33, 0.03, (0, 0.02, zh + 0.75), me, padre=r)
    # cúpula de cristal con el rotor dentro
    cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.28)
    esfera("cupula", 0.31, (0, 0.02, zh + 0.75), cristal, padre=r, media=True, escala=(1, 1, 0.55))
    rot = vacio("rotor", (0, 0.02, zh + 0.77), padre=r)
    cilindro("rotor_eje", 0.05, 0.1, (0, 0, 0.0), me, lados=16, padre=rot)
    cilindro("rotor_plato", 0.24, 0.035, (0, 0, -0.02), me, lados=32, bisel=0.01, padre=rot)
    for i in range(6):
        a = i * math.tau / 6
        x, y = math.cos(a) * 0.17, math.sin(a) * 0.17
        tm = mat("tubo_rojo") if i % 2 == 0 else mat("tubo_amarillo")
        cilindro(f"rotor_tubo{i}", 0.028, 0.14, (x, y, 0.05), tm, lados=12, bisel=0.01, padre=rot,
                 giro=(math.cos(a + math.pi / 2) * 0.5, math.sin(a + math.pi / 2) * -0.5 * -1, 0))
        esfera(f"rotor_tapon{i}", 0.03, (x, y, 0.12), mat("tubo_blanco"), padre=rot)
    # panel frontal inclinado con pantalla y mandos (cara -Y = frente hacia cámara)
    panel = caja("panel", (0.42, 0.1, 0.22), (0, -0.43, zh + 0.3), gr, bisel=0.02, padre=r,
                 giro=(math.radians(-20), 0, 0))
    pan = mat("pantalla", color=(0.05, 0.25, 0.2), rug=0.3, emision=(0.25, 1.0, 0.7), fuerza=1.5)
    caja("pantalla", (0.24, 0.02, 0.1), (-0.05, -0.485, zh + 0.32), pan, bisel=0.0, padre=r,
         giro=(math.radians(-20), 0, 0))
    for k, x in enumerate((0.12, 0.17)):
        cilindro(f"mando{k}", 0.022, 0.03, (x, -0.49, zh + 0.29), me, lados=12, padre=r,
                 giro=(math.radians(70), 0, 0))
    # bocas
    puerto("entrada", -1, 0.16, 0.22, zh + 0.18, r, mitad=bx / 2, z_zocalo=zh)
    puerto("salida", 1, 0.16, 0.22, zh + 0.18, r, mitad=bx / 2, z_zocalo=zh)
    # patas de goma y baliza
    baliza((0.24, 0.3, zh + 0.5), r, alto_poste=0.16)
    exportar(os.path.join(salida, "centrifuga.glb"))


# ---------------------------------------------------------------- secuenciador
def secuenciador():
    limpiar(); comun._mats.clear()
    r = vacio("secuenciador")
    zh = zocalo(r, 2.0, 2.0)
    ch, gr, me, ac = mat("chasis"), mat("grafito"), mat("metal"), mat("acento_procesado")
    # torre trasera (+Y) con pantalla grande alta e inclinada hacia la cámara
    caja("torre", (1.5, 0.6, 1.55), (0, 0.6, zh + 0.775), ch, bisel=0.08, segmentos=3, padre=r)
    caja("torre_techo", (1.56, 0.66, 0.1), (0, 0.6, zh + 1.58), ac, bisel=0.04, padre=r)
    for s_ in (-1, 1):
        caja(f"torre_franja{s_}", (0.05, 0.64, 1.3), (s_ * 0.76, 0.6, zh + 0.8), ac, bisel=0.02, padre=r)
    inc = math.radians(-22)
    pz = zh + 1.22
    pan_raiz = vacio("pantalla_raiz", (0, 0.29, pz), padre=r)
    pan_raiz.rotation_euler = (inc, 0, 0)
    caja("pantalla_marco", (1.16, 0.06, 0.56), (0, 0, 0), gr, bisel=0.025, padre=pan_raiz)
    pan = mat("pantalla", color=(0.02, 0.06, 0.07), rug=0.3, emision=(0.05, 0.2, 0.2), fuerza=1.0)
    caja("pantalla", (1.04, 0.02, 0.44), (0, -0.03, 0), pan, bisel=0.0, padre=pan_raiz)
    cols = [(0.2, 0.9, 0.4), (0.25, 0.6, 1.0), (1.0, 0.8, 0.2), (1.0, 0.3, 0.3)]
    nombres = ["A", "C", "G", "T"]
    import random
    random.seed(7)
    for fila in range(5):
        x = -0.46
        while x < 0.44:
            w = random.choice((0.03, 0.05, 0.07))
            k = random.randrange(4)
            m = mat("base_" + nombres[k], color=cols[k], rug=0.3, emision=cols[k], fuerza=2.2)
            caja(f"barra{fila}_{x:.2f}", (w, 0.012, 0.05), (x + w / 2, -0.045, 0.16 - fila * 0.08), m,
                 bisel=0.0, padre=pan_raiz)
            x += w + 0.012
    # mesa delantera con campana de cristal
    caja("mesa", (1.5, 1.1, 0.72), (0, -0.33, zh + 0.36), ch, bisel=0.06, segmentos=3, padre=r)
    caja("mesa_banda", (1.52, 1.12, 0.06), (0, -0.33, zh + 0.6), ac, bisel=0.02, padre=r)
    caja("mesa_tablero", (1.4, 1.0, 0.04), (0, -0.33, zh + 0.74), gr, bisel=0.01, padre=r)
    # placa de 96 pocillos (8 x 6 visibles), pocillos verdes
    caja("placa", (0.6, 0.42, 0.04), (-0.15, -0.35, zh + 0.78), mat("tubo_blanco"), bisel=0.01, padre=r)
    poc = mat("pocillo", color=(0.2, 0.85, 0.35), rug=0.2, emision=(0.2, 0.85, 0.35), fuerza=0.6)
    for i in range(8):
        for j in range(5):
            cilindro(f"pocillo{i}{j}", 0.022, 0.012, (-0.42 + i * 0.077, -0.5 + j * 0.075, zh + 0.805), poc,
                     lados=10, bisel=0.0, padre=r)
    # pórtico con cabezal móvil
    for s in (-1, 1):
        caja(f"riel{s}", (1.3, 0.05, 0.05), (0, -0.33 + s * 0.42, zh + 1.08), me, bisel=0.01, padre=r)
        caja(f"pilar{s}a", (0.05, 0.05, 0.32), (-0.66, -0.33 + s * 0.42, zh + 0.92), me, bisel=0.01, padre=r)
        caja(f"pilar{s}b", (0.05, 0.05, 0.32), (0.66, -0.33 + s * 0.42, zh + 0.92), me, bisel=0.01, padre=r)
    cab = vacio("cabezal", (0, -0.33, zh + 1.08), padre=r)
    caja("cabezal_puente", (0.1, 0.9, 0.06), (0, 0, 0), ac, bisel=0.015, padre=cab)
    caja("cabezal_cuerpo", (0.14, 0.14, 0.16), (0, -0.02, -0.08), ch, bisel=0.03, padre=cab)
    cilindro("cabezal_aguja", 0.012, 0.16, (0, -0.02, -0.22), me, lados=8, padre=cab)
    # campana de cristal (sin cara inferior)
    cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.22)
    caja("campana", (1.42, 1.02, 0.42), (0, -0.33, zh + 0.97), cristal, bisel=0.04, padre=r)
    for s_ in (-1, 1):
        caja(f"campana_marco_x{s_}", (1.44, 0.04, 0.04), (0, -0.33 + s_ * 0.51, zh + 1.18), gr, bisel=0.01, padre=r)
        caja(f"campana_marco_y{s_}", (0.04, 1.04, 0.04), (s_ * 0.71, -0.33, zh + 1.18), gr, bisel=0.01, padre=r)
    # bocas a media altura de la mesa
    puerto("entrada", -1, 0.24, 0.32, zh + 0.32, r, mitad=0.75, z_zocalo=zh)
    puerto("salida", 1, 0.24, 0.32, zh + 0.32, r, mitad=0.75, z_zocalo=zh)
    # rejilla de ventilación en la torre
    for k in range(5):
        caja(f"rejilla{k}", (0.5, 0.02, 0.025), (0.35, 0.29, zh + 0.18 + k * 0.05), gr, bisel=0.0, padre=r)
    baliza((0.6, 0.75, zh + 1.63), r, alto_poste=0.12)
    exportar(os.path.join(salida, "secuenciador.glb"))


# ---------------------------------------------------------------- biorreactor
def biorreactor():
    limpiar(); comun._mats.clear()
    r = vacio("biorreactor")
    zh = zocalo(r, 2.0, 2.0, h=0.14)
    ch, gr, me, ac = mat("chasis"), mat("grafito"), mat("metal"), mat("acento_producto")
    cx, cy = 0.14, -0.12     # depósito hacia delante; armario de control en la esquina trasera -X +Y
    # pedestal y depósito
    cilindro("pedestal", 0.66, 0.34, (cx, cy, zh + 0.17), ch, lados=48, bisel=0.05, segmentos=3, padre=r)
    toro("pedestal_aro", 0.67, 0.05, (cx, cy, zh + 0.33), ac, padre=r)
    cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.14)
    cilindro("deposito", 0.6, 1.2, (cx, cy, zh + 0.96), cristal, lados=48, bisel=0.0, padre=r)
    liq = mat("liquido", color=(0.18, 0.8, 0.12), rug=0.1, emision=(0.2, 0.9, 0.1), fuerza=0.9, alfa=0.95)
    cilindro("liquido", 0.56, 0.85, (cx, cy, zh + 0.36 + 0.425), liq, lados=40, bisel=0.0, padre=r)
    # costillas metálicas del depósito
    for i in range(4):
        a = i * math.tau / 4 + math.pi / 4
        caja(f"costilla{i}", (0.05, 0.05, 1.2), (cx + math.cos(a) * 0.61, cy + math.sin(a) * 0.61, zh + 0.96),
             me, bisel=0.012, padre=r)
    toro("aro_medio", 0.61, 0.025, (cx, cy, zh + 0.96), me, padre=r)
    # tapa, motor y agitador
    cilindro("tapa", 0.64, 0.1, (cx, cy, zh + 1.6), me, lados=48, bisel=0.03, padre=r)
    esfera("tapa_cupula", 0.62, (cx, cy, zh + 1.65), ch, padre=r, media=True, escala=(1, 1, 0.3))
    caja("motor", (0.36, 0.3, 0.26), (cx, cy, zh + 1.92), ac, bisel=0.05, segmentos=3, padre=r)
    cilindro("motor_tapa", 0.1, 0.06, (cx, cy, zh + 2.08), gr, lados=24, padre=r)
    ag = vacio("agitador", (cx, cy, zh + 0.36), padre=r)
    cilindro("agitador_eje", 0.025, 1.3, (0, 0, 0.65), me, lados=12, padre=ag)
    for k, h in enumerate((0.25, 0.6)):
        for s in range(3):
            a = s * math.tau / 3 + k * 0.5
            caja(f"pala{k}{s}", (0.34, 0.06, 0.02), (math.cos(a) * 0.17, math.sin(a) * 0.17, h), me,
                 bisel=0.005, padre=ag, giro=(math.radians(30), 0, a))
    # armario de control
    ax, ay = -0.66, 0.64
    caja("armario", (0.46, 0.42, 1.25), (ax, ay, zh + 0.625), ch, bisel=0.05, segmentos=3, padre=r)
    caja("armario_franja", (0.48, 0.44, 0.06), (ax, ay, zh + 1.0), ac, bisel=0.015, padre=r)
    pan = mat("pantalla", color=(0.05, 0.25, 0.2), rug=0.3, emision=(0.25, 1.0, 0.7), fuerza=1.5)
    caja("pantalla_marco", (0.32, 0.03, 0.24), (ax, ay - 0.215, zh + 0.78), gr, bisel=0.01, padre=r)
    caja("pantalla", (0.27, 0.02, 0.19), (ax, ay - 0.228, zh + 0.78), pan, bisel=0.0, padre=r)
    for k in range(3):
        cilindro(f"boton{k}", 0.02, 0.02, (ax - 0.08 + k * 0.08, ay - 0.225, zh + 0.55), mat("amarillo") if k == 1 else me,
                 lados=12, padre=r, giro=(math.radians(90), 0, 0))
    # tuberías del armario a la tapa
    tubo_curvo("tuberia1", [(ax - 0.08, ay + 0.05, zh + 1.25), (ax - 0.08, ay + 0.05, zh + 1.5),
                            (cx - 0.35, cy + 0.35, zh + 1.72), (cx - 0.25, cy + 0.25, zh + 1.7)], 0.035, me, padre=r)
    tubo_curvo("tuberia2", [(ax + 0.1, ay + 0.1, zh + 1.25), (ax + 0.1, ay + 0.1, zh + 1.45),
                            (cx - 0.05, cy + 0.5, zh + 1.7), (cx - 0.02, cy + 0.38, zh + 1.68)], 0.03, ac, padre=r)
    # tolva de entrada (-X) y boca de salida (+X)
    caja("tolva_soporte", (0.22, 0.36, 0.5), (-0.69, -0.3, zh + 0.25), gr, bisel=0.03, padre=r)
    puerto("entrada", -1, 0.22, 0.28, zh + 0.25, r, mitad=0.8, z_zocalo=zh, y=-0.3)
    caja("salida_soporte", (0.2, 0.36, 0.42), (0.7, 0.55, zh + 0.21), gr, bisel=0.03, padre=r)
    puerto("salida", 1, 0.22, 0.28, zh + 0.22, r, mitad=0.8, z_zocalo=zh, y=0.55)
    baliza((ax - 0.1, ay - 0.08, zh + 1.25), r, alto_poste=0.16)
    exportar(os.path.join(salida, "biorreactor.glb"))


centrifuga()
secuenciador()
biorreactor()
print("LOTE1 OK")
