extends SceneTree
## Lámina de estilo R1.2: laboratorio de sangre al estilo Two Point con la centrífuga nueva, cinta Alchemy
## Factory que entra por un pasamuros con gradillas, salida de bolsas, tubería de plasma, técnico trabajando y
## pasillo con pacientes. Cámara del rediseño: FOV 32°, inclinación 52°, girada 45°.
## Uso: xvfb-run godot -s tools/laminas/lamina_estilo.gd -- salida.png [cerca]

const TP := "res://assets/modelos/tp/"
const PJ := "res://assets/personajes/quaternius/"
var _f := 0
var _salida := "/tmp/estilo.png"
var _cerca := false
var _gif := false
var _cf: Node3D
var _ent: Array = []     # gradillas de la cinta de entrada
var _sal: Array = []     # gradillas de la cinta de salida
var _a: Node3D           # gradilla que entra y coge el brazo
var _b: Node3D           # gradilla en las agujas (sangre)
var _bh: Node3D          # la misma, ya con hematíes
var _brazo: Node3D
var _pinza: Node3D
var _agujas: Node3D
var _plasma: Node3D
var _rotor: Node3D
var mundo: Node3D
var _aps: Array = []

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_salida = a[0]
	_cerca = a.size() > 1
	_gif = a.size() > 1 and a[1] == "gif"
	root.size = Vector2i(1920, 1080) if not _gif else Vector2i(960, 540)
	root.msaa_3d = Viewport.MSAA_4X
	root.use_taa = false
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	root.scaling_3d_scale = 2.0 if not _gif else 1.0
	mundo = Node3D.new()
	root.add_child(mundo)
	_luz()
	_suelo("tp_suelo_pasillo", Rect2(-4, -8, 16, 14), 0.0)
	_suelo("tp_suelo_lab", Rect2(0, -4, 5, 4), 0.004)
	# --- laboratorio de sangre (x 0..5, z -4..0)
	for x in 5:
		var k := "pared_recta"
		if x == 1:
			k = "pared_puerta"
		elif x == 3:
			k = "pared_ventana"
		_pieza(k, Vector3(x + 0.5, 0, 0), 0)        # pared delantera
		_pieza("pared_recta", Vector3(x + 0.5, 0, -4), 0)
	for z in 4:
		_pieza("pared_pasamuros" if z == 1 else "pared_recta", Vector3(0, 0, -z - 0.5), 90)
		_pieza("pared_pasamuros" if z == 1 else "pared_recta", Vector3(5, 0, -z - 0.5), 90)
	for p in [Vector3(0, 0, 0), Vector3(5, 0, 0), Vector3(0, 0, -4), Vector3(5, 0, -4)]:
		_pieza("pared_esquina", p, 0)
	# centrífuga de paso en (2,-2) girada 180°: la línea entra por +X y sale por -X en la fila z=-1.5;
	# plasma por la brida trasera al depósito; consola y ventana del túnel hacia la cámara
	var cf := _cargar(TP + "tp_centrifuga.glb", Vector3(2.0, 0, -2.0), 180)
	_cf = cf
	_rotor = cf.find_child("rotor", true, false)
	_rotor.rotation.y = 0.7
	_brazo = cf.find_child("brazo_carga", true, false)
	_pinza = cf.find_child("pinza", true, false)
	_agujas = cf.find_child("cabezal_agujas", true, false)
	_plasma = cf.find_child("plasma_subiendo", true, false)
	_a = cf.find_child("gradilla_dentro0", true, false)
	_b = cf.find_child("gradilla_dentro1", true, false)
	_bh = _cargar(TP + "gradilla_hematies.glb", Vector3(1.5, 0.38, -1.5), 0)
	_bh.visible = false
	for x in range(3, 10):
		_pieza("cinta_recta", Vector3(x + 0.5, 0, -1.5), 180)
	for k in 13:
		_ent.append(_cargar(TP + "gradilla_sangre.glb", Vector3(3.75 + k * 0.48, 0.38, -1.5), 0))
	_pieza("cinta_recta", Vector3(0.5, 0, -1.5), 180)
	_pieza("cinta_recta", Vector3(-0.5, 0, -1.5), 180)
	for k in 3:
		_sal.append(_cargar(TP + "gradilla_hematies.glb", Vector3(0.73 - k * 0.48, 0.38, -1.5), 0))
	var tub := _pieza("tuberia_recta", Vector3(1.38, 0, -3.08), 90)
	tub.scale = Vector3(0.18, 1, 1)
	var dep := _cargar("res://assets/modelos/estaciones/deposito.glb", Vector3(1.38, 0, -3.55), 0)
	dep.scale = Vector3.ONE * 0.8
	_persona("Doctor_Female_Young", Vector3(2.5, 0, -0.72), 180, "Working_A", 0.4)
	_persona("Worker_Male", Vector3(3.9, 0, -0.55), -90, "Holding_A", 0.2)
	_cargar(TP + "gradilla_sangre.glb", Vector3(3.72, 0.3, -0.55), 90)
	# pasillo: banco con pacientes esperando y gente que pasa
	_cargar(TP + "banco.glb", Vector3(1.6, 0, 0.75), 180)
	_persona("Casual_Female", Vector3(1.0, 0.03, 0.8), 0, "Sit_Chair_Idle", 0.2)
	_persona("OldClassy_Male", Vector3(2.2, 0.03, 0.8), 0, "Sit_Chair_Idle", 0.6)
	_persona("Casual3_Male", Vector3(4.6, 0, 1.2), -90, "Walking_A", 0.3)
	_persona("Suit_Female", Vector3(-1.2, 0, 0.5), 90, "Walking_B", 0.6)
	_persona("Zombie_Male", Vector3(7.0, 0, 0.3), -110, "Walking_C", 0.2)
	# cámara
	var cam := Camera3D.new()
	cam.fov = 32.0 if not _cerca else 24.0
	var piv := Vector3(2.6, 0.3, -1.4) if not _cerca else Vector3(2.4, 0.4, -1.7)
	var dist := 13.0 if not _cerca else 8.0
	if _gif:
		piv = Vector3(2.0, 0.5, -1.75)
		dist = 6.2
		cam.fov = 26.0
	var d := Vector3(sin(deg_to_rad(45.0)) * cos(deg_to_rad(52.0)), sin(deg_to_rad(52.0)), cos(deg_to_rad(45.0)) * cos(deg_to_rad(52.0)))
	mundo.add_child(cam)
	cam.look_at_from_position(piv + d * dist, piv)
	cam.current = true

