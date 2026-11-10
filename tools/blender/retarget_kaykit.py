"""Pasa animaciones de KayKit (Rig_Medium, CC0) al esqueleto de los personajes de Quaternius
«Ultimate Animated Character» (CC0) y exporta un .glb con el personaje y todas las animaciones.

Uso:
  blender -b -P tools/blender/retarget_kaykit.py -- personaje.gltf salida.glb anim1.glb [anim2.glb ...]

Cómo: por cada fotograma, la rotación de cada hueso de KayKit respecto a su pose de reposo (en espacio
del mundo) se aplica al hueso equivalente de Quaternius sobre su propia pose de reposo. La cadera además
se traslada (escalada por la altura de cadera). Los pies de Quaternius son controladores de IK colgados de
la raíz: antes se cuelgan de la pierna para que sigan a la rodilla.
"""
import sys
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
PERSONAJE, SALIDA, ANIMS = args[0], args[1], args[2:]
SOLO = None  # lista de nombres de animación a pasar (None = todas)
QUIERO = {
    "Idle_A", "Idle_B", "Walking_A", "Walking_B", "Walking_C", "Running_A", "Running_B",
    "Sit_Chair_Down", "Sit_Chair_Idle", "Sit_Chair_StandUp", "Lie_Down", "Lie_Idle", "Lie_StandUp",
    "Interact", "PickUp", "Use_Item", "Throw", "Work_A", "Work_B", "Work_C", "Working_A", "Working_B",
    "Working_C", "Holding_A", "Holding_B", "Holding_C", "Cheering", "Waving", "Hit_A", "Hit_B",
    "Death_A", "Death_A_Pose", "Crouching", "Sneaking", "Push_Ups", "Hammering", "Sawing", "Digging",
    "Lockpicking",
}
MAPA = {  # KayKit -> Quaternius
    "hips": "Hips", "spine": "Abdomen", "chest": "Torso", "head": "Head",
    "upperarm.l": "UpperArm.L", "lowerarm.l": "LowerArm.L", "wrist.l": "Fist.L",
    "upperarm.r": "UpperArm.R", "lowerarm.r": "LowerArm.R", "wrist.r": "Fist.R",
    "upperleg.l": "UpperLeg.L", "lowerleg.l": "LowerLeg.L", "foot.l": "Foot.L",
    "upperleg.r": "UpperLeg.R", "lowerleg.r": "LowerLeg.R", "foot.r": "Foot.R",
}

bpy.ops.wm.read_factory_settings(use_empty=True)
escena = bpy.context.scene


def importar(ruta):
    antes = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=ruta)
    nuevos = [o for o in bpy.data.objects if o not in antes]
    arm = next(o for o in nuevos if o.type == "ARMATURE")
    return arm, nuevos


# --- personaje destino
destino, objs_dest = importar(PERSONAJE)
for a in list(bpy.data.actions):
    bpy.data.actions.remove(a)
if destino.animation_data:
    destino.animation_data_clear()
bpy.context.view_layer.objects.active = destino
bpy.ops.object.mode_set(mode="EDIT")
eb = destino.data.edit_bones
for lado in ("L", "R"):
    pie = eb.get("Foot." + lado)
    pierna = eb.get("LowerLeg." + lado)
    if pie and pierna:
        pie.use_connect = False
        pie.parent = pierna
bpy.ops.object.mode_set(mode="OBJECT")
for pb in destino.pose.bones:
    pb.rotation_mode = "QUATERNION"
    pb.matrix_basis = Matrix.Identity(4)

dest_mw = destino.matrix_world.copy()
dest_rest = {b.name: b.matrix_local.copy() for b in destino.data.bones}
orden = []  # huesos del destino de padre a hijo
def _rec(b):
    orden.append(b)
    for c in b.children:
        _rec(c)
for b in destino.data.bones:
    if b.parent is None:
        _rec(b)

