"""Tuberías y cápsulas (V1.9) y granja (V1.10): tubería recta y codo, depósito de sangre, cápsula de
donante, granja de cuatro cápsulas y centrífuga industrial (separadora de discos, 2×2).
Uso: blender -b -P tools/blender/piezas_v19.py -- <carpeta_salida> <carpeta_calcomanias>
Nodos: «sangre» (líquido de la tubería, el juego lo hace correr), «liquido» (nivel), «humano*»
(vacíos donde el juego mete a la persona), «rotor», «baliza_v/a/r», «pantalla».
Ejes: entra por -X, sale por +X; +Z del juego = -Y de Blender.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

CAL = None
ZT = 0.26       # altura del eje de las tuberías
RT = 0.065      # radio exterior de la tubería


def acero():
    return mat("acero_inox", color=(0.72, 0.74, 0.76), metal=0.85, rug=0.3)


def brida(nombre, pos, eje, padre, r=RT * 1.55):
    """Brida con seis tornillos. eje: 'x' o 'y'."""
    giro = (0, math.radians(90), 0) if eje == "x" else (math.radians(90), 0, 0)
    cilindro(nombre, r, 0.024, pos, acero(), lados=32, bisel=0.004, giro=giro, padre=padre)
    for k in range(6):
        a = k * math.tau / 6 + 0.3
        dx, dy, dz = 0, 0, 0
        if eje == "x":
            dy, dz = math.cos(a) * r * 0.78, math.sin(a) * r * 0.78
            cilindro(f"{nombre}_perno{k}", 0.008, 0.04, (pos[0], pos[1] + dy, pos[2] + dz), mat("metal"), lados=6,
                     bisel=0.001, giro=giro, padre=padre)
        else:
            dx, dz = math.cos(a) * r * 0.78, math.sin(a) * r * 0.78
            cilindro(f"{nombre}_perno{k}", 0.008, 0.04, (pos[0] + dx, pos[1], pos[2] + dz), mat("metal"), lados=6,
                     bisel=0.001, giro=giro, padre=padre)


def soporte(nombre, x, y, padre):
    """Pie de tubería: placa al suelo, poste y abrazadera."""
    gr, met = mat("grafito"), mat("metal")
    caja(nombre + "_placa", (0.12, 0.12, 0.012), (x, y, 0.006), gr, bisel=0.003, padre=padre)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cilindro(f"{nombre}_taco{sx}{sy}", 0.008, 0.008, (x + sx * 0.042, y + sy * 0.042, 0.016), met, lados=6, padre=padre)
    caja(nombre + "_poste", (0.035, 0.035, ZT - RT - 0.01), (x, y, (ZT - RT) / 2 + 0.006), mat("amarillo"), bisel=0.006, padre=padre)
    toro(nombre + "_abrazadera", RT + 0.006, 0.008, (x, y, ZT), met, padre=padre).rotation_euler = (0, math.radians(90), 0)


def tuberia_recta():
    r = vacio("tuberia_recta")
    ac = acero()
    # tramo de acero, mirilla de vidrio en el centro con la sangre dentro
    for s in (-1, 1):
        cilindro(f"tubo{s}", RT, 0.3, (s * 0.32, 0, ZT), ac, lados=32, bisel=0.0, giro=(0, math.radians(90), 0), padre=r)
        brida(f"brida_ext{s}", (s * 0.488, 0, ZT), "x", r)
        brida(f"brida_mir{s}", (s * 0.165, 0, ZT), "x", r)
    cilindro("mirilla", RT * 0.95, 0.31, (0, 0, ZT), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.18), lados=32,
             bisel=0.0, giro=(0, math.radians(90), 0), padre=r)
    cilindro("sangre", RT * 0.8, 0.31, (0, 0, ZT), mat("liq_sangre_tubo", color=(0.32, 0.01, 0.02), rug=0.25), lados=24,
             bisel=0.0, giro=(0, math.radians(90), 0), padre=r)
    # flecha de sentido pintada encima y etiqueta roja de «sangre»
    chevron("flecha", (0.32, 0, ZT + RT + 0.001), 0.07, mat("amarillo"), r)
    manga("banda_roja", RT + 0.0015, 0.05, (-0.32, 0, ZT), mat("banda_sangre", color=(0.75, 0.08, 0.06), rug=0.5), padre=r,
          lados=32).rotation_euler = (0, math.radians(90), 0)
    soporte("pie", 0.32, 0, r)
    return r


def tuberia_curva():
    """Codo: entra por -X y sale por -Y de Blender (+Z del juego)."""
    r = vacio("tuberia_curva")
    ac = acero()
    pts = [(-0.5, 0, ZT), (-0.2, 0, ZT), (0, -0.2, ZT), (0, -0.5, ZT)]
    tubo_curvo("codo", [(-0.5, 0, ZT), (-0.15, 0, ZT), (0.0, -0.15, ZT), (0, -0.5, ZT)], RT, ac, padre=r)
    brida("brida_a", (-0.488, 0, ZT), "x", r)
    brida("brida_b", (0, -0.488, ZT), "y", r)
    # vacío «sangre» sin malla para que el juego no falle; la mirilla del codo es un ojo de buey
    cilindro("ojo_marco", 0.04, 0.02, (-0.06, -0.06, ZT + RT - 0.004), mat("grafito"), lados=24, bisel=0.003, padre=r)
    cilindro("sangre", 0.03, 0.022, (-0.06, -0.06, ZT + RT - 0.002), mat("liq_sangre_tubo", color=(0.32, 0.01, 0.02), rug=0.25),
             lados=20, bisel=0.0, padre=r)
    cilindro("ojo_vidrio", 0.032, 0.024, (-0.06, -0.06, ZT + RT), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.18),
             lados=24, bisel=0.0, padre=r)
    soporte("pie", -0.04, -0.04, r)
    return r


def deposito():
    """Depósito vertical de 200 l: patas, virola con aros, mirilla de nivel, escalerilla, boca de hombre,
    válvula de salida con volante (+X) y entrada (-X)."""
    r = vacio("deposito")
    ac, gr, met = acero(), mat("grafito"), mat("metal")
    R, H, z0 = 0.34, 0.9, 0.12
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        x, y = math.cos(a) * R * 0.8, math.sin(a) * R * 0.8
        cilindro(f"pata{k}", 0.025, z0 + 0.05, (x, y, (z0 + 0.05) / 2), met, lados=12, padre=r)
        cilindro(f"pata_pie{k}", 0.045, 0.012, (x, y, 0.006), gr, lados=16, padre=r)
    torneado("cuerpo", [(0, z0 - 0.05), (R * 0.7, z0 - 0.04), (R, z0 + 0.04), (R, z0 + H), (R * 0.7, z0 + H + 0.08), (0.08, z0 + H + 0.1),
                        (0, z0 + H + 0.1)], ac, lados=48, padre=r)
    for k in range(3):
        toro(f"aro{k}", R + 0.005, 0.012, (0, 0, z0 + 0.15 + k * 0.32), met, padre=r)
    # mirilla de nivel con la sangre (nodo «liquido» con origen abajo)
    caja("nivel_marco", (0.05, 0.05, H - 0.1), (R + 0.03, -0.12, z0 + H / 2), gr, bisel=0.01, padre=r)
    caja("nivel_vidrio", (0.03, 0.055, H - 0.16), (R + 0.03, -0.12, z0 + H / 2), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.2),
         bisel=0.004, padre=r)
    lq = vacio("liquido", (R + 0.03, -0.12, z0 + 0.08), r)
    caja("liquido_sangre", (0.022, 0.045, H - 0.18), (0, 0, (H - 0.18) / 2), mat("liq_sangre_dep", color=(0.32, 0.01, 0.02), rug=0.25),
         bisel=0.002, padre=lq)
    for k in range(5):
        caja(f"nivel_marca{k}", (0.008, 0.02, 0.004), (R + 0.057, -0.12, z0 + 0.12 + k * 0.17), mat("blanco_marca", color=(0.95, 0.95, 0.95)),
             bisel=0.0, padre=r)
    # escalerilla
    for s in (-1, 1):
        caja(f"escala_larguero{s}", (0.015, 0.015, H + 0.1), (-0.08 + s * 0.08, R + 0.06, z0 + (H + 0.1) / 2), met, bisel=0.003, padre=r)
    for k in range(7):
        cilindro(f"escala_peldano{k}", 0.007, 0.16, (-0.08, R + 0.06, z0 + 0.1 + k * 0.13), met, lados=8,
                 giro=(0, math.radians(90), 0), padre=r)
    # boca de hombre arriba con tornillos
    cilindro("boca_hombre", 0.11, 0.04, (0.1, 0.05, z0 + H + 0.08), ac, lados=32, bisel=0.006, padre=r)
    for k in range(8):
        a = k * math.tau / 8
        cilindro(f"boca_perno{k}", 0.008, 0.02, (0.1 + math.cos(a) * 0.09, 0.05 + math.sin(a) * 0.09, z0 + H + 0.105), met, lados=6, padre=r)
    # conexiones: entrada (-X) y salida con válvula de volante (+X), a la altura de las tuberías
    cilindro("entrada", RT, 0.18, (-0.42, 0, ZT), ac, lados=24, giro=(0, math.radians(90), 0), padre=r)
    brida("brida_entrada", (-0.488, 0, ZT), "x", r)
    cilindro("salida", RT, 0.18, (0.42, 0, ZT), ac, lados=24, giro=(0, math.radians(90), 0), padre=r)
    brida("brida_salida", (0.488, 0, ZT), "x", r)
    caja("valvula", (0.1, 0.1, 0.1), (0.4, 0, ZT), mat("valvula_roja", color=(0.75, 0.1, 0.08), rug=0.4), bisel=0.02, padre=r)
    cilindro("valvula_vastago", 0.01, 0.08, (0.4, 0, ZT + 0.09), met, lados=8, padre=r)
    toro("valvula_volante", 0.045, 0.007, (0.4, 0, ZT + 0.13), mat("valvula_roja"), padre=r)
    calcomania_bio(r, (0.0, -R - 0.002, z0 + H * 0.6), 0.16)
    return r


def calcomania_bio(padre, pos, w):
    if CAL:
        ruta = os.path.join(CAL, "aviso_biorriesgo.png")
        if os.path.exists(ruta):
            calcomania("pegatina_bio", w, w, pos, mat_calcomania("aviso_biorriesgo", ruta, recorte=True), padre=padre)


def _capsula(r, x, y, idx, con_base=True):
    """Una cápsula: zócalo con maquinaria, cilindro de vidrio con líquido verdoso, tapa con tubos,
    soporte de bolsas de suero detrás y vacío «humano<idx>» donde el juego mete a la persona."""
    ac, gr, met = acero(), mat("grafito"), mat("metal")
    ch = mat("chasis")
    if con_base:
        caja(f"cap{idx}_zocalo", (0.8, 0.8, 0.12), (x, y, 0.06), gr, bisel=0.03, padre=r)
    cilindro(f"cap{idx}_base", 0.32, 0.12, (x, y, 0.18), ch, lados=40, bisel=0.02, padre=r)
    toro(f"cap{idx}_junta_baja", 0.3, 0.012, (x, y, 0.245), mat("goma"), padre=r)
    for k in range(10):  # rejilla de ventilación en la base
        a = k * math.tau / 10
        caja(f"cap{idx}_rejilla{k}", (0.04, 0.01, 0.06), (x + math.cos(a) * 0.32, y + math.sin(a) * 0.32, 0.17), gr, bisel=0.002, padre=r,
             giro=(0, 0, a + math.pi / 2))
    # vidrio con grosor y líquido de conservación
    H = 0.62
    torneado(f"cap{idx}_vidrio", [(0.27, 0.25), (0.28, 0.25), (0.28, 0.25 + H), (0.27, 0.25 + H)], vidrio(), lados=48, padre=r,
             pos=(x, y, 0), cerrar=True)
    lq = vacio(f"liquido_cap{idx}", (x, y, 0.255), r)
    torneado(f"cap{idx}_fluido", [(0, 0), (0.265, 0), (0.265, H * 0.92), (0.2, H * 0.925), (0, H * 0.93)],
             mat("liq_conservante", color=(0.45, 0.85, 0.55), rug=0.15, alfa=0.22), lados=40, padre=lq)
    vacio(f"humano{idx}", (x, y, 0.27), r)
    # tapa con anillo, tornillos y mangueras
    cilindro(f"cap{idx}_tapa", 0.31, 0.1, (x, y, 0.25 + H + 0.05), ch, lados=40, bisel=0.02, padre=r)
    toro(f"cap{idx}_junta_alta", 0.29, 0.012, (x, y, 0.25 + H), mat("goma"), padre=r)
    for k in range(8):
        a = k * math.tau / 8
        tornillo(f"cap{idx}_torn{k}", (x + math.cos(a) * 0.27, y + math.sin(a) * 0.27, 0.25 + H + 0.1), r, r=0.009, normal="+Z")
    cilindro(f"cap{idx}_cupula", 0.12, 0.06, (x, y, 0.25 + H + 0.13), gr, lados=24, bisel=0.01, padre=r)
    # vía de sangre: de la tapa baja por fuera a la salida (+X)
    tubo_curvo(f"cap{idx}_via_sangre", [(x, y, 0.25 + H + 0.16), (x + 0.15, y, 0.25 + H + 0.2), (x + 0.33, y - 0.05, 0.6),
                                         (x + 0.36, y - 0.05, ZT)], 0.014, mat("tubo_sangre_cap", color=(0.55, 0.03, 0.04), rug=0.3), padre=r)
    # vía de suero: de la bolsa (detrás, +Y) a la tapa
    tubo_curvo(f"cap{idx}_via_suero", [(x - 0.1, y + 0.36, 0.95), (x - 0.12, y + 0.2, 1.0), (x - 0.06, y + 0.05, 0.25 + H + 0.16)], 0.008,
               mat("via_suero", color=(0.9, 0.88, 0.6), rug=0.3, alfa=0.7), padre=r)
    cilindro(f"cap{idx}_palo", 0.012, 0.85, (x - 0.1, y + 0.38, 0.55), met, lados=10, padre=r)
    caja(f"cap{idx}_bolsa", (0.012, 0.09, 0.14), (x - 0.1, y + 0.36, 1.05), mat("bolsa_suero_pl", color=(0.85, 0.9, 0.95), rug=0.15, alfa=0.35),
         bisel=0.006, segmentos=3, padre=r, giro=(0, 0, math.radians(90)))
    lb = vacio(f"liquido_bolsa{idx}", (x - 0.1, y + 0.36, 0.99), r)
    caja(f"cap{idx}_bolsa_suero", (0.009, 0.08, 0.1), (0, 0, 0.05), mat("liq_suero_cap", color=(0.9, 0.85, 0.55), rug=0.2), bisel=0.004,
         padre=lb, giro=(0, 0, math.radians(90)))
    # monitor pequeño en la base, mirando al lado de trabajo (-Y)
    caja(f"cap{idx}_monitor", (0.16, 0.03, 0.1), (x, y - 0.33, 0.18), gr, bisel=0.01, padre=r)
    pantalla_plano(f"pantalla_cap{idx}", 0.13, 0.075, (x, y - 0.347, 0.18), padre=r)


def capsula():
    r = vacio("capsula")
    _capsula(r, 0, 0, 0)
    # salida de sangre a tubería (+X)
    cilindro("salida", RT, 0.12, (0.44, -0.05, ZT), acero(), lados=24, giro=(0, math.radians(90), 0), padre=r)
    brida("brida_salida", (0.488, -0.05, ZT), "x", r)
    # tolva de bolsas de suero (-X)
    caja("tolva_suero", (0.18, 0.3, 0.2), (-0.4, 0, 0.22), mat("chasis"), bisel=0.02, padre=r)
    caja("tolva_suero_boca", (0.12, 0.24, 0.02), (-0.4, 0, 0.325), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r)
    torre_luces((0.32, 0.32, 0.12), r, r=0.03, h=0.04, poste=0.12)
    calcomania_bio(r, (0.0, -0.4005, 0.08), 0.1)
    return r


def granja():
    """Hilera de cuatro cápsulas a lo largo de -Y (cuatro casillas), colector común de sangre que sale
    por +X en la primera (y = +1.5), línea de suero por arriba y pasarela."""
    r = vacio("granja")
    gr, met, ac = mat("grafito"), mat("metal"), acero()
    caja("bancada", (0.9, 3.96, 0.12), (0, 0, 0.06), gr, bisel=0.03, padre=r)
    for k in range(4):
        y = 1.5 - k
        _capsula(r, 0, y, k, con_base=False)
    # colector de sangre a lo largo de la hilera
    cilindro("colector", RT, 3.3, (0.38, 0, ZT), ac, lados=24, giro=(math.radians(90), 0, 0), padre=r)
    for k in range(4):
        brida(f"colector_brida{k}", (0.38, 1.5 - k - 0.45, ZT), "y", r)
    tubo_curvo("colector_salida", [(0.38, 1.65, ZT), (0.42, 1.5, ZT), (0.5, 1.5, ZT)], RT, ac, padre=r)
    brida("brida_salida", (0.488, 1.5, ZT), "x", r)
    # pórtico con la línea de suero por arriba
    for y in (1.95, -1.95):
        for s in (-1, 1):
            caja(f"portico_poste{y}{s}", (0.05, 0.05, 1.3), (s * 0.4, y, 0.65), mat("amarillo"), bisel=0.008, padre=r)
        caja(f"portico_trav{y}", (0.85, 0.05, 0.05), (0, y, 1.3), mat("amarillo"), bisel=0.008, padre=r)
    cilindro("linea_suero", 0.03, 3.9, (-0.2, 0, 1.25), mat("tubo_suero", color=(0.9, 0.85, 0.55), rug=0.35), lados=16,
             giro=(math.radians(90), 0, 0), padre=r)
    caja("cuadro_granja", (0.3, 0.08, 0.35), (0.25, -1.98, 0.5), mat("chasis"), bisel=0.015, padre=r)
    pantalla_plano("pantalla", 0.24, 0.16, (0.25, -2.022, 0.52), padre=r)
    torre_luces((-0.35, -1.85, 0.12), r)
    calcomania_bio(r, (-0.3, -1.98, 0.85), 0.18)
    return r


def centrifuga_ind():
    """Separadora de discos 2×2: bancada, bastidor, cuba con tapa abovedada y mirilla (rotor girando
    dentro), motor vertical con correa, entrada de sangre por tubería (-X), salida de tubos de plasma
    por una rampa con tapones a la cinta (+X), cuadro con pantalla y torre de luces."""
    r = vacio("centrifuga_ind")
    z = base_maquina(r, 2.0, CAL)
    gr, met, ac, ch = mat("grafito"), mat("metal"), acero(), mat("chasis")
    acc = mat("acento_procesado")
    caja("bastidor", (1.2, 1.2, 0.35), (-0.15, 0.1, z + 0.175), ch, bisel=0.04, padre=r)
    caja("bastidor_franja", (1.202, 0.06, 0.06), (-0.15, -0.5, z + 0.3), acc, bisel=0.01, padre=r)
    for k in range(4):
        tornillo(f"bastidor_torn{k}", (-0.7 + k * 0.36, -0.502, z + 0.08), r, r=0.012)
    # cuba
    cx, cy = -0.15, 0.1
    cilindro("cuba", 0.48, 0.45, (cx, cy, z + 0.575), ac, lados=48, bisel=0.02, padre=r)
    toro("cuba_aro", 0.485, 0.018, (cx, cy, z + 0.8), met, padre=r)
    esfera("cuba_cupula", 0.48, (cx, cy, z + 0.8), ac, padre=r, media=True, escala=(1, 1, 0.45))
    for k in range(12):
        a = k * math.tau / 12
        tornillo(f"cuba_perno{k}", (cx + math.cos(a) * 0.47, cy + math.sin(a) * 0.47, z + 0.82), r, r=0.011, normal="+Z")
    # mirilla en la cúpula: vidrio y rotor (discos) que gira debajo
    rot = vacio("rotor", (cx, cy, z + 0.82), r)
    for k in range(5):
        cilindro(f"rotor_disco{k}", 0.3 - k * 0.04, 0.015, (0, 0, k * 0.03), mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.2),
                 lados=32, bisel=0.003, padre=rot)
    for k in range(6):
        a = k * math.tau / 6
        caja(f"rotor_nervio{k}", (0.26, 0.02, 0.15), (math.cos(a) * 0.13, math.sin(a) * 0.13, 0.07), mat("rojo_rotor", color=(0.6, 0.05, 0.05), rug=0.3),
             bisel=0.004, padre=rot, giro=(0, 0, a))
    esfera("mirilla", 0.35, (cx, cy, z + 0.88), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.2), padre=r, media=True,
           escala=(1, 1, 0.5))
    # motor vertical y correa
    mx, my = 0.5, 0.45
    cilindro("motor", 0.14, 0.4, (mx, my, z + 0.55), mat("motor_azul", color=(0.15, 0.3, 0.55), rug=0.4), lados=32, bisel=0.02, padre=r)
    for k in range(16):
        a = k * math.tau / 16
        caja(f"motor_aleta{k}", (0.02, 0.01, 0.34), (mx + math.cos(a) * 0.145, my + math.sin(a) * 0.145, z + 0.55), mat("motor_azul"),
             bisel=0.002, padre=r, giro=(0, 0, a))
    cilindro("motor_ventilador", 0.13, 0.06, (mx, my, z + 0.78), gr, lados=32, bisel=0.01, padre=r)
    caja("correa_carter", (0.75, 0.12, 0.08), ((cx + mx) / 2, (cy + my) / 2, z + 0.4), mat("amarillo"), bisel=0.02, padre=r,
         giro=(0, 0, math.atan2(my - cy, mx - cx)))
    # entrada de sangre (-X) con brida a la altura de las tuberías (en el zócalo bajo)
    cilindro("entrada_tubo", RT, 0.5, (-0.75, -0.5, ZT), ac, lados=24, giro=(0, math.radians(90), 0), padre=r)
    brida("brida_entrada", (-0.988, -0.5, ZT), "x", r)
    tubo_curvo("entrada_subida", [(-0.55, -0.5, ZT), (-0.45, -0.4, z + 0.5), (cx - 0.4, cy - 0.2, z + 0.75)], RT * 0.8, ac, padre=r)
    for y in (-0.5, 0.5):  # segunda boca (fila 1) también
        pass
    cilindro("entrada_tubo2", RT, 0.5, (-0.75, 0.5, ZT), ac, lados=24, giro=(0, math.radians(90), 0), padre=r)
    brida("brida_entrada2", (-0.988, 0.5, ZT), "x", r)
    # salida de plasma: rampa con gradilla de tubos (+X, fila 0 = y +0.5 en Blender es -0.5 del juego?)
    caja("salida_rampa", (0.4, 0.3, 0.04), (0.8, -0.5, z + 0.25), ch, bisel=0.01, padre=r, giro=(0, math.radians(18), 0))
    boca_cinta("boca_salida", 1, 1.0, 0.5, r, salida=True)
    caja("cuadro", (0.36, 0.1, 0.42), (0.55, -0.8, z + 0.42), ch, bisel=0.02, padre=r)
    pantalla_plano("pantalla", 0.28, 0.16, (0.55, -0.852, z + 0.5), padre=r)
    cilindro("cuadro_seta", 0.03, 0.03, (0.45, -0.86, z + 0.3), mat("seta_roja", color=(0.85, 0.08, 0.06), rug=0.35), lados=20,
             bisel=0.008, giro=(math.radians(90), 0, 0), padre=r)
    manometro("mano_vel", (0.62, -0.856, z + 0.3), r, r=0.035)
    torre_luces((-0.8, 0.8, z), r)
    calcomania_bio(r, (-0.4, -0.502, z + 0.2), 0.12)
    if CAL:
        ruta = os.path.join(CAL, "aviso_rotor.png")
        if os.path.exists(ruta):
            calcomania("pegatina_rotor", 0.12, 0.12, (0.05, -0.502, z + 0.2), mat_calcomania("aviso_rotor", ruta, recorte=True), padre=r)
    return r


def main():
    global CAL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, CAL = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("tuberia_recta", tuberia_recta), ("tuberia_curva", tuberia_curva), ("deposito", deposito),
                       ("capsula", capsula), ("granja", granja), ("centrifuga_ind", centrifuga_ind)):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("PIEZA", nombre)


if __name__ == "__main__":
    main()