func _luz() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.32, 0.36, 0.38)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.92
	e.ssao_enabled = true
	e.ssao_radius = 0.5
	e.ssao_intensity = 1.6
	e.ssao_detail = 0.8
	e.ssil_enabled = true
	e.ssil_intensity = 0.6
	e.glow_enabled = true
	e.glow_intensity = 0.25
	e.glow_bloom = 0.04
	env.environment = e
	mundo.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-58, -25, 0)
	sol.light_color = Color(1.0, 0.94, 0.84)
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.shadow_blur = 1.0
	sol.directional_shadow_max_distance = 30.0
	mundo.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-35, 150, 0)
	relleno.light_color = Color(0.75, 0.85, 1.0)
	relleno.light_energy = 0.35
	mundo.add_child(relleno)

func _suelo(tex: String, r: Rect2, y: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = r.size
	mi.mesh = pm
	mi.position = Vector3(r.position.x + r.size.x / 2, y, r.position.y + r.size.y / 2)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/texturas/%s.png" % tex)
	m.uv1_scale = Vector3(r.size.x, r.size.y, 1)
	m.roughness = 0.75
	var n := {"tp_suelo_pasillo": "tp_baldosa_n", "tp_suelo_extraccion": "tp_baldosa_n", "tp_suelo_lab": "tp_suelo_lab_n"}
	if n.has(tex):
		m.normal_enabled = true
		m.normal_texture = load("res://assets/texturas/%s.png" % n[tex])
		m.normal_scale = 0.8
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mi.material_override = m
	mundo.add_child(mi)

var _grano: Texture2D
var _banda: Texture2D
var _banda_n: Texture2D
var _cache := {}

## Calidad (R1.2b): grano de pintura en relieve (triplanar) en los materiales lisos, banda de goma con estrías.
func _materiales(n: Node) -> void:
	if _grano == null:
		_grano = load("res://assets/texturas/tp_grano_n.png")
		_banda = load("res://assets/texturas/tp_banda.png")
		_banda_n = load("res://assets/texturas/tp_banda_n.png")
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mm: Mesh = (mi as MeshInstance3D).mesh
		for s in mm.get_surface_count():
			var mat := mm.surface_get_material(s) as StandardMaterial3D
			if mat == null:
				continue
			var clave := mat.get_instance_id()
			if not _cache.has(clave):
				var d: StandardMaterial3D = mat.duplicate()
				if mat.resource_name == "banda":
					d.albedo_texture = _banda
					d.albedo_color = Color.WHITE
					d.normal_enabled = true
					d.normal_texture = _banda_n
					d.roughness = 0.7
					d.uv1_triplanar = true
					d.uv1_scale = Vector3(1, 1, 1)
				elif d.albedo_texture == null and d.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and d.metallic < 0.5:
					d.normal_enabled = true
					d.normal_texture = _grano
					d.normal_scale = 0.25
					d.uv1_triplanar = true
					d.uv1_scale = Vector3(3, 3, 3)
				_cache[clave] = d
			(mi as MeshInstance3D).set_surface_override_material(s, _cache[clave])

func _cargar(ruta: String, pos: Vector3, giro: float) -> Node3D:
	var n: Node3D = (load(ruta) as PackedScene).instantiate()
	if ruta.begins_with(TP):
		_materiales(n)
	mundo.add_child(n)
	n.position = pos
	n.rotation.y = deg_to_rad(giro)
	return n

func _pieza(k: String, pos: Vector3, giro: float, zocalo := Color(0, 0, 0, 0)) -> Node3D:
	var n := _cargar(TP + k + ".glb", pos, giro)
	if zocalo.a > 0:
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var mm: Mesh = (mi as MeshInstance3D).mesh
			for s in mm.get_surface_count():
				var mat := mm.surface_get_material(s)
				if mat and mat.resource_name == "pared_zocalo":
					var z := StandardMaterial3D.new()
					z.albedo_color = zocalo
					z.roughness = 0.55
					(mi as MeshInstance3D).set_surface_override_material(s, z)
	return n

func _persona(n: String, pos: Vector3, giro: float, anim: String, t: float) -> Node3D:
	var p := _cargar(PJ + n + ".glb", pos, giro)
	p.scale = Vector3.ONE * 0.3
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var mm: Mesh = (mi as MeshInstance3D).mesh
		for s in mm.get_surface_count():
			var mat := mm.surface_get_material(s)
			if mat and mat.resource_name == "Skin":
				var piel := StandardMaterial3D.new()
				piel.albedo_color = Color(0.96, 0.78, 0.64) if not n.begins_with("Zombie") else Color(0.55, 0.72, 0.42)
				(mi as MeshInstance3D).set_surface_override_material(s, piel)
			elif mat and mat.resource_name == "Face":
				var o := StandardMaterial3D.new()
				o.albedo_color = Color(0.1, 0.08, 0.08)
				(mi as MeshInstance3D).set_surface_override_material(s, o)
	var aps := p.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		var ap: AnimationPlayer = aps[0]
		if ap.has_animation(anim):
			ap.play(anim)
			ap.seek(ap.current_animation_length * t, true)
			ap.pause()
	return p

## Ciclo de 6 s de la centrífuga de paso (para el GIF): la cinta adelanta una gradilla, el túnel la lleva al brazo,
## el brazo la mete en el tambor, la que vuelve del tambor pasa por las agujas (sube el plasma) y sale con hematíes.
func _ciclo(t: float) -> void:
	var k := clampf(t / 1.5, 0.0, 1.0)
	for i in _ent.size():
		_ent[i].global_position = Vector3(3.75 + 0.48 * i - 0.48 * k, 0.38, -1.5)
	_ent[0].visible = k < 0.999
	# A: del borde de la cinta al brazo por el túnel
	var ta := Vector3(3.27, 0.38, -1.5).lerp(Vector3(2.25, 0.41, -1.5), smoothstep(0.0, 1.5, t))
	var giro := 0.0
	if t > 1.6:
		giro = smoothstep(1.7, 2.5, t) * PI
	_brazo.rotation.y = giro
	var baja := 0.0
	if t < 1.8:
		baja = smoothstep(1.2, 1.6, t) * -0.05
	elif t < 2.6:
		baja = -0.05 + smoothstep(1.6, 1.85, t) * 0.13
	else:
		baja = 0.08 - smoothstep(4.5, 5.5, t) * 0.08
	_pinza.position.y = baja
	if t >= 1.6 and t < 2.6:
		ta = _pinza.global_position + Vector3(0, -0.2, 0)
	_a.global_position = ta
	_a.visible = t < 2.55
	_rotor.rotation.y = t * (6.0 if t < 2.6 else 14.0)
	# B en las agujas: bajan, sale el plasma, suben; la gradilla pasa a hematíes y sale
	var ag := 0.0
	if t < 2.0:
		ag = -smoothstep(0.2, 0.6, t) * 0.12 + smoothstep(1.5, 1.9, t) * 0.12
	_agujas.position.y = 0.67 + ag
	_plasma.scale = Vector3(1, 1, clampf((t - 0.6) / 1.0, 0.05, 1.0)) if t < 3.0 else Vector3(1, 1, 0.05)
	_b.visible = t < 1.6 or t > 5.4
	_b.global_position = Vector3(1.5, 0.38 + (0.2 * (1.0 - smoothstep(5.4, 6.0, t)) if t > 5.4 else 0.0), -1.5)
	_bh.visible = t >= 1.6
	var kb := smoothstep(2.0, 3.2, t)
	_bh.global_position = Vector3(1.5 - 0.77 * kb, 0.38, -1.5)
	for i in _sal.size():
		_sal[i].global_position = Vector3(0.73 - 0.48 * i - 0.48 * kb, 0.38, -1.5)

func _process(_d: float) -> bool:
	_f += 1
	if _gif:
		_ciclo(fmod((_f - 3) * 0.1, 6.0))
		if _f >= 3 and _f < 63:
			root.get_texture().get_image().save_png(_salida % (_f - 3))
		if _f >= 64:
			print("lamina: gif")
			return true
		return false
	if _f == 6:
		root.get_texture().get_image().save_png(_salida)
		print("lamina: ", _salida)
		return true
	return false
