class_name HUD
extends CanvasLayer
## HUD de la pantalla objetivo (P3.8). Todo en paneles: ningún texto sobre el mundo.
## Datos de muestra hasta que exista la simulación (P4); los textos van por tr().

const C_PANEL := Color(0.075, 0.09, 0.1, 0.9)
const C_CASILLA := Color(0.13, 0.16, 0.18)        # = fondo de los iconos renderizados
const C_BORDE := Color(1, 1, 1, 0.07)
const C_TEXTO := Color(0.91, 0.93, 0.94)
const C_TENUE := Color(0.55, 0.61, 0.64)
const C_ACENTO := Color(0.25, 0.71, 0.66)         # verde clínico de la empresa
const C_OK := Color(0.33, 0.8, 0.45)
const C_AMBAR := Color(0.95, 0.7, 0.24)
const C_ROJO := Color(0.9, 0.29, 0.3)
const C_ZOMBI := Color(0.56, 0.84, 0.27)

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
var _seleccion := 0
var _casillas: Array[Panel] = []
var _ficha: PanelContainer
var _ficha_titulo: Label
var _ficha_desc: Label
var _ficha_coste: Label
var _ficha_kw: Label
var _lbl_dinero: Label
var _lbl_hora: Label
var _barra_prog: ProgressBar
var _lbl_prog: Label
var _mapa: MapaHUD
var _teletipo: Label
var _teletipo_caja: Control
var _t := 0.0
var _iconos := {}

func _ready() -> void:
	layer = 5
	# idioma: castellano por defecto hasta que haya menú de opciones; «-- --idioma=en» para probar
	var idioma := "es"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--idioma="):
			idioma = a.trim_prefix("--idioma=")
	TranslationServer.set_locale(idioma)
	# móvil: interfaz más grande (la pantalla es pequeña aunque tenga muchos píxeles)
	var movil := OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or "--movil" in OS.get_cmdline_user_args()
	if movil:
		get_window().content_scale_factor = 1.3
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = _tema()
	add_child(raiz)
	_barra_superior(raiz)
	_panel_objetivo(raiz)
	_panel_maquina(raiz)
	_barra_construccion(raiz)
	_inventario(raiz)
	_seleccionar(0)

# ------------------------------------------------------------------ utilidades
func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = F_MED
	t.default_font_size = 15
	t.set_color("font_color", "Label", C_TEXTO)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(1, 1, 1, 0.08)
	fondo.set_corner_radius_all(3)
	var lleno := StyleBoxFlat.new()
	lleno.bg_color = C_ACENTO
	lleno.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", fondo)
	t.set_stylebox("fill", "ProgressBar", lleno)
	return t

func _caja(c := C_PANEL, radio := 8, borde := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radio)
	if borde:
		s.border_color = C_BORDE
		s.set_border_width_all(1)
	s.shadow_color = Color(0, 0, 0, 0.25)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 2)
	return s

func _panel(padre: Control, margen := 14) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _caja()
	s.set_content_margin_all(margen)
	p.add_theme_stylebox_override("panel", s)
	padre.add_child(p)
	return p

func _texto(padre: Control, t: String, tam := 15, fuente: Font = F_MED, color := C_TEXTO) -> Label:
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
	h.alignment = BoxContainer.ALIGNMENT_BEGIN
	padre.add_child(h)
	return h

func _columna(padre: Control, sep := 6) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	padre.add_child(v)
	return v

func _icono(nombre: String) -> Texture2D:
	if not _iconos.has(nombre):
		var r := "res://assets/iconos/%s.png" % nombre
		_iconos[nombre] = load(r) if ResourceLoader.exists(r) else null
	return _iconos[nombre]

## Icono renderizado del objeto/máquina en una casilla redondeada.
func _casilla_icono(padre: Control, nombre: String, lado := 48, cantidad := -1) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(lado, lado)
	var s := _caja(C_CASILLA, 6)
	s.shadow_size = 0
	p.add_theme_stylebox_override("panel", s)
	padre.add_child(p)
	var tex := _icono(nombre) if nombre != "" else null
	if tex:
		var tr_ := TextureRect.new()
		tr_.texture = tex
		tr_.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr_.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr_.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr_.offset_left = 3; tr_.offset_top = 3; tr_.offset_right = -3; tr_.offset_bottom = -3
		tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(tr_)
	if cantidad >= 0 and nombre != "":
		var l := _texto(p, str(cantidad), maxi(11, lado / 4), F_BOLD)
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.offset_left = -40; l.offset_top = -22; l.offset_right = -5; l.offset_bottom = -2
	return p

