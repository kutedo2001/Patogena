class_name HUD
extends CanvasLayer
## HUD (P3.8, segunda versión): los paneles son piezas del laboratorio, con el mismo
## lenguaje que las máquinas. Carcasa blanca biselada con tornillos y franja azul de
## proceso; los datos van dentro de «pantallas» iguales a las de las máquinas (fondo verde
## oscuro con rejilla, tinta verde clara); las casillas son bandejas hundidas y los botones
## son pulsadores físicos. Datos de muestra hasta P4; textos por tr().

# colores en sRGB sacados de los materiales de las máquinas (comun.py) y de la sala
const C_CARCASA := Color(0.93, 0.925, 0.9)
const C_CARCASA_OSC := Color(0.8, 0.81, 0.8)
const C_BISEL_LUZ := Color(1, 1, 1, 0.9)
const C_BISEL_SOMBRA := Color(0.62, 0.63, 0.62)
const C_GRAFITO := Color(0.25, 0.28, 0.29)
const C_ACENTO := Color(0.4, 0.77, 0.9)          # franja azul de las máquinas de proceso
const C_MARCA := Color(0.29, 0.58, 0.54)          # verde agua de la empresa (paredes, placa P)
const C_AMARILLO := Color(0.98, 0.86, 0.36)
const C_TINTA_OSC := Color(0.16, 0.19, 0.2)       # texto serigrafiado sobre la carcasa
const C_TENUE_OSC := Color(0.42, 0.46, 0.47)
# pantallas (iguales que PantallaMaquina)
const P_FONDO := Color(0.03, 0.075, 0.085)
const P_REJILLA := Color(0.09, 0.2, 0.2)
const P_TINTA := Color(0.6, 1.0, 0.88)
const P_TENUE := Color(0.32, 0.62, 0.57)
const C_OK := Color(0.3, 1.0, 0.45)
const C_AMBAR := Color(1.0, 0.7, 0.1)
const C_ROJO := Color(1.0, 0.24, 0.18)
const C_ZOMBI := Color(0.55, 1.0, 0.25)
const C_CURA := Color(0.45, 0.7, 1.0)
const C_BANDEJA := Color(0.74, 0.76, 0.76)        # = fondo de los iconos renderizados

const F_REG := preload("res://assets/fuentes/Inter-Regular.otf")
const F_MED := preload("res://assets/fuentes/Inter-Medium.otf")
const F_SEMI := preload("res://assets/fuentes/Inter-SemiBold.otf")
const F_BOLD := preload("res://assets/fuentes/Inter-Bold.otf")

## barra de construcción: [icono, clave de nombre, coste, kW, bloqueada]
const CONSTRUCCIONES := {
	"HUD_CAT_EXTRACCION": [],
	"HUD_CAT_PROCESADO": [
		["centrifuga", "MAQ_CENTRIFUGA", 450, 4.5, false],
		["secuenciador", "MAQ_SECUENCIADOR", 900, 6.0, false],
		["mezcladora", "MAQ_MEZCLADORA", 650, 3.0, false],
		["biorreactor", "MAQ_BIORREACTOR", 1800, 9.0, false],
		["envasadora", "MAQ_ENVASADORA", 1200, 5.0, false],
		["cinta_recta_mk1", "MAQ_CINTA_MK1", 12, 0.2, false],
		["cinta_curva_mk1", "MAQ_CINTA_MK2", 30, 0.4, true],
		["proteina", "MAQ_SINTETIZADOR", 3200, 12.0, true],
		["neurotoxina", "MAQ_DESTILADOR", 4100, 14.0, true],
	],
	"HUD_CAT_PRODUCTO": [], "HUD_CAT_LOGISTICA": [], "HUD_CAT_ENERGIA": [],
}
const ICONO_CAT := {"HUD_CAT_EXTRACCION": "tubo_sangre", "HUD_CAT_PROCESADO": "centrifuga", "HUD_CAT_PRODUCTO": "vial_mutacion",
	"HUD_CAT_LOGISTICA": "cinta_recta_mk1", "HUD_CAT_ENERGIA": "energia"}
