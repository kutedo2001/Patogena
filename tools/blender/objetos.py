"""Objetos de laboratorio pieza a pieza (P3.4a): tubos, eppendorf, vial, placa de Petri y gradilla.
Se usan solos (objetos que viajan por las cintas) y dentro de las máquinas.
Uso: blender -b -P tools/blender/objetos.py -- <carpeta_salida> <carpeta_texturas>
Escala: metros, algo generosa respecto a la real para que se lea con la cámara del juego.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *
import bmesh

TEX = None  # carpeta de texturas de etiquetas; la fija main()

# Colores de los productos (los mismos que usarán iconos y HUD)
COL = {
    "sangre": (0.11, 0.0, 0.003),
    "plasma": (0.9, 0.55, 0.06),
    "adn": (0.25, 0.95, 0.35),
    "mutacion": (0.3, 0.85, 0.05),
}


def arco(cx, cz, r, a0, a1, n):
    return [(cx + math.cos(math.radians(a0 + (a1 - a0) * i / n)) * r,
             cz + math.sin(math.radians(a0 + (a1 - a0) * i / n)) * r) for i in range(n + 1)]


# ---------------------------------------------------------------- tubo de muestra
def tubo(raiz_nombre="tubo_sangre", padre=None, pos=(0, 0, 0), tipo="sangre", R=0.012, H=0.13,
         lleno=0.72, con_etiqueta=True):
    """Tubo de muestra de vidrio de fondo redondo con tapón de rosca moleteado y etiqueta.
    tipo: sangre (tapón rojo), plasma (tapón amarillo, dos fases), cultivo."""
    r = vacio(raiz_nombre, pos, padre)
    t = 0.0011
    # vidrio: interior hacia arriba, borde, exterior hacia abajo
    interior = [(0, t)] + [(x, z) for x, z in arco(0, R, R - t, -90, 0, 10)[1:]] + [(R - t, H)]
    exterior = [(R, H)] + [(x, z) for x, z in reversed(arco(0, R, R, -90, 0, 10))]
    torneado("vidrio", interior + exterior, vidrio(), lados=40, padre=r)
    # líquido con menisco
    ri = R - t - 0.0002
    hf = H * lleno
    def liquido(nombre, z0, z1, color, emis=0.0, fondo=True, menisco=True):
        m = mat("liq_" + nombre, color=color, rug=0.22, emision=color if emis else None, fuerza=emis)
        if fondo:
            base = [(0, t + 0.0002)] + [(x, z) for x, z in arco(0, R, ri, -90, 0, 10)[1:]]
        else:
            base = [(0, z0), (ri, z0)]
        cima = [(ri, z1 + (0.0025 if menisco else 0)), (ri * 0.7, z1 + 0.0004), (0, z1)]
        return torneado("liquido_" + nombre, base + cima, m, lados=32, padre=r)
    if tipo == "plasma":
        corte = H * 0.32
        liquido("rojo", 0, corte, (0.11, 0.0, 0.003), menisco=False)
        # capa leucocitaria fina y plasma ámbar encima
        liquido("capa", corte, corte + 0.003, (0.9, 0.88, 0.8), fondo=False, menisco=False)
        liquido("plasma", corte + 0.003, hf, COL["plasma"], emis=0.15, fondo=False)
        tap_col, et = (0.85, 0.55, 0.04), "plasma"
    elif tipo == "cultivo":
        liquido("cultivo", 0, hf, (0.75, 0.55, 0.2))
        tap_col, et = (0.2, 0.45, 0.85), "cultivo"
    else:
        liquido("sangre", 0, hf, COL["sangre"])
        tap_col, et = (0.62, 0.03, 0.03), "sangre"
    # tapón: falda lisa + cuerpo moleteado + cúpula, junta de goma gris dentro
    tap = mat("tapon_" + tipo, color=tap_col, rug=0.45)
    cilindro("tapon_goma", R - t * 0.6, 0.012, (0, 0, H - 0.004), mat("goma_gris", color=(0.35, 0.36, 0.37), rug=0.8),
             lados=24, bisel=0.001, padre=r)
    torneado("tapon_falda", [(R + 0.0006, H - 0.012), (R + 0.0014, H - 0.012), (R + 0.0016, H + 0.004),
                             (R + 0.0006, H + 0.004)], tap, lados=40, padre=r, cerrar=True)
    estriado("tapon_moleteado", R + 0.0024, 0.016, 18, 0.0009, tap, padre=r, pos=(0, 0, H + 0.003))
    torneado("tapon_cupula", [(R + 0.0024, H + 0.019), (R + 0.001, H + 0.0215), (R * 0.5, H + 0.0225), (0, H + 0.0228)],
             tap, lados=40, padre=r)
    if con_etiqueta:
        manga("etiqueta", R + 0.00025, H * 0.42, (0, 0, H * 0.3), mat_imagen("etq_" + et, os.path.join(TEX, et + ".png"), 0.7),
              padre=r, arco=0.72, lados=40)
    return r


# ---------------------------------------------------------------- eppendorf (ADN)
def eppendorf(raiz_nombre="tubo_adn", padre=None, pos=(0, 0, 0), color=None, abierto=False):
    """Tubo cónico de 1,5 ml con tapa abatible unida por una tira; ADN verde fluorescente."""
    color = color or COL["adn"]
    r = vacio(raiz_nombre, pos, padre)
    pp = mat("polipropileno", color=(0.9, 0.93, 0.93), rug=0.35, alfa=0.35)
    R, H = 0.011, 0.075
    t = 0.0009
    perfil_ext = [(0, 0), (0.0025, 0.0005), (R * 0.62, H * 0.38), (R, H * 0.48), (R, H)]
    torneado("cuerpo", [(0, t + 0.0005), (0.0018, 0.0015), (R * 0.62 - t, H * 0.38), (R - t, H * 0.48), (R - t, H),
                        (R + 0.0012, H), (R + 0.0012, H - 0.003), (R, H - 0.003)] + list(reversed(perfil_ext)),
             pp, lados=36, padre=r)
    m = mat("liq_adn", color=(0.05, 0.75, 0.12), rug=0.1, emision=(0.1, 1.0, 0.2), fuerza=2.5)
    hf = H * 0.62
    torneado("liquido_adn", [(0, t + 0.0007), (0.0016, 0.0017), (R * 0.62 - t - 0.0003, H * 0.38),
                              (R - t - 0.0003, H * 0.48), (R - t - 0.0003, hf + 0.002), (0, hf)], m, lados=28, padre=r)
    # bisagra, tira y tapa
    caja("bisagra", (0.004, 0.006, 0.004), (0, -(R + 0.003), H - 0.001), pp, bisel=0.001, padre=r)
    tapa = vacio("tapa", (0, -(R + 0.003), H + 0.001), padre=r)
    if abierto:
        tapa.rotation_euler = (math.radians(-110), 0, 0)
    torneado("tapa_disco", [(0, 0), (R + 0.0015, 0), (R + 0.0015, 0.0035), (R * 0.6, 0.0042), (0, 0.0042)], pp,
             lados=36, padre=tapa, pos=(0, R + 0.003, 0))
    torneado("tapa_tapon", [(0, -0.004), (R - t - 0.0002, -0.004), (R - t - 0.0002, 0), (0, 0)], pp, lados=36,
             padre=tapa, pos=(0, R + 0.003, 0))
    caja("tapa_pestana", (0.008, 0.006, 0.0018), (0, R * 2 + 0.006, 0.001), pp, bisel=0.0006, padre=tapa)
    return r


# ---------------------------------------------------------------- vial de mutación
def vial(raiz_nombre="vial_mutacion", padre=None, pos=(0, 0, 0), color=None):
    """Vial de 10 ml: vidrio con hombro y cuello, tapón de goma, cápsula de aluminio dorada engastada."""
    color = color or COL["mutacion"]
    r = vacio(raiz_nombre, pos, padre)
    R, H = 0.0155, 0.05
    t = 0.0013
    rc, hc = 0.0085, 0.008    # cuello
    ext = [(R * 0.9, 0), (R, 0.0015), (R, H), (R * 0.92, H + 0.003), (rc, H + 0.007), (rc, H + 0.007 + hc),
           (rc + 0.0015, H + 0.008 + hc), (rc + 0.0015, H + 0.0105 + hc)]
    inn = [(rc - t, H + 0.0105 + hc), (rc - t, H + 0.007), (R - t, H - 0.0005), (R - t, t + 0.002), (R * 0.9 - t, t), (0, t)]
    torneado("vidrio", [(0, 0)] + ext + inn, vidrio(), lados=48, padre=r)
    m = mat("liq_mutacion", color=color, rug=0.1, emision=color, fuerza=0.9)
    hf = H * 0.78
    torneado("liquido", [(0, t + 0.0003), (R * 0.9 - t - 0.0003, t + 0.0003), (R - t - 0.0003, t + 0.0023),
                         (R - t - 0.0003, hf + 0.0025), (R * 0.7, hf + 0.0005), (0, hf)], m, lados=40, padre=r)
    zc = H + 0.0105 + hc
    cilindro("goma", rc - t * 0.5, 0.008, (0, 0, zc - 0.002), mat("goma_gris", color=(0.35, 0.36, 0.37), rug=0.8),
             lados=32, bisel=0.001, padre=r)
    oro = mat("aluminio_dorado", color=(1.0, 0.68, 0.22), metal=1.0, rug=0.35)
    torneado("capsula", [(rc + 0.0006, H + 0.0085 + hc - 0.0015), (rc + 0.0024, H + 0.0085 + hc - 0.0015),
                         (rc + 0.0026, zc + 0.003), (rc - 0.0004, zc + 0.0045), (0.0042, zc + 0.0045),
                         (0.0042, zc + 0.0025), (rc + 0.0006, zc + 0.0015)], oro, lados=48, padre=r, cerrar=True)
    # tapa flip-off de plástico, del color del producto
    torneado("flip", [(0, zc + 0.0045), (rc - 0.0002, zc + 0.0045), (rc, zc + 0.0075), (rc * 0.8, zc + 0.0085),
                      (0, zc + 0.0086)], mat("flip", color=tuple(c * 0.75 for c in color), rug=0.4), lados=40, padre=r)
    manga("etiqueta", R + 0.0003, H * 0.55, (0, 0, H * 0.18), mat_imagen("etq_mutacion", os.path.join(TEX, "mutacion.png"), 0.7),
          padre=r, arco=0.8, lados=48)
    return r


# ---------------------------------------------------------------- placa de Petri
def petri(raiz_nombre="placa_petri", padre=None, pos=(0, 0, 0), semilla=3):
    r = vacio(raiz_nombre, pos, padre)
    R, H = 0.045, 0.012
    t = 0.0012
    torneado("base", [(0, 0), (R, 0), (R, H), (R - t, H), (R - t, t), (0, t)], vidrio(), lados=64, padre=r)
    agar = mat("agar", color=(0.78, 0.6, 0.22), rug=0.25, alfa=0.92)
    torneado("agar", [(0, t), (R - t - 0.0002, t), (R - t - 0.0002, H * 0.62), (R * 0.9, H * 0.58), (0, H * 0.56)],
             agar, lados=64, padre=r)
    random.seed(semilla)
    colonia = [mat("colonia_verde", color=(0.35, 0.85, 0.3), rug=0.4, emision=(0.3, 0.8, 0.25), fuerza=0.35),
               mat("colonia_crema", color=(0.93, 0.9, 0.78), rug=0.5)]
    for i in range(26):
        a = random.random() * math.tau
        d = math.sqrt(random.random()) * (R - 0.006)
        rr = random.choice((0.0015, 0.002, 0.003, 0.0045))
        esfera(f"colonia{i}", rr, (math.cos(a) * d, math.sin(a) * d, H * 0.56 + 0.0002), colonia[i % 5 == 0],
               padre=r, media=True, escala=(1, 1, 0.35))
    # tapa, algo más ancha y apoyada
    torneado("tapa", [(0, H + 0.002), (R + 0.0022, H + 0.002), (R + 0.0022, H * 0.35), (R + 0.001, H * 0.35),
                      (R + 0.001, H + 0.002 - t), (0, H + 0.002 - t)], vidrio(), lados=64, padre=r)
    return r


# ---------------------------------------------------------------- gradilla
def gradilla(raiz_nombre="gradilla", padre=None, pos=(0, 0, 0), filas=2, cols=5, paso=0.034, con_tubos=True):
    """Gradilla de polipropileno con agujeros (dos pisos y laterales) y tubos dentro."""
    r = vacio(raiz_nombre, pos, padre)
    azul = mat("gradilla_azul", color=(0.18, 0.42, 0.78), rug=0.45)
    w, d = cols * paso + 0.012, filas * paso + 0.012
    for z, nombre in ((0.075, "piso_alto"), (0.03, "piso_bajo")):
        placa = caja(nombre, (w, d, 0.005), (0, 0, z), azul, bisel=0.0015, padre=r)
        # agujeros por booleana
        for i in range(cols):
            for j in range(filas):
                x = -w / 2 + 0.006 + paso / 2 + i * paso
                y = -d / 2 + 0.006 + paso / 2 + j * paso
                bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.0145, depth=0.02, location=(x, y, z))
                h = bpy.context.active_object
                md = placa.modifiers.new("ag", "BOOLEAN")
                md.operation = "DIFFERENCE"
                md.object = h
                bpy.context.view_layer.objects.active = placa
                bpy.ops.object.modifier_apply(modifier="ag")
                bpy.data.objects.remove(h)
    for s in (-1, 1):
        caja(f"lateral{s}", (0.005, d, 0.08), (s * (w / 2 - 0.0025), 0, 0.04), azul, bisel=0.0015, padre=r)
    caja("base", (w, d, 0.004), (0, 0, 0.002), azul, bisel=0.001, padre=r)
    if con_tubos:
        tipos = ["sangre", "sangre", "plasma", "sangre", "plasma", "plasma", "sangre", "plasma", "sangre", "sangre"]
        k = 0
        for i in range(cols):
            for j in range(filas):
                x = -w / 2 + 0.006 + paso / 2 + i * paso
                y = -d / 2 + 0.006 + paso / 2 + j * paso
                if (i + j) % 4 == 3:
                    continue
                tubo(f"tubo{i}{j}", padre=r, pos=(x, y, 0.004), tipo=tipos[k % len(tipos)], con_etiqueta=True)
                k += 1
    return r


# ---------------------------------------------------------------- garrafa de agua destilada
def garrafa(raiz_nombre="garrafa_agua", padre=None, pos=(0, 0, 0), lleno=0.8):
    """Garrafa de 5 l de polietileno translúcido con asa, boca con tapón moleteado y etiqueta azul."""
    r = vacio(raiz_nombre, pos, padre)
    pe = mat("polipropileno_garrafa", color=(0.88, 0.92, 0.94), rug=0.4, alfa=0.45)
    W, D, H = 0.075, 0.05, 0.11
    caja("cuerpo", (W, D, H), (0, 0, H / 2), pe, bisel=0.014, segmentos=4, padre=r)
    agua = mat("liq_agua", color=(0.55, 0.8, 0.95), rug=0.15, alfa=0.6)
    caja("liquido", (W - 0.006, D - 0.006, H * lleno), (0, 0, 0.003 + H * lleno / 2), agua, bisel=0.01, segmentos=3, padre=r)
    # hombro inclinado hacia la boca
    torneado("hombro", [(0.0, H - 0.006), (0.019, H - 0.006), (0.016, H + 0.006), (0.012, H + 0.012), (0, H + 0.012)], pe, lados=32,
             padre=r, pos=(-0.015, 0, 0))
    cilindro("boca", 0.011, 0.012, (-0.015, 0, H + 0.02), pe, lados=24, bisel=0.001, padre=r)
    estriado("tapon", 0.0135, 0.014, 20, 0.0008, mat("tapon_agua", color=(0.15, 0.45, 0.85), rug=0.45), padre=r,
             pos=(-0.015, 0, H + 0.024), bisel=0.0008)
    # asa hueca en el lado contrario
    tubo_curvo("asa", [(0.012, 0, H + 0.002), (0.022, 0, H + 0.02), (0.035, 0, H + 0.016), (0.035, 0, H - 0.008)], 0.006, pe, padre=r)
    calcomania("etiqueta", 0.05, 0.045, (0, -D / 2 - 0.0005, H * 0.45), mat_imagen("etq_agua", os.path.join(TEX, "agua.png"), 0.7),
               padre=r)
    return r


# ---------------------------------------------------------------- frasco de reactivo (tipo Duran, tapón azul)
def frasco_reactivo(raiz_nombre="frasco_reactivo", padre=None, pos=(0, 0, 0), color=(0.35, 0.15, 0.75), lleno=0.62):
    """Frasco de vidrio redondo con graduación, anillo vertedor y tapón de rosca azul; reactivo morado."""
    r = vacio(raiz_nombre, pos, padre)
    R, H = 0.028, 0.07
    t = 0.0014
    rc = 0.016
    ext = [(R * 0.9, 0), (R, 0.004), (R, H), (R * 0.92, H + 0.008), (rc + 0.002, H + 0.018), (rc, H + 0.026)]
    inn = [(rc - t, H + 0.026), (rc - t + 0.002, H + 0.018), (R * 0.92 - t, H + 0.007), (R - t, H - 0.001), (R - t, t + 0.004), (R * 0.9 - t, t), (0, t)]
    torneado("vidrio", [(0, 0)] + ext + inn, vidrio(), lados=48, padre=r)
    m = mat("liq_reactivo", color=color, rug=0.15, emision=color, fuerza=0.25)
    hf = H * lleno
    torneado("liquido", [(0, t + 0.0003), (R * 0.9 - t - 0.0003, t + 0.0003), (R - t - 0.0003, t + 0.0043),
                         (R - t - 0.0003, hf + 0.0025), (R * 0.7, hf + 0.0006), (0, hf)], m, lados=40, padre=r)
    # graduación blanca impresa
    for k in range(5):
        z = 0.015 + k * 0.011
        a = math.radians(-115)
        caja(f"marca{k}", (0.0006, 0.012 if k % 2 == 0 else 0.007, 0.0012), (math.cos(a) * (R + 0.0002), math.sin(a) * (R + 0.0002), z),
             mat("blanco_impreso", color=(0.95, 0.95, 0.95), rug=0.5), bisel=0.0, padre=r, giro=(0, 0, a))
    azul = mat("tapon_reactivo", color=(0.08, 0.3, 0.75), rug=0.4)
    torneado("anillo_vertedor", [(rc + 0.0005, H + 0.019), (rc + 0.004, H + 0.019), (rc + 0.004, H + 0.024), (rc + 0.0005, H + 0.024)], azul,
             lados=32, padre=r, cerrar=True)
    estriado("tapon", rc + 0.003, 0.016, 22, 0.0009, azul, padre=r, pos=(0, 0, H + 0.025), bisel=0.0008)
    manga("etiqueta", R + 0.0003, H * 0.4, (0, 0, H * 0.32), mat_imagen("etq_reactivo", os.path.join(TEX, "reactivo.png"), 0.7),
          padre=r, arco=0.45, lados=48)
    return r


# ---------------------------------------------------------------- bolsa de suero
def bolsa_suero(raiz_nombre="bolsa_suero", padre=None, pos=(0, 0, 0), lleno=1.0):
    """Bolsa de suero de 500 ml: plástico flexible con soldadura perimetral, ojal para colgar, graduación,
    líquido ámbar claro y dos puertos abajo con tapón. El nodo «llenado» (líquido) escala en Z al llenarse."""
    r = vacio(raiz_nombre, pos, padre)
    pl = mat("polipropileno_bolsa", color=(0.9, 0.93, 0.92), rug=0.3, alfa=0.35)
    W, D, H = 0.075, 0.016, 0.115
    Z0 = 0.03                     # la bolsa empieza encima de los puertos
    caja("soldadura", (W + 0.006, 0.0016, H + 0.01), (0, 0, Z0 + H / 2), pl, bisel=0.002, padre=r)
    caja("cuerpo", (W, D, H), (0, 0, Z0 + H / 2), pl, bisel=0.0075, segmentos=5, padre=r)
    suero = mat("liq_suero", color=(0.95, 0.85, 0.5), rug=0.15, alfa=0.75)
    liq = caja("llenado", (W - 0.006, D - 0.004, H - 0.01), (0, 0, (H - 0.01) / 2), suero, bisel=0.006, segmentos=4, padre=r)
    # origen del líquido en el fondo de la bolsa para que crezca hacia arriba
    liq.location = (0, 0, Z0 + 0.004)
    me = liq.data
    for v in me.vertices:
        v.co.z += (H - 0.01) / 2
    liq.scale = (1, 1, lleno)
    # ojal superior
    caja("ojal_pestana", (0.03, 0.0016, 0.016), (0, 0, Z0 + H + 0.012), pl, bisel=0.002, padre=r)
    toro("ojal", 0.0055, 0.0012, (0, 0, Z0 + H + 0.013), pl, padre=r).rotation_euler = (math.radians(90), 0, 0)
    # puertos
    for k, (x, c) in enumerate(((-0.014, (0.15, 0.4, 0.85)), (0.014, (0.92, 0.92, 0.9)))):
        cilindro(f"puerto{k}", 0.004, 0.022, (x, 0, Z0 - 0.009), pl, lados=12, padre=r)
        cilindro(f"puerto{k}_tapon", 0.0055, 0.009, (x, 0, Z0 - 0.022), mat(f"tapon_puerto{k}", color=c, rug=0.4), lados=12, bisel=0.001, padre=r)
    calcomania("graduacion", W * 0.9, H * 0.85, (0, -D / 2 - 0.0006, Z0 + H / 2), mat_calcomania("etq_suero", os.path.join(TEX, "suero_bolsa.png"), 0.6, True), padre=r)
    return r


# ---------------------------------------------------------------- caja de vacunas
def caja_vacunas(raiz_nombre="caja_vacunas", padre=None, pos=(0, 0, 0), abierta=False, con_viales=True):
    """Caja de cartón blanca con cruz verde: bandeja con separadores y 6 viales, tapa con solapa abatible (nodo tapa_caja)."""
    r = vacio(raiz_nombre, pos, padre)
    carton = mat("carton", color=(0.94, 0.94, 0.91), rug=0.85)
    carton_int = mat("carton_int", color=(0.78, 0.74, 0.66), rug=0.9)
    W, D, H = 0.1, 0.066, 0.042
    t = 0.0012
    caja("fondo", (W, D, t), (0, 0, t / 2), carton, bisel=0.0, padre=r)
    for s in (-1, 1):
        caja(f"pared_x{s}", (t, D, H), (s * (W / 2 - t / 2), 0, H / 2), carton, bisel=0.0003, padre=r)
        caja(f"pared_y{s}", (W, t, H), (0, s * (D / 2 - t / 2), H / 2), carton, bisel=0.0003, padre=r)
    for k in (-1, 1):
        caja(f"separador_x{k}", (0.0008, D - 2 * t, H * 0.7), (k * W / 6, 0, H * 0.35), carton_int, bisel=0.0, padre=r)
    caja("separador_y", (W - 2 * t, 0.0008, H * 0.7), (0, 0, H * 0.35), carton_int, bisel=0.0, padre=r)
    if con_viales:
        for i in range(3):
            for j in range(2):
                v = vial(f"vacuna{i}{j}", padre=r, pos=((i - 1) * W / 3, (j - 0.5) * D / 2, t), color=(0.85, 0.92, 0.95))
                v.scale = (0.62, 0.62, 0.62)
    imp = mat_imagen("caja_impresa", os.path.join(os.path.dirname(TEX), "calcomanias", "caja_vacunas.png"), 0.8)
    calcomania("cara_frente", W * 0.96, H * 0.92, (0, -D / 2 - 0.0004, H / 2), imp, padre=r)
    tapa = vacio("tapa_caja", (0, D / 2, H), padre=r)
    if abierta:
        tapa.rotation_euler = (math.radians(-115), 0, 0)
    caja("tapa", (W + 0.002, D + 0.002, t), (0, -D / 2, t / 2), carton, bisel=0.0003, padre=tapa)
    caja("solapa", (W + 0.002, t, 0.012), (0, -D - 0.0005, -0.006), carton, bisel=0.0003, padre=tapa)
    calcomania("cara_tapa", W * 0.96, D * 0.94, (0, -D / 2, t + 0.0004), imp, padre=tapa, giro=(0, 0, 0))
    return r


# ---------------------------------------------------------------- proteína vírica: cristal naranja en su placa
def proteina(raiz_nombre="proteina", padre=None, pos=(0, 0, 0)):
    """Cristal de proteína (racimo de prismas hexagonales naranjas) sobre una placa de cristalización."""
    r = vacio(raiz_nombre, pos, padre)
    caja("placa", (0.06, 0.06, 0.006), (0, 0, 0.003), mat("placa_blanca", color=(0.92, 0.93, 0.92), rug=0.4), bisel=0.0015, padre=r)
    cilindro("pocillo", 0.022, 0.003, (0, 0, 0.0065), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), lados=24, bisel=0.0, padre=r)
    naranja = mat("proteina_cristal", color=(1.0, 0.32, 0.03), rug=0.12, emision=(1.0, 0.3, 0.02), fuerza=0.4, alfa=0.9)
    random.seed(4)
    for k in range(7):
        a = k * math.tau / 7
        d = 0.0 if k == 0 else 0.008
        h = 0.03 if k == 0 else random.uniform(0.014, 0.022)
        c = cilindro(f"prisma{k}", 0.0045 if k else 0.006, h, (math.cos(a) * d, math.sin(a) * d, 0.007 + h / 2), naranja, lados=6, bisel=0.0005, padre=r)
        c.rotation_euler = (random.uniform(-0.4, 0.4) if k else 0, random.uniform(-0.4, 0.4) if k else 0, a)
        torneado(f"punta{k}", [(0, 0), (0.0045 if k else 0.006, 0), (0, 0.006)], naranja, lados=6, padre=c, pos=(0, 0, h / 2), suave=False)
    return r


# ---------------------------------------------------------------- vector: cápsula blanca y roja
def vector(raiz_nombre="vector", padre=None, pos=(0, 0, 0)):
    """Cápsula de dos mitades (roja y blanca) con junta y un pequeño contenido visible por una ventana."""
    r = vacio(raiz_nombre, pos, padre)
    R, L = 0.011, 0.028
    rojo = mat("capsula_roja", color=(0.8, 0.08, 0.08), rug=0.25)
    blanco = mat("capsula_blanca", color=(0.95, 0.95, 0.93), rug=0.3)
    g = vacio("eje", (0, 0, R), padre=r)
    g.rotation_euler = (0, math.radians(90), 0)
    roja = [(0, -L / 2 - R)] + [(R * math.sin(math.radians(a)), -L / 2 - R * math.cos(math.radians(a))) for a in range(10, 91, 10)] + [(R, 0.001), (0, 0.001)]
    torneado("mitad_roja", roja, rojo, lados=32, padre=g)
    Rb = R + 0.0005
    blanca = [(0, -0.004), (Rb, -0.004), (Rb, L / 2)] + [(Rb * math.cos(math.radians(a)), L / 2 + Rb * math.sin(math.radians(a))) for a in range(10, 91, 10)]
    torneado("mitad_blanca", blanca, blanco, lados=32, padre=g)
    toro("junta", R + 0.0006, 0.0007, (0, 0, -0.004), mat("junta_gris", color=(0.5, 0.52, 0.55), rug=0.5), padre=g)
    return r


# ---------------------------------------------------------------- neurotoxina: ampolla morada
def ampolla(raiz_nombre="neurotoxina", padre=None, pos=(0, 0, 0)):
    """Ampolla de vidrio con cuello estrangulado, anillo de rotura y líquido morado; calavera estilizada en la etiqueta."""
    r = vacio(raiz_nombre, pos, padre)
    R = 0.0085
    t = 0.0008
    ext = [(R * 0.85, 0), (R, 0.002), (R, 0.032), (R * 0.75, 0.038), (0.003, 0.044), (0.0028, 0.047), (0.0045, 0.052), (0.0045, 0.06), (0, 0.064)]
    torneado("vidrio", [(0, 0)] + ext, vidrio(), lados=32, padre=r)
    m = mat("liq_neurotoxina", color=(0.45, 0.05, 0.6), rug=0.15, emision=(0.55, 0.1, 0.8), fuerza=0.6)
    torneado("liquido", [(0, t), (R * 0.85 - t, t), (R - t, 0.002 + t), (R - t, 0.026), (R * 0.6, 0.0255), (0, 0.025)], m, lados=24, padre=r)
    toro("anillo_rotura", 0.0031, 0.0006, (0, 0, 0.0455), mat("anillo_rojo", color=(0.85, 0.1, 0.1), rug=0.4), padre=r)
    manga("etiqueta", R + 0.0002, 0.014, (0, 0, 0.008), mat_imagen("etq_neuro", os.path.join(TEX, "neurotoxina.png"), 0.7), padre=r, arco=0.7, lados=32)
    return r


# ---------------------------------------------------------------- cápside: esfera geodésica en un soporte
def capside(raiz_nombre="capside", padre=None, pos=(0, 0, 0)):
    """Cápside vírica impresa: icosaedro geodésico con caras de dos tonos y aristas marcadas, sobre un aro."""
    r = vacio(raiz_nombre, pos, padre)
    toro("soporte", 0.012, 0.0025, (0, 0, 0.0025), mat("metal"), padre=r)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.018, location=(0, 0, 0.02))
    ob = bpy.context.active_object
    ob.name = "geodesica"
    ob.data.materials.append(mat("capside_a", color=(0.3, 0.75, 0.85), rug=0.35))
    ob.data.materials.append(mat("capside_b", color=(0.85, 0.95, 0.98), rug=0.35))
    for i, p in enumerate(ob.data.polygons):
        p.material_index = i % 3 == 0
        p.use_smooth = False
    md = ob.modifiers.new("w", "WIREFRAME"); md.thickness = 0.0012; md.use_replace = False; md.material_offset = 0
    bpy.context.view_layer.objects.active = ob
    bpy.ops.object.modifier_apply(modifier="w")
    ob.parent = r
    for k in range(12):
        pass
    return r


# ---------------------------------------------------------------- núcleo zombi: cubo verde que late
def nucleo(raiz_nombre="nucleo_zombi", padre=None, pos=(0, 0, 0)):
    """Cubo de contención de acero con caras de cristal y un núcleo verde orgánico dentro (nodo «latir»)."""
    r = vacio(raiz_nombre, pos, padre)
    A = 0.034
    acero = mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4)
    for sx in (-1, 1):
        for sy in (-1, 1):
            caja(f"arista_z{sx}{sy}", (0.004, 0.004, A), (sx * A / 2, sy * A / 2, A / 2), acero, bisel=0.0008, padre=r)
            caja(f"arista_x{sx}{sy}", (A, 0.004, 0.004), (0, sx * A / 2, A / 2 + sy * A / 2), acero, bisel=0.0008, padre=r)
            caja(f"arista_y{sx}{sy}", (0.004, A, 0.004), (sx * A / 2, 0, A / 2 + sy * A / 2), acero, bisel=0.0008, padre=r)
    caja("cristal", (A - 0.002, A - 0.002, A - 0.002), (0, 0, A / 2), vidrio(), bisel=0.0, padre=r)
    lat = vacio("latir", (0, 0, A / 2), padre=r)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.011, location=(0, 0, 0))
    ob = bpy.context.active_object
    ob.name = "nucleo"
    bm = bmesh.new(); bm.from_mesh(ob.data)
    random.seed(9)
    for v in bm.verts:
        v.co *= 1.0 + 0.18 * math.sin(v.co.x * 400) * math.cos(v.co.y * 380) + random.uniform(-0.05, 0.05)
    bm.to_mesh(ob.data); bm.free()
    ob.data.materials.append(mat("nucleo_verde", color=(0.25, 0.85, 0.1), rug=0.35, emision=(0.4, 1.0, 0.1), fuerza=1.5))
    for p in ob.data.polygons:
        p.use_smooth = True
    ob.parent = lat
    for k in range(5):
        a = k * math.tau / 5
        tubo_curvo(f"vena{k}", [(0, 0, 0), (math.cos(a) * 0.008, math.sin(a) * 0.008, 0.004 * (k % 2)), (math.cos(a) * 0.015, math.sin(a) * 0.015, -0.003)],
                   0.0012, mat("vena_roja", color=(0.6, 0.05, 0.08), rug=0.4), padre=lat)
    caja("placa_tapa", (A + 0.004, A + 0.004, 0.003), (0, 0, A + 0.0015), acero, bisel=0.0008, padre=r)
    caja("placa_base", (A + 0.004, A + 0.004, 0.003), (0, 0, 0.0015), acero, bisel=0.0008, padre=r)
    for sx in (-1, 1):
        for sy in (-1, 1):
            tornillo(f"base_t{sx}{sy}", (sx * A * 0.4, sy * A * 0.4, A + 0.003), r, r=0.0018, normal="+Z")
    cilindro("tapa_valvula", 0.004, 0.004, (0, 0, A + 0.005), mat("volante_rojo", color=(0.7, 0.05, 0.05), rug=0.45), lados=12, padre=r)
    return r


def main():
    global TEX
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, TEX = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("tubo_sangre", lambda: tubo("tubo_sangre", tipo="sangre")),
                       ("tubo_plasma", lambda: tubo("tubo_plasma", tipo="plasma")),
                       ("tubo_adn", lambda: eppendorf("tubo_adn")),
                       ("vial_mutacion", lambda: vial("vial_mutacion")),
                       ("placa_petri", lambda: petri("placa_petri")),
                       ("gradilla", lambda: gradilla("gradilla")),
                       ("garrafa_agua", lambda: garrafa("garrafa_agua")),
                       ("frasco_reactivo", lambda: frasco_reactivo("frasco_reactivo")),
                       ("bolsa_suero", lambda: bolsa_suero("bolsa_suero")),
                       ("caja_vacunas", lambda: caja_vacunas("caja_vacunas", abierta=True)),
                       ("proteina", lambda: proteina("proteina")),
                       ("vector", lambda: vector("vector")),
                       ("neurotoxina", lambda: ampolla("neurotoxina")),
                       ("capside", lambda: capside("capside")),
                       ("nucleo_zombi", lambda: nucleo("nucleo_zombi"))):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("OBJ", nombre)


if __name__ == "__main__":
    main()
