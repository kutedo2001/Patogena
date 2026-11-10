extends SceneTree
## Pantalla objetivo del rediseño 2.0 (R1.3, puerta 3): recepción, espera, sala de extracción y laboratorio de sangre
## unidos por una cinta que cruza la pared, con el personal trabajando y la interfaz estilo Two Point.
## Cámara del juego: FOV 32°, 52°, girada 45°. Uso: xvfb-run godot -s tools/laminas/pantalla_objetivo.gd -- salida.png [sin_hud]

const TP := "res://assets/modelos/tp/"
const PJ := "res://assets/personajes/quaternius/"
const AZUL := Color(0.25, 0.47, 0.7)
var _f := 0
var _salida := "/tmp/objetivo.png"
var _hud := true
var mundo: Node3D

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_salida = a[0]
	_hud = not (a.size() > 1 and a[1] == "sin_hud")
	root.size = Vector2i(1920, 1080)
	root.msaa_3d = Viewport.MSAA_4X
	root.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	root.scaling_3d_scale = 2.0
	mundo = Node3D.new()
	root.add_child(mundo)
	_luz()
	_suelo("tp_suelo_pasillo", Rect2(-4, -5, 14, 9), 0.0)
	_suelo("tp_suelo_lab", Rect2(0, -4, 5, 4), 0.004)
	_suelo("tp_suelo_extraccion", Rect2(5, -4, 3, 4), 0.004)
	_exterior()
	_laboratorio()
	_extraccion()
	_pasillo()
	var cam := Camera3D.new()
	cam.fov = 32.0 if not OS.get_cmdline_user_args().has("banco") else 14.0
	var piv := Vector3(3.1, 0.3, 0.45)
	var d := Vector3(sin(deg_to_rad(45.0)) * cos(deg_to_rad(52.0)), sin(deg_to_rad(52.0)), cos(deg_to_rad(45.0)) * cos(deg_to_rad(52.0)))
	mundo.add_child(cam)
	if OS.get_cmdline_user_args().has("banco"):
		piv = Vector3(1.8, 0.3, 0.6)
	cam.look_at_from_position(piv + d * 12.6, piv)
	cam.current = true
	if _hud:
		var capa := CanvasLayer.new()
		root.add_child(capa)
		var h: Control = load("res://tools/laminas/hud_objetivo.gd").new()
		capa.add_child(h)

func _exterior() -> void:
	# acera y césped alrededor de la parcela, muro exterior al fondo
	var acera := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	acera.mesh = pm
	acera.position = Vector3(3, -0.01, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.56, 0.7, 0.42)
	m.roughness = 0.95
	acera.material_override = m
	mundo.add_child(acera)
	var borde := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(15, 0.06, 10)
	borde.mesh = bm
	borde.position = Vector3(3, -0.04, -0.5)
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.78, 0.76, 0.72)
	borde.material_override = mb
	mundo.add_child(borde)
	for x in range(-4, 10):
		_pieza("pared_recta", Vector3(x + 0.5, 0, -5), 0, Color(0.55, 0.42, 0.34))
	for z in range(-5, 4):
		_pieza("pared_recta" if z != 1 else "pared_ventana", Vector3(-4, 0, z + 0.5), 90, Color(0.55, 0.42, 0.34))
	_pieza("pared_esquina", Vector3(-4, 0, -5), 0, Color(0.55, 0.42, 0.34))

func _sala(x0: int, z0: int, w: int, h: int, puerta: int, ventana: int, zoc: Color, pasamuros := {}) -> void:
	for x in w:
		var k := "pared_recta"
		if x == puerta:
			k = "pared_puerta"
		elif x == ventana:
			k = "pared_ventana"
		_pieza(k, Vector3(x0 + x + 0.5, 0, z0 + h), 0, zoc)
	for z in h:
		for lado in [0, 1]:
			var xx: int = x0 if lado == 0 else x0 + w
			var k2 := "pared_pasamuros" if pasamuros.get(Vector2i(xx, z0 + z), false) else "pared_recta"
			_pieza(k2, Vector3(xx, 0, z0 + z + 0.5), 90, zoc)
	for p in [Vector3(x0, 0, z0 + h), Vector3(x0 + w, 0, z0 + h)]:
		_pieza("pared_esquina", p, 0, zoc)

