class_name LisaHUD
extends Control
## LISA en el HUD: un monitor pequeño con su «cara» de IA (dos ojos de barra y una onda de voz),
## dibujada con formas planas de interfaz, no un rostro humano.

var _t := 0.0

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.25, 0.28, 0.29))
	draw_rect(Rect2(Vector2(4, 4), s - Vector2(8, 8)), Color(0.03, 0.075, 0.085))
	var c := Color(0.6, 1.0, 0.88)
	var parpadeo := 0.15 if fmod(_t, 4.0) < 0.12 else 1.0
	for x in [0.33, 0.67]:
		draw_rect(Rect2(Vector2(s.x * x - 5, s.y * 0.32), Vector2(10, 10 * parpadeo)), c)
	var pts := PackedVector2Array()
	for i in 24:
		var t := i / 23.0
		pts.append(Vector2(s.x * (0.2 + 0.6 * t), s.y * 0.7 + sin(t * 18.0 + _t * 9.0) * 4.0 * sin(t * PI)))
	draw_polyline(pts, c, 2.0, true)
