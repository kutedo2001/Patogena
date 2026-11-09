class_name PantallaCepa
extends Control
## Pantalla viva de la mesa de ingeniería genética (V1.14): el árbol de la cepa en tres columnas
## (hechas en verde, la elegida en ámbar con su progreso, bloqueadas apagadas), una hélice de ADN que
## gira y las cifras del mundo. Sin texto en el mundo más allá de lo que hay en la propia pantalla.

const FONDO := Color(0.03, 0.075, 0.085)
const TINTA := Color(0.6, 1.0, 0.88)
const TENUE := Color(0.25, 0.45, 0.42)
const OK := Color(0.3, 1.0, 0.45)
const AMBAR := Color(1.0, 0.7, 0.1)
const F := preload("res://assets/fuentes/Inter-SemiBold.otf")

var juego: Juego
var _t := 0.0

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), FONDO)
	for k in 12:
		draw_line(Vector2(0, s.y * k / 12.0), Vector2(s.x, s.y * k / 12.0), Color(0.08, 0.16, 0.16), 1.0)
	if juego == null:
		return
	var f := juego.fab
	# hélice a la izquierda
	var hx := s.x * 0.08
	for k in 28:
		var y := s.y * (0.1 + 0.8 * k / 27.0)
		var a := _t * 2.0 + k * 0.45
		var x1 := hx + cos(a) * s.x * 0.035
		var x2 := hx - cos(a) * s.x * 0.035
		draw_line(Vector2(x1, y), Vector2(x2, y), TENUE, 1.5)
		draw_circle(Vector2(x1, y), 2.5, OK if sin(a) > 0 else TENUE)
		draw_circle(Vector2(x2, y), 2.5, AMBAR if sin(a) < 0 else TENUE)
	# tres ramas
	var ramas := ["transmision", "sintomas", "resistencias"]
	var x0 := s.x * 0.18
	var ancho := s.x * 0.6 / 3.0
	for ri in 3:
		var cx := x0 + ancho * (ri + 0.5)
		draw_string(F, Vector2(cx - ancho * 0.45, s.y * 0.1), tr("RAMA_" + ramas[ri].to_upper()).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, ancho * 0.9, 13, TINTA)
		var lista: Array = []
		for m in Fabrica.datos.cepa.mejoras:
			if m.rama == ramas[ri]:
				lista.append(m)
		for k in lista.size():
			var m: Dictionary = lista[k]
			var y := s.y * (0.18 + 0.75 * k / maxf(lista.size() - 1, 1))
			var c := TENUE
			var r := 7.0
			if m.id in f.cepa_hechas:
				c = OK
			elif m.id == f.cepa_actual:
				c = AMBAR
				r = 8.0 + sin(_t * 5.0) * 1.5
				var pr := juego.progreso_cepa()
				draw_arc(Vector2(cx, y), 13.0, -PI * 0.5, -PI * 0.5 + TAU * float(pr.x) / maxf(pr.y, 1), 32, AMBAR, 3.0)
			if k > 0:
				var y0 := s.y * (0.18 + 0.75 * (k - 1) / maxf(lista.size() - 1, 1))
				draw_line(Vector2(cx, y0 + 8), Vector2(cx, y - 8), OK if m.id in f.cepa_hechas else TENUE, 2.0)
			draw_circle(Vector2(cx, y), r, c)
	# cifras del mundo a la derecha
	var m2 := juego.mundo
	var xr := s.x * 0.8
	var datos := [["%", m2.fraccion_infectada() * 100.0, TINTA], ["Z", m2.fraccion_zombi() * 100.0, OK], ["+", m2.cura * 100.0, Color(0.45, 0.7, 1.0)]]
	for i in 3:
		var y := s.y * (0.25 + i * 0.25)
		draw_string(F, Vector2(xr, y), str(datos[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, datos[i][2])
		draw_string(F, Vector2(xr + 22, y), String.num(datos[i][1], 1).replace(".", ","), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, datos[i][2])
		draw_rect(Rect2(xr, y + 8, s.x * 0.16, 5), TENUE)
		draw_rect(Rect2(xr, y + 8, s.x * 0.16 * clampf(datos[i][1] / 100.0, 0.0, 1.0), 5), datos[i][2])
