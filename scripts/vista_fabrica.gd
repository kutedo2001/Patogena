class_name VistaFabrica
extends Node3D
## Dibuja en 3D lo que pasa en la simulación (Fabrica): una pieza por entidad, los objetos
## sobre las cintas y el estado de cada máquina. Solo lee la simulación; nunca la cambia.
## Brazos, divisores, almacenes, extractores y muelles son provisionales (puerta 4 en gris).

const ESCALA_OBJETOS := 2.5
const MODELO_MAQUINA := {
	"centrifuga": "res://assets/modelos/maquinas/centrifuga.glb", "secuenciador": "res://assets/modelos/maquinas/secuenciador.glb",
	"mezcladora": "res://assets/modelos/maquinas/mezcladora.glb", "envasadora": "res://assets/modelos/maquinas/envasadora.glb",
	"biorreactor": "res://assets/modelos/maquinas/biorreactor.glb", "camara_cepa": "res://assets/modelos/maquinas/camara_cepa.glb",
	"centrifuga_ind": "res://assets/modelos/estaciones/centrifuga_ind.glb"}
const PANTALLA := {"centrifuga": PantallaMaquina.Tipo.CENTRIFUGA, "secuenciador": PantallaMaquina.Tipo.SECUENCIADOR,
	"mezcladora": PantallaMaquina.Tipo.MEZCLADORA, "envasadora": PantallaMaquina.Tipo.ENVASADORA,
	"biorreactor": PantallaMaquina.Tipo.BIORREACTOR, "camara_cepa": PantallaMaquina.Tipo.CEPA,
	"centrifuga_ind": PantallaMaquina.Tipo.CENTRIFUGA}

var fab: Fabrica
var juego: Juego
var _vis := {}                  # entidad → nodo
var _objetos: Dictionary = {}   # nombre base → Array de nodos (reserva)
var _usados: Dictionary = {}    # nombre base → cuántos se usan este fotograma
var _escenas := {}
var _mat_banda: StandardMaterial3D
var _mat_curva: StandardMaterial3D
var _n_cintas := -1
var _tiempo := 0.0

func _process(dt: float) -> void:
	if fab == null:
		return
	_tiempo += dt
	_sincronizar()
	_objetos_en_cintas()
	_estados()
	if _mat_banda:
		_mat_banda.uv1_offset.x -= 0.5 * dt
	if _mat_curva and _mat_banda:
		_mat_curva.uv1_offset = _mat_banda.uv1_offset

func centro(e: Fabrica.Entidad) -> Vector3:
	var s := Vector2.ZERO
	for c in e.casillas:
		s += Vector2(c)
	s /= e.casillas.size()
	return Vector3(s.x + 0.5, 0, s.y + 0.5)

## Nodo de dibujo para una entidad suelta (fantasma de construcción, iconos).
static func nodo_para(e: Fabrica.Entidad, pos: Vector3, j: Juego) -> Node3D:
	if e is Fabrica.Estacion:
		return EstacionVista.crear_estacion(e, pos, j)
	if e is Fabrica.SalaEspera or e is Fabrica.Generador or e is Fabrica.Capsula or e is Fabrica.Deposito:
		return PiezaVista.crear_pieza(e, pos, j)
	return Provisional.crear(e, pos)

static func giro_y(g: int) -> float:
	return -g * PI * 0.5

# ------------------------------------------------------------------ altas y bajas
func _sincronizar() -> void:
	var vivas := {}
	var cintas := 0
	for e in fab.entidades:
		vivas[e] = true
		if e is Fabrica.Cinta:
			cintas += 1
		if not _vis.has(e):
			var n := _crear(e)
			if n:
				add_child(n)
				_vis[e] = n
	for e in _vis.keys():
		if not vivas.has(e):
			_vis[e].queue_free()
			_vis.erase(e)
	# las cintas cambian de forma (recta o curva) según sus vecinas
	var firma := cintas * 1000 + fab.entidades.size()
	if firma != _n_cintas:
		_n_cintas = firma
		for e in fab.entidades:
			if e is Fabrica.Cinta:
				_vis[e].queue_free()
				var n := _crear(e)
				add_child(n)
				_vis[e] = n

