extends Node3D
## Sala del laboratorio generada por código: suelo de baldosa, paredes con
## zócalo verde clínico, ventanas y marcas en el suelo. Las dos paredes que dan
## a la cámara se esconden (como en Timberborn / Two Point).

@export var ancho := 24          # casillas en X
@export var fondo := 16          # casillas en Z
## ventanas que no se ponen en la pared del fondo (sitio para el monitor del mundo)
@export var sin_ventana_fondo: Array[float] = [2.0, 6.0]
const ALTO := 3.2
const GROSOR := 0.3
const ALTO_ZOCALO := 1.1

const C_VERDE := Color(0.29, 0.58, 0.54)      # verde agua clínico (marca)
const C_BLANCO := Color(0.88, 0.89, 0.87)
const C_GRAFITO := Color(0.17, 0.19, 0.2)
const C_CRISTAL := Color(0.62, 0.78, 0.82)
const C_AMARILLO := Color(0.93, 0.74, 0.18)

var _paredes: Array = []   # [nodo, normal hacia fuera]
var camara: Node3D

func _ready() -> void:
	_suelo()
	_pared(Vector3(0, 0, -fondo / 2.0), ancho, Vector3(0, 0, -1), 0.0)
	_pared(Vector3(0, 0, fondo / 2.0), ancho, Vector3(0, 0, 1), 180.0)
	_pared(Vector3(-ancho / 2.0, 0, 0), fondo, Vector3(-1, 0, 0), 90.0)
	_pared(Vector3(ancho / 2.0, 0, 0), fondo, Vector3(1, 0, 0), -90.0)
	_marcas()

func _process(_dt: float) -> void:
	if camara == null or not camara.has_method("direccion_vista"):
		return
	var dir: Vector3 = camara.direccion_vista()
	for p in _paredes:
		(p[0] as Node3D).visible = (p[1] as Vector3).dot(dir) < 0.2

func _mat(c: Color, rugosidad := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rugosidad
	m.metallic = metal
	return m

func _caja(padre: Node3D, tam: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	padre.add_child(mi)
	return mi

func _suelo() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ancho, fondo)
	mi.mesh = pm
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/texturas/baldosa.png")
	m.uv1_scale = Vector3(ancho, fondo, 1)
	m.roughness = 0.55
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mi.material_override = m
	add_child(mi)
	# losa bajo el suelo para que el borde tenga canto
	_caja(self, Vector3(ancho + GROSOR * 2, 0.4, fondo + GROSOR * 2), Vector3(0, -0.201, 0), _mat(C_GRAFITO))

## Pared centrada en `centro`, de longitud `largo`, girada `giro_y` grados.
func _pared(centro: Vector3, largo: float, normal: Vector3, giro_y: float) -> void:
	var p := Node3D.new()
	p.position = centro + normal * (GROSOR / 2.0)
	p.rotation_degrees.y = giro_y
	add_child(p)
	_paredes.append([p, normal])
	var l := largo + GROSOR * 2
	var m_verde := _mat(C_VERDE, 0.7)
	var m_blanco := _mat(C_BLANCO, 0.9)
	var m_graf := _mat(C_GRAFITO, 0.6, 0.2)
	# zócalo oscuro, franja verde, remate
	_caja(p, Vector3(l, 0.14, GROSOR + 0.04), Vector3(0, 0.07, 0), m_graf)
	_caja(p, Vector3(l, ALTO_ZOCALO - 0.14, GROSOR), Vector3(0, 0.14 + (ALTO_ZOCALO - 0.14) / 2.0, 0), m_verde)
	_caja(p, Vector3(l, 0.06, GROSOR + 0.05), Vector3(0, ALTO_ZOCALO, 0), m_graf)
	_caja(p, Vector3(l, 0.08, GROSOR + 0.06), Vector3(0, ALTO + 0.04, 0), m_graf)
	# parte alta blanca con ventanas cada 4 casillas
	var y0 := ALTO_ZOCALO + 0.03
	var hv0 := 1.45
	var hv1 := 2.75
	var ancho_v := 2.0
	var n_v := int(largo / 4.0)
	var huecos: Array = []
	for i in n_v:
		var hx := -largo / 2.0 + 2.0 + i * 4.0
		if is_equal_approx(giro_y, 0.0) and sin_ventana_fondo.has(hx):
			continue
		huecos.append(hx)
	# tiras de pared entre ventanas
	var x := -l / 2.0
	for hx in huecos:
		var x1: float = hx - ancho_v / 2.0
		_caja(p, Vector3(x1 - x, ALTO - y0, GROSOR), Vector3((x + x1) / 2.0, y0 + (ALTO - y0) / 2.0, 0), m_blanco)
		_ventana(p, hx, ancho_v, y0, hv0, hv1, m_blanco, m_graf)
		x = hx + ancho_v / 2.0
	_caja(p, Vector3(l / 2.0 - x, ALTO - y0, GROSOR), Vector3((x + l / 2.0) / 2.0, y0 + (ALTO - y0) / 2.0, 0), m_blanco)

func _ventana(p: Node3D, cx: float, w: float, y0: float, h0: float, h1: float, m_pared: Material, m_marco: Material) -> void:
	_caja(p, Vector3(w, h0 - y0, GROSOR), Vector3(cx, (y0 + h0) / 2.0, 0), m_pared)
	_caja(p, Vector3(w, ALTO - h1, GROSOR), Vector3(cx, (h1 + ALTO) / 2.0, 0), m_pared)
	# marco
	_caja(p, Vector3(w, 0.08, GROSOR + 0.08), Vector3(cx, h0, 0), m_marco)
	_caja(p, Vector3(w, 0.08, GROSOR + 0.08), Vector3(cx, h1, 0), m_marco)
	_caja(p, Vector3(0.08, h1 - h0, GROSOR + 0.08), Vector3(cx - w / 2.0 + 0.04, (h0 + h1) / 2.0, 0), m_marco)
	_caja(p, Vector3(0.08, h1 - h0, GROSOR + 0.08), Vector3(cx + w / 2.0 - 0.04, (h0 + h1) / 2.0, 0), m_marco)
	_caja(p, Vector3(0.05, h1 - h0, GROSOR + 0.04), Vector3(cx, (h0 + h1) / 2.0, 0), m_marco)
	# cristal: algo emisivo para leer como luz de día
	var mc := _mat(C_CRISTAL, 0.1, 0.0)
	mc.emission_enabled = true
	mc.emission = C_CRISTAL
	mc.emission_energy_multiplier = 0.6
	_caja(p, Vector3(w - 0.1, h1 - h0, 0.04), Vector3(cx, (h0 + h1) / 2.0, 0), mc)

## Marcas de seguridad en el suelo: pasillo perimetral amarillo.
func _marcas() -> void:
	var m := _mat(C_AMARILLO, 0.6)
	var y := 0.006
	var e := 0.08
	var mx := ancho / 2.0 - 1.0
	var mz := fondo / 2.0 - 1.0
	_caja(self, Vector3(mx * 2, 0.01, e), Vector3(0, y, -mz), m)
	_caja(self, Vector3(mx * 2, 0.01, e), Vector3(0, y, mz), m)
	_caja(self, Vector3(e, 0.01, mz * 2), Vector3(-mx, y, 0), m)
	_caja(self, Vector3(e, 0.01, mz * 2), Vector3(mx, y, 0), m)
