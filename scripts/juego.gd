class_name Juego
extends Node3D
## Partida (puerta 4, nuevo inicio tras la prueba de Edu): el jugador es un científico que se
## mueve con WASD o clic y al principio lo hace todo a mano; construye estaciones de extracción
## (camilla, incubadora, toma de agua) que mejora con máquinas y luego pone a cargo de zombis.
## Une la simulación (Fabrica), su dibujo (VistaFabrica), la construcción, la venta, las
## mutaciones, los hitos y el tutorial. El HUD solo lee de aquí y llama a sus funciones públicas.

signal aviso(clave: String)

const ANCHO := 16
const FONDO := 12
const ZONA := Rect2i(-7, -5, 14, 10)          # construible (dentro del pasillo amarillo)
const SALA := Rect2i(-8, -6, 16, 12)          # se puede andar
const DINERO_INICIAL := 1000.0
const SEG_POR_DIA := 60.0
const VEL_CIENTIFICO := 3.0
const MANOS_MAX := 4
const PUERTA := Vector2(-8.6, 0.5)            # puerta de pacientes (pared oeste)
const ESPERA_ZOMBIS := Vector2(-7.4, 3.6)     # donde esperan los convertidos

## [id, icono, clave de nombre, coste, kW, clase, extra]
const CATALOGO := {
	"HUD_CAT_EXTRACCION": [
		["camilla", "camilla", "EST_CAMILLA", 100, 0.0, "estacion", "camilla"],
		["incubadora", "incubadora", "EST_INCUBADORA", 150, 1.0, "estacion", "incubadora"],
		["toma_agua", "toma_agua", "EST_TOMA_AGUA", 80, 0.5, "estacion", "toma_agua"],
	],
	"HUD_CAT_PROCESADO": [
		["centrifuga", "centrifuga", "MAQ_CENTRIFUGA", 300, 4.5, "maquina", "centrifuga"],
		["secuenciador", "secuenciador", "MAQ_SECUENCIADOR", 500, 6.0, "maquina", "secuenciador"],
		["mezcladora", "mezcladora", "MAQ_MEZCLADORA", 400, 3.0, "maquina", "mezcladora"],
	],
	"HUD_CAT_PRODUCTO": [
		["biorreactor", "biorreactor", "MAQ_BIORREACTOR", 600, 9.0, "maquina", "biorreactor"],
		["envasadora", "envasadora", "MAQ_ENVASADORA", 600, 5.0, "maquina", "envasadora"],
	],
	"HUD_CAT_LOGISTICA": [
		["cinta", "cinta_recta_mk1", "MAQ_CINTA_MK1", 5, 0.1, "cinta", ""],
		["brazo", "brazo", "CONS_BRAZO", 50, 0.5, "brazo", ""],
		["divisor", "divisor", "CONS_DIVISOR", 40, 0.2, "divisor", ""],
		["almacen", "almacen", "CONS_ALMACEN", 80, 0.0, "almacen", ""],
	],
	"HUD_CAT_ENERGIA": [],
}
const MEJORA := {"camilla": ["MEJ_EXTRACTOR", 250], "incubadora": ["MEJ_RECOLECTOR", 250], "toma_agua": ["MEJ_BOMBA", 150]}
## [objeto contado, cantidad, clave, premio de Dirección]
const HITOS := [["tubo_plasma", 10, "HUD_OBJ_PLASMA", 500], ["tubo_adn", 5, "HUD_OBJ_ADN", 400], ["mutacion", 1, "HUD_OBJ_MUTACION", 1000]]

