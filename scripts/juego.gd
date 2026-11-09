class_name Juego
extends Node3D
## Partida (puerta 4): une la simulación (Fabrica), su dibujo (VistaFabrica), la construcción
## con el ratón, la extracción a mano, los pedidos, las ventas, las mutaciones y los hitos.
## El HUD solo lee de aquí y llama a seleccionar_herramienta / elegir_receta / pedir.

signal aviso(clave: String)     # mensajes cortos para el teletipo del HUD (claves de traducción)

## Laboratorio nivel 1 (sótano 16 × 12). Zona construible dentro del pasillo amarillo.
const ANCHO := 16
const FONDO := 12
const ZONA := Rect2i(-7, -5, 14, 10)
const DINERO_INICIAL := 2000.0
const DEVOLUCION_TOTAL := 10.0       # segundos con devolución del 100 %
const SEG_POR_DIA := 60.0

## Catálogo de construcción por categoría: [id, icono, clave de nombre, coste, kW, clase, extra]
const CATALOGO := {
	"HUD_CAT_EXTRACCION": [
		["extractor_sangre", "tubo_sangre", "CONS_EXTRACTOR", 200, 2.0, "extractor", ""],
		["recolector", "placa_petri", "CONS_RECOLECTOR", 200, 2.0, "extractor", ""],
		["bomba", "garrafa_agua", "CONS_BOMBA", 150, 1.5, "extractor", ""],
	],
	"HUD_CAT_PROCESADO": [
		["centrifuga", "centrifuga", "MAQ_CENTRIFUGA", 300, 4.5, "maquina", "centrifuga"],
		["secuenciador", "secuenciador", "MAQ_SECUENCIADOR", 500, 6.0, "maquina", "secuenciador"],
		["mezcladora", "mezcladora", "MAQ_MEZCLADORA", 400, 3.0, "maquina", "mezcladora"],
	],
	"HUD_CAT_PRODUCTO": [
		["biorreactor", "biorreactor", "MAQ_BIORREACTOR", 800, 9.0, "maquina", "biorreactor"],
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
const HITOS := [["tubo_plasma", 10, "HUD_OBJ_PLASMA"], ["tubo_adn", 5, "HUD_OBJ_ADN"], ["mutacion", 1, "HUD_OBJ_MUTACION"]]
const INVENTARIO_MAX := 40

var fab: Fabrica
var vista: VistaFabrica
var camara: Node3D
var categoria := "HUD_CAT_PROCESADO"
var herramienta: Array = []          # entrada del catálogo elegida ([] = ninguna)
var quitando := false
var giro := 0
var seleccion: Fabrica.Entidad
var inventario := {}                 # objeto → unidades
var propagacion := 0.0               # 0..1 de la población mundial
var cura := 0.0
var liberado := false
var velocidad := 1.0
var ingresos_min := 0.0
var _cel := Vector2i.ZERO
var _arrastre := false
var _inicio := Vector2i.ZERO
var _hecho_en := {}                  # entidad → tiempo de construcción (para la devolución)
var _fantasma: Node3D
var _fantasma_cintas: Array[Node3D] = []
var _mat_ok: StandardMaterial3D
var _mat_mal: StandardMaterial3D
var _huella: Array[MeshInstance3D] = []
var _anillo: MeshInstance3D
var _extrayendo := Vector2i(999, 999)
var _t_mano := 0.0
var _pedidos: Array = []             # [tiempo de llegada, objeto, lote]
var _muelle_carga: Fabrica.Almacen
var _terminal := Vector2i.ZERO
var _cepa: Fabrica.MaquinaSim
var _ventas_hist: Array = []         # [tiempo, euros]
var _ultimo_dinero := 0.0
var _desechados := 0

func _ready() -> void:
	fab = Fabrica.new()
	fab.dinero = DINERO_INICIAL
	vista = VistaFabrica.new()
	vista.fab = fab
	add_child(vista)
	_montar_nivel_1()
	_mat_ok = _mat_fantasma(Color(0.3, 0.85, 0.5))
	_mat_mal = _mat_fantasma(Color(0.95, 0.3, 0.25))
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
	# nodos de extracción en la pared oeste: dos donantes, una incubadora y una toma de agua
	for c in [Vector2i(-7, -4), Vector2i(-7, -2)]:
		_nodo(c, "donante")
	_nodo(Vector2i(-7, 0), "incubadora")
	_nodo(Vector2i(-7, 2), "agua")
	# fijas: cámara de cepa (fondo, a la derecha), muelle de envío, muelle de carga y terminal
	_cepa = fab.poner_maquina("camara_cepa", Vector2i(4, -5))
	fab.poner_muelle_envio(Vector2i(6, 4))
	_muelle_carga = fab.poner_almacen(Vector2i(-7, 4), 0)
	_terminal = Vector2i(-6, 4)
	_hecho_en[_cepa] = -INF
	_terminal_visual(_terminal)

func _nodo(c: Vector2i, tipo: String) -> void:
	fab.nodos[c] = tipo
	var p := Provisional.new()
	p.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
	add_child(p)
	match tipo:
		"donante":
			p.caja(Vector3(0.9, 0.06, 0.5), Vector3(0, 0.34, 0), Provisional.C_CHASIS)    # camilla
			p.caja(Vector3(0.9, 0.04, 0.5), Vector3(0, 0.36, 0), Color(0.55, 0.75, 0.8))
			for x in [-0.4, 0.4]:
				for z in [-0.2, 0.2]:
					p.cilindro(0.02, 0.32, Vector3(x, 0.16, z), Provisional.C_GRAFITO)
			p.cilindro(0.015, 0.9, Vector3(-0.4, 0.75, -0.3), Provisional.C_GRAFITO)    # gotero
			p.caja(Vector3(0.1, 0.16, 0.04), Vector3(-0.4, 1.1, -0.3), Color(0.75, 0.1, 0.12))
			var paciente := Personaje.new()
			paciente.variante = "paciente_m" if c.y % 4 == 0 else "paciente_f"
			paciente.animacion = "sit"
			paciente.position = Vector3(0.05, 0.38, 0.05)
			paciente.rotation_degrees.y = 90
			p.add_child(paciente)
		"incubadora":
			p.caja(Vector3(0.8, 0.9, 0.7), Vector3(0, 0.45, 0), Provisional.C_CHASIS)
			p.caja(Vector3(0.6, 0.5, 0.02), Vector3(0, 0.5, 0.36), Color(0.5, 0.75, 0.45))
			p.caja(Vector3(0.82, 0.06, 0.72), Vector3(0, 0.92, 0), Provisional.C_ACENTO)
		"agua":
			p.cilindro(0.18, 0.7, Vector3(0, 0.35, 0), Color(0.55, 0.78, 0.95))
			p.cilindro(0.04, 0.3, Vector3(0.15, 0.6, 0), Provisional.C_GRAFITO)
			p.cilindro(0.2, 0.05, Vector3(0, 0.72, 0), Provisional.C_GRAFITO)

func _terminal_visual(c: Vector2i) -> void:
	var p := Provisional.new()
	p.position = Vector3(c.x + 0.5, 0, c.y + 0.5)
	add_child(p)
	p.caja(Vector3(0.5, 1.0, 0.4), Vector3(0, 0.5, 0), Provisional.C_CHASIS)
	p.caja(Vector3(0.4, 0.3, 0.02), Vector3(0, 0.8, 0.21), Color(0.1, 0.3, 0.3))
	p.caja(Vector3(0.52, 0.06, 0.42), Vector3(0, 1.0, 0), Provisional.C_ACENTO)

# ------------------------------------------------------------------ bucle
func _process(dt: float) -> void:
	var dtj := dt * velocidad
	fab.avanzar(dtj)
	# pedidos que llegan
	for p in _pedidos.duplicate():
		if fab.tiempo >= p[0]:
			for k in int(p[2]):
				_muelle_carga.contenido.append(p[1])
			_pedidos.erase(p)
			aviso.emit("AVISO_PEDIDO")
	if fab.desechados > _desechados:
		_desechados = fab.desechados
		aviso.emit("AVISO_REPETIDA")
	# virus
	if not liberado and fab.mutaciones > 0:
		liberado = true
		propagacion = 0.001
		aviso.emit("AVISO_LIBERADO")
	if liberado:
		var ritmo := 0.004 * (1.0 + fab.mutaciones * 0.6)
		propagacion = minf(1.0, propagacion + propagacion * ritmo * dtj * 0.2 + 0.00001 * dtj)
		cura = minf(1.0, cura + 0.0004 * dtj)
	# ingresos por minuto
	if fab.ingresos > _ultimo_dinero:
		_ventas_hist.append([fab.tiempo, fab.ingresos - _ultimo_dinero])
	_ultimo_dinero = fab.ingresos
	while not _ventas_hist.is_empty() and fab.tiempo - _ventas_hist[0][0] > 60.0:
		_ventas_hist.pop_front()
	ingresos_min = 0.0
	for v in _ventas_hist:
		ingresos_min += v[1]
	# extracción a mano
	if _extrayendo.x != 999:
		_t_mano += dt
		_anillo.visible = true
		_anillo.position = Vector3(_extrayendo.x + 0.5, 0.03, _extrayendo.y + 0.5)
		var k := 0.3 + 0.2 * minf(_t_mano / float(Fabrica.datos.a_mano.tiempo), 1.0)
		_anillo.scale = Vector3(k, 0.05, k)
		if _t_mano >= float(Fabrica.datos.a_mano.tiempo):
			_t_mano = 0.0
			var o: String = Fabrica.datos.nodos[fab.nodos[_extrayendo]].objeto
			if _meter(o):
				fab.anotar(o)
	elif seleccion != null:
		_anillo.visible = true
		var c := vista.centro(seleccion)
		var r := 0.45 + 0.5 * maxf(_tam(seleccion).x, _tam(seleccion).y) * 0.5
		var pulso := 1.0 + 0.03 * sin(fab.tiempo * 6.0)
		_anillo.position = Vector3(c.x, 0.03, c.z)
		_anillo.scale = Vector3(r * pulso, 0.05, r * pulso)
	else:
		_anillo.visible = false
	_actualizar_fantasma()

func _tam(e: Fabrica.Entidad) -> Vector2i:
	return e.tam if e is Fabrica.MaquinaSim else Vector2i.ONE

func dia() -> int:
	return 1 + int(fab.tiempo / SEG_POR_DIA)

func hora() -> int:
	return int(fmod(fab.tiempo, SEG_POR_DIA) / SEG_POR_DIA * 24.0 * 60.0 + 8 * 60) % 1440

func hito(i: int) -> Vector2i:
	var h: Array = HITOS[i]
	return Vector2i(mini(int(fab.producido.get(h[0], 0)), h[1]), h[1])

## Consejo del momento para el panel de objetivo (que se juegue sin explicaciones).
func consejo() -> String:
	var hay := func(clase) -> bool:
		for e in fab.entidades:
			if is_instance_of(e, clase):
				return true
		return false
	var tipo := func(t: String) -> bool:
		for e in fab.entidades:
			if e is Fabrica.MaquinaSim and e.tipo == t:
				return true
		return false
	if fab.producido.get("tubo_sangre", 0) == 0:
		return "CONSEJO_EXTRAER"
	if not tipo.call("centrifuga"):
		return "CONSEJO_CENTRIFUGA"
	if fab.producido.get("tubo_plasma", 0) == 0:
		return "CONSEJO_ECHAR"
	if not tipo.call("biorreactor"):
		return "CONSEJO_BIORREACTOR"
	if fab.mutaciones == 0:
		return "CONSEJO_CEPA"
	if not hay.call(Fabrica.Extractor):
		return "CONSEJO_AUTOMATIZAR"
	if fab.producido.get("tubo_adn", 0) < 5:
		return "CONSEJO_ADN"
	return "CONSEJO_VACUNAS"

func inventario_total() -> int:
	var n := 0
	for o in inventario:
		n += inventario[o]
	return n

func _meter(o: String) -> bool:
	if inventario_total() >= INVENTARIO_MAX:
		aviso.emit("AVISO_INVENTARIO_LLENO")
		return false
	inventario[o] = inventario.get(o, 0) + 1
	return true

# ------------------------------------------------------------------ herramientas (desde el HUD)
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
	var espera: float = randf_range(float(p.espera[0]), float(p.espera[1]))
	_pedidos.append([fab.tiempo + espera, objeto, p.lote])
	aviso.emit("AVISO_PEDIDO_HECHO")

func pedidos_en_camino() -> int:
	return _pedidos.size()

# ------------------------------------------------------------------ ratón
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

func _casilla_raton(p: Vector2):
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var o := cam.project_ray_origin(p)
	var d := cam.project_ray_normal(p)
	if absf(d.y) < 0.001:
		return null
	var t := -o.y / d.y
	var q := o + d * t
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
	# sin herramienta: extraer a mano, usar el terminal o la máquina
	if fab.nodos.has(_cel) and not fab.celdas.has(_cel):
		_extrayendo = _cel
		_t_mano = 0.0
		return
	if _cel == _terminal:
		pedir("frasco_reactivo")
		return
	var e: Fabrica.Entidad = fab.celdas.get(_cel)
	seleccion = e
	if e != null:
		_usar(e)

func _soltar() -> void:
	_extrayendo = Vector2i(999, 999)
	if _arrastre:
		_arrastre = false
		var ruta := _ruta_cinta(_inicio, _cel)
		var coste := ruta.size() * int(herramienta[3])
		if _ruta_libre(ruta) and fab.dinero >= coste:
			fab.dinero -= coste
			var antes := fab.entidades.size()
			fab.poner_linea(ruta, 1, giro if ruta.size() == 1 else -1)
			for e in fab.entidades.slice(antes):
				_hecho_en[e] = fab.tiempo
			for e in fab.entidades:
				if e is Fabrica.Cinta and not _hecho_en.has(e):
					_hecho_en[e] = fab.tiempo
		elif fab.dinero < coste:
			aviso.emit("AVISO_SIN_DINERO")

## Echar a mano lo que la máquina acepte del inventario y recoger lo que tenga hecho.
func _usar(e: Fabrica.Entidad) -> void:
	for o in inventario.keys():
		while inventario.get(o, 0) > 0 and e.aceptar(fab, o, -1, e.casillas[0]):
			inventario[o] -= 1
			if inventario[o] == 0:
				inventario.erase(o)
	if e is Fabrica.MaquinaSim or e is Fabrica.Almacen or e is Fabrica.Extractor:
		var o2 := e.sacar("")
		while o2 != "":
			if not _meter(o2):
				# no cabe: se devuelve
				if e is Fabrica.MaquinaSim:
					e.salida.push_front(o2)
				elif e is Fabrica.Almacen:
					e.contenido.push_front(o2)
				break
			o2 = e.sacar("")

func _ruta_cinta(a: Vector2i, b: Vector2i) -> Array:
	var r: Array = []
	var dx := signi(b.x - a.x)
	var dz := signi(b.y - a.y)
	var c := a
	r.append(c)
	while c.x != b.x:
		c.x += dx
		r.append(c)
	while c.y != b.y:
		c.y += dz
		r.append(c)
	return r

func _ruta_libre(r: Array) -> bool:
	for c in r:
		if not ZONA.has_point(c) or fab.celdas.has(c) or fab.nodos.has(c) or c == _terminal:
			return false
	return true

func _casillas_de(entrada: Array, origen: Vector2i) -> Array:
	match entrada[5]:
		"maquina":
			var t: Array = Fabrica.datos.maquinas[entrada[6]].tam
			var cs: Array = []
			var w: int = t[0] if giro % 2 == 0 else t[1]
			var h: int = t[1] if giro % 2 == 0 else t[0]
			for i in w:
				for j in h:
					cs.append(origen + Vector2i(i, j))
			return cs
		_:
			return [origen]

func _valido(entrada: Array, origen: Vector2i) -> bool:
	var cs := _casillas_de(entrada, origen)
	for c in cs:
		if not ZONA.has_point(c) or fab.celdas.has(c) or c == _terminal:
			return false
		if entrada[5] != "extractor" and fab.nodos.has(c):
			return false
	if entrada[5] == "extractor":
		var n = fab.nodos.get(origen)
		return n != null and Fabrica.datos.nodos[n].extractor == entrada[0]
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
		"extractor": e = fab.poner_extractor(c, giro)
		"brazo": e = fab.poner_brazo(c, giro)
		"divisor": e = fab.poner_divisor(c, giro)
		"almacen": e = fab.poner_almacen(c, giro)
	if e:
		fab.dinero -= float(herramienta[3])
		_hecho_en[e] = fab.tiempo

func coste_de(e: Fabrica.Entidad) -> float:
	for cat in CATALOGO:
		for en in CATALOGO[cat]:
			if (e is Fabrica.MaquinaSim and en[6] == e.tipo) or (e is Fabrica.Cinta and en[5] == "cinta") \
					or (e is Fabrica.Brazo and en[5] == "brazo") or (e is Fabrica.Divisor and en[5] == "divisor") \
					or (e is Fabrica.Almacen and en[5] == "almacen") or (e is Fabrica.Extractor and en[0] == e.tipo):
				return float(en[3])
	return 0.0

func _quitar(c: Vector2i) -> void:
	var e: Fabrica.Entidad = fab.celdas.get(c)
	if e == null or e == _cepa or e == _muelle_carga or e is Fabrica.MuelleEnvio:
		return
	var t: float = _hecho_en.get(e, -INF)
	var parte := 1.0 if fab.tiempo - t <= DEVOLUCION_TOTAL else 0.5
	fab.dinero += coste_de(e) * parte
	# lo que llevaba dentro vuelve al inventario si cabe
	if e is Fabrica.Cinta:
		for o in e.objetos:
			_meter(o[0])
	elif e is Fabrica.MaquinaSim:
		for o in e.salida:
			_meter(o)
	fab.quitar(c)
	if seleccion == e:
		seleccion = null

# ------------------------------------------------------------------ fantasma
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
				"extractor": e = Fabrica.Extractor.new(Vector2i.ZERO, 0, "donante")
			n = Provisional.crear(e, Vector3.ZERO)
	_fantasma = n
	add_child(n)
	var cs := _casillas_de(herramienta, Vector2i.ZERO)
	for c in cs:
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
	var cs := _casillas_de(herramienta, _cel)
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