func _crear(e: Fabrica.Entidad) -> Node3D:
	if e is Fabrica.Cinta:
		return _crear_cinta(e)
	if e is Fabrica.MaquinaSim:
		var m := Maquina.new()
		m.modelo = load(MODELO_MAQUINA[e.tipo])
		m.tipo_pantalla = PANTALLA[e.tipo]
		m.ciclo = e.duracion()
		m.estado = Maquina.Estado.SIN_MATERIAL
		m.position = centro(e)
		m.rotation.y = giro_y(e.giro)
		return m
	if e is Fabrica.Estacion:
		return EstacionVista.crear_estacion(e, centro(e), juego)
	if e is Fabrica.SalaEspera or e is Fabrica.Generador or e is Fabrica.Capsula or e is Fabrica.Deposito:
		var pv := PiezaVista.crear_pieza(e, centro(e), juego)
		if e is Fabrica.SalaEspera:
			for o in fab.entidades:
				if o == e:
					break
				if o is Fabrica.SalaEspera:
					pv.indice_sala += 1
		return pv
	return Provisional.crear(e, centro(e))

## Dirección por la que entra el objeto en esta cinta: la de la cinta de detrás si apunta aquí,
## si no la de una lateral que apunte aquí (curva), si no, recta.
func entrada_cinta(e: Fabrica.Cinta) -> int:
	var c: Vector2i = e.casillas[0]
	var atras = fab.celdas.get(c - Fabrica.DIRS[e.giro])
	if _apunta(atras, c):
		return e.giro
	for k in [1, 3]:
		var g := posmod(e.giro + k, 4)
		var v = fab.celdas.get(c - Fabrica.DIRS[g])
		if v is Fabrica.Cinta and _apunta(v, c):
			return g
	return e.giro

func _apunta(v, c: Vector2i) -> bool:
	if v == null:
		return false
	if v is Fabrica.Cinta or v is Fabrica.Brazo or v is Fabrica.Extractor or v is Fabrica.Divisor or v is Fabrica.Estacion:
		return v.casillas[0] + Fabrica.DIRS[v.giro] == c or v is Fabrica.Divisor
	if v is Fabrica.MaquinaSim:
		return v.casilla_salida == c
	return false

func _crear_cinta(e: Fabrica.Cinta) -> Node3D:
	if e is Fabrica.Tuberia:
		return _crear_tuberia(e)
	var d_in := Fabrica.DIRS[entrada_cinta(e)]
	var d_out := Fabrica.DIRS[e.giro]
	var nombre := "recta"
	if d_in != d_out:
		var cruz := d_in.x * d_out.y - d_in.y * d_out.x
		nombre = "curva_der" if cruz > 0 else "curva"
	var ruta := "res://assets/modelos/cintas/cinta_%s_mk%d.glb" % [nombre, e.nivel]
	if not _escenas.has(ruta):
		_escenas[ruta] = load(ruta)
	var p: Node3D = _escenas[ruta].instantiate()
	p.position = centro(e)
	p.rotation.y = atan2(-float(d_in.y), float(d_in.x))
	for mi in p.find_children("banda*", "MeshInstance3D", true, false):
		var m := (mi as MeshInstance3D).get_active_material(0)
		if m == null:
			continue
		if _mat_banda == null:
			_mat_banda = m.duplicate()
			_mat_curva = _mat_banda.duplicate()
			_mat_curva.albedo_texture = preload("res://assets/texturas/banda_curva.png")
		(mi as MeshInstance3D).material_override = _mat_curva if nombre != "recta" else _mat_banda
	return p