var fab: Fabrica
var vista: VistaFabrica
var camara: Node3D
var categoria := "HUD_CAT_EXTRACCION"
var herramienta: Array = []
var quitando := false
var giro := 0
var seleccion: Fabrica.Entidad
var propagacion := 0.0
var cura := 0.0
var liberado := false
var velocidad := 1.0
var ingresos_min := 0.0
var zombis_libres := 0
var hitos_pagados: Array[bool] = [false, false, false]
# científico
var cientifico: Personaje
var pos := Vector2(-2.5, 3.5)
var mano_obj := ""
var mano_n := 0
var _ruta: Array = []                 # casillas por las que ir
var _objetivo: Fabrica.Entidad        # con qué interactuar al llegar
var _objetivo_terminal := false
var _trabajando: Fabrica.Estacion
var _andado := 0.0
# construcción
var _cel := Vector2i.ZERO
var _arrastre := false
var _inicio := Vector2i.ZERO
var _fantasma: Node3D
var _fantasma_cintas: Array[Node3D] = []
var _mat_ok: StandardMaterial3D
var _mat_mal: StandardMaterial3D
var _huella: Array[MeshInstance3D] = []
var _anillo: MeshInstance3D
var _flechas: Array[MeshInstance3D] = []
var _mat_entra: StandardMaterial3D
var _mat_sale: StandardMaterial3D
# resto
var _pedidos: Array = []
var _muelle_carga: Fabrica.Almacen
var _terminal := Vector2i(-6, 5)
var _cepa: Fabrica.MaquinaSim
var _ventas_hist: Array = []
var _ultimo_ingreso := 0.0
var _desechados := 0
var _t_zombi := 0.0
var _zombis_espera: Array[Personaje] = []
var _carga: Node3D                    # lo que lleva en las manos (dibujo)
var _carga_nombre := ""
var tutorial: Tutorial

func _ready() -> void:
	fab = Fabrica.new()
	fab.dinero = DINERO_INICIAL
	vista = VistaFabrica.new()
	vista.fab = fab
	vista.juego = self
	add_child(vista)
	_montar_nivel_1()
	_mat_ok = _mat_fantasma(Color(0.3, 0.85, 0.5))
	_mat_mal = _mat_fantasma(Color(0.95, 0.3, 0.25))
	_mat_entra = Provisional.mat(Color(0.3, 0.95, 0.45), 0.5, 1.2)
	_mat_sale = Provisional.mat(Color(1.0, 0.6, 0.15), 0.5, 1.2)
	for m in [_mat_entra, _mat_sale]:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anillo = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.03
	tm.rings = 48
	_anillo.mesh = tm
	var am := Provisional.mat(Color(0.25, 0.71, 0.66), 0.5, 1.5)
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anillo.material_override = am
	_anillo.visible = false
	add_child(_anillo)
	cientifico = Personaje.new()
	cientifico.variante = "investigador_m"
	cientifico.animacion = "idle"
	add_child(cientifico)
	cientifico.position = Vector3(pos.x, 0, pos.y)
	tutorial = Tutorial.new()
	tutorial.juego = self
	add_child(tutorial)

