extends Control
## Interfaz del modo director (R2.7), estilo Two Point: menú redondo abajo a la izquierda (Mundo, Salas, Objetos,
## Personal, Info), dinero y velocidad abajo a la derecha, catálogo de salas u objetos encima del menú, ficha de la
## sala seleccionada a la izquierda y barra de construcción arriba al centro con lo que falta o lo que no vale.

const CREMA := Color("f7f3e8")
const CREMA2 := Color("ebe5d4")
const VERDE := Color("2c6b63")
const VERDE2 := Color("4f9b8f")
const NARANJA := Color("f2862a")
const TINTA := Color("22302d")
const TENUE := Color("6c7a76")
const ROJO := Color("c9302c")

var j: JuegoHub
var F_B: Font
var F_S: Font
var catalogo := ""            # "", "salas", "objetos"
var _zonas := []              # [Rect2, acción(Callable)] de lo que se puede pulsar
var _hover := -1

func _init(juego: JuegoHub) -> void:
	j = juego

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_PASS
	F_B = load("res://assets/fuentes/Inter-Bold.otf")
	F_S = load("res://assets/fuentes/Inter-SemiBold.otf")
	j.cambio.connect(queue_redraw)

func _process(_dt: float) -> void:
	queue_redraw()

# ------------------------------------------------------------------ entrada: solo se queda el clic si cae en el HUD
func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var h := _zona_en(ev.position)
		if h != _hover:
			_hover = h
			queue_redraw()
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var i := _zona_en(ev.position)
		if i >= 0:
			Sonido.tocar("clic", 0.7)
			(_zonas[i][1] as Callable).call()
			accept_event()
			queue_redraw()

func _has_point(p: Vector2) -> bool:
	return _zona_en(p) >= 0 or _sobre_panel(p)

func _zona_en(p: Vector2) -> int:
	for i in range(_zonas.size() - 1, -1, -1):
		if (_zonas[i][0] as Rect2).has_point(p):
			return i
	return -1

var _paneles: Array = []
func _sobre_panel(p: Vector2) -> bool:
	for r in _paneles:
		if (r as Rect2).has_point(p):
			return true
	return false

# ------------------------------------------------------------------ dibujo
func _panel(r: Rect2, radio := 22.0, fondo := CREMA, borde := VERDE, grueso := 5, sombra := true) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = borde
	sb.set_border_width_all(grueso)
	sb.set_corner_radius_all(int(radio))
	if sombra:
		sb.shadow_color = Color(0, 0, 0, 0.28)
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true
	draw_style_box(sb, r)

func _txt(p: Vector2, t: String, tam: int, f: Font, c := TINTA, ancho := -1.0, alin := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(f, p, t, alin, ancho, tam, c)

func _boton(r: Rect2, texto: String, color: Color, accion: Callable, activo := true) -> void:
	var hover := _zona_en(get_local_mouse_position()) == _zonas.size()
	_panel(r, 16, (color.lightened(0.12) if hover else color) if activo else CREMA2, (color.darkened(0.25)) if activo else CREMA2, 3, false)
	_txt(Vector2(r.position.x, r.position.y + r.size.y * 0.5 + 6), texto, 16, F_B, CREMA if activo else TENUE, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if activo:
		_zonas.append([r, accion])

func _redondo(c: Vector2, r: float, color: Color, icono: String, etiqueta: String, accion: Callable, activo := true) -> void:
	var hover := Rect2(c - Vector2(r, r), Vector2(r, r) * 2).has_point(get_local_mouse_position())
	draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.25))
	draw_circle(c, r, VERDE)
	draw_circle(c, r - 5, (color.lightened(0.15) if hover else color) if activo else Color("b9b4a6"))
	draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.35, Color(1, 1, 1, 0.12))
	IconosTP.dibujar(self, c, r * 0.5, icono, CREMA)
	_txt(c + Vector2(-60, r + 26), etiqueta, 17, F_B, TINTA if activo else TENUE, 120, HORIZONTAL_ALIGNMENT_CENTER)
	if activo:
		_zonas.append([Rect2(c - Vector2(r, r), Vector2(r, r) * 2), accion])

func _draw() -> void:
	_zonas.clear()
	_paneles.clear()
	var tam := size
	_menu(tam)
	_dinero(tam)
	if catalogo == "salas":
		_catalogo_salas(tam)
	elif catalogo == "objetos":
		_catalogo_objetos(tam)
	if j.seleccion and j.modo == "":
		_ficha(tam)
	if j.modo != "":
		_barra_construccion(tam)

