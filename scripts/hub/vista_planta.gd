class_name VistaPlanta
extends Node3D
## Dibuja la operación (R2.3–R2.5): personas con su modelo y animación según lo que hacen (andar, sentarse en el
## banco en su plaza, tumbarse en la camilla, trabajar en su puesto, llevar una gradilla con los brazos delante),
## gradillas en las cintas y en las máquinas, y las piezas que se mueven (rotor, brazo, agujas, empujador).
## Los puntos de uso están medidos con los huesos de la animación (regla 8: nada se atraviesa).

const PJ := "res://assets/personajes/quaternius/"
const ESCALA := 0.3
const BRAZOS := ["CharacterArmature/Skeleton3D:UpperArm.L", "CharacterArmature/Skeleton3D:LowerArm.L",
	"CharacterArmature/Skeleton3D:UpperArm.R", "CharacterArmature/Skeleton3D:LowerArm.R"]
const ASIENTO_X := [-0.6, 0.0, 0.6]
const ASIENTO_FONDO := 0.19        # el origen de la persona sentada va 0,19 por delante del centro del banco

var pl: Planta
var vista: VistaHub
var _gente := {}                    # Persona.id → {nodo, ap, arbol, carga}
var _items: Array = []              # gradillas de las cintas (reutilizadas)
var _modelos := {}
var _maq := {}                      # Objeto.id → {rotor, brazo, agujas, ...}
var _t := 0.0

func _init(planta: Planta, v: VistaHub) -> void:
	pl = planta
	vista = v

func _escena(ruta: String) -> PackedScene:
	if not _modelos.has(ruta):
		_modelos[ruta] = load(ruta)
	return _modelos[ruta]

func _gradilla(objeto: String) -> Node3D:
	var n: Node3D = _escena("res://assets/modelos/tp/%s.glb" % ("gradilla_hematies" if objeto == "gradilla_hematies" else "gradilla_sangre")).instantiate()
	Acabado.materiales(n)
	n.set_meta("objeto", objeto)
	return n

# ------------------------------------------------------------------ personas
func _crear(p: Planta.Persona) -> Dictionary:
	var n: Node3D = _escena(PJ + p.modelo + ".glb").instantiate()
	n.scale = Vector3.ONE * ESCALA
	Acabado.persona(n, p.modelo.begins_with("Zombie"))
	add_child(n)
	var ap: AnimationPlayer = n.find_children("*", "AnimationPlayer", true, false)[0]
	# árbol: cuerpo con la animación de lo que hace y, si lleva algo, los brazos con «Holding_A»
	var arbol := AnimationTree.new()
	var bt := AnimationNodeBlendTree.new()
	var cuerpo := AnimationNodeAnimation.new()
	cuerpo.animation = &"Idle_A"
	var brazos := AnimationNodeAnimation.new()
	brazos.animation = &"Holding_A"
	var mezcla := AnimationNodeBlend2.new()
	mezcla.filter_enabled = true
	for b in BRAZOS:
		mezcla.set_filter_path(NodePath(b), true)
	bt.add_node(&"cuerpo", cuerpo)
	bt.add_node(&"brazos", brazos)
	bt.add_node(&"mezcla", mezcla)
	bt.connect_node(&"mezcla", 0, &"cuerpo")
	bt.connect_node(&"mezcla", 1, &"brazos")
	bt.connect_node(&"output", 0, &"mezcla")
	arbol.tree_root = bt
	n.add_child(arbol)
	arbol.anim_player = arbol.get_path_to(ap)
	arbol.active = true
	return {"nodo": n, "ap": ap, "arbol": arbol, "bt": bt, "anim": "", "carga": null, "sk": n.find_children("*", "Skeleton3D", true, false)[0]}

func _anim(g: Dictionary, nombre: String) -> void:
	if g.anim == nombre:
		return
	g.anim = nombre
	var nodo: AnimationNodeAnimation = (g.bt as AnimationNodeBlendTree).get_node(&"cuerpo")
	nodo.animation = StringName(nombre)
	(g.arbol as AnimationTree).set("parameters/mezcla/blend_amount", 0.0)