func _mat_fantasma(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.15
	return m

# ------------------------------------------------------------------ nivel 1
func _montar_nivel_1() -> void:
	_cepa = fab.poner_maquina("camara_cepa", Vector2i(4, -5))
	fab.poner_muelle_envio(Vector2i(6, 4))
	_muelle_carga = fab.poner_almacen(Vector2i(-7, 5), 0)
	# terminal de pedidos
	var t := Provisional.new()
	t.position = Vector3(_terminal.x + 0.5, 0, _terminal.y + 0.5)
	add_child(t)
	t.caja(Vector3(0.5, 1.0, 0.4), Vector3(0, 0.5, 0), Provisional.C_CHASIS)
	t.caja(Vector3(0.4, 0.3, 0.02), Vector3(0, 0.8, -0.21), Color(0.1, 0.3, 0.3))
	t.caja(Vector3(0.52, 0.06, 0.42), Vector3(0, 1.0, 0), Provisional.C_ACENTO)
	# puerta de pacientes en la pared oeste
	var pu := Provisional.new()
	pu.position = Vector3(-8.05, 0, 0.5)
	add_child(pu)
	pu.caja(Vector3(0.12, 2.2, 1.3), Vector3(0, 1.1, 0), Provisional.C_GRAFITO)
	pu.caja(Vector3(0.14, 2.0, 1.1), Vector3(0.02, 1.0, 0), Color(0.55, 0.75, 0.8))
	pu.caja(Vector3(0.16, 0.18, 1.1), Vector3(0.02, 2.0, 0), Color(0.3, 1.0, 0.45))

# ------------------------------------------------------------------ bucle
func _process(dt: float) -> void:
	var dtj := dt * velocidad
	fab.avanzar(dtj)
	_mover_cientifico(dt)
	if _trabajando:
		if _trabajando.listo != "":
			var est := _trabajando
			_trabajando = null
			if mano_n == 0 or mano_obj == est.listo:
				_coger_de(est)
			else:
				aviso.emit("AVISO_MANOS_OCUPADAS")
		elif cerca(_trabajando):
			_trabajando.trabajar(fab, dtj)
		else:
			_trabajando = null
	for p in _pedidos.duplicate():
		if fab.tiempo >= p[0]:
			for k in int(p[2]):
				_muelle_carga.contenido.append(p[1])
			_pedidos.erase(p)
			aviso.emit("AVISO_PEDIDO")
	if fab.desechados > _desechados:
		_desechados = fab.desechados
		aviso.emit("AVISO_REPETIDA")
	if not liberado and fab.mutaciones > 0:
		liberado = true
		propagacion = 0.001
		aviso.emit("AVISO_LIBERADO")
	if liberado:
		propagacion = minf(1.0, propagacion + propagacion * 0.0008 * (1.0 + fab.mutaciones * 0.6) * dtj + 0.000002 * dtj)
		cura = minf(1.0, cura + 0.0004 * dtj)
		_t_zombi += dtj
		if _t_zombi >= 40.0 and zombis_libres < 6:
			_t_zombi = 0.0
			_llega_zombi()
	# hitos con premio de Dirección
	for i in HITOS.size():
		if not hitos_pagados[i] and hito(i).x >= hito(i).y:
			hitos_pagados[i] = true
			fab.dinero += HITOS[i][3]
			aviso.emit("AVISO_HITO")
	if fab.ingresos > _ultimo_ingreso:
		_ventas_hist.append([fab.tiempo, fab.ingresos - _ultimo_ingreso])
	_ultimo_ingreso = fab.ingresos
	while not _ventas_hist.is_empty() and fab.tiempo - _ventas_hist[0][0] > 60.0:
		_ventas_hist.pop_front()
	ingresos_min = 0.0
	for v in _ventas_hist:
		ingresos_min += v[1]
	_actualizar_anillo()
	_actualizar_fantasma()
	_actualizar_flechas()
	_actualizar_carga()

func _actualizar_anillo() -> void:
	var e = seleccion if seleccion != null else (_trabajando if _trabajando else null)
	if e == null:
		_anillo.visible = false
		return
	_anillo.visible = true
	var c := vista.centro(e)
	var t := _tam(e)
	var r := 0.45 + 0.25 * maxf(t.x, t.y)
	var pulso := 1.0 + 0.03 * sin(fab.tiempo * 6.0)
	_anillo.position = Vector3(c.x, 0.03, c.z)
	_anillo.scale = Vector3(r * pulso, 0.05, r * pulso)

func _tam(e: Fabrica.Entidad) -> Vector2i:
	return e.tam if e is Fabrica.MaquinaSim else Vector2i.ONE

func dia() -> int:
	return 1 + int(fab.tiempo / SEG_POR_DIA)

func hora() -> int:
	return int(fmod(fab.tiempo, SEG_POR_DIA) / SEG_POR_DIA * 24.0 * 60.0 + 8 * 60) % 1440

func hito(i: int) -> Vector2i:
	var h: Array = HITOS[i]
	return Vector2i(mini(int(fab.producido.get(h[0], 0)), h[1]), h[1])

func hay(t: String) -> bool:
	for e in fab.entidades:
		if (e is Fabrica.MaquinaSim and e.tipo == t) or (e is Fabrica.Estacion and e.tipo == t):
			return true
	return false

# ------------------------------------------------------------------ zombis trabajadores
func _llega_zombi() -> void:
	zombis_libres += 1
	var z := Personaje.new()
	z.variante = ["zombi", "paciente_infectado", "investigador_infectado"][randi() % 3]
	z.animacion = "idle"
	z.estilo = "zombi"
	add_child(z)
	z.position = Vector3(ESPERA_ZOMBIS.x + (_zombis_espera.size() % 3) * 0.45, 0, ESPERA_ZOMBIS.y - (_zombis_espera.size() / 3) * 0.5)
	z.rotation.y = PI * 0.5
	_zombis_espera.append(z)
	aviso.emit("AVISO_ZOMBI")

func mejorar(e: Fabrica.Estacion) -> void:
	var m: Array = MEJORA[e.tipo]
	if e.modo != "mano":
		return
	if fab.dinero < float(m[1]):
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= float(m[1])
	e.modo = "maquina"

func asignar_zombi(e: Fabrica.Estacion) -> void:
	if e.modo != "maquina" or zombis_libres <= 0:
		return
	zombis_libres -= 1
	var z: Personaje = _zombis_espera.pop_back()
	if z:
		z.queue_free()
	e.modo = "zombi"

# ------------------------------------------------------------------ científico
## Al lado: a menos de 0,95 casillas del borde de la entidad.
func cerca(e: Fabrica.Entidad) -> bool:
	for c in e.casillas:
		var q := Vector2(clampf(pos.x, c.x, c.x + 1.0), clampf(pos.y, c.y, c.y + 1.0))
		if q.distance_to(pos) < 0.95:
			return true
	return false

func _celda(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.y))

