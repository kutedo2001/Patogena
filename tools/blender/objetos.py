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
                       ("gradilla", lambda: gradilla("gradilla"))):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("OBJ", nombre)


if __name__ == "__main__":
    main()
