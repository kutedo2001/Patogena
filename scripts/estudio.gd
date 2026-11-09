extends Node3D
## Estudio de láminas: coloca modelos en fila sobre una mesa neutra con luz de
## tres puntos para revisarlos de cerca. Argumentos de usuario:
##   --modelos=ruta1,ruta2,...   --escala=1.0   --separacion=0.08
##   --cam_dist=0.5 --cam_alto=25 --cam_giro=30   (distancia en m, ángulos en grados)

func _ready() -> void:
	var modelos: PackedStringArray = []
	var escala := 1.0
	var sep := 0.08
	var dist := 0.5
	var alto := 25.0
	var giro := 30.0
	var personajes: PackedStringArray = []   # variante:animación:estilo:amp+amp
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=")
		if kv.size() != 2:
			continue
		match kv[0]:
			"modelos": modelos = kv[1].split(",")
			"escala": escala = float(kv[1])
			"separacion": sep = float(kv[1])
			"cam_dist": dist = float(kv[1])
			"cam_alto": alto = float(kv[1])
			"cam_giro": giro = float(kv[1])
			"personajes": personajes = kv[1].split(",")
	var x := -sep * (modelos.size() - 1) / 2.0
	var alto_max := 0.0
	for ruta in modelos:
		var ps: PackedScene = load(ruta)
		if ps == null:
			push_error("no se carga " + ruta)
			continue
		var n: Node3D = ps.instantiate()
		Materiales.ajustar(n)
		n.scale = Vector3.ONE * escala
		n.position.x = x
		add_child(n)
		x += sep
		alto_max = maxf(alto_max, _alto(n))
	for i in personajes.size():
		var c := personajes[i].split(":")
		var p := Personaje.new()
		p.variante = c[0]
		p.animacion = c[1] if c.size() > 1 else "idle"
		p.estilo = c[2] if c.size() > 2 else ""
		if c.size() > 3 and c[3] != "":
			p.amputado = PackedStringArray(c[3].split("+"))
		p.position.x = (i - (personajes.size() - 1) / 2.0) * sep
		add_child(p)
		alto_max = 0.9
	var cam: Camera3D = $Camara
	var objetivo := Vector3(0, alto_max * 0.45, 0)
	var dir := Basis(Vector3.UP, deg_to_rad(giro)) * Basis(Vector3.RIGHT, deg_to_rad(-alto)) * Vector3(0, 0, 1)
	cam.position = objetivo + dir * dist
	cam.look_at(objetivo)

func _alto(n: Node) -> float:
	var h := 0.0
	if n is VisualInstance3D:
		var aabb: AABB = (n as VisualInstance3D).get_aabb()
		h = (n as Node3D).global_transform.origin.y + aabb.end.y * (n as Node3D).global_transform.basis.get_scale().y
	for c in n.get_children():
		h = maxf(h, _alto(c))
	return h