func andable(c: Vector2i) -> bool:
	if not SALA.has_point(c):
		return false
	var e = fab.celdas.get(c)
	return e == null or e is Fabrica.Cinta

## Entidad bajo el ratón (para la ficha flotante del HUD).
func bajo_raton():
	if _cel == _terminal:
		return "terminal"
	return fab.celdas.get(_cel)

func _mover_cientifico(dt: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_key_pressed(KEY_S): dir.y += 1
	if Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_D): dir.x += 1
	if dir != Vector2.ZERO:
		_ruta.clear()
		_objetivo = null
		_tareas.clear()
		_trabajando = null
		var g: float = deg_to_rad(camara.giro) if camara else 0.0
		dir = dir.normalized().rotated(-g)
	elif not _ruta.is_empty():
		var meta := Vector2(_ruta[0].x + 0.5, _ruta[0].y + 0.5)
		if pos.distance_to(meta) < 0.12:
			_ruta.pop_front()
			if _ruta.is_empty():
				_llegar()
		else:
			dir = (meta - pos).normalized()
	var mov := dir * VEL_CIENTIFICO * dt
	if mov != Vector2.ZERO:
		var nueva := pos + mov
		# deslizar por las paredes y máquinas
		if not andable(_celda(nueva + dir * 0.2)):
			nueva = pos + Vector2(mov.x, 0)
			if not andable(_celda(nueva + Vector2(signf(mov.x), 0) * 0.2)):
				nueva = pos + Vector2(0, mov.y)
				if not andable(_celda(nueva + Vector2(0, signf(mov.y)) * 0.2)):
					nueva = pos
		_andado += pos.distance_to(nueva)
		pos = nueva
		cientifico.rotation.y = atan2(dir.x, dir.y)
	cientifico.position = Vector3(pos.x, 0, pos.y)
	var anim := "walk" if mov != Vector2.ZERO else ("interact-right" if _trabajando and _trabajando.trabajando else ("holding-both" if mano_n > 0 else "idle"))
	if cientifico.animacion != anim:
		cientifico.animacion = anim
		cientifico.poner(anim)

## Camino por casillas (BFS) hasta la casilla destino o hasta una vecina de la entidad.
func ir_a(destino: Vector2i, e: Fabrica.Entidad = null) -> void:
	_trabajando = null
	_objetivo = e
	var metas := {}
	if e != null:
		for c in e.casillas:
			for d in Fabrica.DIRS:
				if andable(c + d) and not e.casillas.has(c + d):
					metas[c + d] = true
	elif andable(destino):
		metas[destino] = true
	var inicio := _celda(pos)
	if metas.has(inicio) or (e != null and cerca(e)):
		_ruta.clear()
		_llegar()
		return
	var previo := {inicio: inicio}
	var cola: Array = [inicio]
	var fin = null
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		if metas.has(c):
			fin = c
			break
		for d in Fabrica.DIRS:
			var n: Vector2i = c + d
			if not previo.has(n) and andable(n):
				previo[n] = c
				cola.append(n)
	_ruta.clear()
	if fin == null:
		aviso.emit("AVISO_NO_LLEGA")
		return
	var c2: Vector2i = fin
	while c2 != inicio:
		_ruta.push_front(c2)
		c2 = previo[c2]

