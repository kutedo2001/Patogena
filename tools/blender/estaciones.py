"""Estaciones de extracción pieza a pieza (V1.7): camilla de extracción, kit de extracción
(portatubos, aguja, tubo de vacío con la sangre que sube, torniquete, algodón y tirita) y el
brazo extractor que se monta en la camilla con la mejora.
Uso: blender -b -P tools/blender/estaciones.py -- <carpeta_salida> <carpeta_texturas>
Ejes: la camilla va a lo largo de X (cabeza en -X); el lado de trabajo (donde está el científico
y el brazo del paciente) es -Y de Blender (+Z del juego). Casilla de 1 m.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

TEX = None
ESC = 0.65   # escala de la camilla y el brazo para que cuadren con los personajes del pack


def rueda(nombre, pos, padre):
    x, y, z = pos
    v = vacio(nombre, (x, y, 0), padre)
    cilindro(nombre + "_eje", 0.006, 0.05, (0, 0, 0.075), mat("metal"), lados=12, padre=v)
    caja(nombre + "_horquilla", (0.03, 0.028, 0.012), (0, 0, 0.05), mat("metal"), bisel=0.003, padre=v)
    for s in (-1, 1):
        caja(f"{nombre}_brazo{s}", (0.012, 0.004, 0.035), (0.006, s * 0.013, 0.032), mat("metal"), bisel=0.001, padre=v)
    cilindro(nombre + "_goma", 0.018, 0.016, (0.008, 0, 0.018), mat("goma"), lados=20, bisel=0.004, padre=v,
             giro=(math.radians(90), 0, 0))
    cilindro(nombre + "_buje", 0.008, 0.019, (0.008, 0, 0.018), mat("metal"), lados=12, bisel=0.001, padre=v,
             giro=(math.radians(90), 0, 0))
    caja(nombre + "_freno", (0.012, 0.012, 0.006), (-0.012, 0, 0.044), mat("pedal_freno", color=(0.75, 0.1, 0.1), rug=0.5),
         bisel=0.002, padre=v)


def camilla():
    r = vacio("camilla")
    met = mat("metal")
    cro = mat("cromo", color=(0.8, 0.82, 0.84), metal=1.0, rug=0.18)
    L, W = 0.9, 0.46
    # ---- base con ruedas, columna hidráulica y tijera
    for s in (-1, 1):
        cilindro(f"base_larguero{s}", 0.012, L - 0.08, (0, s * (W / 2 - 0.05), 0.085), met, lados=16,
                 giro=(0, math.radians(90), 0), padre=r)
    for x in (-L / 2 + 0.06, L / 2 - 0.06):
        cilindro(f"base_trav{x:.2f}", 0.012, W - 0.1, (x, 0, 0.085), met, lados=16, giro=(math.radians(90), 0, 0), padre=r)
        for s in (-1, 1):
            rueda(f"rueda{x:.2f}{s}", (x, s * (W / 2 - 0.05), 0), r)
    caja("cubre_base", (0.3, 0.2, 0.05), (0, 0, 0.11), mat("chasis"), bisel=0.02, padre=r)
    caja("cubre_base_franja", (0.302, 0.05, 0.012), (0, -0.075, 0.13), mat("acento_producto"), bisel=0.004, padre=r)
    cilindro("columna", 0.045, 0.16, (0, 0, 0.2), mat("chasis_osc"), lados=24, bisel=0.008, padre=r)
    cilindro("columna_vastago", 0.03, 0.06, (0, 0, 0.3), cro, lados=20, padre=r)
    cilindro("columna_fuelle", 0.05, 0.03, (0, 0, 0.13), mat("goma"), lados=24, bisel=0.008, padre=r)
    caja("pedal_altura", (0.06, 0.035, 0.012), (0.12, -0.13, 0.11), mat("grafito"), bisel=0.004, padre=r)
    # ---- somier, colchón, almohada y papel
    z0 = 0.34
    caja("somier", (L, W, 0.035), (0, 0, z0), mat("chasis"), bisel=0.012, padre=r)
    for s in (-1, 1):
        caja(f"somier_canto{s}", (L - 0.02, 0.012, 0.02), (0, s * (W / 2 + 0.002), z0), mat("grafito"), bisel=0.004, padre=r)
    vin = mat("vinilo", color=(0.16, 0.44, 0.46), rug=0.42)
    caja("colchon_cuerpo", (L * 0.64, W - 0.02, 0.07), (0.12, 0, z0 + 0.052), vin, bisel=0.028, segmentos=4, padre=r)
    caja("colchon_cabeza", (L * 0.33, W - 0.02, 0.07), (-0.3, 0, z0 + 0.06), vin, bisel=0.028, segmentos=4, padre=r,
         giro=(0, math.radians(-6), 0))
    for s in (-1, 1):  # vivos cosidos del colchón
        cilindro(f"vivo_cuerpo{s}", 0.003, L * 0.62, (0.12, s * (W / 2 - 0.012), z0 + 0.086), mat("vivo", color=(0.1, 0.3, 0.32), rug=0.5),
                 lados=8, giro=(0, math.radians(90), 0), padre=r)
    papel = mat("papel_camilla", color=(0.96, 0.96, 0.93), rug=0.85)
    caja("papel", (L * 0.86, W * 0.58, 0.003), (0.03, 0, z0 + 0.0905), papel, bisel=0.0, padre=r)
    for k in range(1, 6):  # perforaciones del rollo
        caja(f"papel_perfo{k}", (0.002, W * 0.58, 0.0035), (-0.35 + k * 0.13, 0, z0 + 0.0906),
             mat("papel_perfo", color=(0.8, 0.8, 0.77), rug=0.9), bisel=0.0, padre=r)
    # rollo de papel a los pies
    caja("rollo_soporte", (0.02, W * 0.7, 0.02), (L / 2 + 0.01, 0, z0 + 0.02), met, bisel=0.005, padre=r)
    cilindro("rollo", 0.032, W * 0.6, (L / 2 + 0.03, 0, z0 + 0.06), papel, lados=24, bisel=0.004,
             giro=(math.radians(90), 0, 0), padre=r)
    cilindro("rollo_eje", 0.008, W * 0.64, (L / 2 + 0.03, 0, z0 + 0.06), mat("grafito"), lados=12,
             giro=(math.radians(90), 0, 0), padre=r)
    caja("almohada", (0.15, 0.3, 0.05), (-0.34, 0, z0 + 0.115), mat("almohada", color=(0.92, 0.94, 0.95), rug=0.8),
         bisel=0.022, segmentos=4, padre=r, giro=(0, math.radians(-6), 0))
    # ---- barandilla plegada (lado lejano, +Y) con bisagras
    for x in (-0.28, 0.08):
        caja(f"baranda_bisagra{x}", (0.03, 0.02, 0.05), (x, W / 2 + 0.01, z0 + 0.02), mat("grafito"), bisel=0.005, padre=r)
    cilindro("baranda_alta", 0.011, 0.5, (-0.1, W / 2 + 0.015, z0 + 0.2), cro, lados=16, giro=(0, math.radians(90), 0), padre=r)
    cilindro("baranda_media", 0.008, 0.5, (-0.1, W / 2 + 0.015, z0 + 0.12), cro, lados=12, giro=(0, math.radians(90), 0), padre=r)
    for x in (-0.33, -0.1, 0.13):
        cilindro(f"baranda_poste{x}", 0.009, 0.2, (x, W / 2 + 0.015, z0 + 0.1), cro, lados=12, padre=r)
    # ---- reposabrazos de extracción (lado de trabajo, -Y), a la altura del codo
    xb = -0.12
    caja("brazal_soporte", (0.04, 0.08, 0.02), (xb, -W / 2 - 0.03, z0 + 0.03), met, bisel=0.006, padre=r)
    cilindro("brazal_rotula", 0.016, 0.03, (xb, -W / 2 - 0.005, z0 + 0.03), mat("grafito"), lados=16, padre=r)
    caja("brazal", (0.12, 0.17, 0.03), (xb, -W / 2 - 0.075, z0 + 0.06), vin, bisel=0.012, segmentos=3, padre=r)
    caja("brazal_papel", (0.09, 0.14, 0.002), (xb, -W / 2 - 0.075, z0 + 0.0765), papel, bisel=0.0, padre=r)
    # ---- palo de gotero con bolsa y monitor (cabecero, lado lejano)
    px, py = -L / 2 + 0.02, W / 2 - 0.03
    cilindro("gotero_palo", 0.008, 1.05, (px, py, z0 + 0.5), cro, lados=12, padre=r)
    cilindro("gotero_pinza", 0.016, 0.04, (px, py, z0 + 0.03), mat("grafito"), lados=16, padre=r)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        tubo_curvo(f"gotero_gancho{k}", [(px, py, z0 + 1.02), (px + math.cos(a) * 0.05, py + math.sin(a) * 0.05, z0 + 1.03),
                                         (px + math.cos(a) * 0.06, py + math.sin(a) * 0.06, z0 + 1.0)], 0.003, cro, padre=r)
    bolsa = mat("bolsa_suero_pl", color=(0.85, 0.9, 0.95), rug=0.15, alfa=0.35)
    caja("gotero_bolsa", (0.012, 0.07, 0.12), (px + 0.04, py, z0 + 0.92), bolsa, bisel=0.005, segmentos=3, padre=r)
    caja("gotero_suero", (0.009, 0.064, 0.085), (px + 0.04, py, z0 + 0.905), mat("liq_suero", color=(0.9, 0.85, 0.55), rug=0.2),
         bisel=0.004, padre=r)
    caja("gotero_etq", (0.0125, 0.05, 0.03), (px + 0.04, py, z0 + 0.94), mat("etq_bolsa", color=(0.95, 0.95, 0.9), rug=0.7),
         bisel=0.0, padre=r)
    cilindro("gotero_camara", 0.008, 0.03, (px + 0.04, py, z0 + 0.84), bolsa, lados=12, padre=r)
    tubo_curvo("gotero_via", [(px + 0.04, py, z0 + 0.825), (px + 0.06, py - 0.02, z0 + 0.6), (px + 0.1, py - 0.08, z0 + 0.3),
                              (px + 0.14, py - 0.1, z0 + 0.12)], 0.0022, mat("via", color=(0.9, 0.9, 0.85), rug=0.3, alfa=0.6), padre=r)
    # monitor de constantes en un brazo del palo, mirando al lado de trabajo
    caja("monitor_brazo", (0.012, 0.09, 0.012), (px, py - 0.045, z0 + 0.62), met, bisel=0.003, padre=r)
    caja("monitor_caja", (0.06, 0.015, 0.11), (px + 0.01, py - 0.1, z0 + 0.62), mat("chasis"), bisel=0.008, padre=r,
         giro=(0, 0, math.radians(-25)))
    caja("monitor_marco", (0.13, 0.03, 0.095), (px + 0.03, py - 0.11, z0 + 0.62), mat("grafito"), bisel=0.008, padre=r,
         giro=(0, 0, math.radians(-25)))
    pantalla_plano("pantalla", 0.11, 0.075, (px + 0.025, py - 0.127, z0 + 0.62), padre=r,
                   giro=(math.radians(90), 0, math.radians(-25)))
    for k in range(3):
        cilindro(f"monitor_boton{k}", 0.005, 0.004, (px + 0.075 + k * 0.006, py - 0.115 - k * 0.003, z0 + 0.565),
                 mat("boton_" + str(k), color=((0.2, 0.8, 0.3), (0.95, 0.7, 0.1), (0.9, 0.15, 0.1))[k], rug=0.4),
                 lados=10, giro=(math.radians(90), 0, math.radians(-25)), padre=r)
    # ---- bandeja de instrumental a los pies, lado de trabajo
    tx, ty = 0.33, -W / 2 - 0.06
    cilindro("bandeja_eje", 0.009, 0.16, (tx + 0.05, -W / 2 + 0.02, z0 - 0.02), met, lados=12, padre=r)
    caja("bandeja_brazo", (0.02, 0.1, 0.012), (tx + 0.05, -W / 2 - 0.03, z0 + 0.065), met, bisel=0.004, padre=r)
    acero = mat("acero_bandeja", color=(0.75, 0.77, 0.78), metal=0.9, rug=0.28)
    caja("bandeja", (0.17, 0.12, 0.008), (tx, ty, z0 + 0.075), acero, bisel=0.003, padre=r)
    for s in (-1, 1):
        caja(f"bandeja_borde_x{s}", (0.17, 0.004, 0.014), (tx, ty + s * 0.06, z0 + 0.083), acero, bisel=0.001, padre=r)
        caja(f"bandeja_borde_y{s}", (0.004, 0.12, 0.014), (tx + s * 0.085, ty, z0 + 0.083), acero, bisel=0.001, padre=r)
    # gradilla con tubos vacíos (tapón rojo) en la bandeja
    caja("bandeja_gradilla", (0.07, 0.024, 0.02), (tx - 0.04, ty + 0.03, z0 + 0.09), mat("gradilla_pl", color=(0.95, 0.95, 0.92), rug=0.5),
         bisel=0.003, padre=r)
    vd = vidrio()
    for k in range(4):
        x = tx - 0.064 + k * 0.016
        cilindro(f"bandeja_tubo{k}", 0.0055, 0.05, (x, ty + 0.03, z0 + 0.115), vd, lados=16, bisel=0.001, padre=r)
        cilindro(f"bandeja_tapon{k}", 0.0062, 0.011, (x, ty + 0.03, z0 + 0.145), mat("tapon_sangre", color=(0.62, 0.03, 0.03), rug=0.45),
                 lados=16, bisel=0.002, padre=r)
    # bote de alcohol, tarro de algodón y contenedor de agujas
    cilindro("alcohol", 0.012, 0.045, (tx + 0.02, ty - 0.03, z0 + 0.1), mat("alcohol_pl", color=(0.85, 0.9, 0.95), rug=0.2, alfa=0.5),
             lados=20, bisel=0.003, padre=r)
    cilindro("alcohol_liq", 0.0105, 0.032, (tx + 0.02, ty - 0.03, z0 + 0.095), mat("liq_alcohol", color=(0.55, 0.75, 0.95), rug=0.2),
             lados=20, padre=r)
    cilindro("alcohol_tapon", 0.007, 0.012, (tx + 0.02, ty - 0.03, z0 + 0.128), mat("tapon_blanco", color=(0.95, 0.95, 0.95), rug=0.4),
             lados=12, bisel=0.002, padre=r)
    cilindro("algodon_tarro", 0.016, 0.03, (tx + 0.055, ty + 0.02, z0 + 0.094), mat("tarro_vidrio", color=(0.8, 0.9, 0.95), rug=0.05, alfa=0.25),
             lados=20, padre=r)
    esfera("algodon_bolas", 0.015, (tx + 0.055, ty + 0.02, z0 + 0.1), mat("algodon", color=(0.98, 0.98, 0.97), rug=1.0), padre=r,
           escala=(1, 1, 0.9))
    amar = mat("contenedor_agujas", color=(0.97, 0.78, 0.1), rug=0.45)
    caja("agujas_contenedor", (0.04, 0.04, 0.05), (tx + 0.055, ty - 0.03, z0 + 0.105), amar, bisel=0.006, padre=r)
    caja("agujas_tapa", (0.042, 0.042, 0.008), (tx + 0.055, ty - 0.03, z0 + 0.133), mat("tapa_roja", color=(0.85, 0.1, 0.08), rug=0.4),
         bisel=0.003, padre=r)
    # ---- tornillos y pegatina de la empresa en el cubre-base
    for x in (-0.13, 0.13):
        tornillo(f"cubre_torn{x}", (x, -0.101, 0.11), r, r=0.006)
    # ---- piloto de estado en el pie (el juego cambia su color)
    caja("piloto_caja", (0.03, 0.05, 0.03), (L / 2 - 0.02, -W / 2 + 0.07, z0 + 0.035), mat("grafito"), bisel=0.006, padre=r)
    esfera("baliza", 0.016, (L / 2 - 0.02, -W / 2 + 0.07, z0 + 0.05), mat("baliza", color=(0.3, 1.0, 0.45), rug=0.2,
           emision=(0.3, 1.0, 0.45), fuerza=4.0), padre=r, media=True)
    # escala de personaje: el paciente mide ~0,45 m de juego; la camilla se queda en 0,59 × 0,3
    r.scale = (ESC, ESC, ESC)
    return r


def kit():
    """Kit de extracción. Eje del kit: aguja hacia +Y (hacia el cuerpo del paciente).
    Nodos: kit (portatubos con aguja y tubo), sangre_kit (escalar en Y del juego = Z de Blender? no: escalar en su eje
    local, se crea con origen en el fondo del tubo y largo en +Y), torniquete, algodon, tirita, tapa_aguja."""
    raiz = vacio("kit_extraccion")
    k = vacio("kit", (0, 0, 0), raiz)
    pp = mat("polipropileno_kit", color=(0.92, 0.94, 0.95), rug=0.35, alfa=0.55)
    R, Lh = 0.0095, 0.045
    # portatubos: cilindro hueco translúcido con aleta para los dedos
    torneado("portatubos", [(R - 0.0008, 0.0), (R, 0.0), (R, Lh), (0.0045, Lh + 0.004), (0.0035, Lh + 0.004), (0.0035, Lh + 0.0025),
                             (R - 0.0008, Lh)], pp, lados=32, padre=k, cerrar=True).rotation_euler = (math.radians(-90), 0, 0)
    caja("portatubos_aleta", (0.034, 0.003, 0.012), (0, 0.0015, 0), pp, bisel=0.0012, padre=k)
    # cono verde de la aguja (calibre 21) y aguja de acero biselada
    torneado("aguja_cono", [(0, 0), (0.0042, 0), (0.0042, 0.004), (0.0025, 0.009), (0, 0.009)],
             mat("cono_verde", color=(0.15, 0.62, 0.25), rug=0.4), lados=20, padre=k, pos=(0, Lh + 0.004, 0)).rotation_euler = (math.radians(-90), 0, 0)
    aguja = mat("acero_aguja", color=(0.85, 0.87, 0.9), metal=1.0, rug=0.12)
    cilindro("aguja", 0.0007, 0.024, (0, Lh + 0.025, 0), aguja, lados=8, bisel=0.0, giro=(math.radians(-90), 0, 0), padre=k)
    # tubo de vacío dentro del portatubos (tapón de goma hacia la aguja), vidrio con grosor
    Rt, Ht = 0.0068, 0.062
    tb = vacio("tubo_kit", (0, -0.02, 0), k)
    torneado("tubo_kit_vidrio", [(0, 0.0), (Rt * 0.7, 0.0006), (Rt, 0.003), (Rt, Ht), (Rt - 0.0007, Ht), (Rt - 0.0007, 0.003),
                                 (Rt * 0.6, 0.0013), (0, 0.0013)], vidrio(), lados=28, padre=tb, cerrar=True).rotation_euler = (math.radians(-90), 0, 0)
    # sangre con menisco: origen en el fondo (el juego la escala en su eje largo)
    sangre = vacio("sangre_kit", (0, 0.0013, 0), tb)
    s = torneado("sangre_kit_liq", [(0, 0), (Rt - 0.0009, 0.0015), (Rt - 0.0009, Ht - 0.016), (Rt * 0.6, Ht - 0.0172), (0, Ht - 0.0175)],
                 mat("liq_sangre_kit", color=(0.11, 0.0, 0.003), rug=0.22), lados=24, padre=sangre)
    s.rotation_euler = (math.radians(-90), 0, 0)
    estriado("tubo_kit_tapon", Rt + 0.0012, 0.015, 14, 0.0007, mat("tapon_sangre", color=(0.62, 0.03, 0.03), rug=0.45),
             padre=tb, pos=(0, Ht + 0.013, 0)).rotation_euler = (math.radians(90), 0, 0)
    manga("tubo_kit_etq", Rt + 0.0002, 0.025, (0, 0.012, 0), mat_imagen("etq_sangre", os.path.join(TEX, "sangre.png"), 0.7),
          padre=tb, arco=0.6, lados=28).rotation_euler = (math.radians(-90), 0, 0)
    # capuchón de la aguja (se quita al empezar)
    cilindro("tapa_aguja", 0.0034, 0.028, (0.03, 0.0, 0.0), mat("capuchon", color=(0.15, 0.62, 0.25), rug=0.45, alfa=0.9),
             lados=14, bisel=0.001, giro=(math.radians(-90), 0, 0), padre=raiz)
    # torniquete: banda azul de látex anudada (se pone en el brazo)
    tq = vacio("torniquete", (0, 0, 0), raiz)
    azul = mat("latex_azul", color=(0.1, 0.35, 0.85), rug=0.5)
    toro("torniquete_banda", 0.024, 0.0035, (0, 0, 0), azul, padre=tq).scale = (1, 1, 2.2)
    for sx in (-1, 1):
        caja(f"torniquete_cola{sx}", (0.004, 0.012, 0.04), (sx * 0.008, 0.028, 0.02 * sx), azul, bisel=0.001, padre=tq,
             giro=(math.radians(30 * sx), 0, math.radians(20 * sx)))
    # algodón con alcohol y tirita
    esfera("algodon", 0.008, (0, 0, 0), mat("algodon", color=(0.98, 0.98, 0.97), rug=1.0), padre=raiz, escala=(1.2, 1, 0.55)).location = (0.06, 0, 0)
    ti = vacio("tirita", (0.09, 0, 0), raiz)
    caja("tirita_tira", (0.03, 0.011, 0.0015), (0, 0, 0), mat("tirita_piel", color=(0.93, 0.76, 0.6), rug=0.7), bisel=0.0007, padre=ti)
    caja("tirita_gasa", (0.011, 0.008, 0.0018), (0, 0, 0.0002), mat("tirita_gasa", color=(0.97, 0.95, 0.92), rug=0.9), bisel=0.0005, padre=ti)
    return raiz


def extractor():
    """Brazo extractor que se atornilla al pie de la camilla (lado de trabajo). Nodos para la IK del juego:
    hombro (gira en Z de Blender = Y del juego), codo (gira igual), muneca. Longitudes: 0,22 y 0,2."""
    r = vacio("extractor_camilla")
    ch, gr, met = mat("chasis"), mat("grafito"), mat("metal")
    acc = mat("acento_procesado")
    caja("ext_abrazadera", (0.08, 0.05, 0.06), (0, 0, 0), gr, bisel=0.01, padre=r)
    for s in (-1, 1):
        tornillo(f"ext_torn{s}", (s * 0.025, -0.026, 0.0), r, r=0.006)
    cilindro("ext_columna", 0.028, 0.2, (0, -0.035, 0.12), ch, lados=24, bisel=0.006, padre=r)
    caja("ext_columna_franja", (0.06, 0.004, 0.02), (0, -0.064, 0.17), acc, bisel=0.002, padre=r)
    h = vacio("hombro", (0, -0.035, 0.23), r)
    cilindro("ext_hombro_motor", 0.036, 0.05, (0, 0, 0), gr, lados=24, bisel=0.008, padre=h)
    caja("ext_brazo1", (0.22, 0.04, 0.03), (0.11, 0, 0.012), ch, bisel=0.012, padre=h)
    caja("ext_brazo1_tapa", (0.16, 0.03, 0.004), (0.11, 0, 0.029), acc, bisel=0.002, padre=h)
    c = vacio("codo", (0.22, 0, 0.02), h)
    cilindro("ext_codo_motor", 0.026, 0.045, (0, 0, 0), gr, lados=20, bisel=0.006, padre=c)
    caja("ext_brazo2", (0.2, 0.032, 0.024), (0.1, 0, 0.012), ch, bisel=0.01, padre=c)
    tubo_curvo("ext_cable", [(0.0, 0.0, 0.03), (0.08, 0.018, 0.04), (0.16, 0.0, 0.035)], 0.004, mat("cable_rojo", color=(0.7, 0.08, 0.08), rug=0.5), padre=c)
    m = vacio("muneca", (0.2, 0, 0.0), c)
    cilindro("ext_muneca", 0.018, 0.04, (0, 0, -0.01), gr, lados=16, bisel=0.004, padre=m)
    cilindro("ext_pinza_base", 0.012, 0.02, (0, 0, -0.04), met, lados=12, padre=m)
    for s in (-1, 1):
        caja(f"ext_dedo{s}", (0.006, 0.004, 0.03), (0, s * 0.008, -0.06), met, bisel=0.001, padre=m)
    cilindro("ext_led", 0.006, 0.004, (0, -0.0185, 0.0), mat("led_verde", color=(0.2, 0.9, 0.3), emision=(0.2, 1.0, 0.35), fuerza=3.0),
             lados=10, giro=(math.radians(90), 0, 0), padre=m)
    r.scale = (ESC, ESC, ESC)
    return r


def main():
    global TEX
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, TEX = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("camilla", camilla), ("kit_extraccion", kit), ("extractor_camilla", extractor)):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("EST", nombre)


if __name__ == "__main__":
    main()
