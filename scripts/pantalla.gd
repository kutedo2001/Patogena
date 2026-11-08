class_name PantallaMaquina
extends Control
## Contenido de la pantalla de una máquina, dibujado con _draw() dentro de un
## SubViewport cuya textura va a la malla «pantalla» del modelo.
## Sin palabras: iconos de producto, números con unidades, gráficas y barras.
## Disposición común: cabecera (estado, reloj, eficiencia, logotipo) · cuerpo
## (gráfica y dato principal) · pie (entrada → progreso → salida, con existencias).

enum Tipo { CENTRIFUGA, SECUENCIADOR, BIORREACTOR }
enum Icono { SANGRE, PLASMA, CULTIVO, ADN, VIAL }

const FONDO := Color(0.03, 0.075, 0.085)
const REJILLA := Color(0.09, 0.2, 0.2)
const TINTA := Color(0.6, 1.0, 0.88)
const TENUE := Color(0.32, 0.62, 0.57)
const C_ESTADO := [Color(0.35, 0.38, 0.4), Color(0.3, 1.0, 0.45), Color(1.0, 0.7, 0.1), Color(1.0, 0.22, 0.16)]
const BASES := [Color(0.25, 0.95, 0.4), Color(0.3, 0.62, 1.0), Color(1.0, 0.82, 0.2), Color(1.0, 0.36, 0.36)]
const C_ICONO := {
	Icono.SANGRE: Color(0.8, 0.06, 0.08), Icono.PLASMA: Color(0.98, 0.72, 0.15),
	Icono.CULTIVO: Color(0.85, 0.66, 0.3), Icono.ADN: Color(0.3, 1.0, 0.45), Icono.VIAL: Color(0.5, 0.95, 0.2)}
# receta que enseña cada máquina: [entrada, salida]
const RECETA := {
	Tipo.CENTRIFUGA: [Icono.SANGRE, Icono.PLASMA],
	Tipo.SECUENCIADOR: [Icono.CULTIVO, Icono.ADN],
	Tipo.BIORREACTOR: [Icono.ADN, Icono.VIAL]}

var tipo: Tipo = Tipo.CENTRIFUGA
var estado := 1            # Maquina.Estado (0 apagada, 1 trabaja, 2 sin material, 3 avería)
var progreso := 0.0        # 0..1 de la pieza actual
var velocidad := 0.0       # 0..1 (rpm, flujo, agitación)
var entradas := 4          # existencias en la boca de entrada
var salidas := 2           # piezas hechas esperando en la salida
var ciclo := 3.0           # segundos por pieza
var eficiencia := 0.96
var color_producto := Color(0.5, 0.95, 0.2)
var _t := 0.0
var _f: Font
var _u := 1.0              # unidad de tamaño (alto / 160)

func _ready() -> void:
	_f = ThemeDB.fallback_font

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

# ------------------------------------------------------------------ utilidades
func _px(v: float) -> float:
	return v * _u

func _txt(pos: Vector2, s: String, tam: float, c: Color, alin := HORIZONTAL_ALIGNMENT_LEFT, ancho := -1.0) -> void:
	draw_string(_f, pos, s, alin, ancho, int(_px(tam)), c)

func _barra(r: Rect2, v: float, c: Color, tramos := 10) -> void:
	draw_rect(r, REJILLA)
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v, 0, 1), r.size.y)), c)
	for i in range(1, tramos):
		var x := r.position.x + r.size.x * i / float(tramos)
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), FONDO, maxf(1.0, _px(1.0)))

func _anillo(c: Vector2, r: float, v: float, col: Color, grosor: float) -> void:
	draw_arc(c, r, 0, TAU, 48, REJILLA, grosor, true)
	if v > 0.001:
		draw_arc(c, r, -PI / 2, -PI / 2 + TAU * clampf(v, 0, 1), 48, col, grosor, true)

func _hash(i: int) -> int:
	var x := (i * 374761393 + 668265263) & 0x7fffffff
	x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff
	return x