func _llegar() -> void:
	if _objetivo_terminal:
		_objetivo_terminal = false
		pedir("frasco_reactivo")
		return
	_objetivo = null
	if _tareas.is_empty():
		return
	var t: Array = _tareas.pop_front()
	var e: Fabrica.Entidad = t[1]
	if not fab.entidades.has(e):
		_tareas.clear()
		return
	match t[0]:
		"dejar": _dejar_en(e)
		"coger": _coger_de(e, t[2] if t.size() > 2 else "")
		"trabajar": _trabajar(e)
	if not _tareas.is_empty():
		ir_a(_tareas[0][1].casillas[0], _tareas[0][1])

## Encargos al científico (desde el HUD: arrastrar o botones). Cada tarea: ["dejar", e],
## ["coger", e, filtro] o ["trabajar", e]. Va andando a cada sitio y la hace al llegar.
var _tareas: Array = []

func encargar(tareas: Array) -> void:
	_tareas = tareas.duplicate()
	if not _tareas.is_empty():
		ir_a(_tareas[0][1].casillas[0], _tareas[0][1])

func _trabajar(e: Fabrica.Entidad) -> void:
	if not (e is Fabrica.Estacion):
		return
	if e.listo != "":
		_coger_de(e)
	elif e.modo == "zombi":
		aviso.emit("AVISO_ZOMBI_TRABAJA")
	else:
		_trabajando = e
		if e.tipo == "camilla" and not e.paciente:
			aviso.emit("AVISO_ESPERA_PACIENTE")

func _dejar_en(e: Fabrica.Entidad) -> void:
	if mano_n == 0:
		return
	var dejados := 0
	while mano_n > 0 and e.aceptar(fab, mano_obj, e.giro if e is Fabrica.Cinta else -1, e.casillas[0]):
		mano_n -= 1
		dejados += 1
	if mano_n == 0:
		mano_obj = ""
	if dejados == 0:
		aviso.emit("AVISO_NO_SE_VENDE" if e is Fabrica.MuelleEnvio else "AVISO_NO_ACEPTA")

## Compatibilidad (pruebas): usar = dejar si lleva algo; si no, trabajar o coger.
func usar(e: Fabrica.Entidad) -> void:
	if e is Fabrica.Estacion:
		_trabajar(e)
	elif mano_n > 0:
		_dejar_en(e)
	else:
		_coger_de(e)

func _coger_de(e: Fabrica.Entidad, filtro := "") -> void:
	if mano_n > 0 and filtro != "" and Fabrica.base(filtro) != Fabrica.base(mano_obj):
		aviso.emit("AVISO_MANOS_OCUPADAS")
		return
	var cogidos := 0
	while mano_n < MANOS_MAX:
		var o := e.sacar(mano_obj if mano_n > 0 else filtro)
		if o == "":
			break
		mano_obj = o
		mano_n += 1
		cogidos += 1
	if cogidos == 0:
		var queda := false
		if e is Fabrica.Estacion:
			queda = e.listo != ""
		elif e is Fabrica.MaquinaSim:
			queda = not e.salida.is_empty()
		aviso.emit("AVISO_MANOS_OCUPADAS" if queda else "AVISO_NADA_QUE_COGER")

func soltar_mano() -> void:
	mano_obj = ""
	mano_n = 0

func _actualizar_carga() -> void:
	var nombre := Fabrica.base(mano_obj) if mano_n > 0 else ""
	if nombre != _carga_nombre:
		_carga_nombre = nombre
		if _carga:
			_carga.queue_free()
			_carga = null
		if nombre != "":
			_carga = Node3D.new()
			add_child(_carga)
			var esc: PackedScene = load("res://assets/modelos/objetos/%s.glb" % nombre)
			for k in MANOS_MAX:
				var n: Node3D = esc.instantiate()
				Materiales.ajustar(n)
				n.scale = Vector3.ONE * 1.6
				n.position = Vector3(0, k * 0.09, 0)
				n.name = "o%d" % k
				_carga.add_child(n)
	if _carga:
		var f := Vector2(sin(cientifico.rotation.y), cos(cientifico.rotation.y))
		_carga.position = Vector3(pos.x + f.x * 0.22, 0.42, pos.y + f.y * 0.22)
		_carga.rotation.y = cientifico.rotation.y
		for k in MANOS_MAX:
			_carga.get_node("o%d" % k).visible = k < mano_n