func _barra(padre: Control, valor: float, color := C_ACENTO, alto := 6, ancho := 0) -> ProgressBar:
	var b := ProgressBar.new()
	b.show_percentage = false
	b.max_value = 1.0
	b.value = valor
	b.custom_minimum_size = Vector2(ancho, alto)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := StyleBoxFlat.new()
	f.bg_color = color
	f.set_corner_radius_all(3)
	b.add_theme_stylebox_override("fill", f)
	padre.add_child(b)
	return b

func _separador(padre: Control, vertical := true) -> void:
	var c := ColorRect.new()
	c.color = Color(1, 1, 1, 0.08)
	c.custom_minimum_size = Vector2(1, 28) if vertical else Vector2(0, 1)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	padre.add_child(c)

func _miles(n: float) -> String:
	var s := str(int(round(n)))
	var r := ""
	while s.length() > 3:
		r = "." + s.right(3) + r
		s = s.left(s.length() - 3)
	return s + r

# ------------------------------------------------------------------ barra superior
func _barra_superior(raiz: Control) -> void:
	var barra := PanelContainer.new()
	var s := _caja(Color(0.06, 0.075, 0.085, 0.94), 0, false)
	s.border_color = Color(0.25, 0.71, 0.66, 0.5)
	s.border_width_bottom = 2
	s.content_margin_left = 18; s.content_margin_right = 18; s.content_margin_top = 6; s.content_margin_bottom = 6
	barra.add_theme_stylebox_override("panel", s)
	barra.set_anchors_preset(Control.PRESET_TOP_WIDE)
	barra.offset_bottom = 58
	raiz.add_child(barra)
	var h := _fila(barra, 22)
	# marca
	var marca := _fila(h, 10)
	var logo := Panel.new()
	logo.custom_minimum_size = Vector2(34, 34)
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ls := _caja(C_ACENTO, 7, false)
	ls.shadow_size = 0
	logo.add_theme_stylebox_override("panel", ls)
	marca.add_child(logo)
	var p := _texto(logo, "P", 24, F_BOLD, Color(0.05, 0.12, 0.11))
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var nm := _columna(marca, -2)
	_texto(nm, tr("HUD_EMPRESA"), 16, F_BOLD)
	_texto(nm, tr("HUD_SEDE"), 12, F_REG, C_TENUE)
	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(hueco)
	# fondos
	var fd := _dato(h, "dinero", C_AMBAR, tr("HUD_FONDOS"))
	_lbl_dinero = _texto(fd, "", 19, F_BOLD)
	_texto(fd, "+340 " + tr("HUD_POR_MIN"), 13, F_SEMI, C_OK)
	_separador(h)
	# energía
	var en := _dato(h, "energia", Color(1.0, 0.82, 0.3), tr("HUD_ENERGIA"))
	_texto(en, "%s / %d kW" % [String.num(energia.x, 1).replace(".", ","), int(energia.y)], 17, F_SEMI)
	_barra(en, energia.x / energia.y, C_AMBAR if energia.x / energia.y > 0.8 else C_ACENTO, 6, 70)
	_separador(h)
	# mundo: mini mapa + propagación
	var mu := _fila(h, 10)
	_mapa = MapaHUD.new()
	_mapa.custom_minimum_size = Vector2(150, 46)
	_mapa.infeccion = propagacion
	mu.add_child(_mapa)
	var mc := _columna(mu, -2)
	var mf := _fila(mc, 6)
	mf.add_child(IconoHUD.new("cepa", C_ZOMBI, 14))
	_texto(mf, tr("HUD_PROPAGACION"), 12, F_MED, C_TENUE)
	_texto(mc, "%s %%" % String.num(propagacion * 100.0, 1).replace(".", ","), 17, F_BOLD, C_ZOMBI)
	_separador(h)
	# cura
	var cu := _dato(h, "cura", Color(0.55, 0.75, 1.0), tr("HUD_CURA"))
	_texto(cu, "%d %%" % int(cura * 100), 17, F_SEMI)
	_barra(cu, cura, Color(0.45, 0.65, 1.0), 6, 60)
	_separador(h)
	# fecha y velocidad
	var fe := _dato(h, "fecha", C_TENUE, tr("HUD_DIA") % dia)
	_lbl_hora = _texto(fe, "", 17, F_SEMI)
	var vel := _fila(h, 4)
	for i in 4:
		var b := Panel.new()
		b.custom_minimum_size = Vector2(30, 30)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bs := _caja(C_ACENTO if i == 1 else Color(1, 1, 1, 0.06), 6, false)
		bs.shadow_size = 0
		b.add_theme_stylebox_override("panel", bs)
		vel.add_child(b)
		var ic := IconoHUD.new(["pausa", "play", "rapido", "rapido"][i], Color(0.05, 0.12, 0.11) if i == 1 else C_TEXTO, 14)
		ic.position = Vector2(8, 8)
		b.add_child(ic)
		if i == 3:
			var x3 := _texto(b, "3", 9, F_BOLD)
			x3.position = Vector2(21, 15)
	_separador(h)
	# pantallas completas
	var pant := _fila(h, 4)
	for n in ["cepa", "mundo", "hitos", "produccion", "correo"]:
		var b := Panel.new()
		b.custom_minimum_size = Vector2(34, 34)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bs := _caja(Color(1, 1, 1, 0.05), 6, false)
		bs.shadow_size = 0
		b.add_theme_stylebox_override("panel", bs)
		pant.add_child(b)
		var ic := IconoHUD.new(n, C_TEXTO, 18)
		ic.position = Vector2(8, 8)
		b.add_child(ic)
		if n == "correo":
			var badge := Panel.new()
			var bb := _caja(C_ROJO, 8, false)
			bb.shadow_size = 0
			badge.add_theme_stylebox_override("panel", bb)
			badge.position = Vector2(20, -4)
			badge.size = Vector2(17, 17)
			b.add_child(badge)
			var n2 := _texto(badge, "2", 11, F_BOLD)
			n2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			n2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# teletipo bajo la barra
	_teletipo_caja = Control.new()
	_teletipo_caja.clip_contents = true
	_teletipo_caja.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_teletipo_caja.offset_top = 58
	_teletipo_caja.offset_bottom = 84
	_teletipo_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_teletipo_caja)
	var fondo := ColorRect.new()
	fondo.color = Color(0.05, 0.06, 0.07, 0.72)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_teletipo_caja.add_child(fondo)
	_teletipo = _texto(_teletipo_caja, "", 13, F_REG, Color(0.8, 0.84, 0.86))
	_teletipo.position = Vector2(190, 3)
	_teletipo.text = "      ●      ".join([tr("HUD_NOTICIA_1"), tr("HUD_NOTICIA_2"), tr("HUD_NOTICIA_3")])
	var directo := PanelContainer.new()
	var ds := _caja(C_ROJO, 0, false)
	ds.shadow_size = 0
	ds.content_margin_left = 12; ds.content_margin_right = 12
	directo.add_theme_stylebox_override("panel", ds)
	directo.position = Vector2(0, 0)
	directo.size = Vector2(0, 26)
	_teletipo_caja.add_child(directo)
	var dl := _texto(directo, "●  " + tr("HUD_DIRECTO"), 12, F_BOLD)
	dl.custom_minimum_size.y = 26

