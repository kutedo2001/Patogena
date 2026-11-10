class_name JuegoHub
extends Node3D
## Modo director del rediseño 2.0 (R2.1 + R2.2): construir salas como en Two Point (arrastrar el plano, poner la
## puerta, colocar los objetos obligatorios), colocar objetos de pasillo, seleccionar salas y venderlas.
## Ratón: izquierdo = construir/seleccionar; derecho o Esc = cancelar; R = girar el objeto; Q/E = girar la cámara.

signal cambio

var h := Hospital.new()
var pl := Planta.new(h)
var vista: VistaHub
var vista_planta: VistaPlanta
var velocidad := 1.0
var _linea: Array = []         # cinta en curso: [[casilla, giro], ...]
var camara: CamaraDirector
var hud: Control
var modo := ""                 # "", "sala_plano", "sala_puerta", "objeto"
var tipo := ""                 # tipo de sala u objeto que se está construyendo
var giro := 0
var seleccion: Hospital.Sala = null
var plano := Rect2i()          # plano en curso
var errores: Array = []
var _ini := Vector2i()
var _arrastrando := false
var _cursor := Vector2i()
var _puerta := []              # [casilla, lado] bajo el ratón
var _fantasma: Node3D
var _marcas: Node3D

func _ready() -> void:
	var idioma := "es"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--idioma="):
			idioma = a.trim_prefix("--idioma=")
	TranslationServer.set_locale(idioma)
	var args := OS.get_cmdline_user_args()
	if "--demo_hub" in args:
		_demo()
	elif not "--prueba_hub" in args:
		_inicio()
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	Acabado.entorno(self)
	if Sonido.yo == null:
		add_child(Sonido.new())
	vista = VistaHub.new(h)
	vista.pasamuros = pl.pasamuros
	add_child(vista)
	vista_planta = VistaPlanta.new(pl, vista)
	add_child(vista_planta)
	camara = CamaraDirector.new()
	add_child(camara)
	camara.limites = Rect2(h.parcela.position.x - 2, h.parcela.position.y - 2, h.parcela.size.x + 4, h.parcela.size.y + 4)
	camara.fijar(Vector3(h.parcela.get_center().x, 0, h.parcela.get_center().y + 0.5), 16.0 if "--demo_hub" in args or "--prueba_hub" in args else 21.0)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--centro="):
			var c := a.trim_prefix("--centro=").split(",")
			var d := 6.0
			for b in OS.get_cmdline_user_args():
				if b.begins_with("--dist="):
					d = float(b.trim_prefix("--dist="))
			camara.fijar(Vector3(float(c[0]), 0, float(c[1])), d)
	_marcas = Node3D.new()
	add_child(_marcas)
	var capa := CanvasLayer.new()
	add_child(capa)
	hud = load("res://scripts/hub/hud_hub.gd").new(self)
	capa.add_child(hud)
	if "--prueba_hub" in OS.get_cmdline_user_args():
		add_child(load("res://scripts/hub/prueba_raton_hub.gd").new(self))

## Partida nueva: el edificio vacío con la recepción y un banco junto a la entrada (como en Two Point,
## lo primero que haces es la primera sala; la recepción ya viene puesta y es gratis).
func _inicio() -> void:
	var d := h.dinero
	pl.poner("recepcion", h.entrada + Vector2i(1, -3), 2)
	pl.poner("banco", h.entrada + Vector2i(-4, -2), 0)
	pl.poner("planta", h.entrada + Vector2i(-5, -2), 0)
	h.dinero = d

## Demostración: el laboratorio de la pantalla objetivo construido con la simulación (para capturas).
func _demo() -> void:
	h.dinero = 20000
	h.construir_sala("extraccion", Rect2i(9, 1, 3, 4), Vector2i(10, 4), 1)
	pl.poner("camilla", Vector2i(11, 1), 0)
	pl.poner("llenadora_gradillas", Vector2i(9, 2), 0)
	pl.poner("carrito_extraccion", Vector2i(11, 3), 0)
	var lab := h.construir_sala("lab_sangre", Rect2i(3, 1, 6, 4), Vector2i(5, 4), 1)
	pl.poner("centrifuga", Vector2i(5, 1), 0)
	pl.poner("muelle", Vector2i(1, 2), 0)
	for c in [Vector2i(8, 2), Vector2i(7, 2), Vector2i(4, 2), Vector2i(3, 2), Vector2i(2, 2)]:
		pl.poner_cinta(c, 2)
	pl.poner("banco", Vector2i(3, 6), 0)
	pl.poner("banco", Vector2i(6, 6), 0)
	pl.poner("planta", Vector2i(2, 6), 0)
	pl.poner("maquina_bebidas", Vector2i(12, 6), 0)
	pl.poner("recepcion", Vector2i(10, 8), 2)
	pl.poner("papelera", Vector2i(5, 6), 0)
	pl.contratar("cientifico")
	pl.contratar("tecnico")
	for i in int(60 / Planta.PASO):
		pl.paso(Planta.PASO)
	h.dinero = 6000