func _menu(tam: Vector2) -> void:
	var r := Rect2(24, tam.y - 166, 560, 142)
	_panel(r, 60)
	_paneles.append(r)
	var y := tam.y - 110
	_redondo(Vector2(98, y), 46, Color("3d8a7f"), "mapa", tr("HUB_MUNDO"), func(): pass, false)
	_redondo(Vector2(210, y), 40, NARANJA, "salas", tr("HUB_SALAS"), func(): catalogo = "" if catalogo == "salas" else "salas")
	_redondo(Vector2(314, y), 40, Color("58a35a"), "objetos", tr("HUB_OBJETOS"), func(): catalogo = "" if catalogo == "objetos" else "objetos")
	_redondo(Vector2(418, y), 40, Color("3f7fc4"), "personal", tr("HUB_PERSONAL"), func(): pass, false)
	_redondo(Vector2(522, y), 40, Color("8a5cc2"), "info", tr("HUB_INFO"), func(): pass, false)

func _dinero(tam: Vector2) -> void:
	var r := Rect2(tam.x - 470, tam.y - 180, 446, 156)
	_panel(r, 34)
	_paneles.append(r)
	_txt(r.position + Vector2(28, 52), _euros(j.h.dinero), 38, F_B, TINTA)
	for i in 5:
		IconosTP.dibujar(self, r.position + Vector2(40 + i * 30, 84), 12, "estrella", NARANJA if i < 1 else CREMA2)
	_txt(r.position + Vector2(198, 91), tr("HUD_REPUTACION"), 16, F_S, TENUE)
	_txt(r.position + Vector2(28, 132), tr("HUB_DIA") % 1, 20, F_S, TINTA)
	var vel := ["pausa", "play", "rapido"]
	for i in 3:
		var c := r.position + Vector2(262 + i * 52, 122)
		draw_circle(c, 21, VERDE if i == 1 else CREMA2)
		IconosTP.dibujar(self, c, 11, vel[i], CREMA if i == 1 else VERDE)

func _euros(v: float) -> String:
	var n := int(round(v))
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "." + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out + " €"

