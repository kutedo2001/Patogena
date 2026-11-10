class_name ArbolCepa
extends Control
## Árbol de la cepa a la manera de un incremental (V1.17): la cepa en el centro y tres ramas que salen
## hacia fuera (transmisión, síntomas, resistencias). Solo se ven con nombre las mejoras hechas, la que
## está en curso y las siguientes que ya se pueden empezar; las demás son puntos apagados con «?» que se
## revelan al avanzar. Clic en un nodo para verlo.

signal elegido(id: String)

const FONDO := Color(0.03, 0.075, 0.085)
const REJILLA := Color(0.08, 0.17, 0.17)
const TINTA := Color(0.6, 1.0, 0.88)
const TENUE := Color(0.25, 0.42, 0.4)
const OK := Color(0.3, 1.0, 0.45)
const AMBAR := Color(1.0, 0.7, 0.1)
const AZUL := Color(0.4, 0.77, 0.9)
const F := preload("res://assets/fuentes/Inter-SemiBold.otf")
const F_BOLD := preload("res://assets/fuentes/Inter-Bold.otf")
const RAMAS := {"transmision": 192.0, "sintomas": -58.0, "resistencias": 52.0}   # dirección en grados
const COLOR_RAMA := {"transmision": Color(0.45, 0.8, 1.0), "sintomas": Color(1.0, 0.45, 0.4), "resistencias": Color(0.75, 0.6, 1.0)}

var fab: Fabrica
var seleccion := ""
var _pos := {}          # id → centro del nodo
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func estado(id: String) -> String:
	if id in fab.cepa_hechas:
		return "hecha"
	if id == fab.cepa_actual:
		return "curso"
	if fab.mejora_disponible(id):
		return "libre"
	var m := Fabrica.mejora(id)
	for r in m.requiere:
		if fab.mejora_disponible(r) or r == fab.cepa_actual:
			return "vista"          # la siguiente a una disponible: se ve, bloqueada
	return "oculta"

func _calcular() -> void:
	_pos.clear()
	var c := size * 0.5 + Vector2(40, 0)
	var cuenta := {}
	for m in Fabrica.datos.cepa.mejoras:
		var rama: String = m.rama
		var k: int = cuenta.get(rama, 0)
		cuenta[rama] = k + 1
		# cada rama se curva un poco y zigzaguea; el óvalo aprovecha el ancho del panel
		var a := deg_to_rad(RAMAS[rama]) + k * 0.07 + (0.13 if k % 2 == 0 else -0.13) * minf(k, 1)
		var radio := 88.0 + k * 31.0
		_pos[m.id] = c + Vector2(cos(a) * radio * 1.3, sin(a) * radio * 0.78)

