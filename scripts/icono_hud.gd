class_name IconoHUD
extends Control
## Iconos vectoriales del HUD dibujados con primitivas (nítidos a cualquier escala).

@export var nombre := "energia"
@export var color := Color(0.9, 0.93, 0.94)

func _init(n := "energia", c := Color(0.9, 0.93, 0.94), lado := 20.0) -> void:
	nombre = n
	color = c
	custom_minimum_size = Vector2(lado, lado)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var g := maxf(1.5, s * 0.09)
	match nombre:
		"energia":
			draw_colored_polygon(PackedVector2Array([p.call(0.58, 0.04), p.call(0.18, 0.56), p.call(0.46, 0.56), p.call(0.38, 0.96), p.call(0.82, 0.4), p.call(0.53, 0.4)]), color)
		"dinero":
			draw_arc(p.call(0.5, 0.5), s * 0.42, 0, TAU, 32, color, g, true)
			draw_arc(p.call(0.56, 0.5), s * 0.2, PI * 0.3, PI * 1.7, 16, color, g, true)
			draw_line(p.call(0.26, 0.44), p.call(0.5, 0.44), color, g * 0.8)
			draw_line(p.call(0.26, 0.57), p.call(0.5, 0.57), color, g * 0.8)
		"mundo":
			draw_arc(p.call(0.5, 0.5), s * 0.42, 0, TAU, 32, color, g, true)
			draw_line(p.call(0.08, 0.5), p.call(0.92, 0.5), color, g * 0.7)
			for k in [-1.0, 1.0]:
				var pts := PackedVector2Array()
				for i in 17:
					var a := -PI / 2 + PI * i / 16.0
					pts.append(p.call(0.5 + k * 0.2 * cos(a), 0.5 + 0.42 * sin(a)))
				draw_polyline(pts, color, g * 0.7, true)
		"cura":
			var esc := PackedVector2Array([p.call(0.5, 0.05), p.call(0.88, 0.2), p.call(0.82, 0.62), p.call(0.5, 0.95), p.call(0.18, 0.62), p.call(0.12, 0.2)])
			draw_colored_polygon(esc, color)
			var f := Color(0.08, 0.1, 0.11)
			draw_rect(Rect2(p.call(0.43, 0.28), Vector2(s * 0.14, s * 0.42)), f)
			draw_rect(Rect2(p.call(0.29, 0.42), Vector2(s * 0.42, s * 0.14)), f)
		"fecha":
			draw_rect(Rect2(p.call(0.1, 0.18), Vector2(s * 0.8, s * 0.72)), color, false, g)
			draw_rect(Rect2(p.call(0.1, 0.18), Vector2(s * 0.8, s * 0.2)), color)
			for x in [0.3, 0.7]:
				draw_line(p.call(x, 0.06), p.call(x, 0.26), color, g)
			for i in 3:
				for j in 2:
					draw_rect(Rect2(p.call(0.22 + i * 0.2, 0.5 + j * 0.18), Vector2(s * 0.12, s * 0.1)), color)
		"correo":
			draw_rect(Rect2(p.call(0.08, 0.22), Vector2(s * 0.84, s * 0.58)), color, false, g)
			draw_polyline(PackedVector2Array([p.call(0.08, 0.24), p.call(0.5, 0.56), p.call(0.92, 0.24)]), color, g, true)
		"cepa":
			draw_circle(p.call(0.5, 0.5), s * 0.24, color)
			for i in 8:
				var a := TAU * i / 8.0
				var d := Vector2(cos(a), sin(a))
				draw_line(p.call(0.5, 0.5) + d * s * 0.22, p.call(0.5, 0.5) + d * s * 0.4, color, g)
				draw_circle(p.call(0.5, 0.5) + d * s * 0.42, s * 0.06, color)
		"hitos":
			draw_line(p.call(0.22, 0.06), p.call(0.22, 0.95), color, g)
			draw_colored_polygon(PackedVector2Array([p.call(0.24, 0.08), p.call(0.86, 0.22), p.call(0.24, 0.5)]), color)
		"produccion":
			for i in 4:
				var h: float = [0.3, 0.55, 0.42, 0.78][i]
				draw_rect(Rect2(p.call(0.1 + i * 0.22, 0.92 - h), Vector2(s * 0.15, s * h)), color)
		"pausa":
			draw_rect(Rect2(p.call(0.24, 0.18), Vector2(s * 0.16, s * 0.64)), color)
			draw_rect(Rect2(p.call(0.6, 0.18), Vector2(s * 0.16, s * 0.64)), color)
		"play":
			draw_colored_polygon(PackedVector2Array([p.call(0.28, 0.16), p.call(0.82, 0.5), p.call(0.28, 0.84)]), color)
		"rapido":
			draw_colored_polygon(PackedVector2Array([p.call(0.08, 0.2), p.call(0.48, 0.5), p.call(0.08, 0.8)]), color)
			draw_colored_polygon(PackedVector2Array([p.call(0.48, 0.2), p.call(0.88, 0.5), p.call(0.48, 0.8)]), color)
		"candado":
			draw_arc(p.call(0.5, 0.42), s * 0.2, PI, TAU, 16, color, g, true)
			draw_line(p.call(0.3, 0.42), p.call(0.3, 0.5), color, g)
			draw_line(p.call(0.7, 0.42), p.call(0.7, 0.5), color, g)
			draw_rect(Rect2(p.call(0.2, 0.5), Vector2(s * 0.6, s * 0.42)), color)
		"flecha":
			draw_line(p.call(0.08, 0.5), p.call(0.8, 0.5), color, g)
			draw_colored_polygon(PackedVector2Array([p.call(0.64, 0.26), p.call(0.94, 0.5), p.call(0.64, 0.74)]), color)
		"reloj":
			draw_arc(p.call(0.5, 0.5), s * 0.4, 0, TAU, 28, color, g, true)
			draw_line(p.call(0.5, 0.5), p.call(0.5, 0.24), color, g)
			draw_line(p.call(0.5, 0.5), p.call(0.7, 0.6), color, g)
		"check":
			draw_polyline(PackedVector2Array([p.call(0.16, 0.52), p.call(0.4, 0.76), p.call(0.86, 0.24)]), color, g * 1.3, true)
		"punto":
			draw_circle(p.call(0.5, 0.5), s * 0.3, color)
		"cerrar":
			draw_line(p.call(0.22, 0.22), p.call(0.78, 0.78), color, g * 1.4, true)
			draw_line(p.call(0.78, 0.22), p.call(0.22, 0.78), color, g * 1.4, true)
		"mover":
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				var c: Vector2 = p.call(0.5, 0.5)
				draw_line(c, c + d * s * 0.4, color, g)
				var t: Vector2 = Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([c + d * s * 0.48, c + d * s * 0.3 + t * s * 0.13, c + d * s * 0.3 - t * s * 0.13]), color)
		"quitar":
			draw_rect(Rect2(p.call(0.24, 0.3), Vector2(s * 0.52, s * 0.62)), color, false, g)
			draw_line(p.call(0.14, 0.22), p.call(0.86, 0.22), color, g)
			draw_line(p.call(0.4, 0.1), p.call(0.6, 0.1), color, g)
			for x in [0.4, 0.6]:
				draw_line(p.call(x, 0.42), p.call(x, 0.8), color, g * 0.8)
		_:
			draw_circle(p.call(0.5, 0.5), s * 0.3, color)
