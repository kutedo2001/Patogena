"""Utilidades comunes para modelar máquinas de Patógena S.A. por script de Blender.

Convenciones (las lee scripts/maquina.gd):
- Casilla = 1 m. El origen de la máquina está en el centro de su huella, a ras de suelo.
- Entrada por -X, salida por +X (la colocación en el juego gira la máquina entera).
- Nodos con nombre especial: "baliza" (luz de estado), "rotor" (gira en Z),
  "cabezal" (va y viene en X), "agitador" (gira en Z), "liquido" (nivel y color),
  "pantalla" (emisivo que parpadea al trabajar).
- Materiales con nombre fijo: chasis, grafito, metal, acento_<familia>, cristal,
  liquido, baliza, pantalla, goma, tubo_<color>.
"""
import bpy
import bmesh
import math
from mathutils import Vector

PALETA = {
    "chasis": ((0.86, 0.85, 0.80), 0.0, 0.55),
    "chasis_osc": ((0.70, 0.71, 0.70), 0.0, 0.6),
    "grafito": ((0.15, 0.17, 0.18), 0.1, 0.6),
    "metal": ((0.62, 0.66, 0.70), 0.85, 0.32),
    "goma": ((0.08, 0.09, 0.09), 0.0, 0.85),
    "acento_procesado": ((0.13, 0.55, 0.78), 0.0, 0.45),
    "acento_producto": ((0.24, 0.62, 0.50), 0.0, 0.45),
    "amarillo": ((0.95, 0.74, 0.16), 0.0, 0.5),
    "tubo_rojo": ((0.72, 0.06, 0.07), 0.0, 0.3),
    "tubo_amarillo": ((0.96, 0.80, 0.22), 0.0, 0.3),
    "tubo_blanco": ((0.92, 0.92, 0.9), 0.0, 0.4),
}


def limpiar():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for col in (bpy.data.meshes, bpy.data.materials, bpy.data.objects):
        for b in list(col):
            if b.users == 0:
                col.remove(b)


_mats = {}


def mat(nombre, color=None, metal=0.0, rug=0.5, emision=None, fuerza=0.0, alfa=1.0):
    if nombre in _mats and nombre in bpy.data.materials:
        return _mats[nombre]
    if color is None and nombre in PALETA:
        color, metal, rug = PALETA[nombre]
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*color, 1.0)
    b.inputs["Metallic"].default_value = metal
    b.inputs["Roughness"].default_value = rug
    if emision is not None:
        b.inputs["Emission Color"].default_value = (*emision, 1.0)
        b.inputs["Emission Strength"].default_value = fuerza
    if alfa < 1.0:
        b.inputs["Alpha"].default_value = alfa
        m.blend_method = "BLEND"
        m.use_backface_culling = True   # una sola capa de vidrio: si no, se suman dos reflejos
    _mats[nombre] = m
    return m


def _acabar(ob, material, bisel, segmentos, padre, suave=True):
    if material is not None:
        ob.data.materials.append(material)
    if bisel > 0:
        md = ob.modifiers.new("bisel", "BEVEL")
        md.width = bisel
        md.segments = segmentos
        md.limit_method = "ANGLE"
        md.angle_limit = math.radians(40)
        md.harden_normals = True
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier="bisel")
    if suave:
        for p in ob.data.polygons:
            p.use_smooth = True
        try:
            ob.data.set_sharp_from_angle(angle=math.radians(35))
        except AttributeError:
            pass
    if padre is not None:
        ob.parent = padre
    return ob


def caja(nombre, tam, pos, material, bisel=0.02, segmentos=2, padre=None, giro=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos, rotation=giro)
    ob = bpy.context.active_object
    ob.name = nombre
    ob.scale = tam
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _acabar(ob, material, min(bisel, min(tam) * 0.45), segmentos, padre)


def cilindro(nombre, r, h, pos, material, lados=32, bisel=0.01, segmentos=2, padre=None, giro=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=lados, radius=r, depth=h, location=pos, rotation=giro)
    ob = bpy.context.active_object
    ob.name = nombre
    return _acabar(ob, material, min(bisel, r * 0.4, h * 0.4), segmentos, padre)