acciones_hechas = []
for ruta in ANIMS:
    fuente, objs_f = importar(ruta)
    fuente_acciones = [a for a in bpy.data.actions if a not in acciones_hechas and a.users >= 0]
    src_mw = fuente.matrix_world.copy()
    src_rest = {b.name: b.matrix_local.copy() for b in fuente.data.bones}
    alto_src = (src_mw @ src_rest["hips"]).translation.z
    alto_dst = (dest_mw @ dest_rest["Hips"]).translation.z
    k_alto = alto_dst / alto_src if alto_src > 1e-4 else 1.0
    if not fuente.animation_data:
        fuente.animation_data_create()
    for acc in fuente_acciones:
        nombre = acc.name.split("|")[-1]
        for suf in ("_Rig_Medium", "_Rig_Large"):
            if nombre.endswith(suf):
                nombre = nombre[: -len(suf)]
        if nombre not in QUIERO or acc in acciones_hechas:
            continue
        fuente.animation_data.action = acc
        f0, f1 = int(acc.frame_range[0]), int(acc.frame_range[1])
        nueva = bpy.data.actions.new(nombre)
        nueva.use_fake_user = True
        if not destino.animation_data:
            destino.animation_data_create()
        destino.animation_data.action = nueva
        for f in range(f0, f1 + 1):
            escena.frame_set(f)
            calc = {}
            for b in orden:
                pb = destino.pose.bones[b.name]
                rel = (dest_rest[b.parent.name].inverted() @ dest_rest[b.name]) if b.parent else dest_rest[b.name]
                base = (calc[b.parent.name] @ rel) if b.parent else rel
                src = next((s for s, d in MAPA.items() if d == b.name), None)
                if src is None or src not in fuente.pose.bones:
                    calc[b.name] = base
                    continue
                sp = fuente.pose.bones[src]
                ws_pose = src_mw @ sp.matrix
                ws_rest = src_mw @ src_rest[src]
                delta = ws_pose.to_quaternion() @ ws_rest.to_quaternion().inverted()
                wd_rest = (dest_mw @ dest_rest[b.name]).to_quaternion()
                rot_arm = dest_mw.to_quaternion().inverted() @ (delta @ wd_rest)
                pos = base.translation.copy()
                if b.name == "Hips":
                    d_mundo = (ws_pose.translation - ws_rest.translation) * k_alto
                    pos = pos + dest_mw.inverted().to_3x3() @ d_mundo
                deseada = Matrix.LocRotScale(pos, rot_arm, Vector((1, 1, 1)))
                calc[b.name] = deseada
                basis = base.inverted() @ deseada
                pb.matrix_basis = basis
                pb.keyframe_insert("rotation_quaternion", frame=f)
                if b.name == "Hips":
                    pb.keyframe_insert("location", frame=f)
        acciones_hechas.append(nueva)
        print("retarget:", nombre, f1 - f0 + 1, "fotogramas")
    for a in fuente_acciones:
        if a not in acciones_hechas:
            acciones_hechas.append(a)  # marcar como vistas
    for o in objs_f:
        bpy.data.objects.remove(o, do_unlink=True)

# limpiar acciones de KayKit que no son nuestras
mias = {a.name for a in bpy.data.actions if a.use_fake_user}
for a in list(bpy.data.actions):
    if a.name not in mias:
        bpy.data.actions.remove(a)
# NLA: una pista por acción para que el exportador las saque todas
destino.animation_data.action = None
for a in bpy.data.actions:
    t = destino.animation_data.nla_tracks.new()
    t.name = a.name
    t.strips.new(a.name, int(a.frame_range[0]), a)
    t.mute = True
bpy.ops.object.select_all(action="DESELECT")
for o in objs_dest:
    if o.name in bpy.data.objects:
        o.select_set(True)
bpy.ops.export_scene.gltf(filepath=SALIDA, export_format="GLB", use_selection=True,
                          export_animations=True, export_animation_mode="NLA_TRACKS",
                          export_force_sampling=True)
print("exportado:", SALIDA, len(bpy.data.actions), "animaciones")