# ------------------------------------------------------------------ herramientas (HUD)
func seleccionar_herramienta(entrada: Array) -> void:
	herramienta = entrada
	quitando = false
	seleccion = null
	_crear_fantasma()

func modo_quitar() -> void:
	herramienta = []
	quitando = not quitando
	_crear_fantasma()

func cancelar() -> void:
	herramienta = []
	quitando = false
	_arrastre = false
	seleccion = null
	_crear_fantasma()

func elegir_receta(r: String) -> void:
	if seleccion is Fabrica.MaquinaSim:
		seleccion.poner_receta(r)

func pedir(objeto: String) -> void:
	var p: Dictionary = Fabrica.datos.pedidos[objeto]
	if fab.dinero < float(p.precio):
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= float(p.precio)
	_pedidos.append([fab.tiempo + randf_range(float(p.espera[0]), float(p.espera[1])), objeto, p.lote])
	aviso.emit("AVISO_PEDIDO_HECHO")

func pedidos_en_camino() -> int:
	return _pedidos.size()

# ------------------------------------------------------------------ ratón y teclado
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var c = _casilla_raton((ev as InputEventMouseMotion).position)
		if c != null:
			_cel = c
	elif ev is InputEventMouseButton:
		var b := ev as InputEventMouseButton
		var c = _casilla_raton(b.position)
		if c != null:
			_cel = c
		if b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				_pulsar()
			else:
				_soltar()
		elif b.button_index == MOUSE_BUTTON_RIGHT and b.pressed:
			if not herramienta.is_empty() or quitando:
				cancelar()
			else:
				_quitar(_cel)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_R:
				giro = (giro + 1) % 4
			KEY_X:
				modo_quitar()
			KEY_ESCAPE:
				cancelar()
			KEY_SPACE:
				velocidad = 0.0 if velocidad > 0.0 else 1.0
			KEY_F:
				if mano_n > 0:
					soltar_mano()          # tirar lo que lleva

func _casilla_raton(p: Vector2):
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var o := cam.project_ray_origin(p)
	var d := cam.project_ray_normal(p)
	if absf(d.y) < 0.001:
		return null
	var q := o + d * (-o.y / d.y)
	return Vector2i(floori(q.x), floori(q.z))

func _pulsar() -> void:
	if quitando:
		_quitar(_cel)
		return
	if not herramienta.is_empty():
		if herramienta[5] == "cinta":
			_arrastre = true
			_inicio = _cel
		else:
			_construir(_cel)
		return
	if _cel == _terminal:
		_objetivo_terminal = true
		ir_a(_cel + Vector2i(1, 0))
		return
	var e: Fabrica.Entidad = fab.celdas.get(_cel)
	seleccion = e
	if e == null:
		_tareas.clear()
		ir_a(_cel)

func _soltar() -> void:
	if not _arrastre:
		return
	_arrastre = false
	var ruta := _ruta_cinta(_inicio, _cel)
	var coste := ruta.size() * int(herramienta[3])
	if not _ruta_libre(ruta):
		return
	if fab.dinero < coste:
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= coste
	fab.poner_linea(ruta, 1, giro if ruta.size() == 1 else -1)

func _ruta_cinta(a: Vector2i, b: Vector2i) -> Array:
	var r: Array = [a]
	var c := a
	while c.x != b.x:
		c.x += signi(b.x - a.x)
		r.append(c)
	while c.y != b.y:
		c.y += signi(b.y - a.y)
		r.append(c)
	return r

func _ruta_libre(r: Array) -> bool:
	for c in r:
		if not ZONA.has_point(c) or fab.celdas.has(c) or c == _terminal:
			return false
	return true

func casillas_de(entrada: Array, origen: Vector2i, g := -1) -> Array:
	if g < 0:
		g = giro
	if entrada[5] == "maquina":
		var t: Array = Fabrica.datos.maquinas[entrada[6]].tam
		var w: int = t[0] if g % 2 == 0 else t[1]
		var h: int = t[1] if g % 2 == 0 else t[0]
		var cs: Array = []
		for i in w:
			for j in h:
				cs.append(origen + Vector2i(i, j))
		return cs
	return [origen]