const INVENTARIO := [["tubo_sangre", 12], ["tubo_plasma", 4], ["placa_petri", 6], ["garrafa_agua", 2], ["frasco_reactivo", 8], ["", 0]]

var dinero := 12480.0
var energia := Vector2(38.5, 60.0)
var propagacion := 0.032
var cura := 0.12
var dia := 47
var minuto := 8 * 60 + 40
var _casillas: Array[Panel] = []
var _ficha: Control
var _ficha_titulo: Label
var _ficha_desc: Label
var _ficha_coste: Label
var _ficha_kw: Label
var _lbl_dinero: Label
var _lbl_hora: Label
var _barra_prog: ProgressBar
var _lbl_prog: Label
var _teletipo: Label
var _t := 0.0
var _iconos := {}

func _ready() -> void:
	layer = 5
	var idioma := "es"   # castellano por defecto hasta que haya menú de opciones
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--idioma="):
			idioma = a.trim_prefix("--idioma=")
	TranslationServer.set_locale(idioma)
	var movil := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or "--movil" in OS.get_cmdline_user_args()
	if movil:
		get_window().content_scale_factor = 1.3
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = _tema()
	add_child(raiz)
	# «-- --vista=general»: sin máquina seleccionada ni ficha de construcción (captura de conjunto)
	var general := "--vista=general" in OS.get_cmdline_user_args()
	_barra_superior(raiz)
	_panel_objetivo(raiz)
	if not general:
		_panel_maquina(raiz)
	_barra_construccion(raiz)
	_inventario(raiz)
	_seleccionar(0)
	if general:
		_ficha.visible = false

# ================================================================== piezas
func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = F_MED
	t.default_font_size = 15
	t.set_color("font_color", "Label", C_TINTA_OSC)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = P_REJILLA
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = P_TINTA
	t.set_stylebox("background", "ProgressBar", fondo)
	t.set_stylebox("fill", "ProgressBar", lleno)
	return t