func _laboratorio() -> void:
	_sala(0, -4, 5, 4, 1, 3, Color(0.36, 0.26, 0.52), {Vector2i(0, -2): true, Vector2i(5, -2): true})
	var cf := _cargar(TP + "tp_centrifuga.glb", Vector3(2.0, 0, -2.0), 180)
	cf.find_child("rotor", true, false).rotation.y = 0.7
	cf.find_child("brazo_carga", true, false).rotation.y = 1.2
	# línea: de la sala de extracción (derecha) a la centrífuga y, con hematíes, al almacén (izquierda)
	for x in [3, 4]:
		_pieza("cinta_recta", Vector3(x + 0.5, 0, -1.5), 180)
	for k in 4:
		_cargar(TP + "gradilla_sangre.glb", Vector3(3.27 + k * 0.48, 0.38, -1.5), 0)
	for x in [0, -1, -2]:
		_pieza("cinta_recta", Vector3(x + 0.5, 0, -1.5), 180)
	for k in 5:
		_cargar(TP + "gradilla_hematies.glb", Vector3(0.73 - k * 0.62, 0.38, -1.5), 0)
	var alm := _cargar("res://assets/modelos/estaciones/almacen.glb", Vector3(-3.0, 0, -1.5), 90)
	alm.scale = Vector3.ONE * 0.9
	# plasma al depósito
	var tub := _pieza("tuberia_recta", Vector3(1.38, 0, -3.08), 90)
	tub.scale = Vector3(0.18, 1, 1)
	var dep := _cargar("res://assets/modelos/estaciones/deposito.glb", Vector3(1.38, 0, -3.55), 0)
	dep.scale = Vector3.ONE * 0.8
	_cargar(TP + "planta.glb", Vector3(4.6, 0, -3.6), 0)
	_persona("Doctor_Female_Young", Vector3(2.5, 0, -0.72), 180, "Working_A", 0.4)

func _extraccion() -> void:
	_sala(5, -4, 3, 4, 1, -1, AZUL)
	_pieza("pared_recta", Vector3(8, 0, -3.5), 90, AZUL)
	var ll := _cargar(TP + "llenadora_gradillas.glb", Vector3(5.5, 0, -1.5), 180)
	_cargar(TP + "gradilla_sangre.glb", Vector3(5.6, 0.58, -1.5), 0).scale = Vector3(1, 0.6, 1)
	var cam := _cargar("res://assets/modelos/estaciones/camilla.glb", Vector3(7.0, 0, -2.7), 90)
	_cargar(TP + "carrito_extraccion.glb", Vector3(7.65, 0, -3.4), 0)
	_persona("Casual2_Male", Vector3(7.0, 0.42, -2.68), 180, "Lie_Idle", 0.3)
	_persona("Doctor_Male_Old", Vector3(6.45, 0, -2.75), 90, "Working_B", 0.5)
	_persona("Zombie_Female", Vector3(6.1, 0, -1.0), -90, "Holding_A", 0.3)
	_cargar(TP + "gradilla_sangre.glb", Vector3(5.85, 0.32, -1.0), 90)
	_cargar(TP + "planta.glb", Vector3(7.6, 0, -0.4), 0)

