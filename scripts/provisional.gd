class_name Provisional
extends Node3D
## Piezas provisionales para la puerta 4 (mecánica en gris): brazo, divisor, almacén,
## extractores, muelles y nodos de extracción. Formas simples con los colores del
## laboratorio; se sustituyen por modelos detallados en la puerta 5.

const C_CHASIS := Color(0.86, 0.86, 0.84)
const C_GRAFITO := Color(0.25, 0.28, 0.29)
const C_ACENTO := Color(0.4, 0.77, 0.9)
const C_AMARILLO := Color(0.98, 0.82, 0.25)
const C_MADERA := Color(0.62, 0.48, 0.3)
const C_MARCA_P := Color(0.29, 0.58, 0.54)

var tipo := ""
var _viajes_vistos := 0
var _t_viaje := 99.0
var _brazo: Node3D
var _luz: StandardMaterial3D
var _barra: MeshInstance3D

static func mat(c: Color, rug := 0.6, emision := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emision > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emision
	return m

func caja(tam: Vector3, pos: Vector3, c: Color, padre: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = tam
	mi.mesh = bm
	mi.material_override = mat(c)
	mi.position = pos
	padre.add_child(mi)
	return mi

func cilindro(r: float, h: float, pos: Vector3, c: Color, padre: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = mat(c)
	mi.position = pos
	padre.add_child(mi)
	return mi

func luz(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	mi.mesh = sm
	_luz = mat(Color(0.3, 1.0, 0.45), 0.3, 2.0)
	mi.material_override = _luz
	mi.position = pos
	add_child(mi)

var _giratorio: Node3D
var _barra_n: Node3D
var _van: Node3D
var _torre_p := {}

## Modelo detallado de estaciones/ (V1.11): sustituye a las formas grises.
func modelo(nombre: String) -> Node3D:
	var m: Node3D = load("res://assets/modelos/estaciones/%s.glb" % nombre).instantiate()
	Materiales.ajustar(m)
	add_child(m)
	return m

func _luz_torre(m: Node3D) -> void:
	for n in ["baliza_v", "baliza_a", "baliza_r"]:
		var mi := m.find_child(n, true, false) as MeshInstance3D
		if mi:
			var mt := mat(Color(0.1, 0.1, 0.1), 0.3, 0.0)
			mt.emission_enabled = true
			mi.material_override = mt
			_torre_p[n] = mt

static func crear(e: Fabrica.Entidad, pos: Vector3) -> Node3D:
	if e is Fabrica.Estacion:
		return EstacionVista.crear_estacion(e, pos, null)
	var p := Provisional.new()
	p.position = pos
	p.rotation.y = VistaFabrica.giro_y(maxi(e.giro, 0))
	if e is Fabrica.Brazo:
		p.tipo = "brazo"
		var m := p.modelo("brazo")
		p._brazo = m.find_child("hombro", true, false)
		p._luz_torre(m)
	elif e is Fabrica.Divisor:
		p.tipo = "divisor"
		var m := p.modelo("divisor")
		p._giratorio = m.find_child("gira_paleta", true, false)
		p._luz_torre(m)
	elif e is Fabrica.Almacen:
		p.tipo = "almacen"
		var m := p.modelo("muelle_carga" if e.carga else "almacen")
		p._barra_n = m.find_child("barra", true, false)
	elif e is Fabrica.Extractor:
		p.tipo = "extractor"
		p.caja(Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0.0), C_CHASIS)
		p.caja(Vector3(0.72, 0.08, 0.52), Vector3(0, 0.46, 0), C_ACENTO)
		p.cilindro(0.06, 0.6, Vector3(-0.2, 0.75, 0), C_GRAFITO)
		p.caja(Vector3(0.24, 0.12, 0.3), Vector3(0.42, 0.3, 0), C_GRAFITO)
		p.luz(Vector3(0.25, 0.56, 0.18))
	elif e is Fabrica.MuelleEnvio:
		p.tipo = "muelle"
		var m := p.modelo("hub")
		var van := m.find_child("van", true, false)
		if van:
			van.name = "van"
			p._van = van
		p._luz_torre(m)
	elif e is Fabrica.Fuente:
		p.tipo = "fuente"
		p.caja(Vector3(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), C_GRAFITO)
	return p

func actualizar(e: Fabrica.Entidad, t: float) -> void:
	if e is Fabrica.Brazo and _brazo:
		_brazo.rotation.y = PI * (1.0 - e.fase())
		_brazo.rotation.y = lerpf(PI, 0.0, e.fase())
	if not _torre_p.is_empty():
		var activo2 := true
		for n in _torre_p:
			var on: bool = (n == "baliza_v") == activo2
			var c: Color = {"baliza_v": Color(0.2, 0.9, 0.35), "baliza_a": Color(1.0, 0.65, 0.08), "baliza_r": Color(0.95, 0.12, 0.1)}[n]
			_torre_p[n].albedo_color = c * (1.0 if on else 0.25)
			_torre_p[n].emission = c
			_torre_p[n].emission_energy_multiplier = 3.0 if on else 0.0
	if _giratorio and e is Fabrica.Divisor:
		_giratorio.rotation.y = -float(e.turno) * TAU / 3.0
	if _barra_n and e is Fabrica.Almacen:
		_barra_n.scale = Vector3(1, clampf(float(e.contenido.size()) / float(e.capacidad), 0.02, 1.0), 1)
	if _luz:
		var activo := true
		if e is Fabrica.Extractor:
			activo = e.listo == ""
		_luz.emission = Color(0.3, 1.0, 0.45) if activo else Color(1.0, 0.7, 0.1)
		_luz.albedo_color = _luz.emission
	if e is Fabrica.Almacen and _barra:
		var f: float = float(e.contenido.size()) / float(e.capacidad)
		_barra.scale.y = maxf(f, 0.02)
		_barra.position.y = 0.15 + 0.25 * _barra.scale.y
	if tipo == "muelle":
		var van: Node3D = _van if _van else get_node_or_null("van")
		if van:
			# sale al completar un viaje: avanza y vuelve (se mide con el número de viajes)
			if e.viajes != _viajes_vistos:
				_viajes_vistos = e.viajes
				Sonido.tocar("furgoneta", 0.7)
				_t_viaje = 0.0
			_t_viaje += get_process_delta_time()
			var k := clampf(_t_viaje / 3.0, 0.0, 1.0)
			var fuera := sin(k * PI)
			if not van.has_meta("x0"):
				van.set_meta("x0", van.position.x)
			van.position.x = float(van.get_meta("x0")) + fuera * 6.0
			van.visible = fuera < 0.95