## Carcasa blanca biselada (luz arriba-izquierda, sombra abajo-derecha) con tornillos.
func _estilo_carcasa(radio := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_CARCASA
	s.set_corner_radius_all(radio)
	s.border_width_top = 2
	s.border_width_left = 2
	s.border_width_bottom = 3
	s.border_width_right = 3
	s.border_color = C_BISEL_SOMBRA
	s.border_blend = true
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 8
	s.shadow_offset = Vector2(2, 4)
	return s

func _carcasa(padre: Control, margen := 14, tornillos := true) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _estilo_carcasa()
	s.set_content_margin_all(margen)
	p.add_theme_stylebox_override("panel", s)
	padre.add_child(p)
	if tornillos:
		var tr_ := TornillosHUD.new()
		tr_.margen = margen
		p.add_child(tr_)
	return p

## Franja azul de proceso con título serigrafiado en blanco (como la franja de las máquinas).
func _franja(padre: Control, titulo: String, icono := "") -> HBoxContainer:
	var f := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_ACENTO
	s.set_corner_radius_all(4)
	s.border_width_bottom = 2
	s.border_color = C_ACENTO.darkened(0.25)
	s.content_margin_left = 10; s.content_margin_right = 10; s.content_margin_top = 4; s.content_margin_bottom = 4
	f.add_theme_stylebox_override("panel", s)
	padre.add_child(f)
	var h := _fila(f, 8)
	if icono != "":
		h.add_child(IconoHUD.new(icono, Color.WHITE, 14))
	var l := _texto(h, titulo, 12, F_BOLD, Color.WHITE)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return h

## Pantalla: igual que las de las máquinas (fondo verde oscuro, rejilla, marco negro).
func _pantalla(padre: Control, margen := 10) -> PanelContainer:
	var p := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = P_FONDO
	s.set_corner_radius_all(5)
	s.border_color = Color(0.06, 0.07, 0.075)
	s.set_border_width_all(3)
	s.set_content_margin_all(margen)
	p.add_theme_stylebox_override("panel", s)
	padre.add_child(p)
	var r := RejillaHUD.new()
	p.add_child(r)
	return p

## Bandeja hundida para un icono (sombra arriba, luz abajo: al revés que la carcasa).
func _estilo_bandeja(resaltada := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = C_BANDEJA
	s.set_corner_radius_all(6)
	s.border_width_top = 3
	s.border_width_left = 2
	s.border_width_bottom = 1
	s.border_width_right = 1
	s.border_color = Color(0.5, 0.52, 0.52)
	s.border_blend = true
	if resaltada:
		s.border_color = C_ACENTO
		s.set_border_width_all(3)
		s.border_blend = false
		s.shadow_color = Color(C_ACENTO, 0.5)
		s.shadow_size = 6
	return s

func _texto(padre: Control, t: String, tam := 15, fuente: Font = F_MED, color := C_TINTA_OSC) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", fuente)
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	padre.add_child(l)
	return l

func _fila(padre: Control, sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	padre.add_child(h)
	return h

func _columna(padre: Control, sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	padre.add_child(v)
	return v

func _hueco(padre: Control) -> void:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(c)

func _icono(nombre: String) -> Texture2D:
	if not _iconos.has(nombre):
		var r := "res://assets/iconos/%s.png" % nombre
		_iconos[nombre] = load(r) if ResourceLoader.exists(r) else null
	return _iconos[nombre]

func _bandeja(padre: Control, nombre: String, lado := 48, cantidad := -1) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(lado, lado)
	p.add_theme_stylebox_override("panel", _estilo_bandeja())
	padre.add_child(p)
	var tex := _icono(nombre) if nombre != "" else null
	if tex:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(t)
	if cantidad >= 0 and nombre != "":
		# contador como una pegatina de existencias: pastilla oscura con cifra
		var c := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.1, 0.12, 0.13, 0.92)
		cs.set_corner_radius_all(4)
		cs.content_margin_left = 4; cs.content_margin_right = 4
		c.add_theme_stylebox_override("panel", cs)
		p.add_child(c)
		_texto(c, str(cantidad), maxi(11, lado / 5), F_BOLD, P_TINTA)
		c.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 3)
		c.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		c.grow_vertical = Control.GROW_DIRECTION_BEGIN
	return p

func _barra(padre: Control, valor: float, color := P_TINTA, alto := 6, ancho := 0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.value = valor
	b.custom_minimum_size = Vector2(ancho, alto)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := StyleBoxFlat.new()
	f.bg_color = color
	b.add_theme_stylebox_override("fill", f)
	padre.add_child(b)
	return b

## Pulsador físico: aro gris y tapa de color (como los botones de las consolas de máquina).
func _pulsador(padre: Control, icono: String, tapa: Color, lado := 34, activo := false) -> Panel:
	var b := Panel.new()
	b.custom_minimum_size = Vector2(lado, lado)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var s := StyleBoxFlat.new()
	s.bg_color = tapa if activo else tapa.lerp(C_CARCASA_OSC, 0.3)
	s.set_corner_radius_all(lado / 2)
	s.border_color = Color(0.45, 0.48, 0.5)
	s.set_border_width_all(3)
	s.border_width_bottom = 5
	s.shadow_color = Color(tapa, 0.6) if activo else Color(0, 0, 0, 0.2)
	s.shadow_size = 6 if activo else 2
	b.add_theme_stylebox_override("panel", s)
	padre.add_child(b)
	var ic := IconoHUD.new(icono, Color.WHITE if activo else C_GRAFITO, lado * 0.42)
	ic.position = Vector2(lado * 0.29, lado * 0.24)
	b.add_child(ic)
	var brillo := IconoHUD.new("punto", Color(1, 1, 1, 0.35), lado * 0.22)
	brillo.position = Vector2(lado * 0.16, lado * 0.1)
	b.add_child(brillo)
	return b

func _tecla(padre: Control, t: String, sobre_pantalla := false) -> void:
	var k := PanelContainer.new()
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0, 0, 0, 0)
	ks.border_color = Color(P_TENUE, 0.8) if sobre_pantalla else Color(C_TENUE_OSC, 0.7)
	ks.set_border_width_all(1)
	ks.set_corner_radius_all(3)
	ks.content_margin_left = 4; ks.content_margin_right = 4
	k.add_theme_stylebox_override("panel", ks)
	k.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	padre.add_child(k)
	_texto(k, t, 10, F_BOLD, P_TENUE if sobre_pantalla else C_TENUE_OSC)

func _miles(n: float) -> String:
	var s := str(int(round(n)))
	var r := ""
	while s.length() > 3:
		r = "." + s.right(3) + r
		s = s.left(s.length() - 3)
	return s + r

func _anclar(c: Control, preset: Control.LayoutPreset) -> void:
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 16)

# ================================================================== barra superior
## Consola larga de carcasa blanca; cada dato es un visor (pantalla pequeña) con su
## etiqueta serigrafiada encima, como el panel de instrumentos de una máquina.
func _barra_superior(raiz: Control) -> void:
	var barra := PanelContainer.new()
	var s := _estilo_carcasa(0)
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.border_width_top = 0
	s.content_margin_left = 14; s.content_margin_right = 14; s.content_margin_top = 4; s.content_margin_bottom = 6
	barra.add_theme_stylebox_override("panel", s)
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	raiz.add_child(barra)
	var v := _columna(barra, 3)
	var h := _fila(v, 14)
	# placa de la empresa
	var placa := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = C_MARCA
	ps.set_corner_radius_all(6)
	ps.border_width_bottom = 3
	ps.border_color = C_MARCA.darkened(0.3)
	ps.content_margin_left = 8; ps.content_margin_right = 12; ps.content_margin_top = 3; ps.content_margin_bottom = 3
	placa.add_theme_stylebox_override("panel", ps)
	placa.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(placa)
	var pf := _fila(placa, 8)
	var logo := Panel.new()
	logo.custom_minimum_size = Vector2(30, 30)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ls := StyleBoxFlat.new()
	ls.bg_color = Color.WHITE
	ls.set_corner_radius_all(5)
	logo.add_theme_stylebox_override("panel", ls)
	pf.add_child(logo)
	var p := _texto(logo, "P", 21, F_BOLD, C_MARCA)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nm := _columna(pf, -3)
	_texto(nm, tr("HUD_EMPRESA"), 15, F_BOLD, Color.WHITE)
	_texto(nm, tr("HUD_SEDE"), 11, F_MED, Color(1, 1, 1, 0.8))
	_hueco(h)
	# visores
	var vd := _visor(h, tr("HUD_FONDOS"), "dinero", C_AMBAR)
	_lbl_dinero = _texto(vd, "", 16, F_BOLD, P_TINTA)
	_texto(vd, "+340" + tr("HUD_POR_MIN"), 12, F_SEMI, C_OK)
	var ve := _visor(h, tr("HUD_ENERGIA"), "energia", C_AMARILLO)
	_texto(ve, "%s/%d kW" % [String.num(energia.x, 1).replace(".", ","), int(energia.y)], 15, F_SEMI, P_TINTA)
	_barra(ve, energia.x / energia.y, P_TINTA, 7, 60)
	var vp := _visor(h, tr("HUD_PROPAGACION"), "cepa", C_ZOMBI)
	_texto(vp, "%s %%" % String.num(propagacion * 100.0, 1).replace(".", ","), 15, F_BOLD, C_ZOMBI)
	var vc := _visor(h, tr("HUD_CURA"), "cura", C_CURA)
	_texto(vc, "%d %%" % int(cura * 100), 15, F_SEMI, C_CURA)
	_barra(vc, cura, C_CURA, 7, 50)
	var vf := _visor(h, tr("HUD_DIA") % dia, "fecha", P_TENUE)
	_lbl_hora = _texto(vf, "", 15, F_SEMI, P_TINTA)
	_hueco(h)
	# pulsadores de velocidad y de pantallas
	var vel := _fila(h, 6)
	for i in 4:
		_pulsador(vel, ["pausa", "play", "rapido", "rapido"][i], [C_AMBAR, C_OK, C_ACENTO, C_ACENTO][i], 30, i == 1)
	var sep := ColorRect.new()
	sep.color = C_BISEL_SOMBRA
	sep.custom_minimum_size = Vector2(2, 34)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(sep)
	var pant := _fila(h, 6)
	for n in ["cepa", "mundo", "hitos", "produccion", "correo"]:
		var b := _pulsador(pant, n, C_GRAFITO, 30)
		if n == "correo":
			var led := Panel.new()
			var lsb := StyleBoxFlat.new()
			lsb.bg_color = C_ROJO
			lsb.set_corner_radius_all(8)
			lsb.shadow_color = Color(C_ROJO, 0.7)
			lsb.shadow_size = 4
			led.add_theme_stylebox_override("panel", lsb)
			led.position = Vector2(22, -4)
			led.size = Vector2(16, 16)
			b.add_child(led)
			var n2 := _texto(led, "2", 10, F_BOLD, Color.WHITE)
			n2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			n2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# teletipo: visor largo de leds dentro de la consola, con piloto rojo EN DIRECTO
	var tt := _fila(v, 8)
	var dir := _fila(tt, 6)
	var piloto := IconoHUD.new("punto", C_ROJO, 12)
	piloto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dir.add_child(piloto)
	_texto(dir, tr("HUD_DIRECTO"), 11, F_BOLD, C_ROJO)
	var visor := _pantalla(tt, 0)
	visor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visor.custom_minimum_size.y = 20
	var clip := Control.new()
	clip.clip_contents = true
	clip.custom_minimum_size = Vector2(0, 16)
	visor.add_child(clip)
	_teletipo = _texto(clip, "      ◆      ".join([tr("HUD_NOTICIA_1"), tr("HUD_NOTICIA_2"), tr("HUD_NOTICIA_3")]), 12, F_SEMI, C_AMBAR)
	_teletipo.position = Vector2(400, -2)

## Visor: etiqueta serigrafiada en la carcasa + pantalla pequeña con icono. Devuelve la fila de valores.
func _visor(padre: Control, titulo: String, icono: String, color: Color) -> HBoxContainer:
	var c := _columna(padre, 2)
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_texto(c, titulo.to_upper(), 10, F_BOLD, C_TENUE_OSC)
	var p := _pantalla(c, 0)
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 8)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 2)
	m.add_theme_constant_override("margin_bottom", 2)
	p.add_child(m)
	var h := _fila(m, 8)
	var ic := IconoHUD.new(icono, color, 16)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	return _fila(h, 8)