## Grupo icono + (título pequeño encima, valores debajo). Devuelve la fila de valores.
func _dato(padre: Control, icono: String, color: Color, titulo: String) -> HBoxContainer:
	var g := _fila(padre, 10)
	var ic := IconoHUD.new(icono, color, 22)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	g.add_child(ic)
	var c := _columna(g, -2)
	_texto(c, titulo, 12, F_MED, C_TENUE)
	return _fila(c, 8)

# ------------------------------------------------------------------ objetivo
func _panel_objetivo(raiz: Control) -> void:
	var p := _panel(raiz, 16)
	p.position = Vector2(18, 100)
	p.custom_minimum_size = Vector2(390, 0)
	var v := _columna(p, 10)
	var cab := _fila(v, 8)
	cab.add_child(IconoHUD.new("hitos", C_ACENTO, 15))
	_texto(cab, tr("HUD_OBJETIVO"), 12, F_BOLD, C_ACENTO)
	_texto(v, tr("HUD_FASE"), 18, F_SEMI)
	for o in [["tubo_plasma", "HUD_OBJ_PLASMA", 34, 50], ["caja_vacunas", "HUD_OBJ_VACUNAS", 20, 20], ["vial_mutacion", "HUD_OBJ_MUTACION", 0, 1]]:
		var f := _fila(v, 12)
		_casilla_icono(f, o[0], 44)
		var c := _columna(f, 5)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var arriba := _fila(c, 6)
		var hecho: bool = o[2] >= o[3]
		var l := _texto(arriba, tr(o[1]), 14, F_MED, C_TENUE if hecho else C_TEXTO)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if hecho:
			arriba.add_child(IconoHUD.new("check", C_OK, 16))
		else:
			_texto(arriba, "%d / %d" % [o[2], o[3]], 14, F_BOLD)
		_barra(c, float(o[2]) / o[3], C_OK if hecho else C_ACENTO, 5)
	_separador(v, false)
	var rec := _fila(v, 8)
	rec.add_child(IconoHUD.new("flecha", C_TENUE, 13))
	_texto(rec, tr("HUD_RECOMPENSA"), 13, F_REG, C_TENUE)