func _sync_personas() -> void:
	var vivos := {}
	for p in pl.personas:
		vivos[p.id] = true
		if not _gente.has(p.id):
			_gente[p.id] = _crear(p)
		var g: Dictionary = _gente[p.id]
		var n: Node3D = g.nodo
		var pos := Vector3(p.pos.x, 0, p.pos.y)
		var yaw := atan2(float(p.mira.x), float(p.mira.y))
		match p.estado:
			"esperando":
				var tr := VistaHub.transform_objeto("banco", p.objeto.origen, p.objeto.giro)
				pos = tr * Vector3(ASIENTO_X[p.asiento], 0, -ASIENTO_FONDO)
				yaw = tr.basis.get_euler().y + PI
			"tumbado":
				var tc := VistaHub.transform_objeto("camilla", p.objeto.origen, p.objeto.giro)
				pos = tc * Vector3(-0.42, 0.42, 0.0)
				yaw = tc.basis.get_euler().y + PI * 0.5
			"trabajando":
				pos += Vector3(p.mira.x, 0, p.mira.y) * 0.3     # pegado a su máquina, sin meterse en ella
			"en_cola", "recepcion", "de_pie":
				pass
		n.position = pos
		n.rotation.y = lerp_angle(n.rotation.y, yaw, 0.35) if p.estado in ["", "a_recepcion", "a_esperar", "a_sentarse", "a_camilla", "saliendo", "a_puesto", "a_coger", "a_dejar", "a_cola", "a_pie"] else yaw
		_anim(g, p.anim)
		(g.arbol as AnimationTree).set("parameters/mezcla/blend_amount", 1.0 if p.lleva != "" else 0.0)
		_carga(g, p.lleva)
	for id in _gente.keys():
		if not vivos.has(id):
			(_gente[id].nodo as Node3D).queue_free()
			_gente.erase(id)

## La gradilla va entre las dos manos (huesos Fist.L/Fist.R de la pose de llevar), no atravesando los brazos.
func _carga(g: Dictionary, objeto: String) -> void:
	if objeto == "":
		if g.carga:
			(g.carga as Node3D).queue_free()
			g.carga = null
		return
	if g.carga == null or (g.carga as Node3D).get_meta("objeto") != objeto:
		if g.carga:
			(g.carga as Node3D).queue_free()
		g.carga = _gradilla(objeto)
		add_child(g.carga)
	var sk: Skeleton3D = g.sk
	var a := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Fist.L")).origin
	var b := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Fist.R")).origin
	var c: Node3D = g.carga
	c.global_position = (a + b) * 0.5 + Vector3(0, -0.06, 0)
	c.rotation.y = (g.nodo as Node3D).rotation.y + PI * 0.5

# ------------------------------------------------------------------ cintas y máquinas
func _sync_items() -> void:
	var lista := []
	for ci in pl.cintas.values():
		for it in ci.items:
			var p := Vector3(ci.c.x + 0.5, 0.38, ci.c.y + 0.5) + Vector3(ci.dir.x, 0, ci.dir.y) * (float(it[1]) - 0.5)
			lista.append([it[0], p, atan2(float(ci.dir.x), float(ci.dir.y))])
	while _items.size() < lista.size():
		var n := _gradilla("gradilla_sangre")
		add_child(n)
		_items.append(n)
	for i in _items.size():
		var n: Node3D = _items[i]
		n.visible = i < lista.size()
		if not n.visible:
			continue
		if n.get_meta("objeto") != lista[i][0]:
			n.queue_free()
			n = _gradilla(lista[i][0])
			add_child(n)
			_items[i] = n
		n.position = lista[i][1]
		n.rotation.y = lista[i][2] + PI * 0.5

func _sync_maquinas(dt: float) -> void:
	for m in pl.maquinas.values():
		var nodo: Node3D = vista._objs.get(m.o.id)
		if nodo == null:
			continue
		if m.o.tipo == "centrifuga":
			var rot := nodo.find_child("rotor", true, false) as Node3D
			if rot and m.proceso >= 0.0:
				rot.rotation.y += dt * 14.0
			var g0 := nodo.find_child("gradilla_dentro0", true, false) as Node3D
			var g1 := nodo.find_child("gradilla_dentro1", true, false) as Node3D
			if g0:
				g0.visible = not m.entrada.is_empty()
			if g1:
				g1.visible = not m.salida.is_empty() or m.proceso >= 0.0
			var ag := nodo.find_child("cabezal_agujas", true, false) as Node3D
			if ag:
				ag.position.y = 0.67 + (sin(_t * 4.0) * 0.05 - 0.05 if m.proceso >= 0.0 else 0.0)
			var br := nodo.find_child("brazo_carga", true, false) as Node3D
			if br:
				br.rotation.y = sin(_t * 1.5) * 0.9 if m.proceso >= 0.0 else 0.0
		elif m.o.tipo == "llenadora_gradillas":
			if not m.has_meta("vis"):
				var gv := _gradilla("gradilla_sangre")
				nodo.add_child(gv)
				gv.position = Vector3(0, 0.58, 0)
				gv.scale = Vector3(1, 1, 1)
				m.set_meta("vis", gv)
			var gv2: Node3D = m.get_meta("vis")
			gv2.visible = m.tubos > 0 or not m.salida.is_empty()

func _process(dt: float) -> void:
	_t += dt
	_sync_personas()
	_sync_items()
	_sync_maquinas(dt)
