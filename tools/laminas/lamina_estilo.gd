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
var mundo: Node3D
var _aps: Array = []

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_salida = a[0]
	_cerca = a.size() > 1
	root.size = Vector2i(1920, 1080)
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
		_pieza("pared_recta", Vector3(0, 0, -z - 0.5), 90)
		_pieza("pared_pasamuros" if z == 2 else "pared_recta", Vector3(5, 0, -z - 0.5), 90)
	for p in [Vector3(0, 0, 0), Vector3(5, 0, 0), Vector3(0, 0, -4), Vector3(5, 0, -4)]:
		_pieza("pared_esquina", p, 0)
	# centrífuga en (2,-2) girada 180°: entra por +X en la fila z=-2.5, bolsas por -X en z=-1.5, plasma atrás
	var cf := _cargar(TP + "tp_centrifuga.glb", Vector3(2.0, 0, -2.0), 180)
	var rot := cf.find_child("rotor", true, false)
	if rot:
		rot.rotation.y = 0.7
	for x in range(3, 10):
		_pieza("cinta_recta", Vector3(x + 0.5, 0, -2.5), 180)
		if x > 3:
			_cargar(TP + "gradilla_sangre.glb", Vector3(x + 0.5, 0.38, -2.5), 0)
	_pieza("cinta_recta", Vector3(0.5, 0, -1.5), 180)
	_cargar(TP + "bolsa_hematies.glb", Vector3(0.75, 0.38, -1.5), 0)
	_cargar(TP + "bolsa_hematies.glb", Vector3(0.3, 0.38, -1.5), 12)
	var tub := _pieza("tuberia_recta", Vector3(1.5, 0, -3.02), 90)
	tub.scale = Vector3(0.18, 1, 1)
	var dep := _cargar("res://assets/modelos/estaciones/deposito.glb", Vector3(1.5, 0, -3.55), 0)
	dep.scale = Vector3.ONE * 0.8
	_persona("Doctor_Female_Young", Vector3(2.5, 0, -0.62), 180, "Working_A", 0.4)
	_persona("Worker_Male", Vector3(3.9, 0, -0.9), -90, "Holding_A", 0.2)
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
	e.ssao_radius = 0.6
	e.ssao_intensity = 1.4
	env.environment = e
	mundo.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-58, -25, 0)
	sol.light_color = Color(1.0, 0.94, 0.84)
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.shadow_blur = 1.5
	mundo.add_child(sol)

func _suelo(tex: String, r: Rect2, y: float) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = r.size
	mi.mesh = pm
	mi.position = Vector3(r.position.x + r.size.x / 2, y, r.position.y + r.size.y / 2)
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/texturas/%s.png" % tex)
	m.uv1_scale = Vector3(r.size.x, r.size.y, 1)
	m.roughness = 0.8
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mi.material_override = m
	mundo.add_child(mi)

func _cargar(ruta: String, pos: Vector3, giro: float) -> Node3D:
	var n: Node3D = (load(ruta) as PackedScene).instantiate()
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

func _process(_d: float) -> bool:
	_f += 1
	if _f == 14:
		root.get_texture().get_image().save_png(_salida)
		print("lamina: ", _salida)
		return true
	return false