# ------------------------------------------------------------------ panel de máquina
func _panel_maquina(raiz: Control) -> void:
	var p := _panel(raiz, 16)
	p.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	p.offset_left = -418
	p.offset_right = -18
	p.offset_top = 100
	var v := _columna(p, 12)
	var cab := _fila(v, 12)
	_casilla_icono(cab, "centrifuga", 64)
	var cc := _columna(cab, 3)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto(cc, tr("MAQ_CENTRIFUGA"), 18, F_SEMI)
	var est := _fila(cc, 8)
	var chip := PanelContainer.new()
	var cs := _caja(Color(0.33, 0.8, 0.45, 0.16), 10, false)
	cs.shadow_size = 0
	cs.content_margin_left = 8; cs.content_margin_right = 10; cs.content_margin_top = 2; cs.content_margin_bottom = 2
	chip.add_theme_stylebox_override("panel", cs)
	est.add_child(chip)
	var ch := _fila(chip, 5)
	ch.add_child(IconoHUD.new("punto", C_OK, 10))
	_texto(ch, tr("HUD_TRABAJANDO"), 11, F_BOLD, C_OK)
	_texto(est, "#C-03", 12, F_MED, C_TENUE)
	# receta
	_texto(v, tr("HUD_RECETA").to_upper(), 11, F_BOLD, C_TENUE)
	var rc := PanelContainer.new()
	var rs := _caja(Color(1, 1, 1, 0.04), 8, false)
	rs.shadow_size = 0
	rs.set_content_margin_all(10)
	rc.add_theme_stylebox_override("panel", rs)
	v.add_child(rc)
	var rf := _fila(rc, 10)
	_casilla_icono(rf, "tubo_sangre", 52, 1)
	var mid := _columna(rf, 4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	var fl := IconoHUD.new("flecha", C_TENUE, 18)
	fl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid.add_child(fl)
	_barra_prog = _barra(mid, 0.4, C_ACENTO, 6)
	var tf := _fila(mid, 4)
	tf.alignment = BoxContainer.ALIGNMENT_CENTER
	tf.add_child(IconoHUD.new("reloj", C_TENUE, 12))
	_lbl_prog = _texto(tf, "3,0 s", 12, F_MED, C_TENUE)
	_casilla_icono(rf, "tubo_plasma", 52, 1)
	# cifras
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for d in [["HUD_RITMO", "20 " + tr("HUD_POR_MIN"), "produccion", C_TEXTO], ["HUD_CONSUMO", "4,5 kW", "energia", Color(1.0, 0.82, 0.3)],
			["HUD_EFICIENCIA", "100 %", "check", C_OK], ["HUD_PRODUCIDO", "1.284", "reloj", C_TEXTO]]:
		var celda := PanelContainer.new()
		var es := _caja(Color(1, 1, 1, 0.04), 8, false)
		es.shadow_size = 0
		es.set_content_margin_all(10)
		celda.add_theme_stylebox_override("panel", es)
		celda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(celda)
		var cf := _fila(celda, 10)
		cf.add_child(IconoHUD.new(d[2], d[3], 18))
		var cv := _columna(cf, -2)
		_texto(cv, tr(d[0]), 11, F_MED, C_TENUE)
		_texto(cv, d[1], 16, F_SEMI)
	# almacenes de entrada y salida
	for b in [["HUD_ENTRADA", "tubo_sangre", 6, 10], ["HUD_SALIDA", "tubo_plasma", 2, 10]]:
		var f := _fila(v, 10)
		var l := _texto(f, tr(b[0]), 13, F_MED, C_TENUE)
		l.custom_minimum_size.x = 64
		var huecos := _fila(f, 3)
		for i in b[3]:
			var h := Panel.new()
			h.custom_minimum_size = Vector2(20, 26)
			var hs := _caja(C_CASILLA if i < b[2] else Color(1, 1, 1, 0.04), 3, false)
			hs.shadow_size = 0
			h.add_theme_stylebox_override("panel", hs)
			huecos.add_child(h)
			if i < b[2]:
				var t := TextureRect.new()
				t.texture = _icono(b[1])
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				t.set_anchors_preset(Control.PRESET_FULL_RECT)
				h.add_child(t)
		_texto(f, "%d/%d" % [b[2], b[3]], 13, F_SEMI)
	# acciones
	var acc := _fila(v, 8)
	for a in [["mover", "HUD_MOVER", "M"], ["pausa", "HUD_PAUSAR", "P"], ["quitar", "HUD_QUITAR", "X"]]:
		var bp := PanelContainer.new()
		var bs := _caja(Color(0.9, 0.29, 0.3, 0.14) if a[0] == "quitar" else Color(1, 1, 1, 0.06), 7, false)
		bs.shadow_size = 0
		bs.content_margin_left = 10; bs.content_margin_right = 10; bs.content_margin_top = 7; bs.content_margin_bottom = 7
		bp.add_theme_stylebox_override("panel", bs)
		bp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		acc.add_child(bp)
		var af := _fila(bp, 7)
		af.alignment = BoxContainer.ALIGNMENT_CENTER
		af.add_child(IconoHUD.new(a[0], C_ROJO if a[0] == "quitar" else C_TEXTO, 14))
		_texto(af, tr(a[1]), 13, F_SEMI, C_ROJO if a[0] == "quitar" else C_TEXTO)
		_tecla(af, a[2])

func _tecla(padre: Control, t: String) -> void:
	var k := PanelContainer.new()
	var ks := StyleBoxFlat.new()
	ks.bg_color = Color(0, 0, 0, 0)
	ks.border_color = Color(1, 1, 1, 0.25)
	ks.set_border_width_all(1)
	ks.set_corner_radius_all(4)
	ks.content_margin_left = 5; ks.content_margin_right = 5
	k.add_theme_stylebox_override("panel", ks)
	padre.add_child(k)
	_texto(k, t, 11, F_BOLD, C_TENUE)

# ------------------------------------------------------------------ construcción
func _barra_construccion(raiz: Control) -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 6)
	caja.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caja.offset_bottom = -18
	raiz.add_child(caja)
	# ficha de la construcción seleccionada (encima de la barra)
	_ficha = _panel(caja, 14)
	_ficha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ficha.custom_minimum_size = Vector2(430, 0)
	var fv := _columna(_ficha, 6)
	var ft := _fila(fv, 10)
	_ficha_titulo = _texto(ft, "", 16, F_SEMI)
	_ficha_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ficha_coste = _texto(ft, "", 15, F_BOLD, C_AMBAR)
	_ficha_desc = _texto(fv, "", 13, F_REG, C_TENUE)
	_ficha_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var fr := _fila(fv, 8)
	_casilla_icono(fr, "tubo_sangre", 34)
	fr.add_child(IconoHUD.new("flecha", C_TENUE, 14))
	_casilla_icono(fr, "tubo_plasma", 34)
	var hu := Control.new()
	hu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fr.add_child(hu)
	fr.add_child(IconoHUD.new("energia", Color(1.0, 0.82, 0.3), 14))
	_ficha_kw = _texto(fr, "", 13, F_SEMI)
	# pestañas de categoría + casillas
	var barra := _panel(caja, 10)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bv := _columna(barra, 8)
	var tabs := _fila(bv, 4)
	for cat in CONSTRUCCIONES:
		var t := PanelContainer.new()
		var activa: bool = cat == "HUD_CAT_PROCESADO"
		var ts := _caja(Color(0.25, 0.71, 0.66, 0.18) if activa else Color(0, 0, 0, 0), 6, false)
		ts.shadow_size = 0
		ts.content_margin_left = 10; ts.content_margin_right = 12; ts.content_margin_top = 4; ts.content_margin_bottom = 4
		t.add_theme_stylebox_override("panel", ts)
		tabs.add_child(t)
		var tf := _fila(t, 6)
		var ic: String = ICONO_CAT[cat]
		if ic == "energia":
			tf.add_child(IconoHUD.new("energia", Color(1.0, 0.82, 0.3), 16))
		else:
			var tex := TextureRect.new()
			tex.texture = _icono(ic)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.custom_minimum_size = Vector2(20, 20)
			tf.add_child(tex)
		_texto(tf, tr(cat), 13, F_SEMI, C_ACENTO if activa else C_TENUE)
	var fila := _fila(bv, 6)
	var lista: Array = CONSTRUCCIONES["HUD_CAT_PROCESADO"]
	for i in lista.size():
		var e: Array = lista[i]
		var col := _columna(fila, 3)
		var c := _casilla_icono(col, e[0], 76)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		c.mouse_entered.connect(_seleccionar.bind(i))
		_casillas.append(c)
		var num := _texto(c, str(i + 1), 11, F_BOLD, C_TENUE)
		num.position = Vector2(6, 2)
		if e[4]:
			c.modulate = Color(0.45, 0.45, 0.45)
			var cand := IconoHUD.new("candado", C_TEXTO, 18)
			cand.position = Vector2(52, 4)
			c.add_child(cand)
		var coste := _texto(col, "%s €" % _miles(e[2]), 12, F_SEMI, C_TENUE if e[4] else C_AMBAR)
		coste.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _seleccionar(i: int) -> void:
	var lista: Array = CONSTRUCCIONES["HUD_CAT_PROCESADO"]
	if i < 0 or i >= lista.size():
		return
	_seleccion = i
	for k in _casillas.size():
		var s := _caja(C_CASILLA, 6)
		s.shadow_size = 0
		if k == i:
			s.border_color = C_ACENTO
			s.set_border_width_all(2)
			s.shadow_color = Color(0.25, 0.71, 0.66, 0.35)
			s.shadow_size = 8
			s.shadow_offset = Vector2.ZERO
		_casillas[k].add_theme_stylebox_override("panel", s)
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