# ------------------------------------------------------------------ acciones (las usan el HUD y las pruebas)
func empezar_sala(t: String) -> void:
	cancelar()
	modo = "sala_plano"
	tipo = t
	cambio.emit()

func empezar_objeto(t: String) -> void:
	if t == "cinta":
		empezar_cinta()
		return
	_quitar_fantasma()
	modo = "objeto"
	tipo = t
	giro = 0
	_fantasma = vista._cargar(Hospital.datos.objetos[t].modelo)
	add_child(_fantasma)
	cambio.emit()

func empezar_cinta() -> void:
	_quitar_fantasma()
	modo = "cinta"
	tipo = "cinta"
	_linea = []
	cambio.emit()

func contratar(rol: String) -> void:
	if pl.contratar(rol):
		Sonido.tocar("pulsador", 0.7)
	else:
		Sonido.tocar("error", 0.6)
	cambio.emit()

func _process(dt: float) -> void:
	pl.avanzar(dt * velocidad)

func cancelar() -> void:
	modo = ""
	tipo = ""
	plano = Rect2i()
	errores = []
	_arrastrando = false
	_quitar_fantasma()
	_limpiar_marcas()
	cambio.emit()

func seleccionar(s: Hospital.Sala) -> void:
	seleccion = s
	cambio.emit()

func vender_seleccion() -> void:
	if seleccion:
		pl.vender_sala(seleccion)
		seleccion = null
		vista.reconstruir()
		cambio.emit()

func _quitar_fantasma() -> void:
	if _fantasma:
		_fantasma.queue_free()
		_fantasma = null

# ------------------------------------------------------------------ ratón
func casilla_bajo(p: Vector2) -> Vector2i:
	var s := camara.suelo_bajo(p)
	return Vector2i(floori(s.x), floori(s.z))

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_ESCAPE:
			cancelar()
		elif ev.keycode == KEY_R and modo in ["objeto", "cinta"]:
			giro = (giro + 1) % 4
			_actualizar_objeto() if modo == "objeto" else _dibujar_linea()
		elif ev.keycode == KEY_SPACE:
			velocidad = 0.0 if velocidad > 0.0 else 1.0
			cambio.emit()
	if ev is InputEventMouseMotion:
		_mover(casilla_bajo(ev.position))
	elif ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			cancelar()
		elif ev.button_index == MOUSE_BUTTON_LEFT:
			_clic(casilla_bajo(ev.position), ev.pressed)

func _mover(c: Vector2i) -> void:
	_cursor = c
	match modo:
		"sala_plano":
			if _arrastrando:
				plano = Rect2i(Vector2i(mini(_ini.x, c.x), mini(_ini.y, c.y)), Vector2i(absi(c.x - _ini.x) + 1, absi(c.y - _ini.y) + 1))
				errores = h.validar_sala(tipo, plano)
			_dibujar_plano()
			cambio.emit()
		"sala_puerta":
			_puerta = _puerta_cerca(c)
			_dibujar_plano()
		"objeto":
			_actualizar_objeto()
		"cinta":
			if _arrastrando:
				_linea = _trazar(_ini, c)
			_dibujar_linea()

## Cinta arrastrada como en Alchemy Factory: recta en el eje largo y luego el corto; cada tramo apunta al siguiente.
func _trazar(a: Vector2i, b: Vector2i) -> Array:
	var cs := [a]
	var d := b - a
	var p := a
	var primero := Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
	var segundo := Vector2i(0, signi(d.y)) if absi(d.x) >= absi(d.y) else Vector2i(signi(d.x), 0)
	while (primero.x != 0 and p.x != b.x) or (primero.y != 0 and p.y != b.y):
		p += primero
		cs.append(p)
	while p != b:
		p += segundo
		cs.append(p)
	var r := []
	for i in cs.size():
		var dir: Vector2i = (cs[i + 1] - cs[i]) if i < cs.size() - 1 else ((cs[i] - cs[i - 1]) if i > 0 else Vector2i(1, 0) if giro == 0 else Hospital.DIRS[giro])
		r.append([cs[i], Hospital.DIRS.find(dir)])
	return r

func _dibujar_linea() -> void:
	_limpiar_marcas()
	errores = []
	var lista := _linea if not _linea.is_empty() else [[_cursor, giro]]
	for t in lista:
		var e := pl.validar_cinta(t[0], t[1])
		if not e.is_empty() and errores.is_empty():
			errores = e
		_marca(t[0], Color(0.3, 0.9, 0.45, 0.4) if e.is_empty() else Color(1.0, 0.3, 0.25, 0.45))
		var f := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.3, 0.3, 0.02)
		f.mesh = pm
		var holder := Node3D.new()
		holder.position = VistaHub.centro(t[0]) + Vector3(0, 0.02, 0)
		holder.rotation.y = atan2(float(Hospital.DIRS[t[1]].x), float(Hospital.DIRS[t[1]].y))
		f.rotation_degrees = Vector3(90, 0, 0)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(1, 1, 1, 0.85)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		f.material_override = m
		holder.add_child(f)
		_marcas.add_child(holder)
	cambio.emit()