# ================================================================== objetivo
func _panel_objetivo(raiz: Control) -> void:
	var p := _carcasa(raiz, 12)
	p.position = Vector2(14, 92)
	p.custom_minimum_size = Vector2(286, 0)
	var v := _columna(p, 10)
	_franja(v, tr("HUD_OBJETIVO"), "hitos")
	_texto(v, tr("HUD_FASE"), 15, F_BOLD)
	var pant := _pantalla(v, 10)
	var lista := _columna(pant, 10)
	for o in [["tubo_plasma", "HUD_OBJ_PLASMA", 34, 50], ["caja_vacunas", "HUD_OBJ_VACUNAS", 20, 20], ["vial_mutacion", "HUD_OBJ_MUTACION", 0, 1]]:
		var f := _fila(lista, 10)
		_bandeja(f, o[0], 34)
		var c := _columna(f, 4)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var arriba := _fila(c, 6)
		var hecho: bool = o[2] >= o[3]
		var l := _texto(arriba, tr(o[1]), 12, F_MED, P_TENUE if hecho else P_TINTA)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if hecho:
			arriba.add_child(IconoHUD.new("check", C_OK, 16))
		else:
			_texto(arriba, "%d/%d" % [o[2], o[3]], 13, F_BOLD, P_TINTA)
		_barra(c, float(o[2]) / o[3], C_OK if hecho else P_TINTA, 6)
	var rec := _fila(v, 8)
	rec.add_child(IconoHUD.new("flecha", C_TENUE_OSC, 13))
	var lr := _texto(rec, tr("HUD_RECOMPENSA"), 11, F_MED, C_TENUE_OSC)
	lr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lr.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# ================================================================== panel de máquina