## Icono de producto (silueta reconocible) centrado en c con alto h.
func _icono(ic: Icono, c: Vector2, h: float, contorno := false) -> void:
	var col: Color = C_ICONO[ic]
	var linea := maxf(1.0, h * 0.06)
	match ic:
		Icono.SANGRE, Icono.PLASMA:
			var w := h * 0.34
			var cuerpo := Rect2(c + Vector2(-w / 2, -h * 0.3), Vector2(w, h * 0.62))
			draw_rect(Rect2(c + Vector2(-w * 0.62, -h / 2), Vector2(w * 1.24, h * 0.22)),
				Color(0.85, 0.12, 0.12) if ic == Icono.SANGRE else Color(0.98, 0.75, 0.15))
			if not contorno:
				var rojo := Color(0.45, 0.02, 0.04)
				if ic == Icono.PLASMA:
					draw_rect(Rect2(cuerpo.position + Vector2(0, cuerpo.size.y * 0.15), Vector2(w, cuerpo.size.y * 0.45)), col)
					draw_rect(Rect2(cuerpo.position + Vector2(0, cuerpo.size.y * 0.6), Vector2(w, cuerpo.size.y * 0.4)), rojo)
					draw_circle(Vector2(c.x, cuerpo.end.y), w / 2, rojo)
				else:
					draw_rect(Rect2(cuerpo.position + Vector2(0, cuerpo.size.y * 0.15), Vector2(w, cuerpo.size.y * 0.85)), col)
					draw_circle(Vector2(c.x, cuerpo.end.y), w / 2, col)
			draw_rect(cuerpo, TINTA, false, linea)
		Icono.CULTIVO:
			var r := h * 0.42
			if not contorno:
				draw_circle(c, r, col)
				for k in 5:
					var a := k * 1.7
					draw_circle(c + Vector2(cos(a), sin(a)) * r * (0.25 + 0.12 * k), r * 0.12, Color(0.4, 0.95, 0.35))
			draw_arc(c, r, 0, TAU, 32, TINTA, linea, true)
		Icono.ADN:
			var w := h * 0.42
			var pts := PackedVector2Array([c + Vector2(-w / 2, -h * 0.32), c + Vector2(w / 2, -h * 0.32),
				c + Vector2(w / 2, h * 0.02), c + Vector2(0, h * 0.48), c + Vector2(-w / 2, h * 0.02)])
			if not contorno:
				draw_colored_polygon(PackedVector2Array([pts[4] + Vector2(0, -h * 0.12), pts[2] + Vector2(0, -h * 0.12), pts[2], pts[3], pts[4]]), col)
			pts.append(pts[0])
			draw_polyline(pts, TINTA, linea, true)
			draw_rect(Rect2(c + Vector2(-w * 0.62, -h * 0.48), Vector2(w * 1.24, h * 0.14)), TINTA)
		Icono.VIAL:
			var w := h * 0.5
			var cuerpo := Rect2(c + Vector2(-w / 2, -h * 0.12), Vector2(w, h * 0.6))
			draw_rect(Rect2(c + Vector2(-w * 0.3, -h * 0.5), Vector2(w * 0.6, h * 0.16)), Color(0.95, 0.75, 0.3))
			draw_rect(Rect2(c + Vector2(-w * 0.2, -h * 0.34), Vector2(w * 0.4, h * 0.22)), TINTA, false, linea)
			if not contorno:
				draw_rect(Rect2(cuerpo.position + Vector2(0, cuerpo.size.y * 0.25), Vector2(w, cuerpo.size.y * 0.75)), color_producto)
			draw_rect(cuerpo, TINTA, false, linea)

func _cabecera(w: float) -> float:
	var hc := _px(20)
	var col: Color = C_ESTADO[estado]
	draw_rect(Rect2(0, 0, w, hc), Color(col, 0.16))
	draw_rect(Rect2(0, hc - _px(1.5), w, _px(1.5)), Color(col, 0.7))
	if estado == 1 or fmod(_t, 0.8) < 0.5:
		draw_circle(Vector2(_px(11), hc / 2), _px(5.5), col)
	_txt(Vector2(_px(22), hc * 0.74), "%02d:%02d:%02d" % [8 + int(_t / 3600.0), int(_t / 60.0) % 60, int(_t) % 60], 11, TENUE)
	# eficiencia como 5 pasos
	var x := w * 0.5
	for i in 5:
		var on := i < int(round(eficiencia * 5))
		draw_rect(Rect2(x + i * _px(7), hc * 0.3, _px(5), hc * 0.42), TINTA if on else REJILLA)
	_txt(Vector2(x + _px(38), hc * 0.74), "%d%%" % int(eficiencia * 100), 11, TENUE)
	# logotipo «P» de Patógena
	draw_rect(Rect2(w - _px(18), _px(4), _px(3), _px(12)), TENUE)
	draw_arc(Vector2(w - _px(13.5), _px(7.8)), _px(3.8), -PI / 2, PI / 2, 12, TENUE, _px(2.5))
	return hc