def esfera(nombre, r, pos, material, padre=None, media=False, escala=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, radius=r, location=pos)
    ob = bpy.context.active_object
    ob.name = nombre
    if media:
        bm = bmesh.new()
        bm.from_mesh(ob.data)
        borrar = [v for v in bm.verts if v.co.z < -1e-4]
        bmesh.ops.delete(bm, geom=borrar, context="VERTS")
        bm.to_mesh(ob.data)
        bm.free()
    ob.scale = escala
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return _acabar(ob, material, 0, 0, padre)


def toro(nombre, r_mayor, r_menor, pos, material, padre=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=r_mayor, minor_radius=r_menor, location=pos,
                                     major_segments=40, minor_segments=12)
    ob = bpy.context.active_object
    ob.name = nombre
    return _acabar(ob, material, 0, 0, padre)


def vacio(nombre, pos=(0, 0, 0), padre=None):
    ob = bpy.data.objects.new(nombre, None)
    bpy.context.collection.objects.link(ob)
    ob.location = pos
    if padre is not None:
        ob.parent = padre
    return ob


def tubo_curvo(nombre, puntos, r, material, padre=None):
    """Tubería que sigue una lista de puntos (curva con grosor)."""
    cd = bpy.data.curves.new(nombre, "CURVE")
    cd.dimensions = "3D"
    cd.bevel_depth = r
    cd.bevel_resolution = 4
    cd.use_fill_caps = True
    sp = cd.splines.new("BEZIER")
    sp.bezier_points.add(len(puntos) - 1)
    for i, p in enumerate(puntos):
        bp = sp.bezier_points[i]
        bp.co = p
        bp.handle_left_type = bp.handle_right_type = "AUTO"
    ob = bpy.data.objects.new(nombre, cd)
    bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    ob = bpy.context.active_object
    ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = True
    if padre is not None:
        ob.parent = padre
    return ob


def chevron(nombre, pos, tam, material, padre=None):
    """Flecha en V plana que apunta a +X (sentido del flujo), para poner sobre el zócalo."""
    me = bpy.data.meshes.new(nombre)
    a, g = tam, tam * 0.38
    pts2 = [(-a * 0.5, a * 0.55), (a * 0.5, 0.0), (-a * 0.5, -a * 0.55),
            (-a * 0.5 + g, -a * 0.55), (a * 0.5 - g * 0.9, 0.0), (-a * 0.5 + g, a * 0.55)]
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, 0)) for x, y in pts2]
    bm.faces.new([vs[0], vs[1], vs[4], vs[5]])
    bm.faces.new([vs[1], vs[2], vs[3], vs[4]])
    r = bmesh.ops.extrude_face_region(bm, geom=bm.faces[:])
    for v in [e for e in r["geom"] if isinstance(e, bmesh.types.BMVert)]:
        v.co.z += 0.012
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(ob)
    ob.location = pos
    ob.data.materials.append(material)
    if padre is not None:
        ob.parent = padre
    return ob


def puerto(nombre, lado, alto, ancho, z, padre, mitad=0.5, z_zocalo=0.12, y=0.0):
    """Boca de entrada (lado -1, -X) o salida (lado +1, +X): marco grafito, hueco oscuro
    y chevron amarillo sobre el zócalo indicando el sentido del flujo (sin texto)."""
    x = lado * mitad
    g = mat("grafito")
    caja(nombre + "_marco", (0.08, ancho + 0.1, alto + 0.1), (x, y, z), g, bisel=0.02, padre=padre)
    caja(nombre + "_hueco", (0.085, ancho, alto), (x, y, z), mat("goma"), bisel=0.0, padre=padre)
    chevron(nombre + "_flecha", (x + lado * 0.11, y, z_zocalo + 0.001), 0.2, mat("amarillo"), padre)
    return x


def baliza(pos, padre, alto_poste=0.18):
    """Luz de estado: poste grafito + lente emisiva (el juego cambia su color)."""
    g = mat("grafito")
    m = mat("baliza", color=(0.3, 1.0, 0.45), rug=0.2, emision=(0.3, 1.0, 0.45), fuerza=4.0)
    x, y, z = pos
    cilindro("baliza_poste", 0.04, alto_poste, (x, y, z + alto_poste / 2), g, lados=12, padre=padre)
    cilindro("baliza_base", 0.095, 0.045, (x, y, z + alto_poste), g, lados=20, padre=padre)
    lente = cilindro("baliza", 0.08, 0.13, (x, y, z + alto_poste + 0.09), m, lados=24, bisel=0.025, padre=padre)
    esfera("baliza_tapa", 0.08, (x, y, z + alto_poste + 0.155), g, padre=padre, media=True, escala=(1, 1, 0.35))
    return lente


