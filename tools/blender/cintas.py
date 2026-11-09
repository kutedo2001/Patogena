"""Cintas transportadoras (P3.6): recta y curva de 1 casilla, en Mk1 (amarillo), Mk2 (azul) y Mk3 (morado).
Bastidor de aluminio con franja del nivel, banda de goma con chevrones (el juego desplaza su UV), rodillos de
cabeza con tapacubos, patas regulables con tornillería, guías laterales; la Mk3 lleva además tapa de motor.
Uso: blender -b -P tools/blender/cintas.py -- <carpeta_salida> <carpeta_texturas>
Convención: entra por -X y sale por +X (la curva gira a +Y). La banda se llama «banda» (material banda).
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *
import bmesh

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
SALIDA, TEX = args[0], args[1]
NIVELES = {1: (0.95, 0.72, 0.12), 2: (0.15, 0.45, 0.9), 3: (0.55, 0.25, 0.85)}
ANCHO = 0.56        # ancho de la banda
ZB = 0.3            # altura de la superficie de la banda


def mat_banda():
    m = mat_imagen("banda", os.path.join(TEX, "banda.png"), 0.85)
    return m


def banda_recta(padre):
    """Plano de banda con UV en metros (U a lo largo de X), un poco curvado en los extremos."""
    me = bpy.data.meshes.new("banda")
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    xs = [-0.5, 0.5]
    vs = [[bm.verts.new((x, y, ZB)) for y in (-ANCHO / 2, ANCHO / 2)] for x in xs]
    f = bm.faces.new((vs[0][0], vs[1][0], vs[1][1], vs[0][1]))
    for lp, (u, v) in zip(f.loops, ((0, 0), (1, 0), (1, 1), (0, 1))):
        lp[uv].uv = (u * 1.0, v * ANCHO)
    for f in bm.faces:
        if f.normal.z < 0:
            f.normal_flip()
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("banda", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat_banda())
    ob.parent = padre
    return ob


def banda_curva(padre, n=16):
    """Banda en cuarto de círculo de centro (−0.5, +0.5); U = longitud de arco por el centro, en metros."""
    me = bpy.data.meshes.new("banda")
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    cx, cy = -0.5, 0.5
    r0, r1 = 0.5 - ANCHO / 2, 0.5 + ANCHO / 2
    filas = []
    for i in range(n + 1):
        a = -math.pi / 2 + i / n * math.pi / 2
        filas.append([bm.verts.new((cx + math.cos(a) * rr, cy + math.sin(a) * rr, ZB)) for rr in (r1, r0)])
    L = math.pi / 2 * 0.5
    for i in range(n):
        f = bm.faces.new((filas[i][0], filas[i + 1][0], filas[i + 1][1], filas[i][1]))
        u0, u1 = i / n * L, (i + 1) / n * L
        for lp, (u, v) in zip(f.loops, ((u0, 0), (u1, 0), (u1, ANCHO), (u0, ANCHO))):
            lp[uv].uv = (u, v)
    for f in bm.faces:
        if f.normal.z < 0:
            f.normal_flip()
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new("banda", me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat_banda())
    ob.parent = padre
    return ob


def pata(nombre, x, y, padre):
    alu = mat("aluminio", color=(0.78, 0.8, 0.82), metal=1.0, rug=0.35)
    caja(nombre, (0.04, 0.04, ZB - 0.07), (x, y, (ZB - 0.07) / 2 + 0.02), alu, bisel=0.006, padre=padre)
    cilindro(nombre + "_pie", 0.035, 0.012, (x, y, 0.006), mat("goma"), lados=16, bisel=0.002, padre=padre)
    cilindro(nombre + "_rosca", 0.01, 0.025, (x, y, 0.02), mat("metal"), lados=10, padre=padre)
    caja(nombre + "_escuadra", (0.06, 0.012, 0.06), (x, y, ZB - 0.09), alu, bisel=0.003, padre=padre)
    tornillo(nombre + "_t", (x, y - 0.007, ZB - 0.09), padre, r=0.006, normal="-Y")


def recta(nivel):
    limpiar(); comun._mats.clear()
    r = vacio(f"cinta_recta_mk{nivel}")
    c = NIVELES[nivel]
    alu = mat("aluminio", color=(0.78, 0.8, 0.82), metal=1.0, rug=0.35)
    franja = mat(f"franja_mk{nivel}", color=c, rug=0.45)
    banda_recta(r)
    caja("lecho", (1.0, ANCHO - 0.02, 0.03), (0, 0, ZB - 0.02), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r)
    for s in (-1, 1):
        y = s * (ANCHO / 2 + 0.03)
        caja(f"bastidor{s}", (1.0, 0.04, 0.12), (0, y, ZB - 0.03), alu, bisel=0.008, padre=r)
        caja(f"bastidor{s}_ranura", (1.0, 0.042, 0.012), (0, y, ZB - 0.05), mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4), bisel=0.0, padre=r)
        caja(f"franja{s}", (0.98, 0.044, 0.045), (0, y, ZB + 0.0), franja, bisel=0.003, padre=r)
        caja(f"guia{s}", (0.98, 0.015, 0.04), (0, s * (ANCHO / 2 + 0.005), ZB + 0.035), mat("guia_blanca", color=(0.9, 0.9, 0.88), rug=0.4), bisel=0.004, padre=r)
        for x in (-0.3, 0.3):
            caja(f"guia{s}_soporte{x}", (0.02, 0.04, 0.03), (x, s * (ANCHO / 2 + 0.025), ZB + 0.035), alu, bisel=0.003, padre=r)
            tornillo(f"bastidor{s}_t{x}", (x, y + s * 0.021, ZB - 0.03), r, r=0.007, normal="+Y" if s > 0 else "-Y")
        for x in (-0.42, 0.42):
            pata(f"pata{s}{x}", x, y, r)
    for x in (-0.42, 0.42):
        caja(f"travesano{x}", (0.03, ANCHO + 0.06, 0.03), (x, 0, 0.12), alu, bisel=0.004, padre=r)
    # rodillos inferiores de retorno visibles entre patas
    for x in (-0.2, 0.0, 0.2):
        cilindro(f"rodillo_ret{x}", 0.02, ANCHO, (x, 0, ZB - 0.07), mat("inox", color=(0.74, 0.76, 0.78), metal=1.0, rug=0.22), lados=12,
                 padre=r, giro=(math.radians(90), 0, 0))
    if nivel == 3:
        caja("tapa_motor", (0.16, 0.12, 0.12), (0.0, -(ANCHO / 2 + 0.12), ZB - 0.08), mat("negro_mate"), bisel=0.015, padre=r)
        cilindro("tapa_motor_eje", 0.03, 0.04, (0.0, -(ANCHO / 2 + 0.06), ZB - 0.08), mat("metal"), lados=16, padre=r, giro=(math.radians(90), 0, 0))
        for k in range(5):
            caja(f"tapa_motor_aleta{k}", (0.14, 0.004, 0.01), (0, -(ANCHO / 2 + 0.181), ZB - 0.12 + k * 0.02), mat("negro_mate"), bisel=0.0, padre=r)
    exportar(os.path.join(SALIDA, f"cinta_recta_mk{nivel}.glb"))


def reflejar_y(raiz):
    """Refleja en Y toda la geometría (para la curva a la derecha) dejando las normales hacia fuera."""
    from mathutils import Matrix
    mallas = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in mallas:
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    bpy.ops.object.select_all(action="DESELECT")
    for o in mallas:
        o.select_set(True)
    bpy.context.view_layer.objects.active = mallas[0]
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for o in mallas:
        o.data.transform(Matrix.Scale(-1, 4, (0, 1, 0)))
        o.data.flip_normals()
        o.parent = raiz
    for o in [o for o in bpy.data.objects if o.type == "EMPTY" and o != raiz]:
        bpy.data.objects.remove(o)


def curva(nivel, derecha=False):
    limpiar(); comun._mats.clear()
    r = vacio(f"cinta_curva_mk{nivel}")
    c = NIVELES[nivel]
    alu = mat("aluminio", color=(0.78, 0.8, 0.82), metal=1.0, rug=0.35)
    franja = mat(f"franja_mk{nivel}", color=c, rug=0.45)
    banda_curva(r)
    cx, cy = -0.5, 0.5
    for nombre, rr in (("int", 0.5 - ANCHO / 2 - 0.03), ("ext", 0.5 + ANCHO / 2 + 0.03)):
        n = 12
        for i in range(n):
            a0 = -math.pi / 2 + i / n * math.pi / 2
            a1 = -math.pi / 2 + (i + 1) / n * math.pi / 2
            am = (a0 + a1) / 2
            largo = rr * (a1 - a0) + 0.004
            x, y = cx + math.cos(am) * rr, cy + math.sin(am) * rr
            caja(f"bastidor_{nombre}{i}", (largo, 0.04, 0.12), (x, y, ZB - 0.03), alu, bisel=0.004, padre=r, giro=(0, 0, am + math.pi / 2))
            caja(f"franja_{nombre}{i}", (largo, 0.044, 0.045), (x, y, ZB + 0.0), franja, bisel=0.002, padre=r, giro=(0, 0, am + math.pi / 2))
        for k, a in enumerate((-math.pi / 2 + 0.25, -0.25)):
            pata(f"pata_{nombre}{k}", cx + math.cos(a) * rr, cy + math.sin(a) * rr, r)
    caja("lecho_tapa", (0.05, 0.05, 0.02), (cx + 0.04, cy - 0.04, ZB - 0.02), alu, bisel=0.005, padre=r)
    if derecha:
        reflejar_y(r)
        r.name = f"cinta_curva_der_mk{nivel}"
    exportar(os.path.join(SALIDA, f"cinta_curva{'_der' if derecha else ''}_mk{nivel}.glb"))


os.makedirs(SALIDA, exist_ok=True)
for n in (1, 2, 3):
    recta(n)
    curva(n)
    curva(n, derecha=True)
print("CINTAS OK")