## Pie: icono de entrada con existencias → barra de progreso → icono de salida.
func _pie(w: float, h: float) -> float:
	var hp := _px(30)
	var y0 := h - hp
	draw_rect(Rect2(0, y0, w, hp), Color(REJILLA, 0.35))
	var r: Array = RECETA[tipo]
	var ic := hp * 0.72
	_icono(r[0], Vector2(_px(14), y0 + hp / 2), ic, entradas == 0)
	_txt(Vector2(_px(26), y0 + hp * 0.68), "×%d" % entradas, 13, TINTA if entradas > 0 else C_ESTADO[2])
	var bx := _px(62)
	var bw := w - bx - _px(66)
	_barra(Rect2(bx, y0 + hp * 0.36, bw, hp * 0.28), progreso, TINTA)
	var fx := bx + bw + _px(4)
	draw_colored_polygon(PackedVector2Array([Vector2(fx, y0 + hp * 0.3), Vector2(fx + _px(7), y0 + hp * 0.5), Vector2(fx, y0 + hp * 0.7)]), TINTA)
	_icono(r[1], Vector2(w - _px(42), y0 + hp / 2), ic)
	_txt(Vector2(w - _px(30), y0 + hp * 0.68), "×%d" % salidas, 13, TINTA)
	return y0

func _aviso(cuerpo: Rect2) -> void:
	var c := cuerpo.get_center()
	var hh := minf(cuerpo.size.y, cuerpo.size.x * 0.3)
	if estado == 2:
		# falta material: icono de la entrada en contorno, tachado, y flechas pidiendo material
		var a := 0.5 + 0.5 * sin(_t * 6.0)
		draw_rect(cuerpo, Color(1.0, 0.7, 0.1, 0.1 * a))
		var r: Array = RECETA[tipo]
		_icono(r[0], c + Vector2(-hh * 0.6, 0), hh * 0.7, true)
		draw_line(c + Vector2(-hh * 0.9, hh * 0.34), c + Vector2(-hh * 0.3, -hh * 0.34), C_ESTADO[2], _px(3))
		var fx := c.x - hh * 0.05 + fmod(_t * 30.0, hh * 0.2)
		for k in 3:
			var x := fx + k * hh * 0.2
			draw_polyline(PackedVector2Array([Vector2(x, c.y - hh * 0.16), Vector2(x + hh * 0.11, c.y), Vector2(x, c.y + hh * 0.16)]), Color(C_ESTADO[2], 0.35 + 0.25 * k), _px(3))
		_txt(Vector2(c.x + hh * 0.7, c.y + _px(9)), "0/1", 24, C_ESTADO[2])
	elif estado == 3:
		var r := hh * 0.34
		var cc := c + Vector2(-hh * 0.55, 0)
		var tri := PackedVector2Array([cc + Vector2(0, -r), cc + Vector2(r * 1.1, r * 0.8), cc + Vector2(-r * 1.1, r * 0.8)])
		var pulso := 0.55 + 0.45 * (1.0 if fmod(_t, 0.5) < 0.3 else 0.0)
		draw_colored_polygon(tri, Color(C_ESTADO[3], pulso))
		draw_rect(Rect2(cc + Vector2(-_px(2.5), -r * 0.45), Vector2(_px(5), r * 0.72)), FONDO)
		draw_rect(Rect2(cc + Vector2(-_px(2.5), r * 0.4), Vector2(_px(5), _px(5))), FONDO)
		_txt(Vector2(c.x - hh * 0.05, c.y + _px(4)), "E-07", 26, C_ESTADO[3])
		# llave inglesa: hace falta un técnico
		var l := c + Vector2(hh * 0.95, 0)
		draw_line(l + Vector2(-_px(12), _px(10)), l + Vector2(_px(8), -_px(8)), TENUE, _px(4))
		draw_arc(l + Vector2(_px(11), -_px(11)), _px(6), -2.4, 2.0, 12, TENUE, _px(3))
		for i in 5:
			var y := cuerpo.position.y + fmod(_t * 70.0 + i * 41.0, cuerpo.size.y)
			draw_line(Vector2(cuerpo.position.x, y), Vector2(cuerpo.end.x, y), Color(1, 0.3, 0.2, 0.13), _px(2))

