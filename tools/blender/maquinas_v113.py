"""Máquinas de la cadena profunda (V1.13) y mesa de ingeniería genética (V1.14), al nivel del lote 1:
bancada con patas regulables, bocas con lamas por fila (entradas -X, salida +X), torre de luces,
pantalla viva, tornillos, pegatinas y una pieza de proceso que se mueve y se entiende.
Uso: blender -b -P tools/blender/maquinas_v113.py -- <carpeta_salida> <carpeta_calcomanias>
- sintetizador (2×2): síntesis de péptidos — columnas de vidrio con resina y un cabezal que dosifica.
- destilador (2×2): alambique de vidrio con matraz que burbujea, columna de fraccionamiento y serpentín.
- impresora (2×2): impresora molecular — cámara de vidrio con pórtico XY y cabezal que deposita cápsides.
- fusionador (3×3): fusionador genético — anillo de contención con brazos que giran alrededor del núcleo.
- mesa_genetica (1×3): banco de ingeniería genética con pantalla grande del árbol, microscopio,
  cabina de guantes y tolva de entrega.
Nodos animados que lee maquina.gd: rotor, agitador, cabezal (va y viene en X), carro (Y), liquido,
burbuja*, gira_*, pantalla, baliza_v/a/r.
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

CAL = None


def _pegatinas(r, z, lado=2.0, cuales=("aviso_biorriesgo",)):
    if not CAL:
        return
    for k, nombre in enumerate(cuales):
        ruta = os.path.join(CAL, nombre + ".png")
        if os.path.exists(ruta):
            calcomania(f"pegatina_{nombre}", 0.12, 0.12, (-0.3 + k * 0.2, -lado / 2 + 0.198, z), mat_calcomania(nombre, ruta, recorte=True), padre=r)


def _armario(r, z, ancho=1.6, fondo=1.2, alto=0.5, x=0.0, y=0.1, acento="acento_procesado"):
    ch, gr = mat("chasis"), mat("grafito")
    caja("armario", (ancho, fondo, alto), (x, y, z + alto / 2), ch, bisel=0.04, padre=r)
    caja("armario_franja", (ancho + 0.002, 0.06, 0.06), (x, y - fondo / 2, z + alto - 0.1), mat(acento), bisel=0.01, padre=r)
    for k in range(4):
        tornillo(f"armario_torn{k}", (x - ancho / 2 + 0.1 + k * (ancho - 0.2) / 3, y - fondo / 2 - 0.002, z + 0.06), r, r=0.011)
    # rejilla de ventilación lateral
    for k in range(8):
        caja(f"armario_rejilla{k}", (0.012, 0.3, 0.02), (x + ancho / 2 + 0.002, y + 0.1, z + 0.12 + k * 0.035), gr, bisel=0.002, padre=r)
    return z + alto


def _bocas(r, z, filas, lado=2.0, salida_fila=1):
    """Bocas con lamas en -X por fila y salida en +X en la fila indicada. Fila i → y = (n-1)/2 - i."""
    n = int(lado)
    bocas_estandar(r, n, filas, salida_fila)


def _cuadro(r, z, x, y, ancho=0.34):
    ch = mat("chasis")
    caja("cuadro", (ancho, 0.1, 0.36), (x, y, z + 0.32), ch, bisel=0.02, padre=r)
    caja("cuadro_poste", (0.07, 0.07, 0.16), (x, y + 0.02, z + 0.08), mat("grafito"), bisel=0.01, padre=r)
    pantalla_plano("pantalla", ancho - 0.08, 0.16, (x, y - 0.052, z + 0.38), padre=r)
    cilindro("cuadro_seta", 0.026, 0.03, (x - ancho / 2 + 0.06, y - 0.058, z + 0.2), mat("seta_roja", color=(0.85, 0.08, 0.06), rug=0.35),
             lados=20, bisel=0.008, giro=(math.radians(90), 0, 0), padre=r)
    for k in range(3):
        cilindro(f"cuadro_tecla{k}", 0.012, 0.012, (x + 0.02 + k * 0.04, y - 0.056, z + 0.2), mat(f"tecla{k}", color=((0.2, 0.8, 0.3), (0.95, 0.7, 0.1), (0.85, 0.85, 0.85))[k]),
                 lados=12, bisel=0.003, giro=(math.radians(90), 0, 0), padre=r)


def sintetizador():
    r = vacio("sintetizador")
    z = base_maquina(r, 2.0, CAL)
    zt = _armario(r, z, alto=0.45)
    gr, met = mat("grafito"), mat("metal")
    # cinco columnas de vidrio con resina naranja que se llena (llenar_*) sobre una placa
    caja("placa_columnas", (1.1, 0.3, 0.03), (-0.2, 0.25, zt + 0.015), gr, bisel=0.008, padre=r)
    for k in range(5):
        x = -0.6 + k * 0.2
        torneado(f"columna{k}", [(0.045, 0), (0.05, 0), (0.05, 0.45), (0.045, 0.45)], vidrio(), lados=28, padre=r,
                 pos=(x, 0.25, zt + 0.03), cerrar=True)
        ll = vacio(f"llenar_col{k}", (x, 0.25, zt + 0.035), r)
        cilindro(f"columna{k}_resina", 0.042, 0.4, (0, 0, 0.2), mat("resina", color=(0.9, 0.5, 0.12), rug=0.4, emision=(0.9, 0.45, 0.1), fuerza=0.3),
                 lados=24, bisel=0.0, padre=ll)
        cilindro(f"columna{k}_tapa", 0.055, 0.03, (x, 0.25, zt + 0.49), met, lados=24, bisel=0.005, padre=r)
        tubo_curvo(f"columna{k}_via", [(x, 0.25, zt + 0.5), (x, 0.15, zt + 0.62), (x + 0.05, -0.05, zt + 0.62)], 0.008,
                   mat("via_ptfe", color=(0.9, 0.9, 0.85), rug=0.3, alfa=0.8), padre=r)
    # pórtico con cabezal dosificador que va y viene en X
    for s in (-1, 1):
        caja(f"portico_pie{s}", (0.05, 0.05, 0.75), (s * 0.75, -0.25, zt + 0.375), met, bisel=0.008, padre=r)
    caja("portico_viga", (1.6, 0.06, 0.06), (0, -0.25, zt + 0.75), met, bisel=0.01, padre=r)
    cab = vacio("cabezal", (0, -0.25, zt + 0.7), r)
    caja("cabezal_cuerpo", (0.12, 0.1, 0.16), (0, 0, 0), mat("acento_procesado"), bisel=0.02, padre=cab)
    cilindro("cabezal_aguja", 0.006, 0.12, (0, 0, -0.14), met, lados=8, padre=cab)
    cilindro("cabezal_led", 0.01, 0.006, (0, -0.052, 0.04), mat("led_verde", color=(0.2, 0.9, 0.3), emision=(0.2, 1.0, 0.35), fuerza=3.0),
             lados=10, giro=(math.radians(90), 0, 0), padre=cab)
    # botellas de reactivos en la parte trasera
    for k in range(4):
        cilindro(f"botella{k}", 0.05, 0.16, (0.3 + k * 0.12, 0.5, zt + 0.08), mat(f"botella_pl{k}", color=((0.6, 0.2, 0.8), (0.2, 0.5, 0.9), (0.9, 0.85, 0.3), (0.85, 0.85, 0.85))[k], rug=0.3, alfa=0.7),
                 lados=20, bisel=0.01, padre=r)
        cilindro(f"botella{k}_tapon", 0.025, 0.04, (0.3 + k * 0.12, 0.5, zt + 0.18), gr, lados=16, bisel=0.004, padre=r)
    _bocas(r, z, (0, 1))
    _cuadro(r, zt, 0.55, -0.55)
    torre_luces((0.8, 0.75, zt), r)
    _pegatinas(r, z + 0.2)
    return r


def destilador():
    r = vacio("destilador")
    z = base_maquina(r, 2.0, CAL)
    zt = _armario(r, z, alto=0.35, acento="acento_producto")
    gr, met = mat("grafito"), mat("metal")
    # manta calefactora y matraz redondo con líquido morado que burbujea
    cilindro("manta", 0.24, 0.12, (-0.4, 0.15, zt + 0.06), mat("manta", color=(0.2, 0.22, 0.24), rug=0.7), lados=32, bisel=0.02, padre=r)
    esfera("matraz", 0.22, (-0.4, 0.15, zt + 0.3), vidrio(), padre=r)
    lq = vacio("liquido", (-0.4, 0.15, zt + 0.12), r)
    esfera("matraz_liquido", 0.2, (0, 0, 0.13), mat("liq_destilado", color=(0.45, 0.12, 0.6), rug=0.15, emision=(0.5, 0.1, 0.7), fuerza=0.4), padre=lq,
           escala=(1, 1, 0.75))
    for k in range(6):
        esfera(f"burbuja{k}", 0.015, (-0.4 + math.cos(k) * 0.08, 0.15 + math.sin(k * 1.7) * 0.08, zt + 0.2 + k * 0.02),
               mat("burbuja", color=(0.85, 0.75, 0.95), rug=0.1, alfa=0.6), padre=r)
    # columna de fraccionamiento con anillos y serpentín refrigerante hasta el colector
    cilindro("columna", 0.05, 0.6, (-0.4, 0.15, zt + 0.82), vidrio(), lados=24, bisel=0.0, padre=r)
    for k in range(6):
        toro(f"columna_anillo{k}", 0.05, 0.006, (-0.4, 0.15, zt + 0.57 + k * 0.1), met, padre=r)
    pts = [(-0.4, 0.15, zt + 1.12), (-0.2, 0.15, zt + 1.15)]
    for k in range(10):
        a = k * 0.9
        pts.append((0.0 + math.cos(a) * 0.12, 0.15 + math.sin(a) * 0.12, zt + 1.0 - k * 0.06))
    pts.append((0.35, 0.0, zt + 0.25))
    tubo_curvo("serpentin", pts, 0.018, mat("vidrio_serp", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.3), padre=r)
    cilindro("refrigerante", 0.16, 0.65, (0.0, 0.15, zt + 0.72), mat("cristal", color=(0.6, 0.85, 0.95), rug=0.05, alfa=0.15), lados=32, padre=r)
    # colector de neurotoxina con ampollas en gradilla
    caja("colector", (0.3, 0.2, 0.2), (0.45, -0.05, zt + 0.1), mat("chasis"), bisel=0.02, padre=r)
    for k in range(4):
        cilindro(f"colector_ampolla{k}", 0.018, 0.06, (0.36 + k * 0.06, -0.05, zt + 0.23), mat("liq_destilado"), lados=12, padre=r)
    # soportes de laboratorio con pinzas
    cilindro("soporte_varilla", 0.012, 1.1, (-0.7, 0.15, zt + 0.55), met, lados=10, padre=r)
    for zz in (0.5, 0.95):
        caja(f"pinza{zz}", (0.3, 0.02, 0.02), (-0.55, 0.15, zt + zz), met, bisel=0.004, padre=r)
    _bocas(r, z, (0, 1))
    manometro("mano_temp", (0.62, -0.52, zt + 0.15), r, r=0.04)
    _cuadro(r, zt, 0.15, -0.55)
    torre_luces((0.8, 0.75, zt), r)
    _pegatinas(r, z + 0.2)
    return r


def impresora():
    r = vacio("impresora")
    z = base_maquina(r, 2.0, CAL)
    zt = _armario(r, z, alto=0.3)
    gr, met = mat("grafito"), mat("metal")
    # cámara de vidrio con marco
    W, D, H = 1.3, 1.1, 0.75
    for sx in (-1, 1):
        for sy in (-1, 1):
            caja(f"marco_poste{sx}{sy}", (0.04, 0.04, H), (sx * W / 2, 0.1 + sy * D / 2, zt + H / 2), gr, bisel=0.006, padre=r)
    for zz in (0.0, H):
        caja(f"marco_x{zz}", (W, 0.04, 0.04), (0, 0.1 - D / 2, zt + zz), gr, bisel=0.006, padre=r)
        caja(f"marco_xb{zz}", (W, 0.04, 0.04), (0, 0.1 + D / 2, zt + zz), gr, bisel=0.006, padre=r)
    caja("cristal_frente", (W - 0.04, 0.01, H - 0.04), (0, 0.1 - D / 2, zt + H / 2), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.14), bisel=0.0, padre=r)
    caja("techo", (W, D, 0.04), (0, 0.1, zt + H + 0.02), mat("chasis"), bisel=0.01, padre=r)
    # pórtico XY: carro (Y) que lleva la viga y cabezal (X)
    for s in (-1, 1):
        caja(f"guia{s}", (0.03, D - 0.1, 0.03), (s * (W / 2 - 0.08), 0.1, zt + H - 0.08), met, bisel=0.005, padre=r)
    car = vacio("carro", (0, 0.1, zt + H - 0.1), r)
    caja("carro_viga", (W - 0.12, 0.05, 0.05), (0, 0, 0), mat("amarillo"), bisel=0.01, padre=car)
    cab = vacio("cabezal", (0, 0, -0.06), car)
    caja("cabezal_cuerpo", (0.1, 0.1, 0.12), (0, 0, 0), mat("acento_procesado"), bisel=0.015, padre=cab)
    cilindro("cabezal_boquilla", 0.012, 0.06, (0, 0, -0.09), met, lados=12, padre=cab)
    cilindro("cabezal_laser", 0.006, 0.25, (0, 0, -0.24), mat("laser", color=(0.3, 1.0, 0.6), emision=(0.3, 1.0, 0.6), fuerza=6.0, alfa=0.7),
             lados=8, bisel=0.0, padre=cab)
    # bandeja con cápsides a medio imprimir (geodésicas)
    caja("bandeja", (0.8, 0.6, 0.03), (0, 0.1, zt + 0.06), met, bisel=0.008, padre=r)
    for k in range(6):
        x, y = -0.25 + (k % 3) * 0.25, 0.0 + (k // 3) * 0.22
        bpy_ico = esfera(f"capside_imp{k}", 0.045, (x, y, zt + 0.12), mat("capside_imp", color=(0.75, 0.9, 1.0), rug=0.25, emision=(0.3, 0.6, 1.0), fuerza=0.4),
                         padre=r, escala=(1, 1, 0.5 + 0.1 * k))
    _bocas(r, z, (0, 1))
    _cuadro(r, zt, 0.62, -0.6, ancho=0.3)
    torre_luces((-0.8, 0.8, zt + H + 0.04), r)
    _pegatinas(r, z + 0.2)
    return r


def fusionador():
    r = vacio("fusionador")
    z = base_maquina(r, 3.0, CAL)
    ch, gr, met = mat("chasis"), mat("grafito"), mat("metal")
    # plataforma circular y anillo de contención
    cilindro("plataforma", 1.1, 0.2, (0, 0, z + 0.1), ch, lados=64, bisel=0.03, padre=r)
    toro("plataforma_franja", 1.1, 0.02, (0, 0, z + 0.18), mat("acento_producto"), padre=r)
    for k in range(4):
        a = k * math.pi / 2 + math.pi / 4
        cilindro(f"pilar{k}", 0.08, 1.2, (math.cos(a) * 0.95, math.sin(a) * 0.95, z + 0.8), gr, lados=24, bisel=0.01, padre=r)
        for j in range(3):
            toro(f"pilar{k}_bobina{j}", 0.085, 0.015, (math.cos(a) * 0.95, math.sin(a) * 0.95, z + 0.5 + j * 0.25), mat("cobre", color=(0.8, 0.45, 0.2), metal=1.0, rug=0.3), padre=r)
    toro("anillo_alto", 0.95, 0.06, (0, 0, z + 1.42), gr, padre=r)
    # cúpula de vidrio con el núcleo latiendo dentro
    esfera("cupula", 0.65, (0, 0, z + 0.2), mat("cristal", color=(0.75, 0.95, 0.85), rug=0.05, alfa=0.15), padre=r, media=True, escala=(1, 1, 1.4))
    lq = vacio("liquido", (0, 0, z + 0.22), r)
    caja("nucleo_vivo", (0.3, 0.3, 0.3), (0, 0, 0.45), mat("nucleo_vivo", color=(0.3, 0.95, 0.15), rug=0.3, emision=(0.35, 1.0, 0.2), fuerza=2.0),
         bisel=0.05, segmentos=3, padre=lq, giro=(math.radians(35), math.radians(45), 0))
    # brazos que giran alrededor (gira_)
    g = vacio("gira_brazos", (0, 0, z + 0.2), r)
    for k in range(3):
        a = k * math.tau / 3
        caja(f"brazo{k}", (0.6, 0.06, 0.06), (math.cos(a) * 0.7, math.sin(a) * 0.7, 0.9), met, bisel=0.01, padre=g, giro=(0, 0, a))
        cilindro(f"brazo{k}_emisor", 0.05, 0.12, (math.cos(a) * 0.42, math.sin(a) * 0.42, 0.9), mat("emisor", color=(0.4, 1.0, 0.5), emision=(0.4, 1.0, 0.5), fuerza=3.0),
                 lados=16, giro=(0, math.radians(90), a), padre=g)
    # tuberías de alimentación desde las bocas
    for i, y in enumerate((1.0, 0.0, -1.0)):
        tubo_curvo(f"alimentacion{i}", [(-1.3, y, z + 0.2), (-1.0, y * 0.6, z + 0.35), (-0.6, y * 0.3, z + 0.3)], 0.04, mat("tubo_amarillo"), padre=r)
    _bocas(r, z, (0, 1, 2), lado=3.0, salida_fila=1)
    _cuadro(r, z, 1.0, -1.25, ancho=0.4)
    torre_luces((1.25, 1.25, z), r)
    _pegatinas(r, z + 0.2, lado=3.0, cuales=("aviso_biorriesgo", "aviso_rotor"))
    return r


def mesa_genetica():
    """Banco de 1×3 (a lo largo de Y): pantalla grande del árbol de la cepa, cabina de guantes,
    microscopio, centrifuguita de mesa, tolva de entrega con flecha y taburete."""
    r = vacio("mesa_genetica")
    ch, gr, met = mat("chasis"), mat("grafito"), mat("metal")
    # patas y tablero
    for sy in (-1, 1):
        for sx in (-1, 1):
            caja(f"pata{sx}{sy}", (0.05, 0.05, 0.4), (sx * 0.35, sy * 1.35, 0.2), met, bisel=0.008, padre=r)
    caja("tablero", (0.85, 2.9, 0.05), (0, 0, 0.42), mat("tablero_resina", color=(0.18, 0.2, 0.22), rug=0.35), bisel=0.01, padre=r)
    caja("cajonera", (0.7, 0.6, 0.35), (0, 1.0, 0.2), ch, bisel=0.02, padre=r)
    for k in range(3):
        caja(f"cajon{k}", (0.005, 0.5, 0.09), (-0.352, 1.0, 0.08 + k * 0.11), gr, bisel=0.002, padre=r)
        caja(f"tirador{k}", (0.02, 0.12, 0.015), (-0.36, 1.0, 0.1 + k * 0.11), met, bisel=0.004, padre=r)
    # pantalla grande en dos postes (mira a -X, hacia donde está el científico)
    for s in (-1, 1):
        cilindro(f"pantalla_poste{s}", 0.02, 0.5, (0.32, s * 0.45, 0.7), met, lados=12, padre=r)
    caja("pantalla_marco", (0.05, 1.3, 0.6), (0.3, 0, 1.05), gr, bisel=0.02, padre=r)
    pantalla_plano("pantalla", 1.2, 0.52, (0.272, 0, 1.05), padre=r, giro=(math.radians(90), 0, math.radians(-90)))
    # cabina de guantes con la cepa (vidrio, dos guantes)
    caja("cabina", (0.5, 0.7, 0.4), (0.05, -0.95, 0.65), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.18), bisel=0.02, padre=r)
    caja("cabina_base", (0.52, 0.72, 0.04), (0.05, -0.95, 0.46), ch, bisel=0.01, padre=r)
    caja("cabina_techo", (0.52, 0.72, 0.05), (0.05, -0.95, 0.87), ch, bisel=0.01, padre=r)
    for s in (-1, 1):
        toro(f"guante_aro{s}", 0.06, 0.012, (-0.2, -0.95 + s * 0.15, 0.62), gr, padre=r).rotation_euler = (0, math.radians(90), 0)
        cilindro(f"guante{s}", 0.05, 0.18, (-0.12, -0.95 + s * 0.15, 0.6), mat("guante", color=(0.15, 0.2, 0.25), rug=0.6), lados=16,
                 giro=(0, math.radians(80), 0), padre=r)
    for k in range(3):
        cilindro(f"cabina_placa{k}", 0.05, 0.01, (0.15, -1.1 + k * 0.12, 0.49), mat("placa_verde", color=(0.4, 0.85, 0.3), rug=0.3, emision=(0.3, 0.9, 0.2), fuerza=0.5),
                 lados=20, padre=r)
    # microscopio
    cilindro("micro_base", 0.07, 0.03, (-0.1, 0.35, 0.46), gr, lados=20, bisel=0.006, padre=r)
    caja("micro_brazo", (0.04, 0.05, 0.22), (-0.03, 0.35, 0.58), gr, bisel=0.008, padre=r, giro=(0, math.radians(-15), 0))
    cilindro("micro_tubo", 0.025, 0.14, (-0.08, 0.35, 0.72), met, lados=16, padre=r, giro=(0, math.radians(30), 0))
    cilindro("micro_platina", 0.05, 0.01, (-0.12, 0.35, 0.56), met, lados=20, padre=r)
    # tolva de entrega (a -X, hacia el pasillo) con flecha amarilla
    caja("tolva", (0.25, 0.35, 0.18), (-0.3, 0.0, 0.54), ch, bisel=0.02, padre=r)
    caja("tolva_boca", (0.18, 0.28, 0.02), (-0.3, 0.0, 0.64), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r)
    chevron("tolva_flecha", (-0.44, 0.0, 0.002), 0.2, mat("amarillo"), r)
    # taburete
    cilindro("taburete_asiento", 0.13, 0.04, (-0.6, -0.4, 0.3), mat("asiento_azul", color=(0.15, 0.35, 0.6), rug=0.5), lados=24, bisel=0.01, padre=r)
    cilindro("taburete_pie", 0.02, 0.28, (-0.6, -0.4, 0.15), met, lados=12, padre=r)
    for k in range(5):
        a = k * math.tau / 5
        caja(f"taburete_pata{k}", (0.15, 0.025, 0.02), (-0.6 + math.cos(a) * 0.07, -0.4 + math.sin(a) * 0.07, 0.02), met, bisel=0.004, padre=r, giro=(0, 0, a))
    torre_luces((0.3, 1.3, 0.445), r, r=0.03, h=0.04, poste=0.15)
    return r


def main():
    global CAL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, CAL = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("sintetizador", sintetizador), ("destilador", destilador), ("impresora", impresora),
                       ("fusionador", fusionador), ("mesa_genetica", mesa_genetica)):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("MAQ", nombre)


if __name__ == "__main__":
    main()
