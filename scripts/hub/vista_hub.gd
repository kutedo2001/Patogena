class_name VistaHub
extends Node3D
## Dibuja el edificio (R2.1) con las piezas de la pantalla objetivo: césped y acera, suelo del pasillo, suelo propio
## de cada sala, paredes de 1 m por los bordes con puerta, esquinas, muro exterior al fondo y objetos con su modelo.
## Casilla (x, y) del edificio = (x, z) del mundo; el centro de la casilla está en +0,5.

const TP := "res://assets/modelos/tp/"
var h: Hospital
var pasamuros := {}      # bordes con pasamuros (los pone la Planta al cruzar paredes con cintas)
var _estatico: Node3D
var _objs := {}          # Objeto.id → Node3D
var _modelos := {}

func _init(hospital: Hospital) -> void:
	h = hospital

func _ready() -> void:
	reconstruir()

static func centro(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5, 0, c.y + 0.5)

func _cargar(ruta: String) -> Node3D:
	if not _modelos.has(ruta):
		_modelos[ruta] = load(ruta)
	var n: Node3D = (_modelos[ruta] as PackedScene).instantiate()
	Acabado.materiales(n)
	return n

func reconstruir() -> void:
	if _estatico:
		_estatico.queue_free()
	_estatico = Node3D.new()
	_estatico.name = "estatico"
	add_child(_estatico)
	var p := h.parcela
	_plano(Rect2(p.position.x - 30, p.position.y - 30, p.size.x + 60, p.size.y + 60), -0.05, Color(0.56, 0.7, 0.42), "")
	_plano(Rect2(p.position.x - 0.3, p.position.y - 0.3, p.size.x + 0.6, p.size.y + 0.6), -0.02, Color(0.78, 0.76, 0.72), "")
	_plano(Rect2(p.position, p.size), 0.0, Color.WHITE, "tp_suelo_pasillo")
	for s in h.salas:
		var d: Dictionary = Hospital.datos.salas[s.tipo]
		_plano(Rect2(s.rect.position, s.rect.size), 0.004, Color.WHITE, d.suelo)
	_paredes()
	_muro_exterior()
	# objetos
	var vivos := {}
	for o in h.objetos:
		vivos[o.id] = true
		if not _objs.has(o.id):
			var n := _cargar(o.dato().modelo)
			add_child(n)
			n.transform = transform_objeto(o.tipo, o.origen, o.giro)
			_objs[o.id] = n
		else:
			_objs[o.id].transform = transform_objeto(o.tipo, o.origen, o.giro)
	for id in _objs.keys():
		if not vivos.has(id):
			_objs[id].queue_free()
			_objs.erase(id)

## Colocación de un objeto: centro de su huella y giro del modelo (frente hacia +y con giro 0).
static func transform_objeto(tipo: String, origen: Vector2i, giro: int) -> Transform3D:
	var cs := Hospital.huella(tipo, origen, giro)
	var m := Vector3.ZERO
	for c in cs:
		m += centro(c)
	m /= cs.size()
	var yaw := deg_to_rad(float(Hospital.datos.objetos[tipo].base) - 90.0 * giro)
	return Transform3D(Basis(Vector3.UP, yaw), m)

func _plano(r: Rect2, y: float, color: Color, tex: String) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = r.size
	mi.mesh = pm
	mi.position = Vector3(r.position.x + r.size.x / 2, y, r.position.y + r.size.y / 2)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if tex != "":
		m.albedo_texture = load("res://assets/texturas/%s.png" % tex)
		m.uv1_scale = Vector3(r.size.x, r.size.y, 1)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		var n := {"tp_suelo_pasillo": "tp_baldosa_n", "tp_suelo_extraccion": "tp_baldosa_n", "tp_suelo_lab": "tp_suelo_lab_n"}
		if n.has(tex):
			m.normal_enabled = true
			m.normal_texture = load("res://assets/texturas/%s.png" % n[tex])
			m.normal_scale = 0.8
	mi.material_override = m
	_estatico.add_child(mi)

func _pieza(k: String, pos: Vector3, giro_deg: float, zoc: Color) -> void:
	var n := _cargar(TP + k + ".glb")
	n.position = pos
	n.rotation.y = deg_to_rad(giro_deg)
	Acabado.zocalo(n, zoc)
	_estatico.add_child(n)

## Paredes de las salas: un módulo por borde de casilla. Borde compartido entre dos salas, una sola pared.
func _paredes() -> void:
	var hechos := {}
	var esquinas := {}
	for s in h.salas:
		var zc: Array = Hospital.datos.salas[s.tipo].zocalo
		var zoc := Color(zc[0], zc[1], zc[2])
		var r: Rect2i = s.rect
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				var c := Vector2i(x, y)
				for l in 4:
					var f: Vector2i = c + Hospital.DIRS[l]
					if r.has_point(f):
						continue
					var clave := [mini(c.x, f.x), mini(c.y, f.y), maxi(c.x, f.x), maxi(c.y, f.y)]
					if hechos.has(clave):
						continue
					hechos[clave] = true
					var k := "pared_puerta" if (c == s.puerta and l == s.lado) else ("pared_pasamuros" if pasamuros.has(clave) else "pared_recta")
					var medio := (centro(c) + centro(f)) * 0.5
					var gir := 0.0 if l == 1 or l == 3 else 90.0
					_pieza(k, medio, gir, zoc)
		for e in [r.position, Vector2i(r.end.x, r.position.y), Vector2i(r.position.x, r.end.y), r.end]:
			esquinas[e] = zoc
	for e in esquinas:
		_pieza("pared_esquina", Vector3(e.x, 0, e.y), 0.0, esquinas[e])

## Muro del edificio por el fondo y la izquierda (los lados de la cámara se ven abiertos, como Two Point).
func _muro_exterior() -> void:
	var p := h.parcela
	var zoc := Color(0.55, 0.42, 0.34)
	for x in range(p.position.x, p.end.x):
		_pieza("pared_recta", Vector3(x + 0.5, 0, p.position.y), 0.0, zoc)
	for y in range(p.position.y, p.end.y):
		_pieza("pared_ventana" if y % 4 == 2 else "pared_recta", Vector3(p.position.x, 0, y + 0.5), 90.0, zoc)
	_pieza("pared_esquina", Vector3(p.position.x, 0, p.position.y), 0.0, zoc)