# ------------------------------------------------------------------ dibujo
func _draw() -> void:
	var w := size.x
	var h := size.y
	_u = minf(h / 160.0, w / 384.0)
	draw_rect(Rect2(Vector2.ZERO, size), FONDO)
	var paso := _px(14)
	var x := 0.0
	while x < w:
		draw_line(Vector2(x, 0), Vector2(x, h), Color(REJILLA, 0.3), 1.0)
		x += paso
	var y := 0.0
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), Color(REJILLA, 0.3), 1.0)
		y += paso
	var y0 := _cabecera(w)
	var y1 := _pie(w, h)
	var cuerpo := Rect2(_px(6), y0 + _px(4), w - _px(12), y1 - y0 - _px(8))
	if estado >= 2:
		_aviso(cuerpo)
		return
	match tipo:
		Tipo.CENTRIFUGA: _centrifuga(cuerpo)
		Tipo.SECUENCIADOR: _secuenciador(cuerpo)
		Tipo.BIORREACTOR: _biorreactor(cuerpo)

func _centrifuga(b: Rect2) -> void:
	# rotor visto desde arriba con 6 cestillos
	var r := b.size.y * 0.44
	var c := b.position + Vector2(r + _px(4), b.size.y / 2)
	draw_arc(c, r, 0, TAU, 48, TENUE, _px(2), true)
	var giro := _t * TAU * velocidad * 3.0
	for i in 6:
		var a := giro + i * TAU / 6.0
		var p := c + Vector2(cos(a), sin(a)) * r * 0.66
		draw_circle(p, r * 0.2, C_ICONO[Icono.SANGRE] if i % 2 == 0 else C_ICONO[Icono.PLASMA])
		draw_arc(p, r * 0.2, 0, TAU, 16, TINTA, _px(1), true)
	draw_circle(c, r * 0.16, TINTA)
	if velocidad > 0.3:
		draw_arc(c, r * 0.88, giro, giro + 1.2, 16, Color(TINTA, 0.35), _px(2), true)
	# datos: rpm grandes, fuerza g y temperatura
	var x0 := c.x + r + _px(12)
	var rpm := int(round(velocidad * 12400.0 / 10.0)) * 10
	_txt(Vector2(x0, b.position.y + b.size.y * 0.5), "%d" % rpm, 34, TINTA)
	_txt(Vector2(x0 + _px(100), b.position.y + b.size.y * 0.5), "rpm", 12, TENUE)
	_txt(Vector2(x0, b.position.y + b.size.y * 0.86), "%d ×g" % int(velocidad * 8900), 13, TENUE)
	_txt(Vector2(x0 + _px(72), b.position.y + b.size.y * 0.86), "4.0°C", 13, TENUE)
	# tiempo restante
	var ca := Vector2(b.end.x - _px(22), b.position.y + b.size.y * 0.4)
	_anillo(ca, _px(15), progreso, TINTA, _px(4))
	_txt(Vector2(ca.x - _px(22), b.end.y - _px(1)), "%.1fs" % ((1.0 - progreso) * ciclo), 11, TENUE, HORIZONTAL_ALIGNMENT_CENTER, _px(44))

