class_name LineaCinta
extends Node3D
## Línea de cinta transportadora construida a partir de una lista de casillas.
## Coloca tramos rectos y curvos (modelos de Blender), desplaza la banda (UV) y
## mueve los objetos por el recorrido a la velocidad del nivel (Mk1–Mk3).

const VELOCIDAD := {1: 0.7, 2: 1.2, 3: 2.0}       # m/s visuales
const ALTURA_BANDA := 0.3

@export var nivel := 1
@export var casillas: Array[Vector2i] = []         # recorrido, casillas contiguas
@export var cerrada := false                       # bucle (vuelve a la primera)
@export var escala_objetos := 2.5

var _puntos: PackedVector3Array = []
var _acum: PackedFloat32Array = []
var _largo := 0.0
var _mat_banda: StandardMaterial3D
var _objetos: Array[Node3D] = []
var _dist: Array[float] = []

func _ready() -> void:
	_construir()

## Coloca un objeto (escena) en la cinta a la distancia d del inicio.
func poner(escena: PackedScene, d: float) -> void:
	var n: Node3D = escena.instantiate()
	Materiales.ajustar(n)
	n.scale = Vector3.ONE * escala_objetos
	add_child(n)
	_objetos.append(n)
	_dist.append(d)

func largo() -> float:
	return _largo

func _dir(a: Vector2i, b: Vector2i) -> Vector2i:
	return b - a

func _construir() -> void:
	var n := casillas.size()
	if n < 2:
		return
	var recta: PackedScene = load("res://assets/modelos/cintas/cinta_recta_mk%d.glb" % nivel)
	var curva: PackedScene = load("res://assets/modelos/cintas/cinta_curva_mk%d.glb" % nivel)
	var curva_der: PackedScene = load("res://assets/modelos/cintas/cinta_curva_der_mk%d.glb" % nivel)
	for i in n:
		var c := casillas[i]
		var prev: Vector2i
		var sig: Vector2i
		if i == 0:
			prev = casillas[n - 1] if cerrada else c - (casillas[1] - c)
		else:
			prev = casillas[i - 1]
		if i == n - 1:
			sig = casillas[0] if cerrada else c + (c - casillas[i - 1])
		else:
			sig = casillas[i + 1]
		var d_in := c - prev
		var d_out := sig - c
		var centro := Vector3(c.x, 0, c.y)
		var pieza: Node3D
		var yaw := atan2(-float(d_in.y), float(d_in.x))
		if d_in == d_out:
			pieza = recta.instantiate()
			_tramo_recto(centro, Vector3(d_in.x, 0, d_in.y))
		else:
			# dos modelos: a la izquierda (+X → −Z en Godot) y a la derecha (+X → +Z)
			var cruz := d_in.x * d_out.y - d_in.y * d_out.x      # >0 derecha (en pantalla, Z hacia abajo)
			pieza = (curva_der if cruz > 0 else curva).instantiate()
			_tramo_curvo(centro, Vector3(d_in.x, 0, d_in.y), Vector3(d_out.x, 0, d_out.y))
		pieza.position = centro
		pieza.rotation.y = yaw
		add_child(pieza)
		_banda_compartida(pieza)
	if cerrada:
		_puntos.append(_puntos[0])
	_acum.resize(_puntos.size())
	_acum[0] = 0.0
	for i in range(1, _puntos.size()):
		_acum[i] = _acum[i - 1] + _puntos[i].distance_to(_puntos[i - 1])
	_largo = _acum[_acum.size() - 1]

func _tramo_recto(c: Vector3, d: Vector3) -> void:
	var a := c - d * 0.5
	if _puntos.is_empty() or _puntos[_puntos.size() - 1].distance_to(a) > 0.01:
		_puntos.append(a)
	_puntos.append(c + d * 0.5)

func _tramo_curvo(c: Vector3, d_in: Vector3, d_out: Vector3) -> void:
	var entrada := c - d_in * 0.5
	var pivote := entrada + d_out * 0.5               # centro del arco
	var r0 := entrada - pivote
	var r1 := (c + d_out * 0.5) - pivote
	if _puntos.is_empty() or _puntos[_puntos.size() - 1].distance_to(entrada) > 0.01:
		_puntos.append(entrada)
	for k in range(1, 9):
		var t := k / 8.0
		var v := r0.slerp(r1, t) if r0.length() > 0 else r1
		_puntos.append(pivote + v.normalized() * 0.5)

## Todas las piezas de la línea comparten un material de banda para desplazarlo a la vez.
func _banda_compartida(pieza: Node) -> void:
	for mi in pieza.find_children("banda*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).get_active_material(0)
		if m == null:
			continue
		if _mat_banda == null:
			_mat_banda = m.duplicate()
			_mat_banda.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		(mi as MeshInstance3D).material_override = _mat_banda

func _punto(d: float) -> Array:
	if _largo <= 0.0:
		return [Vector3.ZERO, Vector3.RIGHT]
	d = fposmod(d, _largo) if cerrada else clampf(d, 0.0, _largo)
	var i := _acum.bsearch(d)
	i = clampi(i, 1, _acum.size() - 1)
	var a := _puntos[i - 1]
	var b := _puntos[i]
	var tramo := _acum[i] - _acum[i - 1]
	var t := (d - _acum[i - 1]) / tramo if tramo > 0.0 else 0.0
	return [a.lerp(b, t), (b - a).normalized()]

func _process(dt: float) -> void:
	var v: float = VELOCIDAD[nivel]
	if _mat_banda:
		_mat_banda.uv1_offset.x -= v * dt
	for i in _objetos.size():
		_dist[i] += v * dt
		if not cerrada and _dist[i] > _largo:
			_dist[i] -= _largo
		var pd := _punto(_dist[i])
		var o := _objetos[i]
		o.position = (pd[0] as Vector3) + Vector3(0, ALTURA_BANDA + 0.002, 0)
		var dir: Vector3 = pd[1]
		o.rotation.y = atan2(-dir.z, dir.x)
