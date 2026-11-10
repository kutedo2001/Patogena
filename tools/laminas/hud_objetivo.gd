extends Control
## Interfaz estilo Two Point para la pantalla objetivo (R1.3). Maqueta dibujada: menú redondo abajo a la izquierda,
## dinero, reputación, fecha y velocidad abajo a la derecha, objetivos arriba a la derecha y ficha de la sala
## seleccionada con pestañas y botones de acción. Paneles gruesos redondeados, crema con borde verde y acento naranja.

const CREMA := Color("f7f3e8")
const CREMA2 := Color("ebe5d4")
const VERDE := Color("2c6b63")
const VERDE2 := Color("4f9b8f")
const NARANJA := Color("f2862a")
const TINTA := Color("22302d")
const TENUE := Color("6c7a76")
const ROJO := Color("c9302c")
var F_B: Font
var F_S: Font
var F_M: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	F_B = load("res://assets/fuentes/Inter-Bold.otf")
	F_S = load("res://assets/fuentes/Inter-SemiBold.otf")
	F_M = load("res://assets/fuentes/Inter-Medium.otf")

func _panel(r: Rect2, radio := 22.0, fondo := CREMA, borde := VERDE, grueso := 5) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fondo
	sb.border_color = borde
	sb.set_border_width_all(grueso)
	sb.set_corner_radius_all(int(radio))
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true
	draw_style_box(sb, r)

func _txt(p: Vector2, t: String, tam: int, f: Font, c := TINTA, ancho := -1.0, alin := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(f, p, t, alin, ancho, tam, c)

func _barra(r: Rect2, k: float, c := VERDE2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREMA2
	sb.set_corner_radius_all(int(r.size.y / 2))
	draw_style_box(sb, r)
	var sb2 := sb.duplicate()
	sb2.bg_color = c
	draw_style_box(sb2, Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * k), r.size.y)))

func _boton_redondo(c: Vector2, r: float, color: Color, icono: String, etiqueta: String) -> void:
	draw_circle(c + Vector2(0, 4), r, Color(0, 0, 0, 0.25))
	draw_circle(c, r, VERDE)
	draw_circle(c, r - 5, color)
	draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.35, Color(1, 1, 1, 0.12))
	_icono(c, r * 0.5, icono, CREMA)
	_txt(c + Vector2(-60, r + 26), etiqueta, 17, F_B, TINTA, 120, HORIZONTAL_ALIGNMENT_CENTER)

func _icono(c: Vector2, s: float, k: String, col: Color) -> void:
	match k:
		"salas":   # plano de una sala con puerta
			draw_rect(Rect2(c - Vector2(s, s * 0.8), Vector2(s * 2, s * 1.6)), col, false, s * 0.22)
			draw_line(c + Vector2(-s * 0.1, s * 0.8), c + Vector2(s * 0.6, s * 0.8), VERDE2, s * 0.3)
			draw_line(c + Vector2(0, -s * 0.8), c + Vector2(0, s * 0.1), col, s * 0.18)
		"objetos":   # planta en maceta
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, s * 0.2), c + Vector2(s * 0.55, s * 0.2), c + Vector2(s * 0.4, s), c + Vector2(-s * 0.4, s)]), col)
			for a in [-0.7, 0.0, 0.7]:
				var d := Vector2(sin(a), -cos(a))
				draw_circle(c + Vector2(0, -s * 0.15) + d * s * 0.55, s * 0.32, col)
		"personal":   # persona con bata
			draw_circle(c + Vector2(0, -s * 0.5), s * 0.38, col)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, s), c + Vector2(-s * 0.55, s * 0.05), c + Vector2(s * 0.55, s * 0.05), c + Vector2(s * 0.8, s)]), col)
			draw_line(c + Vector2(0, s * 0.1), c + Vector2(0, s), VERDE, s * 0.12)
		"info":   # portapapeles
			draw_rect(Rect2(c - Vector2(s * 0.7, s * 0.8), Vector2(s * 1.4, s * 1.8)), col, true)
			draw_rect(Rect2(c - Vector2(s * 0.3, s * 1.0), Vector2(s * 0.6, s * 0.35)), VERDE2, true)
			for i in 3:
				draw_line(c + Vector2(-s * 0.4, -s * 0.2 + i * s * 0.42), c + Vector2(s * 0.4, -s * 0.2 + i * s * 0.42), VERDE, s * 0.14)
		"mapa":
			draw_circle(c, s * 0.9, col)
			draw_arc(c, s * 0.9, 0, TAU, 32, VERDE, s * 0.12)
			draw_line(c + Vector2(-s * 0.9, 0), c + Vector2(s * 0.9, 0), VERDE, s * 0.1)
			draw_arc(c, s * 0.45, -PI / 2, PI / 2, 16, VERDE, s * 0.1)
		"pausa":
			draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.6), Vector2(s * 0.38, s * 1.2)), col)
			draw_rect(Rect2(c + Vector2(s * 0.17, -s * 0.6), Vector2(s * 0.38, s * 1.2)), col)
		"play":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.65), c + Vector2(s * 0.65, 0), c + Vector2(-s * 0.45, s * 0.65)]), col)
		"rapido":
			for dx in [-0.45, 0.25]:
				draw_colored_polygon(PackedVector2Array([c + Vector2((dx - 0.25) * s, -s * 0.6), c + Vector2((dx + 0.45) * s, 0), c + Vector2((dx - 0.25) * s, s * 0.6)]), col)
		"estrella":
			var pts := PackedVector2Array()
			for i in 10:
				var rr := s if i % 2 == 0 else s * 0.45
				var a := -PI / 2 + i * PI / 5
				pts.append(c + Vector2(cos(a), sin(a)) * rr)
			draw_colored_polygon(pts, col)
		"check":
			draw_polyline(PackedVector2Array([c + Vector2(-s * 0.6, 0), c + Vector2(-s * 0.15, s * 0.5), c + Vector2(s * 0.7, -s * 0.5)]), col, s * 0.3, true)
		"centrifuga":
			draw_circle(c, s, col)
			draw_circle(c, s * 0.7, VERDE2)
			for i in 6:
				var a := i * TAU / 6
				draw_circle(c + Vector2(cos(a), sin(a)) * s * 0.42, s * 0.13, col)
		"gradilla":
			draw_rect(Rect2(c + Vector2(-s, -s * 0.1), Vector2(s * 2, s * 0.5)), col)
			for i in 3:
				draw_rect(Rect2(c + Vector2(-s * 0.75 + i * s * 0.6, -s * 0.8), Vector2(s * 0.3, s * 0.8)), Color("b71c1c"))
		"bolsa":
			draw_circle(c + Vector2(0, s * 0.15), s * 0.75, Color("6d0e14"))
			draw_rect(Rect2(c + Vector2(-s * 0.2, -s), Vector2(s * 0.4, s * 0.5)), col)
		"plasma":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.65, s * 0.2), c + Vector2(0, s), c + Vector2(-s * 0.65, s * 0.2)]), Color("f4b740"))