# ------------------------------------------------------------------ inventario
func _inventario(raiz: Control) -> void:
	var p := _panel(raiz, 12)
	p.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_anclar.call_deferred(p, Control.PRESET_BOTTOM_LEFT)
	var v := _columna(p, 8)
	var cab := _fila(v, 8)
	_texto(cab, tr("HUD_INVENTARIO").to_upper(), 11, F_BOLD, C_TENUE)
	var hu := Control.new()
	hu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(hu)
	_texto(cab, "32 / 40", 12, F_SEMI)
	var f := _fila(v, 6)
	for it in INVENTARIO:
		_casilla_icono(f, it[0], 58, it[1])

func _anclar(c: Control, preset: Control.LayoutPreset) -> void:
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 18)

# ------------------------------------------------------------------ vivo
func _process(dt: float) -> void:
	_t += dt
	dinero += 340.0 / 60.0 * dt
	_lbl_dinero.text = "%s €" % _miles(dinero)
	var m := int(minuto + _t * 2.0) % (24 * 60)
	_lbl_hora.text = "%02d:%02d" % [m / 60, m % 60]
	var ciclo := 3.0
	var fr := fmod(_t, ciclo) / ciclo
	_barra_prog.value = fr
	_lbl_prog.text = "%s s" % String.num(ciclo * (1.0 - fr), 1).replace(".", ",")
	# teletipo
	var ancho := _teletipo.get_minimum_size().x
	_teletipo.position.x = 190.0 - fmod(_t * 60.0, ancho + 400.0) + 400.0