func _panel_maquina(raiz: Control) -> void:
	var p := _carcasa(raiz, 14)
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.offset_left = -404
	p.offset_right = -14
	p.offset_top = 92
	var v := _columna(p, 10)
	var cab := _fila(v, 12)
	_bandeja(cab, "centrifuga", 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("MAQ_CENTRIFUGA"), 17, F_BOLD)
	var est := _fila(cc, 8)
	# torre de luces en miniatura: verde encendida
	var torre := _fila(est, 3)
	for k in 3:
		var col: Color = [C_OK, C_AMBAR, C_ROJO][k]
		torre.add_child(IconoHUD.new("punto", col if k == 0 else col.lerp(C_CARCASA_OSC, 0.75), 12))
	_texto(est, tr("HUD_TRABAJANDO"), 11, F_BOLD, Color(0.15, 0.6, 0.3))
	_texto(est, "#C-03", 11, F_MED, C_TENUE_OSC)
	_franja(v, tr("HUD_RECETA").to_upper())
	var rc := _pantalla(v, 10)
	var rf := _fila(rc, 10)
	_bandeja(rf, "tubo_sangre", 50, 1)
	var mid := _columna(rf, 4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	var fl := IconoHUD.new("flecha", P_TENUE, 18)
	fl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid.add_child(fl)
	_barra_prog = _barra(mid, 0.4, P_TINTA, 8)
	var tf := _fila(mid, 4)
	tf.alignment = BoxContainer.ALIGNMENT_CENTER
	tf.add_child(IconoHUD.new("reloj", P_TENUE, 12))
	_lbl_prog = _texto(tf, "3,0 s", 12, F_SEMI, P_TENUE)
	_bandeja(rf, "tubo_plasma", 50, 1)
	# cifras en una pantalla partida
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)
	for d in [["HUD_RITMO", "20" + tr("HUD_POR_MIN"), "produccion", P_TINTA], ["HUD_CONSUMO", "4,5 kW", "energia", C_AMARILLO],
			["HUD_EFICIENCIA", "100 %", "check", C_OK], ["HUD_PRODUCIDO", "1.284", "reloj", P_TINTA]]:
		var celda := _pantalla(grid, 8)
		celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cf := _fila(celda, 8)
		var ic := IconoHUD.new(d[2], d[3], 18)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cf.add_child(ic)
		var cv := _columna(cf, -2)
		_texto(cv, tr(d[0]), 10, F_SEMI, P_TENUE)
		_texto(cv, d[1], 16, F_BOLD, P_TINTA)
	# almacenes de entrada y salida: fila de huecos como una gradilla
	for b in [["HUD_ENTRADA", "tubo_sangre", 6, 10], ["HUD_SALIDA", "tubo_plasma", 2, 10]]:
		var f := _fila(v, 8)
		var l := _texto(f, tr(b[0]).to_upper(), 10, F_BOLD, C_TENUE_OSC)
		l.custom_minimum_size.x = 58
		var huecos := _fila(f, 2)
		for i in b[3]:
			var hp := Panel.new()
			hp.custom_minimum_size = Vector2(20, 28)
			var hs := _estilo_bandeja()
			hs.set_corner_radius_all(3)
			if i >= b[2]:
				hs.bg_color = C_CARCASA_OSC
			hp.add_theme_stylebox_override("panel", hs)
			huecos.add_child(hp)
			if i < b[2]:
				var t := TextureRect.new()
				t.texture = _icono(b[1])
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 1)
				hp.add_child(t)
		_texto(f, "%d/%d" % [b[2], b[3]], 12, F_BOLD)
	# pulsadores de acción
	var acc := _fila(v, 8)
	for a in [["mover", "HUD_MOVER", "M", C_ACENTO], ["pausa", "HUD_PAUSAR", "P", C_AMBAR], ["quitar", "HUD_QUITAR", "X", C_ROJO]]:
		var c := _fila(acc, 6)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_pulsador(c, a[0], a[3], 30, true)
		var cv := _columna(c, 0)
		_texto(cv, tr(a[1]), 12, F_BOLD)
		_tecla(cv, a[2])

