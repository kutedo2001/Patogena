class_name IconosTP
extends RefCounted
## Iconos vectoriales de la interfaz estilo Two Point (R2.7), dibujados en cualquier CanvasItem.

static func dibujar(ci: CanvasItem, c: Vector2, s: float, k: String, col: Color) -> void:
	match k:
		"salas":   # plano de una sala con puerta
			ci.draw_rect(Rect2(c - Vector2(s, s * 0.8), Vector2(s * 2, s * 1.6)), col, false, s * 0.22)
			ci.draw_line(c + Vector2(-s * 0.1, s * 0.8), c + Vector2(s * 0.6, s * 0.8), Color("4f9b8f"), s * 0.3)
			ci.draw_line(c + Vector2(0, -s * 0.8), c + Vector2(0, s * 0.1), col, s * 0.18)
		"objetos":   # planta en maceta
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, s * 0.2), c + Vector2(s * 0.55, s * 0.2), c + Vector2(s * 0.4, s), c + Vector2(-s * 0.4, s)]), col)
			for a in [-0.7, 0.0, 0.7]:
				var d := Vector2(sin(a), -cos(a))
				ci.draw_circle(c + Vector2(0, -s * 0.15) + d * s * 0.55, s * 0.32, col)
		"personal":   # persona con bata
			ci.draw_circle(c + Vector2(0, -s * 0.5), s * 0.38, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, s), c + Vector2(-s * 0.55, s * 0.05), c + Vector2(s * 0.55, s * 0.05), c + Vector2(s * 0.8, s)]), col)
			ci.draw_line(c + Vector2(0, s * 0.1), c + Vector2(0, s), Color("2c6b63"), s * 0.12)
		"info":   # portapapeles
			ci.draw_rect(Rect2(c - Vector2(s * 0.7, s * 0.8), Vector2(s * 1.4, s * 1.8)), col, true)
			ci.draw_rect(Rect2(c - Vector2(s * 0.3, s * 1.0), Vector2(s * 0.6, s * 0.35)), Color("4f9b8f"), true)
			for i in 3:
				ci.draw_line(c + Vector2(-s * 0.4, -s * 0.2 + i * s * 0.42), c + Vector2(s * 0.4, -s * 0.2 + i * s * 0.42), Color("2c6b63"), s * 0.14)
		"mapa":
			ci.draw_circle(c, s * 0.9, col)
			ci.draw_arc(c, s * 0.9, 0, TAU, 32, Color("2c6b63"), s * 0.12)
			ci.draw_line(c + Vector2(-s * 0.9, 0), c + Vector2(s * 0.9, 0), Color("2c6b63"), s * 0.1)
			ci.draw_arc(c, s * 0.45, -PI / 2, PI / 2, 16, Color("2c6b63"), s * 0.1)
		"pausa":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.6), Vector2(s * 0.38, s * 1.2)), col)
			ci.draw_rect(Rect2(c + Vector2(s * 0.17, -s * 0.6), Vector2(s * 0.38, s * 1.2)), col)
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.65), c + Vector2(s * 0.65, 0), c + Vector2(-s * 0.45, s * 0.65)]), col)
		"rapido":
			for dx in [-0.45, 0.25]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2((dx - 0.25) * s, -s * 0.6), c + Vector2((dx + 0.45) * s, 0), c + Vector2((dx - 0.25) * s, s * 0.6)]), col)
		"estrella":
			var pts := PackedVector2Array()
			for i in 10:
				var rr := s if i % 2 == 0 else s * 0.45
				var a := -PI / 2 + i * PI / 5
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			ci.draw_colored_polygon(pts, col)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.6, 0), c + Vector2(-s * 0.15, s * 0.5), c + Vector2(s * 0.7, -s * 0.5)]), col, s * 0.3, true)
		"centrifuga":
			ci.draw_circle(c, s, col)
			ci.draw_circle(c, s * 0.7, Color("4f9b8f"))
			for i in 6:
				var a := i * TAU / 6
				ci.draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.42, s * 0.13, col)
		"gradilla":
			ci.draw_rect(Rect2(c + Vector2(-s, -s * 0.1), Vector2(s * 2, s * 0.5)), col)
			for i in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.75 + i * s * 0.6, -s * 0.8), Vector2(s * 0.3, s * 0.8)), Color("b71c1c"))
		"bolsa":
			ci.draw_circle(c + Vector2(0, s * 0.15), s * 0.75, Color("6d0e14"))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, -s), Vector2(s * 0.4, s * 0.5)), col)
		"plasma":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.65, s * 0.2), c + Vector2(0, s), c + Vector2(-s * 0.65, s * 0.2)]), Color("f4b740"))
		"camilla":
			ci.draw_rect(Rect2(c + Vector2(-s, -s * 0.2), Vector2(s * 2, s * 0.45)), col)
			ci.draw_line(c + Vector2(-s * 0.8, s * 0.25), c + Vector2(-s * 0.8, s), col, s * 0.15)
			ci.draw_line(c + Vector2(s * 0.8, s * 0.25), c + Vector2(s * 0.8, s), col, s * 0.15)
			ci.draw_circle(c + Vector2(-s * 0.6, -s * 0.45), s * 0.3, col)
		"banco":
			ci.draw_rect(Rect2(c + Vector2(-s, -s * 0.1), Vector2(s * 2, s * 0.35)), col)
			ci.draw_rect(Rect2(c + Vector2(-s, -s * 0.8), Vector2(s * 2, s * 0.3)), col)
			ci.draw_line(c + Vector2(-s * 0.8, s * 0.25), c + Vector2(-s * 0.8, s), col, s * 0.15)
			ci.draw_line(c + Vector2(s * 0.8, s * 0.25), c + Vector2(s * 0.8, s), col, s * 0.15)
		"estrella_obl":
			IconosTP.dibujar(ci, c, s, "estrella", Color("f2b630"))
		"x":
			ci.draw_line(c + Vector2(-s, -s) * 0.6, c + Vector2(s, s) * 0.6, col, s * 0.3)
			ci.draw_line(c + Vector2(s, -s) * 0.6, c + Vector2(-s, s) * 0.6, col, s * 0.3)

