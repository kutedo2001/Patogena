class_name Acabado
extends RefCounted
## Acabados comunes del rediseño 2.0 (R1.2b): grano de pintura en relieve, banda de goma con estrías, piel y ojos
## de los personajes, zócalo por sala. Lo usan la partida y las láminas para que se vean igual.

static var _grano: Texture2D
static var _banda: Texture2D
static var _banda_n: Texture2D
static var _cache := {}

static func materiales(n: Node) -> void:
	if _grano == null:
		_grano = load("res://assets/texturas/tp_grano_n.png")
		_banda = load("res://assets/texturas/tp_banda.png")
		_banda_n = load("res://assets/texturas/tp_banda_n.png")
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mm: Mesh = (mi as MeshInstance3D).mesh
		if mm == null:
			continue
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
				elif d.albedo_texture == null and d.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and d.metallic < 0.5:
					d.normal_enabled = true
					d.normal_texture = _grano
					d.normal_scale = 0.25
					d.uv1_triplanar = true
					d.uv1_scale = Vector3(3, 3, 3)
				_cache[clave] = d
			(mi as MeshInstance3D).set_surface_override_material(s, _cache[clave])

static func zocalo(n: Node, c: Color) -> void:
	var z := StandardMaterial3D.new()
	z.albedo_color = c
	z.roughness = 0.55
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mm: Mesh = (mi as MeshInstance3D).mesh
		for s in mm.get_surface_count():
			var mat := mm.surface_get_material(s)
			if mat and mat.resource_name == "pared_zocalo":
				(mi as MeshInstance3D).set_surface_override_material(s, z)

static func persona(p: Node, zombi := false) -> void:
	for mi in p.find_children("*", "MeshInstance3D", true, false):
		var mm: Mesh = (mi as MeshInstance3D).mesh
		for s in mm.get_surface_count():
			var mat := mm.surface_get_material(s)
			if mat and mat.resource_name == "Skin":
				var piel := StandardMaterial3D.new()
				piel.albedo_color = Color(0.55, 0.72, 0.42) if zombi else Color(0.96, 0.78, 0.64)
				(mi as MeshInstance3D).set_surface_override_material(s, piel)
			elif mat and mat.resource_name == "Face":
				var o := StandardMaterial3D.new()
				o.albedo_color = Color(0.1, 0.08, 0.08)
				(mi as MeshInstance3D).set_surface_override_material(s, o)

## Luz y entorno de la pantalla objetivo.
static func entorno(padre: Node) -> void:
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
	e.ssil_enabled = true
	e.ssil_intensity = 0.6
	e.glow_enabled = true
	e.glow_intensity = 0.25
	env.environment = e
	padre.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-58, -25, 0)
	sol.light_color = Color(1.0, 0.94, 0.84)
	sol.light_energy = 1.2
	sol.shadow_enabled = true
	sol.shadow_blur = 1.0
	sol.directional_shadow_max_distance = 40.0
	padre.add_child(sol)
	var relleno := DirectionalLight3D.new()
	relleno.rotation_degrees = Vector3(-35, 150, 0)
	relleno.light_color = Color(0.75, 0.85, 1.0)
	relleno.light_energy = 0.35
	padre.add_child(relleno)