func _catalogo_salas(tam: Vector2) -> void:
	var tipos: Array = Hospital.datos.salas.keys()
	var r := Rect2(24, tam.y - 196 - 150, 230 * tipos.size() + 24, 150)
	_panel(r, 24)
	_paneles.append(r)
	for i in tipos.size():
		var t: String = tipos[i]
		var d: Dictionary = Hospital.datos.salas[t]
		var cr := Rect2(r.position.x + 16 + i * 230, r.position.y + 16, 218, 118)
		var zc := Color(d.zocalo[0], d.zocalo[1], d.zocalo[2])
		var hover := cr.has_point(get_local_mouse_position())
		_panel(cr, 16, CREMA2.lightened(0.3) if hover else CREMA2, zc, 4, false)
		draw_rect(Rect2(cr.position + Vector2(4, 4), Vector2(cr.size.x - 8, 8)), zc)
		_txt(cr.position + Vector2(14, 40), tr("SALA_" + t.to_upper()), 18, F_B, TINTA)
		_txt(cr.position + Vector2(14, 64), tr("HUB_MINIMO") % [int(d.min[0]), int(d.min[1])], 15, F_S, TENUE)
		_txt(cr.position + Vector2(14, 86), tr("HUB_POR_CASILLA") % int(Hospital.datos.precio_casilla_sala), 15, F_S, TENUE)
		var x := cr.position.x + 14
		for o in d.obligatorios:
			IconosTP.dibujar(self, Vector2(x + 8, cr.position.y + 104), 7, "estrella_obl", NARANJA)
			_txt(Vector2(x + 18, cr.position.y + 109), tr("OBJ_" + str(o).to_upper()), 12, F_S, TINTA)
			x += 18 + F_S.get_string_size(tr("OBJ_" + str(o).to_upper()), HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 10
		_zonas.append([cr, func(): catalogo = ""; j.empezar_sala(t)])

func _catalogo_objetos(tam: Vector2) -> void:
	var zona := j.seleccion.tipo if j.seleccion else ""
	var lista := []
	for t in Hospital.datos.objetos:
		if j.h.zona_permitida(t, j.seleccion):
			lista.append(t)
	var cols := mini(lista.size(), 6)
	var filas := ceili(lista.size() / float(cols))
	var r := Rect2(24, tam.y - 196 - 24 - filas * 104, cols * 170 + 24, filas * 104 + 24 + 30)
	_panel(r, 24)
	_paneles.append(r)
	_txt(r.position + Vector2(20, 34), tr("HUB_OBJETOS_DE") % (tr("SALA_" + zona.to_upper()) if zona != "" else tr("HUB_PASILLO")), 17, F_B, VERDE)
	for i in lista.size():
		var t: String = lista[i]
		var cr := Rect2(r.position.x + 16 + (i % cols) * 170, r.position.y + 48 + (i / cols) * 104, 158, 92)
		var hover := cr.has_point(get_local_mouse_position())
		var obl: bool = j.seleccion != null and t in Hospital.datos.salas[j.seleccion.tipo].obligatorios
		_panel(cr, 14, CREMA2.lightened(0.3) if hover else CREMA2, NARANJA if obl else CREMA2, 3, false)
		if obl:
			IconosTP.dibujar(self, cr.position + Vector2(cr.size.x - 18, 18), 9, "estrella_obl", NARANJA)
		_txt(cr.position + Vector2(12, 34), tr("OBJ_" + t.to_upper()), 15, F_B, TINTA, cr.size.x - 30)
		var tm: Array = Hospital.datos.objetos[t].tam
		_txt(cr.position + Vector2(12, 58), "%d × %d" % [int(tm[0]), int(tm[1])], 14, F_S, TENUE)
		_txt(cr.position + Vector2(12, 80), _euros(float(Hospital.datos.objetos[t].precio)), 15, F_B, VERDE)
		_zonas.append([cr, func(): catalogo = ""; j.empezar_objeto(t)])

func _ficha(tam: Vector2) -> void:
	var s: Hospital.Sala = j.seleccion
	var d: Dictionary = Hospital.datos.salas[s.tipo]
	var faltan := j.h.faltan(s)
	var alto := 300 + faltan.size() * 34
	var r := Rect2(24, 140, 420, alto)
	_panel(r, 26)
	_paneles.append(r)
	_panel(Rect2(r.position, Vector2(r.size.x, 92)), 26, VERDE, VERDE, 0, false)
	draw_rect(Rect2(r.position + Vector2(5, 60), Vector2(r.size.x - 10, 32)), VERDE)
	draw_circle(r.position + Vector2(54, 46), 30, CREMA)
	IconosTP.dibujar(self, r.position + Vector2(54, 46), 18, "salas", VERDE)
	_txt(r.position + Vector2(98, 40), tr("SALA_" + s.tipo.to_upper()), 23, F_B, CREMA)
	_txt(r.position + Vector2(98, 68), "%d × %d" % [s.rect.size.x, s.rect.size.y], 16, F_S, Color(1, 1, 1, 0.75))
	var y := r.position.y + 128
	if faltan.is_empty():
		draw_circle(Vector2(r.position.x + 36, y - 6), 13, VERDE2)
		IconosTP.dibujar(self, Vector2(r.position.x + 36, y - 6), 9, "check", CREMA)
		_txt(Vector2(r.position.x + 58, y), tr("HUB_SALA_LISTA"), 17, F_B, VERDE)
		y += 40
	else:
		_txt(Vector2(r.position.x + 22, y), tr("HUB_FALTA"), 13, F_B, TENUE)
		y += 30
		for o in faltan:
			IconosTP.dibujar(self, Vector2(r.position.x + 36, y - 6), 10, "estrella_obl", NARANJA)
			_txt(Vector2(r.position.x + 56, y), tr("OBJ_" + str(o).to_upper()), 17, F_S, TINTA)
			y += 34
	_txt(Vector2(r.position.x + 22, y + 10), tr("HUB_PERSONAL_SALA") % tr("PERSONAL_" + str(d.personal).to_upper()) if d.personal != "" else "", 15, F_S, TENUE)
	var by := r.end.y - 72
	_boton(Rect2(r.position.x + 16, by, 186, 52), tr("HUB_ANADIR_OBJETOS"), VERDE2, func(): catalogo = "objetos")
	_boton(Rect2(r.position.x + 218, by, 186, 52), tr("HUB_VENDER"), ROJO, func(): j.vender_seleccion())

func _barra_construccion(tam: Vector2) -> void:
	var r := Rect2(tam.x * 0.5 - 380, 24, 760, 96)
	_panel(r, 26)
	_paneles.append(r)
	var titulo := ""
	var detalle := ""
	match j.modo:
		"sala_plano":
			titulo = tr("HUB_CONSTRUYENDO") % tr("SALA_" + j.tipo.to_upper())
			var m: Array = Hospital.datos.salas[j.tipo].min
			if j.plano.size != Vector2i.ZERO:
				detalle = tr("HUB_PLANO") % [j.plano.size.x, j.plano.size.y, int(m[0]), int(m[1]), _euros(j.h.precio_sala(j.plano))]
			else:
				detalle = tr("HUB_ARRASTRA") % [int(m[0]), int(m[1])]
		"sala_puerta":
			titulo = tr("HUB_PON_PUERTA")
			detalle = tr("HUB_PUERTA_AYUDA")
		"objeto":
			titulo = tr("HUB_COLOCANDO") % tr("OBJ_" + j.tipo.to_upper())
			detalle = tr("HUB_OBJETO_AYUDA")
	_txt(r.position + Vector2(28, 40), titulo, 21, F_B, VERDE)
	var err := ""
	if not j.errores.is_empty():
		err = tr(j.errores[0])
	_txt(r.position + Vector2(28, 74), err if err != "" else detalle, 16, F_S, ROJO if err != "" else TENUE, 600)
	_boton(Rect2(r.end.x - 130, r.position.y + 24, 106, 48), tr("HUB_CANCELAR"), ROJO, func(): j.cancelar())