func _secuenciador(b: Rect2) -> void:
	# cromatograma: cada pico es una base con su color
	var g := Rect2(b.position, Vector2(b.size.x, b.size.y * 0.64))
	var esp := _px(15)
	var desp := _t * 40.0 * maxf(velocidad, 0.05)
	var c0 := PackedVector2Array()
	var c1 := PackedVector2Array()
	var c2 := PackedVector2Array()
	var c3 := PackedVector2Array()
	var muestras := 140
	for i in muestras:
		var x := g.position.x + g.size.x * i / float(muestras - 1)
		var xs := x + desp
		var idx := int(floor(xs / esp))
		var vals := [0.0, 0.0, 0.0, 0.0]
		for d in [-1, 0, 1]:
			var k: int = idx + d
			var base := _hash(k) % 4
			var alto := 0.45 + 0.55 * float(_hash(k * 7 + 3) % 100) / 100.0
			var dx := (xs - (k + 0.5) * esp) / (esp * 0.28)
			vals[base] = maxf(vals[base], exp(-dx * dx) * alto)
		var base_y := g.end.y - _px(2)
		var esc := g.size.y - _px(6)
		c0.append(Vector2(x, base_y - vals[0] * esc))
		c1.append(Vector2(x, base_y - vals[1] * esc))
		c2.append(Vector2(x, base_y - vals[2] * esc))
		c3.append(Vector2(x, base_y - vals[3] * esc))
	draw_polyline(c0, BASES[0], _px(1.6), true)
	draw_polyline(c1, BASES[1], _px(1.6), true)
	draw_polyline(c2, BASES[2], _px(1.6), true)
	draw_polyline(c3, BASES[3], _px(1.6), true)
	draw_line(Vector2(g.position.x, g.end.y), Vector2(g.end.x, g.end.y), TENUE, 1.0)
	# letras bajo cada pico (bases leídas)
	var y := g.end.y + _px(13)
	var k0 := int(floor(desp / esp))
	var n := int(g.size.x / esp) + 2
	for i in n:
		var k := k0 + i
		var x := g.position.x + (k + 0.5) * esp - desp
		if x < g.position.x or x > g.end.x - _px(4):
			continue
		var base := _hash(k) % 4
		_txt(Vector2(x - _px(4), y), "ACGT"[base], 11, BASES[base])
	# calidad y longitud leída
	_txt(Vector2(b.end.x - _px(118), b.end.y), "Q%d" % (32 + int(sin(_t) * 3)), 12, TENUE)
	_txt(Vector2(b.end.x - _px(76), b.end.y), "%d pb" % int(progreso * 1200), 12, TINTA)

func _biorreactor(b: Rect2) -> void:
	# nivel del depósito con burbujas
	var t := Rect2(b.position, Vector2(b.size.x * 0.16, b.size.y))
	draw_rect(t, TENUE, false, _px(1.5))
	var nivel := 0.3 + progreso * 0.6
	var lleno := Rect2(t.position + Vector2(_px(2), t.size.y * (1 - nivel)), Vector2(t.size.x - _px(4), t.size.y * nivel - _px(2)))
	draw_rect(lleno, Color(color_producto, 0.85))
	for i in 5:
		var by := fmod(_t * _px(22) + i * _px(27), lleno.size.y)
		draw_circle(Vector2(lleno.position.x + _px(4) + fmod(i * _px(9), maxf(lleno.size.x - _px(8), 1)), lleno.end.y - by), _px(1.8), Color(1, 1, 1, 0.55))
	for i in range(1, 5):
		var yy := t.position.y + t.size.y * i / 5.0
		draw_line(Vector2(t.end.x, yy), Vector2(t.end.x + _px(5), yy), TENUE, 1.0)
	# lecturas
	var x0 := t.end.x + _px(12)
	_txt(Vector2(x0, b.position.y + _px(26)), "%.1f°C" % (37.0 + sin(_t * 0.7) * 0.15), 26, TINTA)
	_txt(Vector2(x0, b.position.y + _px(46)), "pH %.2f" % (7.2 + sin(_t * 0.4) * 0.03), 13, TENUE)
	_txt(Vector2(x0 + _px(72), b.position.y + _px(46)), "O₂ %d%%" % (40 + int(sin(_t * 0.3) * 4)), 13, TENUE)
	_txt(Vector2(x0 + _px(142), b.position.y + _px(46)), "%d rpm" % int(velocidad * 120), 13, TENUE)
	# curva de crecimiento (sigmoide hasta el progreso actual)
	var g := Rect2(x0, b.position.y + _px(56), b.end.x - x0 - _px(58), b.size.y - _px(56))
	draw_rect(g, Color(REJILLA, 0.5), false, 1.0)
	var pts := PackedVector2Array()
	var n := 48
	for i in n + 1:
		var u := i / float(n)
		if u > progreso:
			break
		var v := 1.0 / (1.0 + exp(-(u - 0.45) * 10.0))
		pts.append(Vector2(g.position.x + g.size.x * u, g.end.y - _px(2) - v * (g.size.y - _px(6))))
	if pts.size() > 1:
		draw_polyline(pts, color_producto.lightened(0.3), _px(2), true)
		draw_circle(pts[pts.size() - 1], _px(3), TINTA)
	# anillo de progreso del vial
	var c := Vector2(b.end.x - _px(26), g.get_center().y)
	_anillo(c, _px(19), progreso, color_producto.lightened(0.2), _px(5))
	_icono(Icono.VIAL, c, _px(20))