func _valido(entrada: Array, origen: Vector2i) -> bool:
	for c in casillas_de(entrada, origen):
		if not ZONA.has_point(c) or fab.celdas.has(c) or c == _terminal or c == _celda(pos):
			return false
	return true

func _construir(c: Vector2i) -> void:
	if not _valido(herramienta, c):
		return
	if fab.dinero < float(herramienta[3]):
		aviso.emit("AVISO_SIN_DINERO")
		return
	var e: Fabrica.Entidad
	match herramienta[5]:
		"maquina": e = fab.poner_maquina(herramienta[6], c, giro)
		"estacion": e = fab.poner_estacion(herramienta[6], c, giro)
		"brazo": e = fab.poner_brazo(c, giro)
		"divisor": e = fab.poner_divisor(c, giro)
		"almacen": e = fab.poner_almacen(c, giro)
	if e:
		fab.dinero -= float(herramienta[3])

func coste_de(e: Fabrica.Entidad) -> float:
	var extra := 0.0
	if e is Fabrica.Estacion and e.modo != "mano":
		extra = float(MEJORA[e.tipo][1])
	for cat in CATALOGO:
		for en in CATALOGO[cat]:
			if (e is Fabrica.MaquinaSim and en[6] == e.tipo) or (e is Fabrica.Estacion and en[6] == e.tipo) \
					or (e is Fabrica.Cinta and en[5] == "cinta") or (e is Fabrica.Brazo and en[5] == "brazo") \
					or (e is Fabrica.Divisor and en[5] == "divisor") or (e is Fabrica.Almacen and en[5] == "almacen"):
				return float(en[3]) + extra
	return 0.0

## Quitar devuelve el 100 % (lo pidió Edu); lo que llevaba dentro se pierde salvo en cintas.
func _quitar(c: Vector2i) -> void:
	var e: Fabrica.Entidad = fab.celdas.get(c)
	if e == null or e == _cepa or e == _muelle_carga or e is Fabrica.MuelleEnvio:
		return
	fab.dinero += coste_de(e)
	if e is Fabrica.Estacion and e.modo == "zombi":
		zombis_libres += 1
		_llega_zombi_vuelve()
	fab.quitar(c)
	if seleccion == e:
		seleccion = null
	if _trabajando == e:
		_trabajando = null

func _llega_zombi_vuelve() -> void:
	zombis_libres -= 1
	_llega_zombi()

# ------------------------------------------------------------------ fantasma y bocas
func _crear_fantasma() -> void:
	if _fantasma:
		_fantasma.queue_free()
		_fantasma = null
	for h in _huella:
		h.queue_free()
	_huella.clear()
	if herramienta.is_empty():
		return
	var n: Node3D
	match herramienta[5]:
		"maquina": n = load(VistaFabrica.MODELO_MAQUINA[herramienta[6]]).instantiate()
		"cinta": n = load("res://assets/modelos/cintas/cinta_recta_mk1.glb").instantiate()
		_:
			var e: Fabrica.Entidad
			match herramienta[5]:
				"brazo": e = Fabrica.Brazo.new(Vector2i.ZERO, 0, "")
				"divisor": e = Fabrica.Divisor.new(Vector2i.ZERO, 0)
				"almacen": e = Fabrica.Almacen.new(Vector2i.ZERO, 0)
				"estacion": e = Fabrica.Estacion.new(herramienta[6], Vector2i.ZERO, 0)
			n = Provisional.crear(e, Vector3.ZERO)
	_fantasma = n
	add_child(n)
	for c in casillas_de(herramienta, Vector2i.ZERO):
		var h := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.94, 0.94)
		h.mesh = pm
		add_child(h)
		_huella.append(h)

