extends SceneTree
## Lámina R1.1: candidatos de personajes CC0 con la cámara del rediseño (FOV 32°, 52°, girada 45°).
## Uso: xvfb-run godot --rendering-method forward_plus -s tools/laminas/lamina_personajes.gd -- salida.png [cerca]

const FILAS := [
	["A", ["res://_lamina/uac/Doctor_Male_Young.gltf", "res://_lamina/uac/Doctor_Female_Young.gltf", "res://_lamina/uac/Suit_Male.gltf", "res://_lamina/uac/Casual_Female.gltf", "res://_lamina/uac/Worker_Male.gltf", "res://_lamina/uac/Zombie_Male.gltf"]],
	["B", ["res://_lamina/zak/Characters_Matt.gltf", "res://_lamina/zak/Characters_Lis.gltf", "res://_lamina/zak/Characters_Sam.gltf", "res://_lamina/zak/Characters_Shaun.gltf", "res://_lamina/zak/Zombie_Basic.gltf", "res://_lamina/zak/Zombie_Chubby.gltf"]],
	["C", ["res://_lamina/kk/Knight.glb", "res://_lamina/kk/Mage.glb", "res://_lamina/kk/Rogue.glb", "res://_lamina/kk/Barbarian.glb"]],
	["D", ["res://assets/personajes/character-male-a.glb", "res://assets/personajes/character-female-d.glb", "res://assets/personajes/character-female-e.glb"]],
]
const ALTO := 0.85

var _f := 0
var _salida := "/tmp/lamina_personajes.png"
var _cerca := false
var _solo := -1

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_salida = a[0]
	_cerca = a.size() > 1
	_solo = int(a[1]) if a.size() > 1 and a[1].is_valid_int() else -1
	root.size = Vector2i(1920, 1080)
	var mundo := Node3D.new()
	root.add_child(mundo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.86, 0.9, 0.88)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.95, 0.92, 0.88)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.ssao_enabled = true
	env.environment = e
	mundo.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -30, 0)
	sol.light_color = Color(1.0, 0.95, 0.86)
	sol.light_energy = 1.25
	sol.shadow_enabled = true
	mundo.add_child(sol)
	# suelo de baldosa verde agua y un tramo de pared Two Point de fondo
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(14, 10)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.62, 0.8, 0.74)
	suelo.material_override = ms
	mundo.add_child(suelo)
	for i in 30:
		for j in 22:
			if (i + j) % 2 == 0:
				var b := MeshInstance3D.new()
				var bm := PlaneMesh.new()
				bm.size = Vector2(0.48, 0.48)
				b.mesh = bm
				b.position = Vector3(-7 + i * 0.5 + 0.25, 0.002, -5 + j * 0.5 + 0.25)
				var mb := StandardMaterial3D.new()
				mb.albedo_color = Color(0.66, 0.84, 0.78)
				b.material_override = mb
				mundo.add_child(b)
	_pared(mundo, Vector3(0, 0, -2.6), 9.0)
	var der := Vector3(1, 0, -1).normalized()
	var fondo := Vector3(-1, 0, -1).normalized()
	var z := -1.7
	for k in FILAS.size():
		var fila: Array = FILAS[k]
		if _solo >= 0 and k != _solo:
			continue
		if _solo >= 0:
			z = 0.0
		var x := -float(fila[1].size() - 1) * 0.5
		for ruta in fila[1]:
			var esc: PackedScene = load(ruta)
			if esc == null:
				continue
			var m: Node3D = esc.instantiate()
			mundo.add_child(m)
			_limpiar(m)
			_ajustar(m)
			m.position += der * x + fondo * z
			m.rotation.y = deg_to_rad(45)
			_animar(m)
			x += 1.0
		z += 1.1
	var cam := Camera3D.new()
	cam.fov = 32.0 if not _cerca else 25.0
	var dist := 13.0 if not _cerca else 8.0
	var piv := Vector3(0, 0.3, -0.1) if _solo < 0 else Vector3(0, 0.42, 0)
	var dir := Vector3(sin(deg_to_rad(45.0)) * cos(deg_to_rad(52.0)), sin(deg_to_rad(52.0)), cos(deg_to_rad(45.0)) * cos(deg_to_rad(52.0)))
	mundo.add_child(cam)
	cam.look_at_from_position(piv + dir * dist, piv)
	cam.current = true

func _pared(p: Node3D, pos: Vector3, largo: float) -> void:
	var capas := [[0.0, 0.25, Color(0.47, 0.36, 0.62)], [0.25, 0.04, Color(0.95, 0.78, 0.25)], [0.29, 0.26, Color(0.93, 0.93, 0.9)], [0.55, 0.03, Color(1, 1, 1)]]
	for c in capas:
		var mi := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(largo, c[1], 0.18 if c[1] > 0.03 else 0.22)
		mi.mesh = bx
		mi.position = pos + Vector3(0, c[0] + c[1] * 0.5, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = c[2]
		mi.material_override = m
		p.add_child(mi)

const ARMAS := ["axe", "guitar", "knife", "pistol", "rifle", "shotgun", "smg", "spear", "bat", "sword", "shield", "staff", "wand", "dagger", "crossbow", "spellbook", "mug", "cape"]

func _limpiar(m: Node3D) -> void:
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var n := String(mi.name).to_lower()
		for a in ARMAS:
			if a in n:
				mi.visible = false
		var mm: Mesh = (mi as MeshInstance3D).mesh
		if mm:
			for i in mm.get_surface_count():
				var mat := mm.surface_get_material(i)
				if mat and mat.resource_name == "Skin":
					var piel := StandardMaterial3D.new()
					piel.albedo_color = Color(0.96, 0.78, 0.64)
					piel.roughness = 0.8
					(mi as MeshInstance3D).set_surface_override_material(i, piel)
				elif mat and mat.resource_name == "Face":
					var ojos := StandardMaterial3D.new()
					ojos.albedo_color = Color(0.1, 0.08, 0.08)
					(mi as MeshInstance3D).set_surface_override_material(i, ojos)

func _ajustar(m: Node3D) -> void:
	var aabb := AABB()
	var primero := true
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			continue
		var t := Transform3D()
		var n: Node = mi
		while n != m and n is Node3D:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var bb: AABB = t * (mi as MeshInstance3D).get_aabb()
		aabb = bb if primero else aabb.merge(bb)
		primero = false
	if aabb.size.y > 0.001:
		var k := ALTO / aabb.size.y
		m.scale = Vector3.ONE * k
		m.position.y = -aabb.position.y * k

func _animar(m: Node3D) -> void:
	var aps := m.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty():
		return
	var ap: AnimationPlayer = aps[0]
	var nombre := ""
	for n in ap.get_animation_list():
		if n.to_lower() in ["idle", "idle_a"] or n.to_lower().ends_with("/idle"):
			nombre = n
	if nombre == "":
		for n in ap.get_animation_list():
			if "idle" in n.to_lower():
				nombre = n
				break
	if nombre != "":
		ap.play(nombre)
		ap.seek(0.4, true)

func _process(_d: float) -> bool:
	_f += 1
	if _f == 12:
		var img := root.get_texture().get_image()
		img.save_png(_salida)
		print("lamina: ", _salida)
		return true
	return false
