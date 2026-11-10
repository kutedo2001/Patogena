"""Piezas del hub estilo Two Point Hospital (rediseño 2.0, R1.2).
Paredes bajadas con zócalo, franja y remate (materiales con nombre para recolorear por sala), puerta doble con
ojos de buey, ventana, pasamuros, cinta estilo Alchemy Factory (ancha, con patas, raíles y rodillos), tubería
a ras de suelo con abrazaderas y los envases que viajan por cinta (gradilla de tubos, bolsa de hematíes).
Uso: blender -b -P tools/blender/tp_hub.py -- <carpeta_salida>
Escala: casilla = 1 m; persona = 0,85; cinta a 0,38; pared visible 0,62.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

SAL = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "."
os.makedirs(SAL, exist_ok=True)

ALTO = 1.0         # pared visible: a la altura de la cabeza, como Two Point (Edu 10-nov)
GRUESO = 0.18
Z_CINTA = 0.38     # superficie de la cinta
ANCHO_CINTA = 0.8


def mats_pared():
    return dict(
        zocalo=mat("pared_zocalo", color=(0.36, 0.26, 0.52), rug=0.55),
        franja=mat("pared_franja", color=(0.96, 0.74, 0.16), rug=0.45),
        alta=mat("pared_alta", color=(0.74, 0.71, 0.84), rug=0.7),
        remate=mat("pared_remate", color=(0.99, 0.99, 0.98), rug=0.5),
        rodapie=mat("pared_rodapie", color=(0.16, 0.15, 0.2), rug=0.6),
    )


def tramo_pared(padre, x0, x1, z0=0.0, z1=ALTO, m=None, nombre="p"):
    """Tramo de pared de x0 a x1 (eje X), con capas. Solo pinta las capas que caen entre z0 y z1."""
    m = m or mats_pared()
    L = x1 - x0
    cx = (x0 + x1) / 2
    capas = [(0.0, 0.035, "rodapie", GRUESO + 0.012), (0.035, 0.42, "zocalo", GRUESO), (0.42, 0.46, "franja", GRUESO + 0.006),
             (0.46, ALTO - 0.02, "alta", GRUESO), (ALTO - 0.02, ALTO + 0.012, "remate", GRUESO + 0.03)]
    for a, b, k, g in capas:
        a2, b2 = max(a, z0), min(b, z1)
        if b2 - a2 < 1e-4:
            continue
        caja(f"{nombre}_{k}", (L, g, b2 - a2), (cx, 0, (a2 + b2) / 2), m[k], bisel=0.006 if k != "remate" else 0.012, padre=padre)
    # juntas verticales de los paneles altos (una cada medio metro)
    if z1 > 0.4:
        n = int(round(L / 0.5))
        for i in range(1, n):
            x = x0 + L * i / n
            for s in (-1, 1):
                caja(f"{nombre}_junta{i}{s}", (0.008, 0.004, ALTO - 0.49), (x, s * (GRUESO / 2 + 0.001), 0.46 + (ALTO - 0.49) / 2),
                     mat("junta", color=(0.68, 0.66, 0.74), rug=0.8), bisel=0.0, padre=padre)


def pared_recta():
    limpiar(); comun._mats.clear()
    r = vacio("pared_recta")
    tramo_pared(r, -0.5, 0.5)
    exportar(os.path.join(SAL, "pared_recta.glb"))


def pared_esquina():
    limpiar(); comun._mats.clear()
    r = vacio("pared_esquina")
    m = mats_pared()
    caja("pilar", (GRUESO + 0.02, GRUESO + 0.02, ALTO), (0, 0, ALTO / 2), m["alta"], bisel=0.012, padre=r)
    caja("pilar_zocalo", (GRUESO + 0.024, GRUESO + 0.024, 0.385), (0, 0, 0.035 + 0.1925), m["zocalo"], bisel=0.008, padre=r)
    caja("pilar_franja", (GRUESO + 0.03, GRUESO + 0.03, 0.04), (0, 0, 0.44), m["franja"], bisel=0.004, padre=r)
    caja("pilar_remate", (GRUESO + 0.05, GRUESO + 0.05, 0.03), (0, 0, ALTO + 0.0), m["remate"], bisel=0.01, padre=r)
    exportar(os.path.join(SAL, "pared_esquina.glb"))


def pared_puerta():
    """Puerta doble de vaivén con ojo de buey, placas de empuje y chapa de patadas. Hojas en nodos puerta_i/puerta_d
    (bisagra en el canto exterior) para que el juego las abra."""
    limpiar(); comun._mats.clear()
    r = vacio("pared_puerta")
    m = mats_pared()
    hueco = 0.72
    for s in (-1, 1):
        x = s * (hueco / 2 + 0.04)
        caja(f"marco{s}", (0.08, GRUESO + 0.04, ALTO + 0.01), (x, 0, (ALTO + 0.01) / 2), m["remate"], bisel=0.012, padre=r)
        a, b = s * (hueco / 2 + 0.08), s * 0.5
        tramo_pared(r, min(a, b), max(a, b), m=m, nombre=f"lado{s}")
    hoja = mat("puerta_hoja", color=(0.55, 0.78, 0.86), rug=0.45)
    chapa = mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.25)
    vid = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.25)
    goma = mat("goma")
    for s, nom in ((-1, "puerta_i"), (1, "puerta_d")):
        bis = vacio(nom, (s * hueco / 2, 0, 0), r)
        w = hueco / 2 - 0.01
        cx = -s * w / 2
        caja(nom + "_hoja", (w, 0.045, ALTO - 0.02), (cx, 0, ALTO / 2), hoja, bisel=0.012, padre=bis)
        caja(nom + "_patadas", (w - 0.03, 0.05, 0.12), (cx, 0, 0.08), chapa, bisel=0.006, padre=bis)
        for sy in (-1, 1):
            cilindro(nom + f"_ojo{sy}", 0.075, 0.052, (cx, sy * 0.0, 0.66), chapa, lados=32, bisel=0.006, padre=bis, giro=(math.radians(90), 0, 0))
        cilindro(nom + "_vidrio", 0.06, 0.056, (cx, 0, 0.66), vid, lados=32, padre=bis, giro=(math.radians(90), 0, 0))
        for sy in (-1, 1):
            caja(nom + f"_empuje{sy}", (0.05, 0.006, 0.16), (cx - s * (w / 2 - 0.06), sy * 0.026, 0.48), chapa, bisel=0.002, padre=bis)
        caja(nom + "_burlete", (0.012, 0.05, ALTO - 0.04), (-s * w, 0, ALTO / 2), goma, bisel=0.0, padre=bis)
    # placa de sala encima (el juego le pone el icono de la sala)
    caja("placa_sala", (0.3, 0.02, 0.09), (0, GRUESO / 2 + 0.012, ALTO + 0.08), mat("placa", color=(0.2, 0.42, 0.5), rug=0.4), bisel=0.01, padre=r)
    caja("placa_soporte", (0.04, 0.02, 0.06), (0, GRUESO / 2 + 0.012, ALTO + 0.02), m["remate"], bisel=0.004, padre=r)
    exportar(os.path.join(SAL, "pared_puerta.glb"))


def pared_ventana():
    limpiar(); comun._mats.clear()
    r = vacio("pared_ventana")
    m = mats_pared()
    tramo_pared(r, -0.5, 0.5, 0.0, 0.46, m, "bajo")
    caja("alfeizar", (0.96, GRUESO + 0.05, 0.03), (0, 0, 0.47), m["remate"], bisel=0.01, padre=r)
    marco = mat("marco_ventana", color=(0.98, 0.98, 0.97), rug=0.5)
    for s in (-1, 1):
        caja(f"jamba{s}", (0.06, GRUESO + 0.01, ALTO - 0.46), (s * 0.47, 0, 0.46 + (ALTO - 0.46) / 2), marco, bisel=0.01, padre=r)
    caja("parteluz", (0.035, GRUESO - 0.04, ALTO - 0.47), (0, 0, 0.46 + (ALTO - 0.46) / 2), marco, bisel=0.008, padre=r)
    caja("dintel", (1.0, GRUESO + 0.03, 0.03), (0, 0, ALTO), m["remate"], bisel=0.01, padre=r)
    caja("vidrio", (0.88, 0.02, ALTO - 0.49), (0, 0, 0.46 + (ALTO - 0.46) / 2), mat("cristal", color=(0.72, 0.88, 0.95), rug=0.05, alfa=0.3), bisel=0.0, padre=r)
    for s in (-1, 1):
        caja(f"brillo{s}", (0.05, 0.022, 0.18), (s * 0.2 - 0.05, 0, 0.72), mat("brillo", color=(1, 1, 1), rug=0.1, alfa=0.35), bisel=0.0, padre=r,
             giro=(0, math.radians(30), 0))
    exportar(os.path.join(SAL, "pared_ventana.glb"))


def pared_pasamuros():
    """Módulo de pared con ventanilla para la cinta: hueco a la altura de la cinta, marco de acero atornillado,
    cortina de lamas y franja amarilla y negra."""
    limpiar(); comun._mats.clear()
    r = vacio("pared_pasamuros")
    m = mats_pared()
    hw = ANCHO_CINTA / 2 + 0.04
    zt = Z_CINTA + 0.24
    tramo_pared(r, -0.5, -hw, m=m, nombre="izq")
    tramo_pared(r, hw, 0.5, m=m, nombre="der")
    tramo_pared(r, -hw, hw, zt, ALTO, m=m, nombre="sobre")
    tramo_pared(r, -hw, hw, 0.0, 0.06, m=m, nombre="bajo")
    acero = mat("acero_pintado", color=(0.36, 0.4, 0.44), metal=0.6, rug=0.4)
    for s in (-1, 1):
        caja(f"marco{s}", (0.05, GRUESO + 0.05, zt - 0.06), (s * (hw - 0.02), 0, 0.06 + (zt - 0.06) / 2), acero, bisel=0.01, padre=r)
    caja("marco_sup", (2 * hw + 0.05, GRUESO + 0.05, 0.05), (0, 0, zt), acero, bisel=0.01, padre=r)
    for sy in (-1, 1):
        caja(f"aviso{sy}", (2 * hw - 0.04, 0.006, 0.03), (0, sy * (GRUESO / 2 + 0.028), zt - 0.04), mat("amarillo"), bisel=0.0, padre=r)
        for k in range(6):
            caja(f"aviso_negro{sy}{k}", (0.035, 0.007, 0.03), (-hw + 0.08 + k * 0.15, sy * (GRUESO / 2 + 0.029), zt - 0.04),
                 mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r, giro=(0, math.radians(35), 0))
        for sx in (-1, 1):
            tornillo(f"torn{sy}{sx}", (sx * (hw - 0.02), sy * (GRUESO / 2 + 0.026), zt - 0.1), r, r=0.008, normal="+Y" if sy > 0 else "-Y")
    n = 9
    for k in range(n):
        caja(f"lama{k}", (2 * hw / n - 0.006, 0.006, 0.17), (-hw + 2 * hw / n * (k + 0.5), 0, zt - 0.11),
             mat("lama", color=(0.2, 0.22, 0.24), rug=0.5, alfa=0.7), bisel=0.0, padre=r)
    exportar(os.path.join(SAL, "pared_pasamuros.glb"))


def cinta_recta():
    """Cinta de 1 casilla en +X: banda de goma con tacos (el juego desplaza su UV), raíles pintados, rodillos de
    extremo, caballete con pies y tornillos. La banda se llama «banda» para animarla."""
    limpiar(); comun._mats.clear()
    r = vacio("cinta_recta")
    rail = mat("cinta_rail", color=(0.98, 0.62, 0.2), rug=0.45)
    acero = mat("acero_pintado", color=(0.36, 0.4, 0.44), metal=0.6, rug=0.4)
    goma = mat("banda", color=(0.13, 0.14, 0.15), rug=0.75)
    cromo = mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.25)
    hw = ANCHO_CINTA / 2
    caja("banda", (1.0, ANCHO_CINTA - 0.1, 0.03), (0, 0, Z_CINTA - 0.015), goma, bisel=0.004, padre=r)
    for k in range(6):
        caja(f"taco{k}", (0.02, ANCHO_CINTA - 0.12, 0.008), (-0.5 + (k + 0.5) / 6, 0, Z_CINTA + 0.002), goma, bisel=0.002, padre=r)
    for s in (-1, 1):
        caja(f"rail{s}", (1.0, 0.05, 0.11), (0, s * (hw - 0.025), Z_CINTA - 0.01), rail, bisel=0.012, padre=r)
        caja(f"rail_borde{s}", (1.0, 0.06, 0.018), (0, s * (hw - 0.025), Z_CINTA + 0.05), rail, bisel=0.006, padre=r)
        for k in range(4):
            tornillo(f"torn{s}{k}", (-0.375 + k * 0.25, s * hw + s * 0.001, Z_CINTA - 0.01), r, r=0.008, normal="+Y" if s > 0 else "-Y")
    for x in (-0.48, 0.48):
        cilindro(f"rodillo{x}", 0.03, ANCHO_CINTA - 0.1, (x, 0, Z_CINTA - 0.035), cromo, lados=16, padre=r, giro=(math.radians(90), 0, 0))
    # caballete
    for s in (-1, 1):
        caja(f"pata{s}", (0.05, 0.05, Z_CINTA - 0.07), (0, s * (hw - 0.06), (Z_CINTA - 0.07) / 2), acero, bisel=0.008, padre=r)
        caja(f"pie{s}", (0.16, 0.09, 0.02), (0, s * (hw - 0.06), 0.01), acero, bisel=0.006, padre=r)
        for sx in (-1, 1):
            cilindro(f"perno{s}{sx}", 0.008, 0.012, (sx * 0.06, s * (hw - 0.06), 0.024), cromo, lados=6, padre=r)
    caja("travesano", (0.04, ANCHO_CINTA - 0.14, 0.04), (0, 0, 0.12), acero, bisel=0.006, padre=r)
    caja("travesano_sup", (0.05, ANCHO_CINTA - 0.1, 0.03), (0, 0, Z_CINTA - 0.075), acero, bisel=0.006, padre=r)
    exportar(os.path.join(SAL, "cinta_recta.glb"))


def tuberia_recta():
    """Tubería de 1 casilla en +X a ras de suelo, con dos abrazaderas atornilladas y franjas de color;
    el material «tubo» lo recolorea el juego según el líquido."""
    limpiar(); comun._mats.clear()
    r = vacio("tuberia_recta")
    tubo = mat("tubo", color=(0.95, 0.65, 0.2), rug=0.35)
    acero = mat("acero_pintado", color=(0.36, 0.4, 0.44), metal=0.6, rug=0.4)
    cromo = mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.25)
    z = 0.09
    cilindro("tubo", 0.045, 1.0, (0, 0, z), tubo, lados=24, bisel=0.0, padre=r, giro=(0, math.radians(90), 0))
    for x in (-0.3, 0.3):
        caja(f"base{x}", (0.06, 0.16, 0.012), (x, 0, 0.006), acero, bisel=0.004, padre=r)
        toro(f"abrazadera{x}", 0.05, 0.008, (x, 0, z), cromo, padre=r).rotation_euler = (0, math.radians(90), 0)
        caja(f"soporte{x}", (0.03, 0.03, z - 0.04), (x, 0, (z - 0.04) / 2 + 0.01), acero, bisel=0.004, padre=r)
        for s in (-1, 1):
            cilindro(f"perno{x}{s}", 0.009, 0.014, (x, s * 0.06, 0.018), cromo, lados=6, padre=r)
    for x in (-0.48, 0.48):
        cilindro(f"brida{x}", 0.06, 0.03, (x, 0, z), cromo, lados=24, bisel=0.004, padre=r, giro=(0, math.radians(90), 0))
    exportar(os.path.join(SAL, "tuberia_recta.glb"))


def gradilla_sangre():
    """Gradilla de 6 tubos de extracción: así viajan los tubos por la cinta (sueltos no tendría sentido)."""
    limpiar(); comun._mats.clear()
    r = vacio("gradilla_sangre")
    plast = mat("gradilla_plastico", color=(0.95, 0.95, 0.92), rug=0.55)
    sangre = mat("sangre_tubo", color=(0.55, 0.03, 0.05), rug=0.25)
    vid = mat("cristal", color=(0.85, 0.92, 0.95), rug=0.05, alfa=0.35)
    tapon = mat("tapon_rojo", color=(0.8, 0.12, 0.12), rug=0.5)
    caja("base", (0.34, 0.16, 0.02), (0, 0, 0.01), plast, bisel=0.006, padre=r)
    caja("tabla", (0.34, 0.16, 0.018), (0, 0, 0.1), plast, bisel=0.006, padre=r)
    for s in (-1, 1):
        caja(f"lado{s}", (0.018, 0.16, 0.1), (s * 0.161, 0, 0.055), plast, bisel=0.005, padre=r)
    for i in range(3):
        for j in range(2):
            x, y = -0.1 + i * 0.1, -0.04 + j * 0.08
            cilindro(f"tubo{i}{j}", 0.022, 0.17, (x, y, 0.105), vid, lados=20, bisel=0.004, padre=r)
            cilindro(f"sangre{i}{j}", 0.0185, 0.13, (x, y, 0.085), sangre, lados=20, bisel=0.004, padre=r)
            cilindro(f"tapon{i}{j}", 0.025, 0.035, (x, y, 0.205), tapon, lados=20, bisel=0.006, padre=r)
    caja("etiqueta", (0.12, 0.004, 0.04), (0, -0.082, 0.055), mat("etiqueta", color=(0.98, 0.98, 0.95), rug=0.6), bisel=0.0, padre=r)
    exportar(os.path.join(SAL, "gradilla_sangre.glb"))


def gradilla_hematies():
    """La misma gradilla al salir de la centrífuga: el plasma ya se ha sacado y solo queda el concentrado de hematíes."""
    limpiar(); comun._mats.clear()
    r = vacio("gradilla_hematies")
    plast = mat("gradilla_plastico", color=(0.95, 0.95, 0.92), rug=0.55)
    hem = mat("hematies_tubo", color=(0.32, 0.01, 0.03), rug=0.2)
    vid = mat("cristal", color=(0.85, 0.92, 0.95), rug=0.05, alfa=0.35)
    tapon = mat("tapon_morado", color=(0.45, 0.2, 0.62), rug=0.5)
    caja("base", (0.34, 0.16, 0.02), (0, 0, 0.01), plast, bisel=0.006, padre=r)
    caja("tabla", (0.34, 0.16, 0.018), (0, 0, 0.1), plast, bisel=0.006, padre=r)
    for s in (-1, 1):
        caja(f"lado{s}", (0.018, 0.16, 0.1), (s * 0.161, 0, 0.055), plast, bisel=0.005, padre=r)
    for i in range(3):
        for j in range(2):
            x, y = -0.1 + i * 0.1, -0.04 + j * 0.08
            cilindro(f"tubo{i}{j}", 0.022, 0.17, (x, y, 0.105), vid, lados=20, bisel=0.004, padre=r)
            cilindro(f"hem{i}{j}", 0.0185, 0.07, (x, y, 0.055), hem, lados=20, bisel=0.004, padre=r)
            cilindro(f"tapon{i}{j}", 0.025, 0.035, (x, y, 0.205), tapon, lados=20, bisel=0.006, padre=r)
    caja("etiqueta", (0.12, 0.004, 0.04), (0, -0.082, 0.055), mat("etiqueta", color=(0.98, 0.98, 0.95), rug=0.6), bisel=0.0, padre=r)
    exportar(os.path.join(SAL, "gradilla_hematies.glb"))


def bolsa_hematies():
    limpiar(); comun._mats.clear()
    r = vacio("bolsa_hematies")
    bolsa = mat("bolsa_hematies", color=(0.42, 0.02, 0.05), rug=0.2)
    borde = mat("bolsa_borde", color=(0.92, 0.9, 0.88), rug=0.4, alfa=0.85)
    caja("borde", (0.3, 0.21, 0.012), (0, 0, 0.012), borde, bisel=0.004, padre=r)
    esfera("cuerpo", 0.12, (0, 0, 0.03), bolsa, padre=r, escala=(1.15, 0.78, 0.22))
    for s in (-1, 1):
        cilindro(f"puerto{s}", 0.012, 0.05, (0.165, s * 0.03, 0.014), borde, lados=12, padre=r, giro=(0, math.radians(90), 0))
    caja("etiqueta", (0.12, 0.08, 0.003), (-0.02, 0, 0.058), mat("etiqueta", color=(0.98, 0.98, 0.95), rug=0.6), bisel=0.0, padre=r)
    caja("etiqueta_roja", (0.12, 0.02, 0.0035), (-0.02, 0.03, 0.0585), mat("tapon_rojo", color=(0.8, 0.12, 0.12), rug=0.5), bisel=0.0, padre=r)
    exportar(os.path.join(SAL, "bolsa_hematies.glb"))


def banco():
    """Banco de pasillo de tres plazas: asientos acolchados verdes con costuras, patas de tubo cromado."""
    limpiar(); comun._mats.clear()
    r = vacio("banco")
    cojin = mat("banco_cojin", color=(0.3, 0.55, 0.45), rug=0.6)
    cromo = mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.25)
    for i in range(3):
        x = -0.6 + i * 0.6
        caja(f"asiento{i}", (0.54, 0.4, 0.07), (x, 0.02, 0.24), cojin, bisel=0.03, segmentos=3, padre=r)
        caja(f"respaldo{i}", (0.54, 0.07, 0.3), (x, -0.19, 0.42), cojin, bisel=0.03, segmentos=3, padre=r, giro=(math.radians(-10), 0, 0))
        caja(f"costura{i}", (0.4, 0.004, 0.004), (x, 0.0, 0.276), mat("costura", color=(0.22, 0.42, 0.34), rug=0.7), bisel=0.0, padre=r)
    caja("larguero", (1.8, 0.05, 0.03), (0, 0, 0.19), cromo, bisel=0.008, padre=r)
    # reposabrazos entre plazas: la animación de sentarse apoya las manos a ±0,24 de la plaza y a 0,43 de alto
    for x in (-0.9, -0.3, 0.3, 0.9):
        caja(f"reposa{x}", (0.06, 0.36, 0.035), (x, -0.02, 0.385), mat("banco_reposa", color=(0.22, 0.42, 0.36), rug=0.5), bisel=0.012, padre=r)
        cilindro(f"reposa_pie{x}", 0.014, 0.12, (x, 0.1, 0.31), cromo, lados=10, padre=r)
    for x in (-0.82, 0.82):
        for y in (-0.15, 0.15):
            cilindro(f"pata{x}{y}", 0.018, 0.19, (x, y, 0.095), cromo, lados=12, padre=r)
            cilindro(f"taco{x}{y}", 0.025, 0.012, (x, y, 0.006), mat("goma"), lados=12, padre=r)
    exportar(os.path.join(SAL, "banco.glb"))


for f in (gradilla_hematies, banco, pared_recta, pared_esquina, pared_puerta, pared_ventana, pared_pasamuros, cinta_recta, tuberia_recta, gradilla_sangre, bolsa_hematies):
    f()
    print("hecho:", f.__name__)


# ------------------------------------------------------------------ objetos de pasillo y salas (R1.3)
def _base_objeto(nombre):
    limpiar(); comun._mats.clear()
    return vacio(nombre)


def recepcion():
    """Mostrador de recepción 2×1 curvo: frente con franja y logo, encimera, monitor con pantalla, teclado, timbre,
    bandeja de formularios y taburete detrás."""
    r = _base_objeto("recepcion")
    frente = mat("rec_frente", color=(0.3, 0.6, 0.66), rug=0.45)
    enc = mat("rec_encimera", color=(0.97, 0.95, 0.9), rug=0.35)
    nar = mat("tp_naranja", color=(0.98, 0.52, 0.14), rug=0.35)
    gr = mat("grafito")
    caja("frente", (1.8, 0.5, 0.62), (0, 0.05, 0.31), frente, bisel=0.12, segmentos=5, padre=r)
    caja("franja", (1.84, 0.54, 0.05), (0, 0.05, 0.45), nar, bisel=0.025, segmentos=3, padre=r)
    caja("encimera", (1.9, 0.62, 0.05), (0, 0.02, 0.645), enc, bisel=0.025, segmentos=3, padre=r)
    caja("mesa_baja", (1.7, 0.32, 0.04), (0, -0.3, 0.46), enc, bisel=0.015, padre=r)
    placa = mat_calcomania("placa_logo", os.path.join("assets/texturas/calcomanias", "placa_logo.png"), 0.4)
    calcomania("logo", 0.5, 0.17, (0, 0.305, 0.25), placa, padre=r, giro=(math.radians(90), 0, math.pi))
    # monitor
    caja("mon_pie", (0.12, 0.08, 0.02), (-0.4, -0.25, 0.49), gr, bisel=0.008, padre=r)
    caja("mon_cuello", (0.03, 0.03, 0.18), (-0.4, -0.25, 0.58), gr, bisel=0.008, padre=r)
    caja("mon_cuerpo", (0.42, 0.04, 0.27), (-0.4, -0.24, 0.74), gr, bisel=0.015, padre=r)
    pantalla_plano("pantalla", 0.38, 0.23, (-0.4, -0.215, 0.74), padre=r, giro=(math.radians(90), 0, math.pi))
    caja("teclado", (0.34, 0.12, 0.02), (-0.4, -0.08, 0.49), mat("teclado", color=(0.9, 0.9, 0.88), rug=0.5), bisel=0.006, padre=r)
    cilindro("timbre", 0.04, 0.025, (0.5, 0.15, 0.68), mat("cromo", color=(0.86, 0.87, 0.89), metal=1.0, rug=0.2), lados=24, bisel=0.008, padre=r)
    esfera("timbre_boton", 0.012, (0.5, 0.15, 0.695), gr, padre=r)
    for k in range(3):
        caja(f"form{k}", (0.2, 0.28, 0.006), (0.15, 0.12, 0.675 + k * 0.008), mat("papel", color=(0.98, 0.98, 0.96), rug=0.7), bisel=0.0, padre=r, giro=(0, 0, math.radians(k * 6)))
    # taburete
    cilindro("tab_asiento", 0.15, 0.05, (0.25, -0.55, 0.255), mat("banco_cojin", color=(0.95, 0.5, 0.2), rug=0.6), lados=24, bisel=0.02, padre=r)
    cilindro("tab_pie", 0.02, 0.23, (0.25, -0.55, 0.12), mat("cromo"), lados=12, padre=r)
    cilindro("tab_base", 0.14, 0.02, (0.25, -0.55, 0.01), mat("cromo"), lados=24, padre=r)
    exportar(os.path.join(SAL, "recepcion.glb"))


def planta():
    r = _base_objeto("planta")
    cilindro("maceta", 0.16, 0.3, (0, 0, 0.15), mat("maceta", color=(0.95, 0.55, 0.2), rug=0.5), lados=32, bisel=0.03, padre=r)
    cilindro("tierra", 0.145, 0.02, (0, 0, 0.3), mat("tierra", color=(0.25, 0.16, 0.1), rug=0.9), lados=32, padre=r)
    hoja = mat("hoja", color=(0.22, 0.6, 0.3), rug=0.5)
    for k in range(9):
        a = k / 9 * math.tau
        e = esfera(f"hoja{k}", 0.09, (math.cos(a) * 0.1, math.sin(a) * 0.1, 0.45 + (k % 3) * 0.08), hoja, padre=r, escala=(1.6, 0.6, 0.25))
        e.rotation_euler = (math.radians(30), 0, a)
    esfera("copa", 0.12, (0, 0, 0.62), hoja, padre=r, escala=(1, 1, 1.3))
    exportar(os.path.join(SAL, "planta.glb"))


def maquina_bebidas():
    r = _base_objeto("maquina_bebidas")
    cuerpo = mat("bebidas", color=(0.85, 0.15, 0.2), rug=0.4)
    caja("cuerpo", (0.62, 0.5, 1.1), (0, 0, 0.55), cuerpo, bisel=0.05, segmentos=3, padre=r)
    caja("vitrina", (0.4, 0.02, 0.62), (-0.06, 0.251, 0.68), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.35), bisel=0.0, padre=r)
    cols = [(0.2, 0.5, 0.9), (0.95, 0.75, 0.2), (0.3, 0.8, 0.4), (0.95, 0.4, 0.6)]
    for f in range(4):
        for c in range(4):
            cilindro(f"lata{f}{c}", 0.03, 0.09, (-0.2 + c * 0.095, 0.2, 0.43 + f * 0.15), mat(f"lata{c}", color=cols[c], rug=0.3, metal=0.4), lados=16, padre=r)
    caja("panel", (0.12, 0.02, 0.3), (0.22, 0.252, 0.75), mat("grafito"), bisel=0.01, padre=r)
    for k in range(6):
        caja(f"tecla{k}", (0.03, 0.01, 0.025), (0.205 + (k % 2) * 0.035, 0.263, 0.82 - (k // 2) * 0.04), mat("teclado", color=(0.9, 0.9, 0.88), rug=0.5), bisel=0.003, padre=r)
    caja("bandeja", (0.36, 0.06, 0.1), (-0.06, 0.25, 0.18), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.01, padre=r)
    caja("cartel", (0.56, 0.02, 0.14), (0, 0.252, 1.03), mat("bebidas_cartel", color=(0.98, 0.95, 0.9), rug=0.5, emision=(1, 0.95, 0.85), fuerza=0.6), bisel=0.01, padre=r)
    exportar(os.path.join(SAL, "maquina_bebidas.glb"))


def papelera():
    r = _base_objeto("papelera")
    cilindro("cubo", 0.13, 0.36, (0, 0, 0.18), mat("papelera", color=(0.3, 0.5, 0.45), rug=0.5), lados=24, bisel=0.02, padre=r)
    toro("aro", 0.13, 0.012, (0, 0, 0.36), mat("cromo", color=(0.86, 0.87, 0.89), metal=1.0, rug=0.2), padre=r)
    esfera("papel", 0.04, (0.03, 0.02, 0.37), mat("papel", color=(0.98, 0.98, 0.96), rug=0.7), padre=r, escala=(1, 0.8, 0.7))
    exportar(os.path.join(SAL, "papelera.glb"))


def extintor():
    r = _base_objeto("extintor")
    rojo = mat("rojo_zona", color=(0.85, 0.1, 0.1), rug=0.4)
    caja("placa", (0.22, 0.02, 0.5), (0, 0, 0.55), mat("placa_ext", color=(0.95, 0.95, 0.9), rug=0.5), bisel=0.01, padre=r)
    cilindro("botella", 0.06, 0.32, (0, 0.08, 0.5), rojo, lados=24, bisel=0.02, padre=r)
    cilindro("valvula", 0.025, 0.05, (0, 0.08, 0.69), mat("grafito"), lados=12, padre=r)
    tubo_curvo("manguera", [(0, 0.08, 0.7), (0.06, 0.1, 0.66), (0.07, 0.12, 0.45)], 0.01, mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), padre=r)
    exportar(os.path.join(SAL, "extintor.glb"))


def carrito_extraccion():
    """Carrito de extracción: bandejas con agujas, algodón, gradilla abierta donde va el tubo recién lleno y
    contenedor amarillo de punzantes."""
    r = _base_objeto("carrito_extraccion")
    crem = mat("tp_crema", color=(0.97, 0.95, 0.88), rug=0.42)
    cromo = mat("cromo", color=(0.86, 0.87, 0.89), metal=1.0, rug=0.2)
    for z in (0.2, 0.55):
        caja(f"bandeja{z}", (0.5, 0.36, 0.03), (0, 0, z), crem, bisel=0.012, padre=r)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cilindro(f"poste{sx}{sy}", 0.012, 0.56, (sx * 0.22, sy * 0.15, 0.32), cromo, lados=10, padre=r)
            cilindro(f"rueda{sx}{sy}", 0.03, 0.025, (sx * 0.22, sy * 0.15, 0.03), mat("goma"), lados=16, padre=r, giro=(math.radians(90), 0, 0))
    caja("punzantes", (0.12, 0.12, 0.16), (0.15, 0.08, 0.65), mat("amarillo"), bisel=0.015, padre=r)
    caja("punzantes_tapa", (0.13, 0.13, 0.02), (0.15, 0.08, 0.735), mat("rojo_zona", color=(0.85, 0.1, 0.1), rug=0.4), bisel=0.006, padre=r)
    esfera("algodon", 0.05, (-0.15, 0.08, 0.59), mat("algodon", color=(1, 1, 1), rug=0.9), padre=r, escala=(1.2, 1, 0.6))
    for k in range(4):
        cilindro(f"jeringa{k}", 0.008, 0.12, (-0.1 + k * 0.03, -0.1, 0.575), mat("cristal", color=(0.85, 0.92, 0.95), rug=0.05, alfa=0.5), lados=8, padre=r, giro=(0, math.radians(90), 0))
    exportar(os.path.join(SAL, "carrito_extraccion.glb"))


def llenadora_gradillas():
    """Puesto de carga 1×1 al principio de la cinta: el tubo lleno se mete en la gradilla abierta y, con 6, la
    gradilla baja a la cinta por la ranura delantera (+X)."""
    r = _base_objeto("llenadora_gradillas")
    men = mat("tp_menta", color=(0.46, 0.78, 0.68), rug=0.38)
    nar = mat("tp_naranja", color=(0.98, 0.52, 0.14), rug=0.35)
    caja("cuerpo", (0.7, 0.8, 0.5), (-0.1, 0, 0.3), men, bisel=0.1, segmentos=4, padre=r)
    caja("cinto", (0.73, 0.83, 0.05), (-0.1, 0, 0.5), nar, bisel=0.02, padre=r)
    caja("encimera", (0.72, 0.82, 0.04), (-0.1, 0, 0.56), mat("tp_crema", color=(0.97, 0.95, 0.88), rug=0.42), bisel=0.015, padre=r)
    caja("hueco", (0.38, 0.2, 0.02), (-0.1, 0, 0.58), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r)
    caja("salida_marco", (0.06, 0.86, 0.06), (0.38, 0, 0.66), mat("grafito"), bisel=0.012, padre=r)
    caja("salida_franja", (0.065, 0.86, 0.02), (0.38, 0, 0.7), mat("franja_salida", color=(1.0, 0.55, 0.12), rug=0.35, emision=(1.0, 0.55, 0.12), fuerza=0.9), bisel=0.004, padre=r)
    for s in (-1, 1):
        caja(f"salida_lat{s}", (0.06, 0.05, 0.3), (0.38, s * 0.43, 0.5), mat("grafito"), bisel=0.01, padre=r)
    pantalla_plano("pantalla", 0.16, 0.1, (-0.1, 0.405, 0.42), padre=r, giro=(math.radians(90), 0, math.pi))
    exportar(os.path.join(SAL, "llenadora_gradillas.glb"))


def cartel_empresa():
    r = _base_objeto("cartel_empresa")
    caja("marco", (0.6, 0.03, 0.42), (0, 0, 0.0), mat("marco_cartel", color=(0.15, 0.15, 0.18), rug=0.5), bisel=0.01, padre=r)
    caja("fondo", (0.54, 0.035, 0.36), (0, 0, 0.0), mat("cartel_fondo", color=(0.98, 0.85, 0.3), rug=0.5), bisel=0.0, padre=r)
    caja("franja", (0.54, 0.036, 0.08), (0, 0, -0.1), mat("rojo_zona", color=(0.85, 0.1, 0.1), rug=0.4), bisel=0.0, padre=r)
    esfera("virus", 0.07, (0, 0.02, 0.06), mat("virus_cartel", color=(0.3, 0.75, 0.35), rug=0.4), padre=r, escala=(1, 0.3, 1))
    exportar(os.path.join(SAL, "cartel_empresa.glb"))


for f in (recepcion, planta, maquina_bebidas, papelera, extintor, carrito_extraccion, llenadora_gradillas, cartel_empresa):
    f()
    print("hecho:", f.__name__)


def camilla_tp():
    """Camilla de extracción 1×2 (largo en X): colchón a 0,40 (la animación de tumbarse apoya ahí), almohada en -X,
    reposabrazos abatible en +Y (lado del científico) con el tubo de muestra, barandilla en -Y, pie de gotero,
    ruedas con freno y pedal de altura."""
    r = _base_objeto("camilla_tp")
    cromo = mat("cromo", color=(0.86, 0.87, 0.89), metal=1.0, rug=0.2)
    colchon = mat("colchon", color=(0.32, 0.62, 0.66), rug=0.55)
    sabana = mat("sabana", color=(0.97, 0.97, 0.95), rug=0.7)
    gr = mat("grafito")
    caja("chasis", (1.7, 0.6, 0.06), (0, 0, 0.27), mat("tp_crema", color=(0.97, 0.95, 0.88), rug=0.42), bisel=0.025, segmentos=3, padre=r)
    caja("columna", (0.3, 0.22, 0.2), (0, 0, 0.15), gr, bisel=0.03, padre=r)
    caja("base", (1.5, 0.5, 0.05), (0, 0, 0.06), gr, bisel=0.02, padre=r)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cilindro(f"rueda{sx}{sy}", 0.04, 0.03, (sx * 0.68, sy * 0.22, 0.04), mat("goma"), lados=20, padre=r, giro=(math.radians(90), 0, 0))
            caja(f"horquilla{sx}{sy}", (0.03, 0.05, 0.05), (sx * 0.68, sy * 0.22, 0.08), cromo, bisel=0.006, padre=r)
    caja("pedal", (0.12, 0.08, 0.02), (0.3, 0.27, 0.06), mat("rojo_zona", color=(0.85, 0.1, 0.1), rug=0.45), bisel=0.008, padre=r)
    caja("colchon", (1.64, 0.56, 0.1), (0, 0, 0.35), colchon, bisel=0.04, segmentos=3, padre=r)
    caja("sabana", (1.2, 0.565, 0.012), (0.2, 0, 0.402), sabana, bisel=0.004, padre=r)
    caja("almohada", (0.28, 0.44, 0.07), (-0.66, 0, 0.43), sabana, bisel=0.03, segmentos=3, padre=r)
    # barandilla en -Y
    for x in (-0.55, 0.55):
        cilindro(f"bar_poste{x}", 0.012, 0.16, (x, -0.3, 0.45), cromo, lados=10, padre=r)
    cilindro("bar_larguero", 0.014, 1.15, (0, -0.3, 0.53), cromo, lados=10, padre=r, giro=(0, math.radians(90), 0))
    # reposabrazos de extracción en +Y, a la altura del brazo del paciente (centro del cuerpo)
    caja("reposa_soporte", (0.06, 0.12, 0.06), (0.05, 0.33, 0.33), gr, bisel=0.01, padre=r)
    caja("reposa", (0.42, 0.13, 0.04), (0.05, 0.4, 0.38), colchon, bisel=0.018, padre=r)
    cilindro("goteo_pie", 0.012, 1.0, (-0.86, -0.34, 0.78), cromo, lados=10, padre=r)
    caja("goteo_brazo", (0.18, 0.012, 0.012), (-0.86, -0.34, 1.27), cromo, bisel=0.0, padre=r)
    esfera("goteo_bolsa", 0.05, (-0.79, -0.34, 1.2), mat("cristal", color=(0.85, 0.92, 0.95), rug=0.05, alfa=0.5), padre=r, escala=(0.7, 0.35, 1.2))
    exportar(os.path.join(SAL, "camilla_tp.glb"))


camilla_tp()
print("hecho: camilla_tp")
