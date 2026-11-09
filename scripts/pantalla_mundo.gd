class_name PantallaMundo
extends Control
## Contenido del monitor del mundo de la pared (sin palabras, como las pantallas de las
## máquinas): mapa de puntos con los focos creciendo y rutas aéreas animadas, % mundial,
## barra de cura, barras por región y gráfica de la curva. Datos de muestra hasta P4.

const FONDO := Color(0.03, 0.075, 0.085)
const REJILLA := Color(0.09, 0.2, 0.2)
const TINTA := Color(0.6, 1.0, 0.88)
const TENUE := Color(0.32, 0.62, 0.57)
const SANO := Color(0.2, 0.36, 0.36)
const ZOMBI := Color(0.55, 1.0, 0.25)
const CURA := Color(0.45, 0.7, 1.0)
const F := preload("res://assets/fuentes/Inter-SemiBold.otf")
const F_BOLD := preload("res://assets/fuentes/Inter-Bold.otf")

## focos de infección: [columna, fila, fuerza 0..1]
const FOCOS := [[23.5, 6.0, 1.0], [26.0, 4.0, 0.55], [14.5, 11.5, 0.25], [36.0, 7.0, 0.18]]
## rutas aéreas entre focos (índices)
const RUTAS := [[0, 1], [0, 2], [1, 3], [0, 3]]
const REGIONES := [0.62, 0.41, 0.18, 0.09, 0.05, 0.03, 0.02, 0.01, 0.0, 0.0, 0.0, 0.0]

var propagacion := 0.032
var real := false          # con partida: los focos y las regiones salen de la propagación
var cura := 0.12
var _t := 0.0

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var u := h / 430.0
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	# rejilla de fondo
	var paso_r := 32.0 * u
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, 0), Vector2(x, h), Color(REJILLA, 0.35), 1.0)
		x += paso_r
	var y := 0.0
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), Color(REJILLA, 0.35), 1.0)
		y += paso_r
	# cabecera
	var cab := 30.0 * u
	draw_rect(Rect2(0, 0, w, cab), Color(0.05, 0.13, 0.13))
	draw_rect(Rect2(10 * u, 6 * u, 18 * u, 18 * u), Color(0.25, 0.71, 0.66))
	draw_string(F_BOLD, Vector2(13.5 * u, 21 * u), "P", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * u), FONDO)
	var parp := 0.5 + 0.5 * sin(_t * 4.0)
	draw_circle(Vector2(44 * u, 15 * u), 5 * u, Color(1.0, 0.25, 0.2, 0.4 + 0.6 * parp))
	var min_ := int(8 * 60 + 40 + _t * 2.0) % 1440
	draw_string(F, Vector2(w - 70 * u, 21 * u), "%02d:%02d" % [min_ / 60, min_ % 60], HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u), TINTA)
	draw_string(F, Vector2(w - 150 * u, 21 * u), "D47", HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u), TENUE)
	# mapa
	var area := Rect2(14 * u, cab + 12 * u, w * 0.64, h - cab - 24 * u)
	_mapa(area, u)
	# columna derecha
	var cx := area.end.x + 22 * u
	var cw := w - cx - 16 * u
	_virus(Vector2(cx + 18 * u, cab + 40 * u), 14 * u)
	draw_string(F_BOLD, Vector2(cx + 42 * u, cab + 54 * u), "%s%%" % String.num(propagacion * 100.0, 1).replace(".", ","), HORIZONTAL_ALIGNMENT_LEFT, -1, int(38 * u), ZOMBI)
	# cura
	var yc := cab + 84 * u
	_escudo(Vector2(cx + 18 * u, yc + 8 * u), 11 * u)
	var rb := Rect2(cx + 40 * u, yc, cw - 90 * u, 16 * u)
	draw_rect(rb, REJILLA)
	draw_rect(Rect2(rb.position, Vector2(rb.size.x * cura, rb.size.y)), CURA)
	for k in range(1, 10):
		draw_line(rb.position + Vector2(rb.size.x * k / 10.0, 0), rb.position + Vector2(rb.size.x * k / 10.0, rb.size.y), FONDO, 1.5)
	draw_string(F, Vector2(rb.end.x + 8 * u, yc + 14 * u), "%d%%" % int(cura * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * u), CURA)
	# barras por región
	var yr := yc + 34 * u
	var alto_b := 9.0 * u
	for i in REGIONES.size():
		var v: float = REGIONES[i] * (clampf(propagacion * 8.0, 0.0, 1.0) if real else 1.0)
		var yy := yr + i * (alto_b + 5 * u)
		draw_circle(Vector2(cx + 6 * u, yy + alto_b / 2), 3 * u, ZOMBI if v > 0.0 else SANO)
		var rr := Rect2(cx + 16 * u, yy, cw - 66 * u, alto_b)
		draw_rect(rr, REJILLA)
		draw_rect(Rect2(rr.position, Vector2(rr.size.x * v, rr.size.y)), ZOMBI.lerp(Color(1, 0.8, 0.2), 1.0 - v))
		draw_string(F, Vector2(rr.end.x + 6 * u, yy + alto_b), "%d" % int(v * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * u), TENUE)
	# gráfica de la curva
	var gy := yr + 12 * (alto_b + 5 * u) + 10 * u
	var gr := Rect2(cx, gy, cw, h - gy - 14 * u)
	draw_rect(gr, Color(REJILLA, 0.6), false, 1.0)
	var pts := PackedVector2Array()
	var pts_c := PackedVector2Array()
	for k in 48:
		var tt := k / 47.0
		pts.append(gr.position + Vector2(gr.size.x * tt, gr.size.y * (1.0 - pow(tt, 3.2) * 0.85 - 0.05)))
		pts_c.append(gr.position + Vector2(gr.size.x * tt, gr.size.y * (1.0 - tt * 0.3 - 0.05)))
	draw_polyline(pts_c, CURA, 2.0 * u, true)
	draw_polyline(pts, ZOMBI, 2.5 * u, true)
	draw_circle(pts[pts.size() - 1], 4 * u * (0.8 + 0.4 * parp), ZOMBI)

