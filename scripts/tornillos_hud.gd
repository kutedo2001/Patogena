class_name TornillosHUD
extends Control
## Cuatro tornillos de cabeza hexagonal en las esquinas de una carcasa del HUD.

var margen := 14.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var d := margen - 7.0
	for c in [Vector2(-d, -d), Vector2(size.x + d, -d), Vector2(-d, size.y + d), Vector2(size.x + d, size.y + d)]:
		_tornillo(c, 3.6)

func _tornillo(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(0.6, 0.8), r + 1.2, Color(0, 0, 0, 0.18))        # sombra
	draw_circle(c, r + 1.0, Color(0.7, 0.72, 0.73))                          # arandela
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, Color(0.58, 0.61, 0.63))
	draw_line(c + Vector2(-r * 0.6, -r * 0.2), c + Vector2(r * 0.6, r * 0.2), Color(0.38, 0.4, 0.42), 1.2)
	draw_circle(c + Vector2(-r * 0.3, -r * 0.4), r * 0.25, Color(1, 1, 1, 0.5))  # brillo