func _draw() -> void:
	_menu_principal()
	_dinero()
	_objetivos()
	_ficha_sala()
	_aviso_lisa()

## Abajo a la izquierda: menú redondo como el de Two Point.
func _menu_principal() -> void:
	_panel(Rect2(24, 914, 560, 142), 60)
	_boton_redondo(Vector2(98, 970), 46, Color("3d8a7f"), "mapa", "Mundo")
	var items := [["salas", "Salas", NARANJA], ["objetos", "Objetos", Color("58a35a")], ["personal", "Personal", Color("3f7fc4")], ["info", "Info", Color("8a5cc2")]]
	for i in items.size():
		_boton_redondo(Vector2(210 + i * 104, 970), 40, items[i][2], items[i][0], items[i][1])

## Abajo a la derecha: dinero, reputación, fecha y velocidad.
func _dinero() -> void:
	var r := Rect2(1450, 900, 446, 156)
	_panel(r, 34)
	_txt(Vector2(1478, 952), "12.480 €", 38, F_B, TINTA)
	_txt(Vector2(1680, 952), "+340 €/min", 18, F_S, Color("2e8b57"))
	for i in 5:
		_icono(Vector2(1490 + i * 30, 984), 12, "estrella", NARANJA if i < 3 else CREMA2)
	_txt(Vector2(1648, 991), "Reputación", 16, F_S, TENUE)
	_txt(Vector2(1478, 1032), "Día 3 · 09:40", 20, F_S, TINTA)
	var vel := ["pausa", "play", "rapido"]
	for i in 3:
		var c := Vector2(1712 + i * 52, 1022)
		draw_circle(c, 21, VERDE if i == 1 else CREMA2)
		_icono(c, 11, vel[i], CREMA if i == 1 else VERDE)

## Arriba a la derecha: objetivos de Dirección.
func _objetivos() -> void:
	var r := Rect2(1520, 24, 376, 262)
	_panel(r, 26)
	draw_rect(Rect2(1525, 29, 366, 50), VERDE)
	_panel(Rect2(1520, 24, 376, 56), 26, VERDE, VERDE, 0)
	_txt(Vector2(1546, 62), "Objetivos de Dirección", 21, F_B, CREMA)
	var obj := [["Extraer 40 tubos de sangre", 26, 40], ["Separar 10 gradillas de hematíes", 4, 10], ["Contratar un técnico", 1, 1]]
	for i in obj.size():
		var y := 112 + i * 60
		var hecho: bool = obj[i][1] >= obj[i][2]
		draw_circle(Vector2(1554, y - 6), 13, VERDE2 if hecho else CREMA2)
		if hecho:
			_icono(Vector2(1554, y - 6), 9, "check", CREMA)
		_txt(Vector2(1578, y), obj[i][0], 17, F_S, TENUE if hecho else TINTA)
		_barra(Rect2(1578, y + 12, 220, 10), float(obj[i][1]) / obj[i][2], VERDE2 if hecho else NARANJA)
		_txt(Vector2(1808, y + 22), "%d/%d" % [obj[i][1], obj[i][2]], 15, F_B, TENUE)