func _mapa(area: Rect2, u: float) -> void:
	var filas := MapaHUD.MAPA.size()
	var cols: int = MapaHUD.MAPA[0].length()
	var paso := minf(area.size.x / cols, area.size.y / filas)
	var o := area.position + (area.size - Vector2(cols, filas) * paso) * 0.5 + Vector2(paso, paso) * 0.5
	var crece := 1.0 + 0.06 * sin(_t * 0.7)
	var k_real := clampf(propagacion * 25.0, 0.0, 1.0) if real else 1.0
	for yy in filas:
		var fila: String = MapaHUD.MAPA[yy]
		for xx in cols:
			if fila[xx] != "X":
				continue
			var c := SANO
			for f in FOCOS:
				var d := Vector2(xx, yy * 1.15).distance_to(Vector2(f[0], f[1] * 1.15))
				var radio: float = (0.8 + f[2] * 5.0) * crece * k_real
				if radio <= 0.05:
					continue
				if d < radio:
					c = c.lerp(ZOMBI, clampf((radio - d) / 1.6, 0.0, 1.0))
			draw_circle(o + Vector2(xx, yy) * paso, paso * 0.36, c)
	# pulsos en los focos
	for i in FOCOS.size():
		var f: Array = FOCOS[i]
		if k_real <= 0.0 or (real and i > 0 and k_real < 0.5):
			continue
		var pc := o + Vector2(f[0], f[1]) * paso
		var k := fmod(_t * 0.6 + i * 0.27, 1.0)
		draw_arc(pc, paso * (1.0 + k * (3.0 + f[2] * 5.0)), 0, TAU, 32, Color(ZOMBI, 0.8 * (1.0 - k)), 1.5 * u, true)
	# rutas aéreas: arco discontinuo y un avión (punto) recorriéndolo
	if k_real < 0.3:
		return
	for i in RUTAS.size():
		var a: Array = FOCOS[RUTAS[i][0]]
		var b: Array = FOCOS[RUTAS[i][1]]
		var pa := o + Vector2(a[0], a[1]) * paso
		var pb := o + Vector2(b[0], b[1]) * paso
		var medio := (pa + pb) * 0.5 + Vector2(0, -pa.distance_to(pb) * 0.3)
		var n := 24
		for k in n:
			if k % 2 == 1:
				continue
			var t0 := k / float(n)
			var t1 := (k + 1) / float(n)
			draw_line(_bez(pa, medio, pb, t0), _bez(pa, medio, pb, t1), Color(1.0, 0.75, 0.25, 0.55), 1.2 * u, true)
		var tt := fmod(_t * 0.18 + i * 0.31, 1.0)
		draw_circle(_bez(pa, medio, pb, tt), 3.0 * u, Color(1.0, 0.8, 0.3))

func _bez(a: Vector2, m: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(m, t).lerp(m.lerp(b, t), t)

func _virus(c: Vector2, r: float) -> void:
	draw_circle(c, r * 0.6, ZOMBI)
	for i in 8:
		var a := TAU * i / 8.0 + _t * 0.5
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * r * 0.55, c + d * r, ZOMBI, 2.0)
		draw_circle(c + d * r, r * 0.16, ZOMBI)

func _escudo(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.85, -r * 0.6), c + Vector2(r * 0.7, r * 0.3), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.3), c + Vector2(-r * 0.85, -r * 0.6)])
	draw_colored_polygon(pts, CURA)
	draw_rect(Rect2(c + Vector2(-r * 0.14, -r * 0.55), Vector2(r * 0.28, r * 1.0)), FONDO)
	draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.19), Vector2(r * 1.0, r * 0.28)), FONDO)