func _clic(c: Vector2i, pulsado: bool) -> void:
	match modo:
		"sala_plano":
			if pulsado:
				_ini = c
				_arrastrando = true
				_mover(c)
			elif _arrastrando:
				_arrastrando = false
				errores = h.validar_sala(tipo, plano)
				if errores.is_empty():
					modo = "sala_puerta"
					_puerta = _puerta_cerca(c)
					_dibujar_plano()
				cambio.emit()
		"sala_puerta":
			if pulsado and not _puerta.is_empty():
				var s := h.construir_sala(tipo, plano, _puerta[0], _puerta[1])
				if s:
					Sonido.tocar("construir", 0.8)
					vista.reconstruir()
					plano = Rect2i()
					_limpiar_marcas()
					seleccionar(s)
					var faltan := h.faltan(s)
					if not faltan.is_empty():
						empezar_objeto(faltan[0])
					else:
						cancelar()
		"objeto":
			if pulsado:
				var o := pl.poner(tipo, c, giro)
				if o:
					Sonido.tocar("construir", 0.6)
					vista.reconstruir()
					var s := h.sala_en(c)
					# si era obligatorio y aún falta otro, pasa a ese; si no, sigue con el mismo
					if s and h.faltan(s).size() > 0 and not (tipo in h.faltan(s)):
						empezar_objeto(h.faltan(s)[0])
					elif s and h.completa(s) and tipo in Hospital.datos.salas[s.tipo].obligatorios:
						cancelar()
						seleccionar(s)
					cambio.emit()
		"cinta":
			if pulsado:
				_ini = c
				_arrastrando = true
				_linea = _trazar(c, c)
				_dibujar_linea()
			elif _arrastrando:
				_arrastrando = false
				var puestas := 0
				for t in _linea:
					if pl.poner_cinta(t[0], t[1]):
						puestas += 1
				if puestas > 0:
					Sonido.tocar("construir", 0.6)
					vista.reconstruir()
				_linea = []
				_dibujar_linea()
		"":
			if pulsado:
				seleccionar(h.sala_en(c))

## Puerta posible más cercana a la casilla del ratón (borde del plano).
func _puerta_cerca(c: Vector2i) -> Array:
	var mejor := []
	var dmin := INF
	for p in h.puertas_posibles(plano):
		var medio := Vector2(p[0]) + Vector2(Hospital.DIRS[p[1]]) * 0.5
		var d := medio.distance_squared_to(Vector2(c))
		if d < dmin:
			dmin = d
			mejor = p
	return mejor

# ------------------------------------------------------------------ marcas en el suelo (plano, huella, usos)
func _limpiar_marcas() -> void:
	for n in _marcas.get_children():
		n.queue_free()

func _marca(c: Vector2i, color: Color, tam := 0.94, y := 0.012) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(tam, tam)
	mi.mesh = pm
	mi.position = VistaHub.centro(c) + Vector3(0, y, 0)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	_marcas.add_child(mi)

func _dibujar_plano() -> void:
	_limpiar_marcas()
	if plano.size == Vector2i.ZERO:
		_marca(_cursor, Color(0.3, 0.6, 1.0, 0.45))
		return
	var ok := errores.is_empty()
	for x in range(plano.position.x, plano.end.x):
		for y in range(plano.position.y, plano.end.y):
			_marca(Vector2i(x, y), Color(0.25, 0.75, 1.0, 0.35) if ok else Color(1.0, 0.3, 0.25, 0.4))
	if modo == "sala_puerta" and not _puerta.is_empty():
		_marca(_puerta[0], Color(1.0, 0.75, 0.2, 0.75), 0.6, 0.016)
		_marca(_puerta[0] + Hospital.DIRS[_puerta[1]], Color(1.0, 0.75, 0.2, 0.45), 0.5, 0.016)

func _actualizar_objeto() -> void:
	if _fantasma == null:
		return
	errores = h.validar_objeto(tipo, _cursor, giro)
	_fantasma.transform = VistaHub.transform_objeto(tipo, _cursor, giro)
	_limpiar_marcas()
	var ok := errores.is_empty()
	for c in Hospital.huella(tipo, _cursor, giro):
		_marca(c, Color(0.3, 0.9, 0.45, 0.35) if ok else Color(1.0, 0.3, 0.25, 0.45))
	var o := Hospital.Objeto.new()
	o.tipo = tipo
	o.origen = _cursor
	o.giro = giro
	for u in o.usos():
		if not (u.get("tumbado", false) or u.get("sentado", false)):
			_marca(u.c, Color(1.0, 0.85, 0.2, 0.6), 0.45, 0.016)   # huella de uso: aquí se pone la persona
	cambio.emit()
