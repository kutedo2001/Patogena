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

## Nodos por capas: profundidad = camino más largo desde la raíz de su rama; los de la misma capa se
## abren en abanico. Así las ramas se bifurcan y se vuelven a juntar como un árbol de incremental.
func _profundidad(id: String) -> int:
	var m := Fabrica.mejora(id)
	var p := 0
	for r in m.requiere:
		p = maxi(p, _profundidad(r) + 1)
	return p

var _c := Vector2.ZERO
var _etq := {}           # rama → posición del nombre (más allá del nodo más lejano)

func _mejora(id: String) -> Dictionary:
	for m in Fabrica.datos.cepa.mejoras:
		if m.id == id:
			return m
	return {}

func _calcular() -> void:
	# posiciones en bruto alrededor de (0,0); luego se escala y centra para que quepa todo
	var bruto := {}
	var capas := {}          # rama|prof → [ids]
	for m in Fabrica.datos.cepa.mejoras:
		var clave := "%s|%d" % [m.rama, _profundidad(m.id)]
		if not capas.has(clave):
			capas[clave] = []
		capas[clave].append(m.id)
	# abanico por rama: radio por profundidad, ángulo repartido dentro del sector
	# y ordenado por el ángulo medio de los padres (baricentro) para que no se crucen líneas
	var ang := {}
	var lejos := {}
	var max_prof := 0
	for clave in capas:
		max_prof = maxi(max_prof, int(clave.split("|")[1]))
	for rama in RAMAS:
		for prof in max_prof + 1:
			var clave := "%s|%d" % [rama, prof]
			if not capas.has(clave):
				continue
			var ids: Array = capas[clave].duplicate()
			var A := deg_to_rad(RAMAS[rama])
			var media := func(id):
				var req: Array = _mejora(id).requiere
				if req.is_empty():
					return A
				var t := 0.0
				for r in req:
					t += ang.get(r, A)
				return t / req.size()
			ids.sort_custom(func(x, y): return media.call(x) < media.call(y))
			var n := ids.size()
			var paso := minf(deg_to_rad(100.0) / maxf(n - 1, 1), deg_to_rad(30.0))
			var r := 120.0 + prof * 75.0
			lejos[rama] = maxf(lejos.get(rama, 0.0), r)
			for i in n:
				var t := A + (i - (n - 1) * 0.5) * paso
				ang[ids[i]] = t
				bruto[ids[i]] = Vector2(cos(t), sin(t)) * r
	var etq := {}
	for rama in RAMAS:
		var a := deg_to_rad(RAMAS[rama])
		etq[rama] = Vector2(cos(a), sin(a)) * (lejos.get(rama, 100.0) + 70.0)
	var caja := Rect2(Vector2.ZERO, Vector2.ZERO)
	for id in bruto:
		caja = caja.expand(bruto[id])
	for rama in etq:
		caja = caja.expand(etq[rama])
	caja = caja.grow_individual(70, 30, 70, 40)   # medio nombre de nodo/rama y radio
	# X e Y por separado: el recuadro es apaisado y las ramas no; así se aprovecha todo y no se pisan
	var esc := Vector2(minf(1.4, size.x / maxf(caja.size.x, 1.0)), minf(1.6, size.y / maxf(caja.size.y, 1.0)))
	var desp := size * 0.5 - caja.get_center() * esc
	_c = desp
	_pos.clear()
	for id in bruto:
		_pos[id] = desp + bruto[id] * esc
	_etq.clear()
	for rama in etq:
		_etq[rama] = desp + etq[rama] * esc

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
	var c := _c
	# conexiones (una línea por requisito: las ramas se separan y se juntan)
	for m in Fabrica.datos.cepa.mejoras:
		var e := estado(m.id)
		var col: Color = COLOR_RAMA[m.rama] if e == "hecha" else (Color(COLOR_RAMA[m.rama], 0.55) if e in ["curso", "libre"] else Color(TENUE, 0.5 if e == "vista" else 0.18))
		var origenes: Array = [c] if m.requiere.is_empty() else m.requiere.map(func(r): return _pos[r])
		for desde in origenes:
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
		var p: Vector2 = _etq[rama] + Vector2(0, 4)
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
