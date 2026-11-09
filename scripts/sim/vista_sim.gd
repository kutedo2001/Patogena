extends Node2D
## Vista esquemática de la simulación (herramienta de depuración de P4.1, no es el juego):
## casillas, cintas con su sentido, máquinas con progreso y color de estado, objetos y contadores.

const COLOR := {"tubo_sangre": Color(0.8, 0.1, 0.12), "tubo_plasma": Color(0.98, 0.78, 0.2), "placa_petri": Color(0.85, 0.7, 0.4),
	"tubo_adn": Color(0.3, 1.0, 0.45), "garrafa_agua": Color(0.55, 0.8, 1.0), "frasco_reactivo": Color(0.45, 0.3, 1.0),
	"bolsa_suero": Color(1.0, 0.9, 0.55), "vial_mutacion": Color(0.6, 1.0, 0.2), "caja_vacunas": Color(0.95, 0.95, 0.95)}
const C_ESTADO := [Color(0.4, 0.4, 0.4), Color(0.3, 1.0, 0.45), Color(1.0, 0.7, 0.1), Color(1.0, 0.45, 0.1)]
var fab: Fabrica
var escala := 56.0
var origen := Vector2(15.0, 7.5)
var f_txt: Font

func _ready() -> void:
	f_txt = load("res://assets/fuentes/Inter-SemiBold.otf")
	fab = load("res://tools/pruebas/prueba_fabrica.gd").montar_cadenas()

func _process(dt: float) -> void:
	fab.avanzar(dt * 3.0)
	queue_redraw()

func _p(c: Vector2) -> Vector2:
	return (c + origen) * escala

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0.07, 0.09, 0.1))
	for x in range(-14, 12):
		for z in range(-7, 9):
			draw_rect(Rect2(_p(Vector2(x, z)), Vector2(escala, escala)), Color(1, 1, 1, 0.04), false, 1.0)
	var hechas := {}
	for e in fab.entidades:
		if hechas.has(e):
			continue
		hechas[e] = true
		if e is Fabrica.Cinta:
			var c: Vector2 = Vector2(e.casillas[0])
			draw_rect(Rect2(_p(c) + Vector2(3, 3), Vector2(escala - 6, escala - 6)), Color(0.2, 0.22, 0.24))
			var d := Vector2(Fabrica.DIRS[e.giro])
			var m := _p(c) + Vector2(escala, escala) * 0.5
			draw_line(m - d * escala * 0.3, m + d * escala * 0.3, Color(1, 1, 1, 0.12), 3.0)
			for o in e.objetos:
				var pos := m + d * escala * (float(o[1]) - 0.5)
				draw_circle(pos, escala * 0.17, COLOR.get(o[0], Color.MAGENTA))
		elif e is Fabrica.MaquinaSim:
			var mn: Vector2 = Vector2(e.casillas[0])
			var mx: Vector2 = mn
			for c in e.casillas:
				mn = Vector2(minf(mn.x, c.x), minf(mn.y, c.y))
				mx = Vector2(maxf(mx.x, c.x), maxf(mx.y, c.y))
			var r := Rect2(_p(mn) + Vector2(4, 4), (mx - mn + Vector2.ONE) * escala - Vector2(8, 8))
			draw_rect(r, Color(0.88, 0.89, 0.87))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), Color(0.4, 0.77, 0.9))
			draw_rect(Rect2(r.position + Vector2(6, r.size.y - 14), Vector2((r.size.x - 12) * e.fraccion(), 8)), Color(0.2, 0.6, 0.5))
			draw_circle(r.position + Vector2(r.size.x - 10, 16), 6, C_ESTADO[e.estado])
			draw_string(f_txt, r.position + Vector2(6, 24), e.tipo, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 12, 12, Color(0.15, 0.17, 0.18))
			var k := 0
			for o in e.entrada:
				for n in e.entrada[o]:
					draw_circle(r.position + Vector2(10 + k * 9, 38), 4, COLOR.get(o, Color.MAGENTA))
					k += 1
		elif e is Fabrica.Fuente or e is Fabrica.Almacen:
			var c2: Vector2 = Vector2(e.casillas[0])
			draw_rect(Rect2(_p(c2) + Vector2(6, 6), Vector2(escala - 12, escala - 12)), Color(0.3, 0.55, 0.5) if e is Fabrica.Fuente else Color(0.6, 0.48, 0.3))
			if e is Fabrica.Almacen:
				draw_string(f_txt, _p(c2) + Vector2(10, 28), str(e.contenido.size()), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	var y := 24.0
	draw_string(f_txt, Vector2(16, y), "Simulación P4.1 · t = %.0f s · mutaciones %d" % [fab.tiempo, fab.mutaciones], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 1.0, 0.88))
	for o in fab.producido:
		y += 20
		draw_string(f_txt, Vector2(16, y), "%s: %d" % [o, fab.producido[o]], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR.get(o, Color(0.8, 0.8, 0.8)))