func _pasillo() -> void:
	_cargar(TP + "recepcion.glb", Vector3(5.4, 0, 1.55), 180)
	_persona("Suit_Female", Vector3(5.15, 0, 1.15), 0, "Sit_Chair_Idle", 0.4)
	_persona("Casual_Male", Vector3(5.2, 0, 2.25), 180, "Idle_B", 0.3)
	_persona("Casual2_Female", Vector3(5.8, 0, 2.75), -150, "Idle_A", 0.6)
	_cargar(TP + "planta.glb", Vector3(4.2, 0, 1.55), 0)
	for b in [[Vector3(1.45, 0, 0.55), 180], [Vector3(3.75, 0, 0.55), 180]]:
		_cargar(TP + "banco.glb", b[0], b[1])
	_persona("Casual_Female", Vector3(0.85, 0.0, 0.74), 0, "Sit_Chair_Idle", 0.2)
	_persona("OldClassy_Male", Vector3(2.05, 0.0, 0.74), 0, "Sit_Chair_Idle", 0.6)
	_persona("Casual3_Male", Vector3(3.75, 0.0, 0.74), 0, "Sit_Chair_Idle", 0.4)
	_persona("Casual_Bald", Vector3(3.6, 0, 2.2), -60, "Walking_A", 0.3)
	_persona("Worker_Male", Vector3(2.6, 0, 1.6), 30, "Walking_B", 0.6)
	_cargar(TP + "maquina_bebidas.glb", Vector3(5.1, 0, 0.42), 180)
	_cargar(TP + "planta.glb", Vector3(0.18, 0, 0.3), 0)
	_cargar(TP + "planta.glb", Vector3(-3.6, 0, -0.4), 0)
	_cargar(TP + "papelera.glb", Vector3(2.6, 0, 0.3), 0)
	var ext := _cargar(TP + "extintor.glb", Vector3(8.0, 0, 1.0), -90)
	var c1 := _cargar(TP + "cartel_empresa.glb", Vector3(2.7, 0.75, 0.1), 180)
	var c2 := _cargar(TP + "cartel_empresa.glb", Vector3(6.6, 0.75, 0.1), 180)

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
	if anim.begins_with("Sit"):
		p.set_meta("sentado", true)
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

## Comprobación de solapes (Edu 10-nov: nada se atraviesa). Cajas de cada objeto colocado en el suelo, encogidas
## 3 cm; se ignoran paredes, suelos, cintas con lo que llevan encima y los pares que se tocan a propósito.
func _solapes() -> void:
	var cajas := []
	for n in mundo.get_children():
		if not (n is Node3D) or n is Camera3D or n is DirectionalLight3D or n is WorldEnvironment:
			continue
		var nom := String(n.scene_file_path).get_file().get_basename()
		if n.has_meta("sentado"):
			nom = "sentado_" + nom
		if nom == "" or nom.begins_with("pared") or nom.begins_with("cinta") or nom.begins_with("tuberia"):
			continue
		var bb := AABB()
		var primero := true
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			if mi.get_parent() is Skeleton3D:
				continue
			var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			bb = b if primero else bb.merge(b)
			primero = false
		if primero:
			# personas: cilindro aproximado de 0,36 × 0,36 alrededor de su origen
			bb = AABB(n.global_position - Vector3(0.18, 0, 0.18), Vector3(0.36, 0.8, 0.36))
		var e := Vector3(minf(0.03, bb.size.x * 0.4), minf(0.03, bb.size.y * 0.4), minf(0.03, bb.size.z * 0.4))
		cajas.append([nom, AABB(bb.position + e, bb.size - e * 2).abs()])
	var permitido := ["banco:sentado", "recepcion:sentado", "gradilla", "camilla:Casual2_Male", "llenadora_gradillas:gradilla_sangre", "almacen:gradilla"]
	var n_solapes := 0
	for i in cajas.size():
		for j in range(i + 1, cajas.size()):
			if cajas[i][1].intersects(cajas[j][1]):
				var par := "%s:%s" % [cajas[i][0], cajas[j][0]]
				var ok := false
				for pm in permitido:
					if pm in par or ("gradilla" in par and pm == "gradilla"):
						ok = true
				if not ok:
					n_solapes += 1
					print("SOLAPE ", par, " ", cajas[i][1].intersection(cajas[j][1]).size)
	print("solapes: ", n_solapes)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		_solapes()
	if _f == 8:
		root.get_texture().get_image().save_png(_salida)
		print("lamina: ", _salida)
		return true
	return false