## Ficha de la sala seleccionada (inspector de Two Point).
func _ficha_sala() -> void:
	var r := Rect2(24, 300, 420, 590)
	_panel(r, 26)
	_panel(Rect2(24, 300, 420, 92), 26, VERDE, VERDE, 0)
	draw_rect(Rect2(29, 360, 410, 32), VERDE)
	draw_circle(Vector2(78, 346), 30, CREMA)
	_icono(Vector2(78, 346), 18, "salas", VERDE)
	_txt(Vector2(122, 340), "Laboratorio de sangre", 23, F_B, CREMA)
	_txt(Vector2(122, 368), "5 × 4 · nivel 1", 16, F_S, Color(1, 1, 1, 0.75))
	for s in [-1, 1]:
		var c := Vector2(410 if s > 0 else 396, 346)
	# pestañas
	var tabs := ["Datos", "Cola", "Máquinas"]
	for i in 3:
		var tr_ := Rect2(40 + i * 132, 404, 124, 40)
		_panel(tr_, 14, VERDE2 if i == 0 else CREMA2, VERDE2 if i == 0 else CREMA2, 0)
		_txt(Vector2(tr_.position.x, 431), tabs[i], 17, F_B, CREMA if i == 0 else TENUE, 124, HORIZONTAL_ALIGNMENT_CENTER)
	# personal
	_txt(Vector2(46, 476), "PERSONAL", 13, F_B, TENUE)
	draw_circle(Vector2(70, 510), 22, Color("d9c9a8"))
	draw_circle(Vector2(70, 504), 10, Color("f2c9a0"))
	draw_rect(Rect2(58, 514, 24, 12), CREMA)
	_txt(Vector2(102, 506), "Dra. Iratxe Gil · técnica", 17, F_S, TINTA)
	_barra(Rect2(102, 516, 160, 9), 0.72, VERDE2)
	_txt(Vector2(272, 526), "Energía", 13, F_M, TENUE)
	# máquina y proceso
	_txt(Vector2(46, 572), "CENTRÍFUGA CF-2 · TRABAJANDO", 13, F_B, TENUE)
	_panel(Rect2(40, 584, 388, 104), 16, Color("eef6f2"), Color("cfe3dc"), 2)
	_icono(Vector2(80, 618), 16, "gradilla", Color("f4f1ea"))
	_txt(Vector2(46, 662), "4/min", 15, F_B, TINTA)
	draw_line(Vector2(112, 616), Vector2(162, 616), VERDE, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(162, 608), Vector2(174, 616), Vector2(162, 624)]), VERDE)
	_icono(Vector2(212, 616), 20, "centrifuga", CREMA)
	draw_line(Vector2(240, 610), Vector2(290, 596), VERDE, 4)
	draw_line(Vector2(240, 622), Vector2(290, 640), VERDE, 4)
	_icono(Vector2(318, 600), 13, "bolsa", CREMA)
	_txt(Vector2(340, 606), "4/min", 15, F_B, TINTA)
	_icono(Vector2(318, 646), 12, "plasma", CREMA)
	_txt(Vector2(340, 652), "12 l/min", 15, F_B, TINTA)
	_barra(Rect2(56, 672, 356, 8), 0.58, NARANJA)
	# estadísticas
	var st := [["Gradillas procesadas", "86"], ["Plasma al depósito", "312 l"], ["Valor de la sala", "18.400 €"]]
	for i in st.size():
		_txt(Vector2(46, 724 + i * 30), st[i][0], 16, F_M, TENUE)
		_txt(Vector2(300, 724 + i * 30), st[i][1], 16, F_B, TINTA, 120, HORIZONTAL_ALIGNMENT_RIGHT)
	# botones de acción
	var acc := [["Editar", VERDE2], ["Prioridad", NARANJA], ["Vender", ROJO]]
	for i in 3:
		var br := Rect2(40 + i * 132, 820, 124, 52)
		_panel(br, 18, acc[i][1], acc[i][1].darkened(0.25), 3)
		_txt(Vector2(br.position.x, 853), acc[i][0], 17, F_B, CREMA, 124, HORIZONTAL_ALIGNMENT_CENTER)

## Correo de LISA en bocadillo pequeño (arriba a la izquierda), no para el juego.
func _aviso_lisa() -> void:
	var r := Rect2(24, 24, 520, 104)
	_panel(r, 24)
	draw_circle(Vector2(78, 76), 34, Color("3f7fc4"))
	draw_circle(Vector2(78, 70), 15, CREMA)
	draw_rect(Rect2(62, 86, 32, 12), CREMA)
	_txt(Vector2(126, 62), "LISA · Dirección", 15, F_B, VERDE)
	_txt(Vector2(126, 90), "La línea de sangre ya llega sola a la centrífuga.", 17, F_S, TINTA)
	_txt(Vector2(126, 114), "Que el técnico no se duerma.", 17, F_S, TENUE)