def exportar(ruta):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=ruta, export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True)


# ---------------------------------------------------------------- piezas finas

def torneado(nombre, perfil, material, lados=48, padre=None, pos=(0, 0, 0), cerrar=False, suave=True):
    """Sólido de revolución alrededor de Z a partir de una lista (r, z).
    Si el perfil empieza y acaba en r=0 queda cerrado; con cerrar=True une el último con el primero."""
    me = bpy.data.meshes.new(nombre)
    bm = bmesh.new()
    vs = [bm.verts.new((max(r, 0.0), 0.0, z)) for r, z in perfil]
    es = [bm.edges.new((vs[i], vs[i + 1])) for i in range(len(vs) - 1)]
    if cerrar:
        es.append(bm.edges.new((vs[-1], vs[0])))
    bmesh.ops.spin(bm, geom=vs + es, axis=(0, 0, 1), cent=(0, 0, 0), angle=math.tau, steps=lados,
                   use_merge=True)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-6)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(ob)
    ob.location = pos
    ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = suave
    try:
        ob.data.set_sharp_from_angle(angle=math.radians(40))
    except AttributeError:
        pass
    if padre is not None:
        ob.parent = padre
    return ob


def estriado(nombre, r, h, n, prof, material, padre=None, pos=(0, 0, 0), bisel=0.0):
    """Cilindro con estrías verticales (tapón de rosca, mando moleteado)."""
    me = bpy.data.meshes.new(nombre)
    bm = bmesh.new()
    pasos = n * 4
    abajo, arriba = [], []
    for i in range(pasos):
        a = i / pasos * math.tau
        rr = r - (prof if (i % 4) in (2, 3) else 0.0)
        abajo.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, 0)))
        arriba.append(bm.verts.new((math.cos(a) * rr, math.sin(a) * rr, h)))
    for i in range(pasos):
        j = (i + 1) % pasos
        bm.faces.new((abajo[i], abajo[j], arriba[j], arriba[i]))
    bm.faces.new(list(reversed(abajo)))
    bm.faces.new(arriba)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(ob)
    ob.location = pos
    ob.data.materials.append(material)
    if padre is not None:
        ob.parent = padre
    if bisel > 0:
        bpy.context.view_layer.objects.active = ob
        md = ob.modifiers.new("b", "BEVEL"); md.width = bisel; md.segments = 1
        md.limit_method = "ANGLE"; md.angle_limit = math.radians(60)
        bpy.ops.object.modifier_apply(modifier="b")
    return ob


def mat_imagen(nombre, ruta, rug=0.6):
    if nombre in _mats and nombre in bpy.data.materials:
        return _mats[nombre]
    m = bpy.data.materials.new(nombre)
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = bpy.data.images.load(ruta)
    nt.links.new(tex.outputs["Color"], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = rug
    _mats[nombre] = m
    return m


def manga(nombre, r, h, pos, material, padre=None, arco=1.0, lados=48):
    """Cilindro abierto (sin tapas) con UV de 0 a 1 en vertical y arco en horizontal: etiquetas."""
    me = bpy.data.meshes.new(nombre)
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new()
    n = max(4, int(lados * arco))
    ab, ar = [], []
    for i in range(n + 1):
        a = -math.pi / 2 - arco * math.pi + i / n * arco * math.tau
        ab.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, 0)))
        ar.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, h)))
    for i in range(n):
        f = bm.faces.new((ab[i], ab[i + 1], ar[i + 1], ar[i]))
        for lp, (u, v) in zip(f.loops, ((i / n, 0), ((i + 1) / n, 0), ((i + 1) / n, 1), (i / n, 1))):
            lp[uv].uv = (u, v)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nombre, me)
    bpy.context.collection.objects.link(ob)
    ob.location = pos
    ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = True
    if padre is not None:
        ob.parent = padre
    return ob


def vidrio():
    return mat("vidrio", color=(0.8, 0.9, 0.95), rug=0.03, alfa=0.1)
