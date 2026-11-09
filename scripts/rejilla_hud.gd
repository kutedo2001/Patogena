class_name RejillaHUD
extends Control
## Rejilla tenue y reflejo de cristal de las pantallas del HUD (como las de las máquinas).

const PASO := 16.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = false

func _draw() -> void:
	var c := Color(0.09, 0.2, 0.2, 0.45)
	var x := PASO
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), c, 1.0)
		x += PASO
	var y := PASO
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), c, 1.0)
		y += PASO
	# reflejo diagonal suave en la parte alta
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x * 0.55, 0), Vector2(size.x * 0.35, size.y * 0.45), Vector2(0, size.y * 0.45)]), Color(1, 1, 1, 0.025))
