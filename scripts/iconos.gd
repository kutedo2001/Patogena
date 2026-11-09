extends Node
## Herramienta: renderiza cada modelo a un icono PNG con fondo transparente, con la
## misma inclinación que la cámara del juego. Uso:
##   godot res://escenas/iconos.tscn -- --iconos   → assets/iconos/<nombre>.png

const LADO := 256
## fondo opaco del color de las casillas del HUD: con fondo transparente el vidrio desaparecía
const FONDO := Color(0.74, 0.76, 0.76)   # = bandeja del HUD
const CARPETAS := ["res://assets/modelos/objetos", "res://assets/modelos/maquinas", "res://assets/modelos/cintas"]
const SOLO := ["cinta_recta_mk1", "cinta_curva_mk1"]   # de las cintas basta una muestra

func _ready() -> void:
	var rutas: Array[String] = []
	for c in CARPETAS:
		for f in DirAccess.get_files_at(c):
			if f.ends_with(".glb") and (not c.ends_with("cintas") or f.get_basename() in SOLO):
				rutas.append(c + "/" + f)
	var vp := SubViewport.new()
	vp.size = Vector2i(LADO, LADO)
	vp.transparent_bg = false
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_8X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var ent := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = FONDO
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.84, 0.88)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ent.environment = e
	vp.add_child(ent)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -30, 0)
	sol.light_energy = 1.2
	vp.add_child(sol)
	var rel := DirectionalLight3D.new()
	rel.rotation_degrees = Vector3(-20, 150, 0)
	rel.light_energy = 0.7
	vp.add_child(rel)
	var cam := Camera3D.new()
	cam.fov = 22
	vp.add_child(cam)
	# piezas provisionales (puerta 4): brazo, divisor y almacén
	Fabrica.cargar_datos()
	var prov := {"brazo": Fabrica.Brazo.new(Vector2i.ZERO, 0, ""), "divisor": Fabrica.Divisor.new(Vector2i.ZERO, 0),
		"almacen": Fabrica.Almacen.new(Vector2i.ZERO, 0), "camilla": Fabrica.Estacion.new("camilla", Vector2i.ZERO, 0),
		"incubadora": Fabrica.Estacion.new("incubadora", Vector2i.ZERO, 0), "toma_agua": Fabrica.Estacion.new("toma_agua", Vector2i.ZERO, 0),
		"ascensor": Fabrica.Ascensor.new(Vector2i.ZERO), "muelle": Fabrica.MuelleEnvio.new(Vector2i.ZERO)}
	for r in rutas + prov.keys():
		var n: Node3D = Provisional.crear(prov[r], Vector3.ZERO) if prov.has(r) else load(r).instantiate()
		Materiales.ajustar(n)
		vp.add_child(n)
		await get_tree().process_frame
		var caja := _aabb(n, Transform3D.IDENTITY)
		var centro := caja.get_center()
		var radio := caja.size.length() * 0.5
		var dir := Basis(Vector3.UP, deg_to_rad(45)) * Basis(Vector3.RIGHT, deg_to_rad(-38)) * Vector3(0, 0, 1)
		cam.position = centro + dir * (radio / tan(deg_to_rad(cam.fov * 0.5)) * 1.02)
		cam.look_at(centro)
		for i in 4:
			await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		var nombre: String = r if prov.has(r) else r.get_file().get_basename()
		img.save_png("res://assets/iconos/%s.png" % nombre)
		print("icono ", nombre)
		n.queue_free()
	get_tree().quit()

func _aabb(n: Node, t: Transform3D) -> AABB:
	var tt := t * (n as Node3D).transform if n is Node3D else t
	var caja := AABB()
	var primera := true
	if n is VisualInstance3D and not (n is Light3D):
		caja = tt * (n as VisualInstance3D).get_aabb()
		primera = false
	for c in n.get_children():
		var sub := _aabb(c, tt)
		if sub.size == Vector3.ZERO:
			continue
		caja = sub if primera else caja.merge(sub)
		primera = false
	return caja
