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

static func crear(e: Fabrica.Entidad, pos: Vector3) -> Node3D:
	if e is Fabrica.Estacion:
		return EstacionVista.crear_estacion(e, pos, null)
	var p := Provisional.new()
	p.position = pos
	p.rotation.y = VistaFabrica.giro_y(maxi(e.giro, 0))
	if e is Fabrica.Brazo:
		p.tipo = "brazo"
		p.cilindro(0.18, 0.08, Vector3(0, 0.04, 0), C_GRAFITO)
		p.cilindro(0.12, 0.25, Vector3(0, 0.2, 0), C_CHASIS)
		var h := Node3D.new()
		h.name = "hombro"
		h.position = Vector3(0, 0.34, 0)
		p.add_child(h)
		var b := Node3D.new()
		b.name = "brazo"
		h.add_child(b)
		p.caja(Vector3(0.5, 0.07, 0.08), Vector3(0.22, 0.05, 0), C_AMARILLO, b)
		var pinza := Node3D.new()
		pinza.name = "pinza"
		pinza.position = Vector3(0.45, 0, 0)
		b.add_child(pinza)
		p.caja(Vector3(0.08, 0.16, 0.12), Vector3(0, -0.02, 0), C_GRAFITO, pinza)
		p._brazo = h
		p.luz(Vector3(0.1, 0.18, 0.1))
	elif e is Fabrica.Divisor:
		p.tipo = "divisor"
		p.caja(Vector3(0.96, 0.26, 0.96), Vector3(0, 0.13, 0), C_GRAFITO)
		p.caja(Vector3(0.9, 0.04, 0.9), Vector3(0, 0.28, 0), Color(0.2, 0.22, 0.24))
		for g in [0, 1, 3]:
			var a := Node3D.new()
			a.rotation.y = -g * PI * 0.5
			p.add_child(a)
			p.caja(Vector3(0.18, 0.02, 0.06), Vector3(0.3, 0.31, 0), C_AMARILLO, a)
		p.luz(Vector3(-0.4, 0.32, 0.4))
	elif e is Fabrica.Almacen:
		p.tipo = "almacen"
		p.caja(Vector3(0.9, 0.1, 0.9), Vector3(0, 0.05, 0), C_MADERA)
		p.caja(Vector3(0.84, 0.6, 0.84), Vector3(0, 0.4, 0), C_CHASIS)
		p.caja(Vector3(0.86, 0.06, 0.86), Vector3(0, 0.72, 0), C_ACENTO)
		p._barra = p.caja(Vector3(0.05, 0.5, 0.02), Vector3(0.43, 0.4, 0), Color(0.3, 1.0, 0.45))
	elif e is Fabrica.Extractor:
		p.tipo = "extractor"
		p.caja(Vector3(0.7, 0.5, 0.5), Vector3(0, 0.25, 0.0), C_CHASIS)
		p.caja(Vector3(0.72, 0.08, 0.52), Vector3(0, 0.46, 0), C_ACENTO)
		p.cilindro(0.06, 0.6, Vector3(-0.2, 0.75, 0), C_GRAFITO)
		p.caja(Vector3(0.24, 0.12, 0.3), Vector3(0.42, 0.3, 0), C_GRAFITO)
		p.luz(Vector3(0.25, 0.56, 0.18))
	elif e is Fabrica.MuelleEnvio:
		# hub de envío 2×2: andén con franjas, rampa y furgoneta que sale cargada
		p.tipo = "muelle"
		p.caja(Vector3(1.96, 0.25, 1.96), Vector3(0, 0.125, 0), C_GRAFITO)
		for k in 7:
			p.caja(Vector3(1.96, 0.005, 0.12), Vector3(0, 0.255, -0.84 + k * 0.28), C_AMARILLO)
		p.caja(Vector3(0.5, 0.5, 0.5), Vector3(-0.6, 0.5, -0.6), C_CHASIS)        # caseta
		p.caja(Vector3(0.52, 0.06, 0.52), Vector3(-0.6, 0.78, -0.6), C_ACENTO)
		var van := Node3D.new()
		van.name = "van"
		p.add_child(van)
		p.caja(Vector3(1.2, 0.55, 0.6), Vector3(0.2, 0.55, 0.45), Color(0.93, 0.94, 0.93), van)
		p.caja(Vector3(0.35, 0.42, 0.58), Vector3(0.95, 0.48, 0.45), Color(0.93, 0.94, 0.93), van)
		p.caja(Vector3(0.05, 0.22, 0.5), Vector3(1.13, 0.58, 0.45), Color(0.2, 0.3, 0.35), van)
		p.caja(Vector3(1.22, 0.1, 0.62), Vector3(0.2, 0.62, 0.45), C_MARCA_P, van)
		for x in [-0.25, 0.85]:
			for z in [0.15, 0.75]:
				p.cilindro(0.11, 0.08, Vector3(x, 0.36, z), Color(0.08, 0.08, 0.09), van).rotation.x = PI * 0.5
		p.luz(Vector3(-0.85, 0.85, -0.85))
	elif e is Fabrica.Ascensor:
		# ascensor de pedidos 2×2: base con tolva, torre de guías y cápsula que sube al completar
		p.tipo = "ascensor"
		p.caja(Vector3(1.96, 0.3, 1.96), Vector3(0, 0.15, 0), C_GRAFITO)
		p.caja(Vector3(1.6, 0.06, 1.6), Vector3(0, 0.33, 0), C_AMARILLO)
		for x in [-0.8, 0.8]:
			for z in [-0.8, 0.8]:
				p.caja(Vector3(0.12, 4.0, 0.12), Vector3(x, 2.3, z), C_CHASIS)
		p.caja(Vector3(1.8, 0.1, 1.8), Vector3(0, 4.3, 0), C_ACENTO)
		var cap := Node3D.new()
		cap.name = "capsula"
		p.add_child(cap)
		p.cilindro(0.55, 0.9, Vector3(0, 0.85, 0), Color(0.93, 0.94, 0.93), cap)
		p.cilindro(0.57, 0.12, Vector3(0, 1.1, 0), C_MARCA_P, cap)
		p.cilindro(0.3, 0.3, Vector3(0, 1.45, 0), C_GRAFITO, cap)
		p.luz(Vector3(0.9, 0.4, 0.9))
	elif e is Fabrica.Fuente:
		p.tipo = "fuente"
		p.caja(Vector3(0.8, 0.8, 0.8), Vector3(0, 0.4, 0), C_GRAFITO)
	return p

func actualizar(e: Fabrica.Entidad, t: float) -> void:
	if e is Fabrica.Brazo and _brazo:
		_brazo.rotation.y = PI * (1.0 - e.fase())
		_brazo.rotation.y = lerpf(PI, 0.0, e.fase())
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
		var van: Node3D = get_node_or_null("van")
		if van:
			# sale al completar un viaje: avanza y vuelve (se mide con el número de viajes)
			if e.viajes != _viajes_vistos:
				_viajes_vistos = e.viajes
				_t_viaje = 0.0
			_t_viaje += get_process_delta_time()
			var k := clampf(_t_viaje / 3.0, 0.0, 1.0)
			var fuera := sin(k * PI)
			van.position.x = fuera * 6.0
			van.visible = fuera < 0.95
	if tipo == "ascensor":
		var cap: Node3D = get_node_or_null("capsula")
		if cap:
			var sube: float = e.subiendo
			cap.position.y = sin((1.0 - sube / 6.0) * PI) * 8.0 if sube > 0.0 else 0.0