## Tubería recta o codo (el codo de la izquierda es el de la derecha en espejo); la sangre de la
## mirilla corre con un sombreado que avanza según lo llena que va.
var _mat_sangre_tubo: ShaderMaterial
func _crear_tuberia(e: Fabrica.Tuberia) -> Node3D:
	var d_in := Fabrica.DIRS[entrada_cinta(e)]
	var d_out := Fabrica.DIRS[e.giro]
	var curva := d_in != d_out
	var ruta := "res://assets/modelos/estaciones/tuberia_%s.glb" % ("curva" if curva else "recta")
	if not _escenas.has(ruta):
		_escenas[ruta] = load(ruta)
	var p: Node3D = _escenas[ruta].instantiate()
	Materiales.ajustar(p)
	p.position = centro(e)
	p.rotation.y = atan2(-float(d_in.y), float(d_in.x))
	if curva and d_in.x * d_out.y - d_in.y * d_out.x < 0:
		p.scale.z = -1.0
	if _mat_sangre_tubo == null:
		_mat_sangre_tubo = ShaderMaterial.new()
		_mat_sangre_tubo.shader = preload("res://assets/shaders/sangre_tubo.gdshader")
	var s := p.find_child("sangre", true, false) as MeshInstance3D
	if s:
		var m := _mat_sangre_tubo.duplicate() as ShaderMaterial
		s.material_override = m
		p.set_meta("mat_sangre", m)
	return p

# ------------------------------------------------------------------ objetos
func _objeto(nombre: String) -> Node3D:
	var b := Fabrica.base(nombre)
	var lista: Array = _objetos.get(b, [])
	var i: int = _usados.get(b, 0)
	_usados[b] = i + 1
	if i < lista.size():
		lista[i].visible = true
		return lista[i]
	var ruta := "res://assets/modelos/objetos/%s.glb" % b
	if not _escenas.has(ruta):
		_escenas[ruta] = load(ruta)
	var n: Node3D = _escenas[ruta].instantiate()
	Materiales.ajustar(n)
	n.scale = Vector3.ONE * ESCALA_OBJETOS
	add_child(n)
	lista.append(n)
	_objetos[b] = lista
	return n

func _objetos_en_cintas() -> void:
	_usados.clear()
	for e in fab.entidades:
		if e is Fabrica.Tuberia:
			var vt: Node3D = _vis.get(e)
			if vt and vt.has_meta("mat_sangre"):
				var mt: ShaderMaterial = vt.get_meta("mat_sangre")
				mt.set_shader_parameter("llenado", e.llenado())
				mt.set_shader_parameter("t", _tiempo)
			continue
		if e is Fabrica.Cinta:
			var c := centro(e)
			var d_in := Vector2(Fabrica.DIRS[entrada_cinta(e)])
			var d_out := Vector2(Fabrica.DIRS[e.giro])
			for o in e.objetos:
				var n := _objeto(o[0])
				var t: float = o[1]
				var p: Vector2
				var dir: Vector2
				if d_in == d_out:
					p = Vector2(c.x, c.z) + d_out * (t - 0.5)
					dir = d_out
				else:
					var entrada := Vector2(c.x, c.z) - d_in * 0.5
					var pivote := entrada + d_out * 0.5
					var r0 := entrada - pivote
					var r1 := (Vector2(c.x, c.z) + d_out * 0.5) - pivote
					var a := r0.angle() + angle_difference(r0.angle(), r1.angle()) * t
					p = pivote + Vector2(cos(a), sin(a)) * 0.5
					dir = d_in.lerp(d_out, t).normalized()
				n.position = Vector3(p.x, LineaCinta.ALTURA_BANDA + 0.002, p.y)
				n.rotation.y = atan2(-dir.y, dir.x)
		elif e is Fabrica.Brazo and e.mano != "":
			var n2 := _objeto(e.mano)
			var v: Node3D = _vis.get(e)
			if v:
				var pinza: Node3D = v.get_node_or_null("hombro/brazo/pinza")
				if pinza:
					n2.global_position = pinza.global_position + Vector3(0, -0.12, 0)
	for b in _objetos:
		var lista: Array = _objetos[b]
		for i in range(_usados.get(b, 0), lista.size()):
			lista[i].visible = false

# ------------------------------------------------------------------ estados
func _estados() -> void:
	for e in _vis:
		var v: Node3D = _vis[e]
		if e is Fabrica.MaquinaSim:
			var m := v as Maquina
			var est: int = Maquina.Estado.TRABAJANDO if e.estado == Fabrica.MaquinaSim.Estado.TRABAJANDO else Maquina.Estado.SIN_MATERIAL
			if m.estado != est:
				m.estado = est
			m.ciclo = e.duracion()
		elif v.has_method("actualizar"):
			v.actualizar(e, _tiempo)

func nodo_de(e: Fabrica.Entidad) -> Node3D:
	return _vis.get(e)
