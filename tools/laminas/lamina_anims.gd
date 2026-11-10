extends SceneTree
## Lámina de animaciones de un personaje: una copia por animación, congelada a mitad.
## Uso: xvfb-run godot -s tools/laminas/lamina_anims.gd -- res://ruta.glb salida.png [anim1,anim2,...]
var _f := 0
var _salida := ""
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var ruta: String = a[0]
	_salida = a[1]
	var lista: PackedStringArray = (a[2] if a.size() > 2 else "Idle_A,Walking_A,Sit_Chair_Idle,Lie_Idle,Working_A,Holding_A,Interact,Cheering").split(",")
	root.size = Vector2i(1920, 1080)
	var mundo := Node3D.new()
	root.add_child(mundo)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.84, 0.9, 0.87)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 0.96, 0.9)
	e.ambient_light_energy = 0.6
	env.environment = e
	mundo.add_child(env)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -35, 0)
	sol.shadow_enabled = true
	mundo.add_child(sol)
	var suelo := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 10)
	suelo.mesh = pm
	var ms := StandardMaterial3D.new()
	ms.albedo_color = Color(0.64, 0.82, 0.76)
	suelo.material_override = ms
	mundo.add_child(suelo)
	var esc: PackedScene = load(ruta)
	for i in lista.size():
		var m: Node3D = esc.instantiate()
		mundo.add_child(m)
		m.scale = Vector3.ONE * float(OS.get_environment("ESC") if OS.has_environment("ESC") else "1.0")
		m.position = Vector3(-float(lista.size() - 1) * 0.6 + i * 1.2, 0, 0)
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			var mm: Mesh = (mi as MeshInstance3D).mesh
			for s in mm.get_surface_count():
				var mat := mm.surface_get_material(s)
				if mat and mat.resource_name == "Skin":
					var p := StandardMaterial3D.new()
					p.albedo_color = Color(0.96, 0.78, 0.64)
					(mi as MeshInstance3D).set_surface_override_material(s, p)
				elif mat and mat.resource_name == "Face":
					var o := StandardMaterial3D.new()
					o.albedo_color = Color(0.1, 0.08, 0.08)
					(mi as MeshInstance3D).set_surface_override_material(s, o)
		var ap: AnimationPlayer = m.find_children("*", "AnimationPlayer", true, false)[0]
		var n := lista[i]
		if ap.has_animation(n):
			ap.play(n)
			ap.seek(ap.current_animation_length * 0.45, true)
			ap.pause()
		else:
			print("falta ", n, " en ", ap.get_animation_list())
	var cam := Camera3D.new()
	cam.fov = 30
	mundo.add_child(cam)
	cam.look_at_from_position(Vector3(0, 4.2, 7.5), Vector3(0, 0.5, 0))
func _process(_d: float) -> bool:
	_f += 1
	if _f == 10:
		root.get_texture().get_image().save_png(_salida)
		print("lamina: ", _salida)
		return true
	return false
