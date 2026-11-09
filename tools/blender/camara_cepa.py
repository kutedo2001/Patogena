"""Cámara de cepa detallada (P3.5d), 3×3 casillas, construcción fija.
Cilindro de cristal blindado con anillos y montantes atornillados; dentro, la cepa: virus gigante (icosaedro
subdividido con espículas y glicoproteínas) que flota, gira y late en un líquido verde con niebla; inyector de viales
con raíl, carro y aguja que sube y baja; dos manómetros, válvulas, mangueras de criogenia con escarcha; balizas
giratorias de aviso; consola con pantalla viva del árbol de mutaciones; plataforma con barandilla y escalera.
Uso: blender -b -P tools/blender/camara_cepa.py -- <salida.glb> <carpeta_texturas>
Nodos animados: virus (gira y late), gira_virus_capa, flotar, niebla_*, gira_baliza*, inyector_carro, inyector_aguja,
vial_inyeccion, aguja_*, pantalla, baliza_v/a/r.
"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun, objetos
importlib.reload(comun); importlib.reload(objetos)
from comun import *
import bmesh

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else ["camara_cepa.glb", "."]
SALIDA, TEX = args[0], args[1]
objetos.TEX = os.path.join(TEX, "etiquetas")
CAL = os.path.join(TEX, "calcomanias")
ESC = 2.5
random.seed(21)

limpiar(); comun._mats.clear()
r = vacio("camara_cepa")
ch, chos, gr, me = mat("chasis"), mat("chasis_osc"), mat("grafito"), mat("metal")
ac = mat("acento_cepa", color=(0.75, 0.12, 0.1), rug=0.45)
inox = mat("inox", color=(0.74, 0.76, 0.78), metal=1.0, rug=0.22)
inox_osc = mat("inox_osc", color=(0.45, 0.47, 0.5), metal=1.0, rug=0.4)
negro = mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7)
cristal = mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.12)
C_VIRUS = (0.45, 1.0, 0.15)

ZH = base_maquina(r, 3.0, CAL)

# ------------------------------------------------------------ pedestal y plataforma
torneado("pedestal", [(0, ZH), (1.05, ZH), (1.05, ZH + 0.18), (0.98, ZH + 0.24), (0.9, ZH + 0.26), (0, ZH + 0.26)], ch, lados=64, padre=r)
toro("pedestal_franja", 1.05, 0.03, (0, 0, ZH + 0.12), ac, padre=r)
for k in range(12):
    a = k * math.tau / 12
    caja(f"pedestal_panel{k}", (0.006, 0.18, 0.1), (math.cos(a) * 1.052, math.sin(a) * 1.052, ZH + 0.06), negro, bisel=0.0, padre=r, giro=(0, 0, a))
Z0 = ZH + 0.26
# anillo inferior blindado con tornillos
def anillo(nombre, z, alto=0.12, n=24):
    torneado(nombre, [(0.74, z), (0.86, z), (0.86, z + alto), (0.74, z + alto)], inox_osc, lados=64, padre=r, cerrar=True)
    for k in range(n):
        a = k * math.tau / n
        tornillo(f"{nombre}_t{k}", (math.cos(a) * 0.86, math.sin(a) * 0.86, z + alto / 2), r, r=0.014, normal="+X")
        bpy.data.objects[f"{nombre}_t{k}"].rotation_euler = (0, math.radians(90), a)
Z1 = Z0 + 1.6
anillo("anillo_inf", Z0)
anillo("anillo_sup", Z1 - 0.12)
anillo("anillo_med", Z0 + 0.74, alto=0.06, n=16)
cilindro("vidrio_blindado", 0.76, Z1 - Z0 - 0.24, (0, 0, (Z0 + Z1) / 2), cristal, lados=64, bisel=0.0, padre=r)
for k in range(6):
    a = k * math.tau / 6 + math.pi / 6
    caja(f"montante{k}", (0.06, 0.08, Z1 - Z0), (math.cos(a) * 0.82, math.sin(a) * 0.82, (Z0 + Z1) / 2), inox_osc, bisel=0.012, padre=r, giro=(0, 0, a))
    for z in (Z0 + 0.3, Z0 + 1.1):
        tornillo(f"montante{k}_t{z:.2f}", (math.cos(a) * 0.865, math.sin(a) * 0.865, z), r, r=0.012, normal="+X")
        bpy.data.objects[f"montante{k}_t{z:.2f}"].rotation_euler = (0, math.radians(90), a)
# líquido verde interior (translúcido) y niebla en capas
liq = mat("caldo_cepa", color=(0.35, 0.8, 0.2), rug=0.15, emision=(0.35, 1.0, 0.15), fuerza=0.15, alfa=0.14)
cilindro("caldo_cepa", 0.72, Z1 - Z0 - 0.3, (0, 0, (Z0 + Z1) / 2 - 0.03), liq, lados=48, bisel=0.0, padre=r)
for k in range(3):
    n = vacio(f"niebla_{k}", (0, 0, Z0 + 0.2 + k * 0.08), padre=r)
    torneado(f"niebla_disco{k}", [(0, 0), (0.7 - k * 0.05, 0), (0.7 - k * 0.05, 0.03), (0, 0.06)],
             mat(f"niebla{k}", color=(0.85, 1.0, 0.85), rug=0.9, alfa=0.12), lados=48, padre=n)
# tapa superior: cúpula de acero con escotilla, ventiladores y luces
torneado("tapa", [(0, Z1), (0.92, Z1), (0.92, Z1 + 0.08), (0.75, Z1 + 0.2), (0.35, Z1 + 0.28), (0, Z1 + 0.3)], ch, lados=64, padre=r)
toro("tapa_franja", 0.92, 0.025, (0, 0, Z1 + 0.05), ac, padre=r)
cilindro("escotilla", 0.22, 0.06, (0, 0, Z1 + 0.32), inox_osc, lados=32, bisel=0.012, padre=r)
toro("escotilla_volante", 0.14, 0.014, (0, 0, Z1 + 0.42), mat("volante_rojo", color=(0.7, 0.05, 0.05), rug=0.45), padre=r)
for k in range(3):
    caja(f"escotilla_radio{k}", (0.28, 0.014, 0.01), (0, 0, Z1 + 0.42), mat("volante_rojo"), bisel=0.0, padre=r, giro=(0, 0, k * math.pi / 3))
cilindro("escotilla_eje", 0.02, 0.08, (0, 0, Z1 + 0.38), inox, lados=12, padre=r)
for k in range(8):
    a = k * math.tau / 8
    tornillo(f"escotilla_t{k}", (math.cos(a) * 0.19, math.sin(a) * 0.19, Z1 + 0.35), r, r=0.012, normal="+Z")
# balizas giratorias de aviso sobre la tapa
for k, a in enumerate((math.radians(45), math.radians(225))):
    x, y = math.cos(a) * 0.55, math.sin(a) * 0.55
    z = Z1 + 0.2
    cilindro(f"baliza_giro_base{k}", 0.07, 0.04, (x, y, z), gr, lados=24, bisel=0.008, padre=r)
    cilindro(f"baliza_giro_cupula{k}", 0.06, 0.1, (x, y, z + 0.08), mat("cupula_ambar", color=(1.0, 0.55, 0.05), rug=0.2, emision=(1.0, 0.5, 0.05), fuerza=0.6, alfa=0.7),
             lados=24, bisel=0.02, padre=r)
    g = vacio(f"gira_baliza{k}", (x, y, z + 0.07), padre=r)
    caja(f"baliza_espejo{k}", (0.07, 0.008, 0.06), (0.0, 0.0, 0.0), mat("espejo_luz", color=(1.0, 0.8, 0.3), rug=0.1, emision=(1.0, 0.7, 0.2), fuerza=4.0), bisel=0.0, padre=g)

# ------------------------------------------------------------ el virus
flo = vacio("flotar", (0, 0, Z0 + 0.66), padre=r)
vir = vacio("virus", (0, 0, 0), padre=flo)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=0.3, location=(0, 0, 0))
cap = bpy.context.active_object
cap.name = "capside"
cap.data.materials.append(mat("virus_capside", color=(0.12, 0.42, 0.08), rug=0.45, emision=(0.3, 0.9, 0.1), fuerza=0.25))
bm = bmesh.new(); bm.from_mesh(cap.data)
for v in bm.verts:
    v.co *= 1.0 + random.uniform(-0.04, 0.04)
bm.to_mesh(cap.data); bm.free()
for p in cap.data.polygons:
    p.use_smooth = False
cap.parent = vir
# espículas: tallo + cabeza en los vértices del icosaedro base
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0)
base = bpy.context.active_object
dirs = [v.co.normalized() for v in base.data.vertices]
bpy.data.objects.remove(base)
esp_tallo = mat("virus_espicula", color=(0.85, 0.35, 0.1), rug=0.45)
esp_cab = mat("virus_cabeza", color=(1.0, 0.25, 0.15), rug=0.4, emision=(1.0, 0.3, 0.1), fuerza=0.8)
for k, d in enumerate(dirs):
    rot = d.to_track_quat('Z', 'Y').to_euler()
    p0 = d * 0.29
    t = cilindro(f"espicula{k}", 0.018, 0.14, tuple(p0 + d * 0.07), esp_tallo, lados=8, bisel=0.0, padre=vir)
    t.rotation_euler = rot
    e = esfera(f"espicula{k}_cabeza", 0.04, tuple(p0 + d * 0.16), esp_cab, padre=vir, escala=(1, 1, 0.7))
    e.rotation_euler = rot
# glicoproteínas pequeñas repartidas (capa que gira al revés)
capa = vacio("gira_virus_capa", (0, 0, 0), padre=vir)
for k in range(40):
    u, v_ = random.random(), random.random()
    th, ph = u * math.tau, math.acos(2 * v_ - 1)
    d = Vector((math.sin(ph) * math.cos(th), math.sin(ph) * math.sin(th), math.cos(ph)))
    g = cilindro(f"glico{k}", 0.01, 0.07, tuple(d * 0.32), mat("virus_glico", color=(0.95, 0.85, 0.2), rug=0.5), lados=6, bisel=0.0, padre=capa)
    g.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
# ARN interior entrevisto (espiral roja)
pts = [(math.cos(i * 0.7) * (0.12 + 0.04 * math.sin(i)), math.sin(i * 0.7) * (0.12 + 0.04 * math.sin(i)), -0.15 + i * 0.012) for i in range(26)]
tubo_curvo("arn", pts, 0.012, mat("virus_arn", color=(0.9, 0.1, 0.15), rug=0.4, emision=(0.9, 0.1, 0.1), fuerza=0.5), padre=vir)

# ------------------------------------------------------------ inyector de viales (lado -X)
IX = -1.08
ZI = Z0 + 0.62
caja("iny_columna", (0.12, 0.12, ZI + 0.45 - ZH), (IX, -0.15, (ZH + ZI + 0.45) / 2), inox_osc, bisel=0.015, padre=r)
caja("iny_riel", (0.06, 0.05, 0.5), (IX + 0.09, -0.15, ZI + 0.2), inox, bisel=0.006, padre=r)
caja("iny_tubo_entrada", (0.22, 0.1, 0.1), (IX + 0.2, -0.15, ZI), inox_osc, bisel=0.012, padre=r)
cilindro("iny_puerto", 0.05, 0.06, (IX + 0.3, -0.15, ZI), inox, lados=24, bisel=0.008, padre=r, giro=(0, math.radians(90), 0))
car = vacio("inyector_carro", (IX + 0.14, -0.15, ZI + 0.05), padre=r)
caja("iny_carro_cuerpo", (0.08, 0.14, 0.14), (0, 0, 0), ac, bisel=0.015, padre=car)
caja("iny_portavial", (0.08, 0.07, 0.05), (0.0, 0.0, 0.1), gr, bisel=0.01, padre=car)
vi = objetos.vial("vial_inyeccion", padre=car, pos=(0.0, 0.0, 0.12), color=C_VIRUS)
vi.scale = (ESC * 0.9, ESC * 0.9, ESC * 0.9)
ag = vacio("inyector_aguja", (IX + 0.42, -0.15, ZI), padre=r)
cilindro("aguja_cuerpo", 0.012, 0.25, (0.1, 0, 0), inox, lados=10, padre=ag, giro=(0, math.radians(90), 0))
torneado("aguja_punta", [(0, 0.0), (0.004, 0.0), (0.012, 0.04), (0, 0.04)], inox, lados=10, padre=ag).rotation_euler = (0, math.radians(-90), 0)
bpy.data.objects["aguja_punta"].location = (0.27, 0, 0)
for s in (-1, 1):
    caja(f"iny_aviso{s}", (0.004, 0.1, 0.1), (IX - 0.062, -0.15 + s * 0.0, Z0 + 0.5 + (s + 1) * 0.15), gr, bisel=0.0, padre=r)
calcomania("iny_bio", 0.09, 0.09, (IX - 0.065, -0.15, Z0 + 0.5), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r,
           giro=(math.radians(90), 0, math.radians(-90)))

# ------------------------------------------------------------ criogenia (lado +X): depósitos, mangueras con escarcha, manómetros
for k, y in enumerate((-0.55, 0.0)):
    cilindro(f"criotanque{k}", 0.18, 0.72, (1.2, y, ZH + 0.38), ch, lados=32, bisel=0.06, segmentos=4, padre=r)
    cilindro(f"criotanque{k}_cuello", 0.07, 0.08, (1.2, y, ZH + 0.77), inox, lados=24, bisel=0.01, padre=r)
    toro(f"criotanque{k}_aro", 0.181, 0.012, (1.2, y, ZH + 0.4), ac, padre=r)
    cilindro(f"criotanque{k}_valvula", 0.03, 0.06, (1.2, y, ZH + 0.86), inox_osc, lados=12, padre=r)
    toro(f"criotanque{k}_volante", 0.045, 0.008, (1.2, y, ZH + 0.9), mat("volante_azul", color=(0.1, 0.3, 0.8), rug=0.45), padre=r)
    manometro(f"manometro{k}", (1.2 - 0.185, y, ZH + 0.6), r, r=0.055, normal_giro=(math.radians(90), 0, math.radians(-90)))
    escarcha = mat("escarcha", color=(0.92, 0.96, 1.0), rug=0.85)
    tubo_curvo(f"manguera{k}", [(1.2, y, ZH + 0.88), (1.1, y, ZH + 1.05), (0.95, y * 0.6, Z0 + 0.4), (0.87, y * 0.5, Z0 + 0.3)], 0.03, escarcha, padre=r)
caja("crio_aviso_marco", (0.004, 0.12, 0.12), (1.2 - 0.182, 0.28, ZH + 0.4), gr, bisel=0.0, padre=r)

# ------------------------------------------------------------ consola con el árbol de mutaciones (delante)
cons = vacio("consola", (0.0, -1.18, ZH), padre=r)
caja("consola_pie", (0.7, 0.3, 0.75), (0, 0, 0.375), ch, bisel=0.04, segmentos=3, padre=cons)
caja("consola_franja", (0.712, 0.312, 0.05), (0, 0, 0.6), ac, bisel=0.012, padre=cons)
pan = vacio("consola_pantalla", (0, 0.02, 0.85), padre=cons)
pan.rotation_euler = (math.radians(-25), 0, 0)
caja("pantalla_marco", (0.8, 0.06, 0.46), (0, 0, 0), gr, bisel=0.02, padre=pan)
pantalla_plano("pantalla", 0.72, 0.38, (0, -0.032, 0), padre=pan)
caja("pantalla_visera", (0.82, 0.08, 0.02), (0, -0.03, 0.235), gr, bisel=0.006, padre=pan)
cilindro("seta_aro", 0.04, 0.01, (0.25, -0.155, 0.62), mat("amarillo"), lados=24, bisel=0.002, padre=cons, giro=(math.radians(90), 0, 0))
esfera("seta", 0.032, (0.25, -0.17, 0.62), mat("seta_roja", color=(0.75, 0.04, 0.04), rug=0.35), padre=cons)
caja("llave_caja", (0.08, 0.02, 0.08), (-0.2, -0.16, 0.62), gr, bisel=0.008, padre=cons)
cilindro("llave", 0.012, 0.04, (-0.2, -0.18, 0.62), mat("aluminio_dorado", color=(1.0, 0.68, 0.22), metal=1.0, rug=0.35), lados=8, padre=cons, giro=(math.radians(90), 0, 0))
calcomania("consola_logo", 0.2, 0.1, (0, -0.152, 0.35), mat_calcomania("placa_logo", os.path.join(CAL, "placa_logo.png"), 0.35), padre=cons)
for sx in (-1, 1):
    for sz in (0.15, 0.5):
        tornillo(f"consola_t{sx}{sz}", (sx * 0.3, -0.152, sz), cons, r=0.009)
tubo_curvo("consola_cable", [(0.0, 0.15, 0.05), (0.0, 0.4, 0.03), (0.3, 0.75, 0.05)], 0.02, negro, padre=cons)

# ------------------------------------------------------------ barandilla de seguridad y torre
for k in range(10):
    a = math.radians(-60 + k * 32)
    if -1.9 < a < -1.25:
        continue
    x, y = math.cos(a) * 1.32, math.sin(a) * 1.32
    cilindro(f"baranda_poste{k}", 0.018, 0.6, (x, y, ZH + 0.3), mat("amarillo"), lados=12, padre=r)
pts = [(math.cos(math.radians(a)) * 1.32, math.sin(math.radians(a)) * 1.32, ZH + 0.6) for a in range(-60, 230, 10)]
tubo_curvo("baranda_pasamanos", pts, 0.02, mat("amarillo"), padre=r)
pts2 = [(x, y, ZH + 0.32) for x, y, _ in pts]
tubo_curvo("baranda_media", pts2, 0.014, mat("amarillo"), padre=r)
torre_luces((-1.25, 1.2, ZH), r, poste=0.6)
calcomania("suelo_aviso", 0.5, 0.5, (0.7, -0.95, ZH + 0.003), mat_calcomania("aviso_bio", os.path.join(CAL, "aviso_biorriesgo.png"), 0.5, True), padre=r,
           giro=(0, 0, math.radians(20)))
puerto_lamas("entrada", -1, -1.4, ZH + 0.25, r, ancho=0.3, alto=0.22, y=-0.15, z_flecha=ZH + 0.002, x_flecha=-1.42)
caja("entrada_conducto", (0.3, 0.3, 0.26), (-1.25, -0.15, ZH + 0.25), gr, bisel=0.015, padre=r)

exportar(SALIDA)
print("CEPA OK")