func _actualizar_fantasma() -> void:
	for f in _fantasma_cintas:
		f.visible = false
	if _fantasma == null:
		return
	var ok := _valido(herramienta, _cel) and fab.dinero >= float(herramienta[3])
	var mat := _mat_ok if ok else _mat_mal
	for mi in _fantasma.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cs := casillas_de(herramienta, _cel)
	var s := Vector2.ZERO
	for c in cs:
		s += Vector2(c)
	s /= cs.size()
	_fantasma.position = Vector3(s.x + 0.5, 0, s.y + 0.5)
	_fantasma.rotation.y = VistaFabrica.giro_y(giro)
	for i in _huella.size():
		_huella[i].position = Vector3(cs[i].x + 0.5, 0.015, cs[i].y + 0.5)
		_huella[i].material_override = mat
	if _arrastre:
		var ruta := _ruta_cinta(_inicio, _cel)
		var libre := _ruta_libre(ruta) and fab.dinero >= ruta.size() * int(herramienta[3])
		_fantasma.visible = false
		while _fantasma_cintas.size() < ruta.size():
			var n: Node3D = load("res://assets/modelos/cintas/cinta_recta_mk1.glb").instantiate()
			add_child(n)
			_fantasma_cintas.append(n)
		for i in ruta.size():
			var f := _fantasma_cintas[i]
			f.visible = true
			f.position = Vector3(ruta[i].x + 0.5, 0, ruta[i].y + 0.5)
			var d: Vector2i = (ruta[i + 1] - ruta[i]) if i < ruta.size() - 1 else ((ruta[i] - ruta[i - 1]) if i > 0 else Fabrica.DIRS[giro])
			f.rotation.y = atan2(-float(d.y), float(d.x))
			for mi in f.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = _mat_ok if libre else _mat_mal
	else:
		_fantasma.visible = true

## Bocas: flecha verde donde entra y naranja donde sale. Se ven en el fantasma y, mientras
## se construye, en todas las máquinas y estaciones; si no, solo en lo seleccionado.
func bocas(entrada_o_entidad, origen := Vector2i.ZERO, g := 0) -> Array:
	var r: Array = []      # [casilla, dirección, sale]
	if entrada_o_entidad is Array:
		var en: Array = entrada_o_entidad
		if en[5] == "maquina":
			var m := Fabrica.MaquinaSim.new(en[6], origen, g)
			return bocas(m)
		if en[5] == "estacion":
			return [[origen + Fabrica.DIRS[g], g, true]]
		if en[5] == "brazo":
			return [[origen - Fabrica.DIRS[g], g, false], [origen + Fabrica.DIRS[g], g, true]]
		if en[5] == "almacen":
			return [[origen + Fabrica.DIRS[g], g, true]]
		return r
	var e: Fabrica.Entidad = entrada_o_entidad
	if e is Fabrica.MaquinaSim:
		for c in e.casillas:
			var fuera: Vector2i = c - Fabrica.DIRS[e.giro]
			if not e.casillas.has(fuera):
				r.append([fuera, e.giro, false])
		if not Fabrica.datos.recetas[e.receta].salidas.is_empty():
			r.append([e.casilla_salida, e.giro, true])
	elif e is Fabrica.Estacion or (e is Fabrica.Almacen and e.giro >= 0):
		r.append([e.casillas[0] + Fabrica.DIRS[e.giro], e.giro, true])
	elif e is Fabrica.Brazo:
		r.append([e.casillas[0] - Fabrica.DIRS[e.giro], e.giro, false])
		r.append([e.casillas[0] + Fabrica.DIRS[e.giro], e.giro, true])
	return r

func _actualizar_flechas() -> void:
	var lista: Array = []
	if not herramienta.is_empty():
		lista.append_array(bocas(herramienta, _cel, giro))
		for e in fab.entidades:
			if e is Fabrica.MaquinaSim or e is Fabrica.Estacion:
				lista.append_array(bocas(e))
	elif seleccion != null:
		lista.append_array(bocas(seleccion))
	while _flechas.size() < lista.size():
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.34, 0.3, 0.03)
		mi.mesh = pm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_flechas.append(mi)
	var pulso := 0.08 * sin(fab.tiempo * 5.0)
	for i in _flechas.size():
		var f := _flechas[i]
		f.visible = i < lista.size()
		if not f.visible:
			continue
		var b: Array = lista[i]
		var c: Vector2i = b[0]
		var d := Vector2(Fabrica.DIRS[b[1]])
		var centro := Vector2(c.x + 0.5, c.y + 0.5) + d * (0.15 + pulso if b[2] else -0.15 + pulso)
		f.position = Vector3(centro.x, 0.36, centro.y)
		# prisma tumbado apuntando en la dirección del flujo
		f.rotation = Vector3(-PI * 0.5, atan2(-d.x, -d.y), 0)
		f.material_override = _mat_sale if b[2] else _mat_entra