# ================================================================== construcción
func _barra_construccion(raiz: Control) -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 8)
	raiz.add_child(caja)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	# ficha: una pantalla con marco de carcasa, encima de la barra
	var ficha := _carcasa(caja, 10)
	_ficha = ficha
	ficha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ficha.custom_minimum_size = Vector2(440, 0)
	var fp := _pantalla(ficha, 12)
	var fv := _columna(fp, 6)
	var ft := _fila(fv, 10)
	_ficha_titulo = _texto(ft, "", 16, F_BOLD, P_TINTA)
	_ficha_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ficha_coste = _texto(ft, "", 15, F_BOLD, C_AMBAR)
	_ficha_desc = _texto(fv, "", 12, F_MED, P_TENUE)
	_ficha_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fr := _fila(fv, 8)
	_bandeja(fr, "tubo_sangre", 34)
	var fl := IconoHUD.new("flecha", P_TENUE, 14)
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fr.add_child(fl)
	_bandeja(fr, "tubo_plasma", 34)
	_hueco(fr)
	var ek := IconoHUD.new("energia", C_AMARILLO, 14)
	ek.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fr.add_child(ek)
	_ficha_kw = _texto(fr, "", 13, F_SEMI, P_TINTA)
	# barra: carcasa con franja de pestañas y bandejas
	var barra := _carcasa(caja, 10)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bv := _columna(barra, 6)
	var tabs := _fila(bv, 4)
	for cat in CONSTRUCCIONES:
		var t := PanelContainer.new()
		var activa: bool = cat == "HUD_CAT_PROCESADO"
		var ts := StyleBoxFlat.new()
		ts.bg_color = C_ACENTO if activa else C_CARCASA_OSC
		ts.set_corner_radius_all(5)
		ts.border_width_bottom = 3
		ts.border_color = (C_ACENTO if activa else C_CARCASA_OSC).darkened(0.25)
		ts.content_margin_left = 8; ts.content_margin_right = 12; ts.content_margin_top = 3; ts.content_margin_bottom = 3
		t.add_theme_stylebox_override("panel", ts)
		tabs.add_child(t)
		var tf := _fila(t, 6)
		var ic: String = ICONO_CAT[cat]
		if ic == "energia":
			tf.add_child(IconoHUD.new("energia", Color.WHITE if activa else C_GRAFITO, 16))
		else:
			var tex := TextureRect.new()
			tex.texture = _icono(ic)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.custom_minimum_size = Vector2(22, 22)
			tf.add_child(tex)
		_texto(tf, tr(cat), 12, F_BOLD, Color.WHITE if activa else C_GRAFITO)
	var fila := _fila(bv, 6)
	_franja_peligro(bv)
	var lista: Array = CONSTRUCCIONES["HUD_CAT_PROCESADO"]
	for i in lista.size():
		var e: Array = lista[i]
		var col := _columna(fila, 4)
		var c := _bandeja(col, e[0], 64)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.mouse_entered.connect(_seleccionar.bind(i))
		_casillas.append(c)
		# número de tecla grabado en la esquina
		var num := _texto(c, str(i + 1), 11, F_BOLD, Color(0.3, 0.33, 0.34))
		num.position = Vector2(6, 2)
		if e[4]:
			c.modulate = Color(0.6, 0.6, 0.6)
			var cand := IconoHUD.new("candado", C_GRAFITO, 14)
			cand.position = Vector2(45, 4)
			c.add_child(cand)
		# precio en una pastilla de visor dentro de la bandeja
		var pv := PanelContainer.new()
		var pvs := StyleBoxFlat.new()
		pvs.bg_color = Color(P_FONDO, 0.92)
		pvs.set_corner_radius_all(3)
		pvs.content_margin_left = 3; pvs.content_margin_right = 3
		pv.add_theme_stylebox_override("panel", pvs)
		c.add_child(pv)
		_texto(pv, "%s€" % _miles(e[2]), 10, F_BOLD, P_TENUE if e[4] else C_AMBAR)
		pv.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 3)
		pv.grow_horizontal = Control.GROW_DIRECTION_BOTH
		pv.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_anclar.call_deferred(caja, Control.PRESET_CENTER_BOTTOM)

