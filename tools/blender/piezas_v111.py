"""Piezas que eran provisionales, al nivel del lote 1 (V1.11 · P5.2): brazo, divisor, almacén,
incubadora, toma de agua, sus máquinas de mejora (recolector y bomba), hub de envío con furgoneta,
terminal de pedidos, puerta de pacientes y muelle de carga.
Uso: blender -b -P tools/blender/piezas_v111.py -- <carpeta_salida> <carpeta_calcomanias>
Nodos que lee el juego: brazo → hombro/brazo/pinza; divisor → gira_paleta; almacén → barra (nivel);
incubadora → placa (crece); toma → agua (nivel); hub → van; puerta → hoja_i/hoja_d; baliza/torre.
Ejes: entra por -X, sale por +X; +Z del juego = -Y de Blender.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

CAL = None


def zocalo_1x1(r, alto=0.08):
    gr = mat("grafito")
    caja("zocalo", (0.94, 0.94, alto), (0, 0, alto / 2), gr, bisel=0.02, padre=r)
    caja("zocalo_goma", (0.95, 0.95, 0.01), (0, 0, 0.005), mat("goma"), bisel=0.003, padre=r)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tornillo(f"zocalo_torn{sx}{sy}", (sx * 0.4, sy * 0.4, alto), r, r=0.01, normal="+Z")
    return alto


def brazo():
    r = vacio("brazo")
    z = zocalo_1x1(r, 0.06)
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    am = mat("amarillo")
    cilindro("base", 0.2, 0.08, (0, 0, z + 0.04), gr, lados=32, bisel=0.015, padre=r)
    for k in range(8):
        a = k * math.tau / 8
        tornillo(f"base_perno{k}", (math.cos(a) * 0.17, math.sin(a) * 0.17, z + 0.08), r, r=0.008, normal="+Z")
    cilindro("columna", 0.11, 0.22, (0, 0, z + 0.19), ch, lados=32, bisel=0.02, padre=r)
    toro("columna_aro", 0.112, 0.01, (0, 0, z + 0.25), mat("acento_procesado"), padre=r)
    h = vacio("hombro", (0, 0, z + 0.32), r)
    cilindro("hombro_motor", 0.09, 0.1, (0, 0, 0), gr, lados=28, bisel=0.015, padre=h)
    b = vacio("brazo", (0, 0, 0), h)
    caja("brazo_viga", (0.42, 0.08, 0.07), (0.2, 0, 0.04), am, bisel=0.02, padre=b)
    caja("brazo_tapa", (0.3, 0.06, 0.01), (0.2, 0, 0.078), gr, bisel=0.003, padre=b)
    tubo_curvo("brazo_cable", [(0.02, 0.045, 0.05), (0.2, 0.06, 0.09), (0.38, 0.045, 0.05)], 0.008, mat("cable_negro", color=(0.06, 0.06, 0.07), rug=0.6), padre=b)
    p = vacio("pinza", (0.45, 0, 0), b)
    cilindro("pinza_muneca", 0.04, 0.06, (0, 0, 0.01), gr, lados=20, bisel=0.008, padre=p)
    caja("pinza_cuerpo", (0.08, 0.12, 0.06), (0, 0, -0.05), met, bisel=0.012, padre=p)
    for s in (-1, 1):
        caja(f"pinza_dedo{s}", (0.03, 0.015, 0.09), (0, s * 0.045, -0.12), met, bisel=0.004, padre=p)
        caja(f"pinza_goma{s}", (0.032, 0.006, 0.03), (0, s * 0.037, -0.15), mat("goma"), bisel=0.002, padre=p)
    torre_luces((-0.3, 0.3, z), r, r=0.025, h=0.03, poste=0.1)
    return r


def divisor():
    r = vacio("divisor")
    z = zocalo_1x1(r, 0.1)
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    caja("tolva", (0.8, 0.8, 0.12), (0, 0, z + 0.06), ch, bisel=0.02, padre=r)
    caja("banda", (0.6, 0.6, 0.01), (0, 0, z + 0.125), mat("goma"), bisel=0.002, padre=r)
    # tres rampas de salida (+X, -Y, +Y de Blender) con chevron
    for k, (dx, dy, a) in enumerate(((1, 0, 0), (0, -1, -math.pi / 2), (0, 1, math.pi / 2))):
        caja(f"rampa{k}", (0.2, 0.3, 0.02), (dx * 0.4, dy * 0.4, z + 0.13), mat("acento_procesado"), bisel=0.005, padre=r, giro=(0, 0, a))
        chevron(f"rampa{k}_flecha", (dx * 0.4, dy * 0.4, z + 0.141), 0.12, mat("amarillo"), r).rotation_euler = (0, 0, a)
    g = vacio("gira_paleta", (0, 0, z + 0.13), r)
    cilindro("paleta_eje", 0.04, 0.12, (0, 0, 0.06), gr, lados=20, bisel=0.008, padre=g)
    for k in range(3):
        a = k * math.tau / 3
        caja(f"paleta{k}", (0.24, 0.02, 0.08), (math.cos(a) * 0.12, math.sin(a) * 0.12, 0.05), mat("amarillo"), bisel=0.005, padre=g, giro=(0, 0, a))
    for s in (-1, 1):
        caja(f"guarda{s}", (0.8, 0.02, 0.1), (-0.2, s * 0.39, z + 0.17), met, bisel=0.004, padre=r)
    torre_luces((-0.35, -0.35, z), r, r=0.025, h=0.03, poste=0.08)
    return r


def almacen():
    r = vacio("almacen")
    z = zocalo_1x1(r, 0.06)
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    # contenedor de plástico apilable con tapa abatible y ventana de nivel
    caja("contenedor", (0.82, 0.78, 0.55), (0, 0, z + 0.3), ch, bisel=0.03, padre=r)
    for k in range(5):
        caja(f"nervio{k}", (0.83, 0.79, 0.02), (0, 0, z + 0.08 + k * 0.11), mat("chasis_osc"), bisel=0.005, padre=r)
    caja("tapa", (0.86, 0.82, 0.04), (0, 0, z + 0.6), mat("acento_producto"), bisel=0.015, padre=r)
    for s in (-1, 1):
        caja(f"asa{s}", (0.2, 0.03, 0.04), (0, s * 0.405, z + 0.5), gr, bisel=0.008, padre=r)
    caja("ventana_marco", (0.06, 0.02, 0.44), (0.3, -0.395, z + 0.3), gr, bisel=0.006, padre=r)
    nv = vacio("barra", (0.3, -0.405, z + 0.09), r)
    caja("barra_nivel", (0.04, 0.008, 0.42), (0, 0, 0.21), mat("nivel_verde", color=(0.3, 1.0, 0.45), emision=(0.3, 1.0, 0.45), fuerza=1.5), bisel=0.002, padre=nv)
    # boca de salida (+X) con lamas
    boca_cinta("boca_salida", 1, 0.5, 0.0, r, salida=True)
    if CAL:
        ruta = os.path.join(CAL, "placa_logo.png")
        if os.path.exists(ruta):
            calcomania("logo", 0.16, 0.08, (-0.15, -0.396, z + 0.35), mat_calcomania("placa_logo", ruta), padre=r)
    return r


def incubadora():
    r = vacio("incubadora")
    z = zocalo_1x1(r, 0.05)
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    caja("cuerpo", (0.62, 0.55, 0.7), (0, 0.05, z + 0.35), ch, bisel=0.03, padre=r)
    caja("puerta_marco", (0.52, 0.03, 0.56), (0, -0.235, z + 0.37), gr, bisel=0.01, padre=r)
    caja("puerta_vidrio", (0.46, 0.035, 0.5), (0, -0.235, z + 0.37), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.2), bisel=0.0, padre=r)
    caja("interior", (0.5, 0.45, 0.52), (0, 0.06, z + 0.37), mat("interior_inc", color=(0.85, 0.88, 0.86), rug=0.4, emision=(1.0, 0.9, 0.7), fuerza=0.3), bisel=0.01, padre=r)
    for k in range(3):
        caja(f"bandeja{k}", (0.46, 0.4, 0.008), (0, 0.06, z + 0.17 + k * 0.17), met, bisel=0.002, padre=r)
        for j in range(3):
            cilindro(f"placa_mini{k}{j}", 0.05, 0.012, (-0.14 + j * 0.14, 0.0, z + 0.18 + k * 0.17), mat("placa_verde", color=(0.5, 0.85, 0.35), rug=0.3),
                     lados=20, padre=r)
    pl = vacio("placa", (0.0, -0.03, z + 0.53), r)
    cilindro("placa_crece", 0.07, 0.016, (0, 0, 0), mat("cultivo_crece", color=(0.45, 0.9, 0.3), rug=0.3, emision=(0.3, 0.8, 0.2), fuerza=0.5), lados=24, padre=pl)
    caja("panel", (0.6, 0.04, 0.1), (0, -0.215, z + 0.72), gr, bisel=0.01, padre=r)
    pantalla_plano("pantalla", 0.25, 0.06, (-0.1, -0.237, z + 0.72), padre=r)
    caja("tirador", (0.03, 0.03, 0.2), (0.21, -0.27, z + 0.37), met, bisel=0.006, padre=r)
    for s in (-1, 1):
        caja(f"bisagra{s}", (0.03, 0.03, 0.05), (-0.25, -0.25, z + 0.37 + s * 0.2), met, bisel=0.005, padre=r)
    caja("salida_bandeja", (0.18, 0.18, 0.04), (0.38, 0.0, z + 0.04), mat("acento_producto"), bisel=0.01, padre=r)
    chevron("salida_flecha", (0.47, 0, 0.002), 0.12, mat("amarillo"), r)
    baliza_peq(r, (0.25, 0.25, z + 0.7))
    return r


def baliza_peq(r, pos):
    caja("piloto_caja", (0.05, 0.05, 0.03), (pos[0], pos[1], pos[2] + 0.015), mat("grafito"), bisel=0.008, padre=r)
    esfera("baliza", 0.022, (pos[0], pos[1], pos[2] + 0.03), mat("baliza", color=(0.3, 1.0, 0.45), rug=0.2, emision=(0.3, 1.0, 0.45), fuerza=4.0), padre=r, media=True)


def toma_agua():
    r = vacio("toma_agua")
    z = zocalo_1x1(r, 0.05)
    gr, met = mat("grafito"), mat("metal")
    ac = mat("acero_inox", color=(0.72, 0.74, 0.76), metal=0.85, rug=0.3)
    # tubería que baja de la pared, filtro de cartucho, grifo y garrafa en una bandeja
    cilindro("tubo_vertical", 0.035, 1.1, (-0.32, 0.25, z + 0.55), ac, lados=20, padre=r)
    for k in range(3):
        caja(f"abrazadera{k}", (0.08, 0.04, 0.03), (-0.32, 0.29, z + 0.2 + k * 0.35), met, bisel=0.005, padre=r)
    cilindro("filtro", 0.07, 0.25, (-0.32, 0.25, z + 0.6), mat("filtro_azul", color=(0.2, 0.45, 0.85), rug=0.3, alfa=0.7), lados=24, bisel=0.01, padre=r)
    cilindro("filtro_cartucho", 0.04, 0.22, (-0.32, 0.25, z + 0.6), mat("cartucho", color=(0.95, 0.95, 0.9), rug=0.6), lados=16, padre=r)
    tubo_curvo("brazo_grifo", [(-0.32, 0.25, z + 0.95), (-0.32, 0.1, z + 1.0), (0.0, 0.0, z + 0.95), (0.05, 0.0, z + 0.8)], 0.03, ac, padre=r)
    toro("llave", 0.04, 0.008, (-0.1, 0.05, z + 1.0), mat("valvula_azul", color=(0.15, 0.35, 0.85), rug=0.4), padre=r)
    caja("bandeja", (0.4, 0.4, 0.04), (0.05, 0.0, z + 0.02), gr, bisel=0.01, padre=r)
    for k in range(6):
        caja(f"bandeja_rejilla{k}", (0.36, 0.01, 0.01), (0.05, -0.15 + k * 0.06, z + 0.045), met, bisel=0.002, padre=r)
    cilindro("garrafa", 0.13, 0.32, (0.05, 0.0, z + 0.21), mat("garrafa_pl", color=(0.8, 0.9, 0.97), rug=0.1, alfa=0.35), lados=32, bisel=0.03, padre=r)
    ag = vacio("agua", (0.05, 0.0, z + 0.06), r)
    cilindro("agua_nivel", 0.12, 0.28, (0, 0, 0.14), mat("liq_agua", color=(0.35, 0.6, 0.95), rug=0.15), lados=28, bisel=0.0, padre=ag)
    cilindro("garrafa_cuello", 0.05, 0.05, (0.05, 0.0, z + 0.4), mat("garrafa_pl"), lados=20, padre=r)
    chevron("salida_flecha", (0.47, 0, 0.002), 0.12, mat("amarillo"), r)
    baliza_peq(r, (0.3, 0.3, z))
    return r


def recolector():
    """Mejora de la incubadora: brazo de pórtico que saca las placas solo."""
    r = vacio("recolector")
    met, gr = mat("metal"), mat("grafito")
    for s in (-1, 1):
        caja(f"poste{s}", (0.04, 0.04, 0.95), (0.35, s * 0.3, 0.48), met, bisel=0.006, padre=r)
    caja("viga", (0.04, 0.64, 0.05), (0.35, 0, 0.95), mat("amarillo"), bisel=0.008, padre=r)
    caja("carro", (0.1, 0.1, 0.1), (0.35, -0.1, 0.88), mat("acento_procesado"), bisel=0.015, padre=r)
    cilindro("vastago", 0.012, 0.3, (0.35, -0.1, 0.7), met, lados=10, padre=r)
    caja("ventosa", (0.06, 0.06, 0.02), (0.35, -0.1, 0.54), mat("goma"), bisel=0.004, padre=r)
    return r


def bomba():
    """Mejora de la toma de agua: bomba centrífuga con motor y manómetro."""
    r = vacio("bomba")
    caja("bancada", (0.3, 0.2, 0.04), (-0.25, -0.3, 0.02), mat("grafito"), bisel=0.008, padre=r)
    cilindro("motor", 0.07, 0.18, (-0.3, -0.3, 0.11), mat("motor_azul", color=(0.15, 0.3, 0.55), rug=0.4), lados=24, bisel=0.01, giro=(0, math.radians(90), 0), padre=r)
    cilindro("voluta", 0.08, 0.06, (-0.15, -0.3, 0.11), mat("acero_inox", color=(0.72, 0.74, 0.76), metal=0.85, rug=0.3), lados=24, bisel=0.01,
             giro=(0, math.radians(90), 0), padre=r)
    manometro("mano_bomba", (-0.15, -0.37, 0.24), r, r=0.03)
    return r


def hub():
    """Hub de envío 2×2: andén con franjas, marquesina, rampa de rodillos que recibe las cajas y furgoneta."""
    r = vacio("hub")
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    caja("anden", (1.96, 1.96, 0.25), (0, 0, 0.125), gr, bisel=0.03, padre=r)
    if CAL:
        fp = os.path.join(CAL, "franja_peligro.png")
        if os.path.exists(fp):
            for s in (-1, 1):
                calcomania(f"franja{s}", 1.9, 0.08, (0, s * 0.92, 0.2505), mat_calcomania("franja_peligro", fp), padre=r, giro=(0, 0, 0))
    # rampa de rodillos a lo largo de X en la mitad de atrás
    caja("rampa_bastidor", (1.5, 0.4, 0.06), (-0.1, 0.5, 0.3), met, bisel=0.01, padre=r)
    for k in range(14):
        cilindro(f"rodillo{k}", 0.025, 0.36, (-0.8 + k * 0.1, 0.5, 0.345), mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.2), lados=12,
                 giro=(math.radians(90), 0, 0), padre=r)
    # caseta con báscula y pantalla
    caja("caseta", (0.45, 0.45, 0.55), (-0.7, -0.6, 0.525), ch, bisel=0.03, padre=r)
    caja("caseta_franja", (0.452, 0.452, 0.05), (-0.7, -0.6, 0.72), mat("acento_producto"), bisel=0.01, padre=r)
    pantalla_plano("pantalla", 0.3, 0.16, (-0.7, -0.826, 0.55), padre=r)
    # marquesina
    for s in (-1, 1):
        cilindro(f"marquesina_poste{s}", 0.03, 1.3, (0.85, s * 0.85, 0.9), met, lados=12, padre=r)
    caja("marquesina", (0.9, 1.96, 0.04), (0.6, 0, 1.56), mat("acento_producto"), bisel=0.01, padre=r, giro=(0, math.radians(-8), 0))
    # furgoneta (nodo «van»): carrocería, cabina, ruedas, logo
    v = vacio("van", (0.2, -0.45, 0.25), r)
    blanco = mat("van_blanco", color=(0.93, 0.94, 0.93), rug=0.35)
    caja("van_caja", (1.1, 0.55, 0.55), (0, 0, 0.35), blanco, bisel=0.04, padre=v)
    caja("van_cabina", (0.32, 0.53, 0.42), (0.7, 0, 0.29), blanco, bisel=0.05, padre=v)
    caja("van_parabrisas", (0.04, 0.48, 0.2), (0.85, 0, 0.42), mat("cristal_oscuro", color=(0.15, 0.22, 0.27), rug=0.1), bisel=0.01, padre=v)
    caja("van_franja", (1.12, 0.56, 0.08), (0, 0, 0.5), mat("acento_producto"), bisel=0.01, padre=v)
    for x in (-0.35, 0.65):
        for s in (-1, 1):
            cilindro(f"van_rueda{x}{s}", 0.1, 0.07, (x, s * 0.28, 0.1), mat("goma"), lados=20, bisel=0.02, giro=(math.radians(90), 0, 0), padre=v)
            cilindro(f"van_llanta{x}{s}", 0.05, 0.072, (x, s * 0.28, 0.1), met, lados=12, giro=(math.radians(90), 0, 0), padre=v)
    for s in (-1, 1):
        caja(f"van_faro{s}", (0.02, 0.08, 0.05), (0.87, s * 0.18, 0.2), mat("faro", color=(1.0, 0.95, 0.8), emision=(1.0, 0.95, 0.8), fuerza=2.0), bisel=0.005, padre=v)
    if CAL:
        ruta = os.path.join(CAL, "placa_logo.png")
        if os.path.exists(ruta):
            calcomania("van_logo", 0.4, 0.2, (0, -0.278, 0.35), mat_calcomania("placa_logo", ruta), padre=v)
    torre_luces((0.85, 0.85, 0.25), r)
    return r


def terminal():
    r = vacio("terminal")
    gr, ch = mat("grafito"), mat("chasis")
    caja("pie", (0.3, 0.25, 0.04), (0, 0, 0.02), gr, bisel=0.01, padre=r)
    caja("cuerpo", (0.42, 0.32, 0.85), (0, 0.02, 0.47), ch, bisel=0.03, padre=r)
    caja("cabezal", (0.46, 0.36, 0.3), (0, 0.02, 1.0), gr, bisel=0.03, padre=r, giro=(math.radians(-12), 0, 0))
    pantalla_plano("pantalla", 0.36, 0.22, (0, -0.16, 1.01), padre=r, giro=(math.radians(78), 0, 0))
    caja("teclado", (0.36, 0.14, 0.03), (0, -0.2, 0.82), gr, bisel=0.008, padre=r, giro=(math.radians(20), 0, 0))
    for k in range(12):
        caja(f"tecla{k}", (0.04, 0.03, 0.01), (-0.13 + (k % 6) * 0.052, -0.2 - (k // 6) * 0.04, 0.84 + (k // 6) * 0.012), mat("tecla_blanca", color=(0.9, 0.9, 0.88)),
             bisel=0.002, padre=r, giro=(math.radians(20), 0, 0))
    caja("ranura_ticket", (0.15, 0.02, 0.01), (0, -0.142, 0.65), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r)
    caja("franja", (0.422, 0.322, 0.05), (0, 0.02, 0.8), mat("acento_procesado"), bisel=0.01, padre=r)
    return r


def puerta():
    """Puerta doble de pacientes en la pared oeste (mira a +X): marco, hojas con ventanuco, luz verde."""
    r = vacio("puerta")
    gr, met = mat("grafito"), mat("metal")
    caja("marco", (0.12, 1.3, 2.2), (0, 0, 1.1), gr, bisel=0.02, padre=r)
    for s, n in ((-1, "hoja_i"), (1, "hoja_d")):
        h = vacio(n, (0.04, s * 0.55, 0), r)
        caja(n + "_cuerpo", (0.05, 0.53, 1.95), (0, -s * 0.27, 0.99), mat("puerta_azul", color=(0.45, 0.65, 0.72), rug=0.5), bisel=0.01, padre=h)
        caja(n + "_vidrio", (0.055, 0.2, 0.35), (0, -s * 0.27, 1.45), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.25), bisel=0.0, padre=h)
        caja(n + "_barra", (0.04, 0.4, 0.04), (0.04, -s * 0.27, 1.0), met, bisel=0.008, padre=h)
        caja(n + "_patada", (0.056, 0.5, 0.25), (0, -s * 0.27, 0.15), met, bisel=0.004, padre=h)
    caja("cartel_luz", (0.08, 0.6, 0.14), (0.05, 0, 2.15), mat("luz_verde", color=(0.3, 1.0, 0.45), emision=(0.3, 1.0, 0.45), fuerza=2.5), bisel=0.01, padre=r)
    return r


def muelle_carga():
    """Muelle de carga 1×1 donde el camión deja los pedidos: palé con cajas y báscula."""
    r = vacio("muelle_carga")
    gr = mat("grafito")
    caja("bascula", (0.9, 0.9, 0.08), (0, 0, 0.04), gr, bisel=0.02, padre=r)
    madera = mat("madera_palet", color=(0.62, 0.48, 0.3), rug=0.85)
    for k in range(3):
        caja(f"palet_tabla{k}", (0.8, 0.14, 0.025), (0, -0.3 + k * 0.3, 0.17), madera, bisel=0.003, padre=r)
        caja(f"palet_taco{k}", (0.8, 0.1, 0.08), (0, -0.3 + k * 0.3, 0.12), madera, bisel=0.004, padre=r)
    for k in range(4):
        caja(f"caja{k}", (0.3, 0.3, 0.25), (-0.17 + (k % 2) * 0.34, -0.17 + (k // 2) * 0.34, 0.31), mat("carton", color=(0.72, 0.56, 0.36), rug=0.8),
             bisel=0.01, padre=r)
        caja(f"caja{k}_cinta", (0.31, 0.05, 0.252), (-0.17 + (k % 2) * 0.34, -0.17 + (k // 2) * 0.34, 0.31), mat("cinta_adhesiva", color=(0.85, 0.75, 0.5), rug=0.4),
             bisel=0.0, padre=r)
    chevron("salida_flecha", (0.47, 0, 0.081), 0.12, mat("amarillo"), r)
    return r


def main():
    global CAL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, CAL = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("brazo", brazo), ("divisor", divisor), ("almacen", almacen), ("incubadora", incubadora),
                       ("toma_agua", toma_agua), ("recolector", recolector), ("bomba", bomba), ("hub", hub),
                       ("terminal", terminal), ("puerta", puerta), ("muelle_carga", muelle_carga)):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("PIEZA", nombre)


if __name__ == "__main__":
    main()