func _draw() -> void:
	if fab == null:
		return
	_calcular()
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	var paso := 28.0
	var x := 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(REJILLA, 0.5), 1.0)
		x += paso
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(REJILLA, 0.5), 1.0)
		y += paso
	var c := size * 0.5 + Vector2(40, 0)
	# conexiones
	for m in Fabrica.datos.cepa.mejoras:
		var desde: Vector2 = c if m.requiere.is_empty() else _pos[m.requiere[0]]
		var e := estado(m.id)
		var col: Color = COLOR_RAMA[m.rama] if e == "hecha" else (Color(COLOR_RAMA[m.rama], 0.55) if e in ["curso", "libre"] else Color(TENUE, 0.5 if e == "vista" else 0.18))
		draw_line(desde, _pos[m.id], col, 3.0 if e == "hecha" else 1.5, true)
	# centro: la cepa
	var lat := 1.0 + 0.05 * sin(_t * 3.0)
	draw_circle(c, 34.0 * lat, Color(0.12, 0.3, 0.12))
	draw_circle(c, 26.0 * lat, OK.darkened(0.2))
	for i in 10:
		var a := TAU * i / 10.0 + _t * 0.3
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * 24.0, c + d * 38.0, OK, 2.0)
		draw_circle(c + d * 38.0, 4.0, OK)
	draw_string(F_BOLD, c + Vector2(-40, 58), tr("HUD_CEPA").to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 80, 13, TINTA)
	# nombres de rama
	for rama in RAMAS:
		var a := deg_to_rad(RAMAS[rama])
		var p := c + Vector2(cos(a) * 120.0 * 1.3, sin(a) * 120.0 * 0.78) + Vector2(0, -26)
		p = p.clamp(Vector2(70, 20), size - Vector2(70, 10))
		draw_string(F_BOLD, p - Vector2(70, 0), tr("RAMA_" + rama.to_upper()).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 140, 13, COLOR_RAMA[rama])
	# nodos
	for m in Fabrica.datos.cepa.mejoras:
		var id: String = m.id
		var p: Vector2 = _pos[id]
		var e := estado(id)
		var cr: Color = COLOR_RAMA[m.rama]
		var r := 15.0 + int(m.nivel) * 1.5
		match e:
			"hecha":
				draw_circle(p, r, cr.darkened(0.15))
				draw_arc(p, r + 3, 0, TAU, 32, OK, 2.5, true)
			"curso":
				draw_circle(p, r, AMBAR.darkened(0.25))
				var k := float(fab.cepa_sintesis / maxf(fab.sintesis_total(), 0.01)) if fab.cepa_sintesis >= 0.0 else _entregado()
				draw_arc(p, r + 5, -PI * 0.5, -PI * 0.5 + TAU * k, 40, AMBAR, 4.0, true)
			"libre":
				var g := 0.5 + 0.5 * sin(_t * 4.0)
				draw_circle(p, r + 6 * g, Color(cr, 0.18))
				draw_circle(p, r, Color(0.08, 0.16, 0.18))
				draw_arc(p, r, 0, TAU, 32, cr, 2.5, true)
			"vista":
				draw_circle(p, r, Color(0.06, 0.11, 0.12))
				draw_arc(p, r, 0, TAU, 32, TENUE, 1.5, true)
				_candado(p, TENUE)
			_:
				draw_circle(p, 5.0, Color(TENUE, 0.5))
				continue
		if e != "vista":
			_icono_rama(p, m.rama, Color.WHITE if e == "hecha" else cr, r * 0.55)
		if e in ["libre", "curso"] or id == seleccion:
			draw_string(F, p + Vector2(-70, r + 16), ["", "I", "II", "III", "IV"][int(m.nivel)] + " · " + tr("MEJ_" + id.to_upper()),
				HORIZONTAL_ALIGNMENT_CENTER, 140, 11, TINTA)
		if id == seleccion:
			draw_arc(p, r + 9, 0, TAU, 40, Color.WHITE, 2.0, true)

func _entregado() -> float:
	var m := Fabrica.mejora(fab.cepa_actual)
	var h := 0
	var t := 0
	for o in m.pide:
		t += int(m.pide[o])
		h += mini(int(fab.cepa_entregado.get(o, 0)), int(m.pide[o]))
	return float(h) / maxf(t, 1)

func _candado(p: Vector2, c: Color) -> void:
	draw_rect(Rect2(p + Vector2(-6, -1), Vector2(12, 9)), c)
	draw_arc(p + Vector2(0, -2), 4.5, PI, TAU, 12, c, 2.0)

func _icono_rama(p: Vector2, rama: String, c: Color, r: float) -> void:
	match rama:
		"transmision":         # ondas de contagio
			for k in 3:
				draw_arc(p + Vector2(-r * 0.5, 0), r * (0.4 + k * 0.35), -0.8, 0.8, 12, c, 2.0)
			draw_circle(p + Vector2(-r * 0.6, 0), r * 0.22, c)
		"sintomas":            # gota
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.55, r * 0.15), p + Vector2(0, r * 0.75), p + Vector2(-r * 0.55, r * 0.15)]), c)
			draw_circle(p + Vector2(0, r * 0.2), r * 0.55, c)
		_:                     # escudo
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.8, -r * 0.55), p + Vector2(r * 0.6, r * 0.35), p + Vector2(0, r),
				p + Vector2(-r * 0.6, r * 0.35), p + Vector2(-r * 0.8, -r * 0.55)]), c)

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for id in _pos:
			if (_pos[id] as Vector2).distance_to(ev.position) < 22.0 and estado(id) != "oculta":
				seleccion = id
				elegido.emit(id)
				Sonido.tocar("clic")
				return
