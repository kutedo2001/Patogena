class_name ResalteHUD
extends Control
## Marco ámbar que late alrededor del botón o casilla que pide el tutorial (V1.18), con una flecha.

var objetivo := Rect2()
var _t := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func _draw() -> void:
	var k := 0.5 + 0.5 * sin(_t * 6.0)
	var esc := get_global_transform().affine_inverse()
	var r := esc * objetivo
	var c := Color(1.0, 0.75, 0.15, 0.6 + 0.4 * k)
	draw_rect(r.grow(4 + k * 4), c, false, 3.0)
	var p := Vector2(r.get_center().x, r.position.y - 18 - k * 8)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, 12), p + Vector2(-10, -4), p + Vector2(10, -4)]), c)