## Franja amarilla y negra como la del zócalo de las máquinas.
func _franja_peligro(padre: Control) -> void:
	var t := TextureRect.new()
	t.texture = preload("res://assets/texturas/hud_peligro.png")
	t.stretch_mode = TextureRect.STRETCH_TILE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.custom_minimum_size = Vector2(0, 6)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(t)

func _seleccionar(i: int) -> void:
	var lista: Array = CONSTRUCCIONES["HUD_CAT_PROCESADO"]
	if i < 0 or i >= lista.size():
		return
	for k in _casillas.size():
		_casillas[k].add_theme_stylebox_override("panel", _estilo_bandeja(k == i))
	var e: Array = lista[i]
	_ficha_titulo.text = tr(e[1])
	_ficha_coste.text = "%s €" % _miles(e[2])
	_ficha_kw.text = "%s kW" % String.num(e[3], 1).replace(".", ",")
	_ficha_desc.text = tr("HUD_BLOQUEADO") if e[4] else tr("DESC_CENTRIFUGA") if e[0] == "centrifuga" else ""

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = (ev as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			_seleccionar(k - KEY_1)

# ================================================================== inventario
func _inventario(raiz: Control) -> void:
	var p := _carcasa(raiz, 12)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := _columna(p, 8)
	var cab := _franja(v, tr("HUD_INVENTARIO").to_upper())
	_texto(cab, "32/40", 12, F_BOLD, Color.WHITE)
	var f := _fila(v, 6)
	for it in INVENTARIO:
		_bandeja(f, it[0], 58, it[1])
	_anclar.call_deferred(p, Control.PRESET_BOTTOM_LEFT)

# ================================================================== vivo
func _process(dt: float) -> void:
	_t += dt
	dinero += 340.0 / 60.0 * dt
	_lbl_dinero.text = "%s €" % _miles(dinero)
	var m := int(minuto + _t * 2.0) % (24 * 60)
	_lbl_hora.text = "%02d:%02d" % [m / 60, m % 60]
	var ciclo := 3.0
	var fr := fmod(_t, ciclo) / ciclo
	if _barra_prog == null:
		_teletipo.position.x = 400.0 - fmod(_t * 60.0, _teletipo.get_minimum_size().x + 800.0)
		return
	_barra_prog.value = fr
	_lbl_prog.text = "%s s" % String.num(ciclo * (1.0 - fr), 1).replace(".", ",")
	var ancho := _teletipo.get_minimum_size().x
	_teletipo.position.x = 400.0 - fmod(_t * 60.0, ancho + 800.0)
