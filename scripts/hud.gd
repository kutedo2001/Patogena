class_name HUD
extends HUDEscaparate
## HUD de la partida (puerta 4): mismas piezas que el escaparate, con datos vivos de Juego.
## Los paneles que cambian de forma (objetivo, máquina, construcción, inventario) se rehacen
## solo cuando cambia su «firma»; las cifras que se mueven se actualizan cada fotograma.

var juego: Juego
var _raiz: Control
var _obj_caja: VBoxContainer
var _maq_panel: PanelContainer
var _maq_caja: VBoxContainer
var _cons_caja: VBoxContainer
var _inv_caja: VBoxContainer
var _firmas := {}
var _lbl_ingresos: Label
var _lbl_energia: Label
var _bar_energia: ProgressBar
var _lbl_prop: Label
var _lbl_cura: Label
var _bar_cura: ProgressBar
var _lbl_dia: Label
var _vel: Array[Panel] = []
var _avisos: Array[String] = []
var _hover := -1
var _maq_prog: ProgressBar
var _maq_estado: Label
var _t_refresco := 0.0

func _ready() -> void:
	layer = 5
	var idioma := "es"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--idioma="):
			idioma = a.trim_prefix("--idioma=")
	TranslationServer.set_locale(idioma)
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios") or "--movil" in OS.get_cmdline_user_args():
		get_window().content_scale_factor = 1.3
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.theme = _tema()
	add_child(_raiz)
	_barra_superior_juego(_raiz)
	# objetivo
	var po := _carcasa(_raiz, 12)
	po.position = Vector2(14, 92)
	po.custom_minimum_size = Vector2(286, 0)
	_obj_caja = _columna(po, 10)
	# máquina seleccionada
	_maq_panel = _carcasa(_raiz, 14)
	_maq_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_maq_panel.offset_left = -404
	_maq_panel.offset_right = -14
	_maq_panel.offset_top = 92
	_maq_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_maq_caja = _columna(_maq_panel, 10)
	_maq_panel.visible = false
	# construcción
	_cons_caja = VBoxContainer.new()
	_cons_caja.add_theme_constant_override("separation", 8)
	_cons_caja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_cons_caja.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_cons_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_cons_caja)
	# inventario
	var pi := _carcasa(_raiz, 12)
	pi.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_inv_caja = _columna(pi, 8)
	_anclar.call_deferred(pi, Control.PRESET_BOTTOM_LEFT)
	if juego:
		juego.tutorial.correo.connect(_mostrar_correo)
		juego.aviso.connect(func(k: String): _avisos.push_front(tr(k)); _avisos.resize(mini(_avisos.size(), 3)))
	_refrescar(true)

var _correo: Control

## Correo de Dirección: carcasa centrada con la cabecera de la empresa, el texto y «Continuar».
func _mostrar_correo(titulo: String, texto: String) -> void:
	if _correo:
		_correo.queue_free()
	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.45)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fondo)
	_correo = fondo
	var p := _carcasa(fondo, 18)
	p.custom_minimum_size = Vector2(620, 0)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	var v := _columna(p, 12)
	var cab := _franja(v, tr("CORREO_DE"), "correo")
	_texto(cab, tr("CORREO_CONFIDENCIAL"), 11, F_BOLD, Color.WHITE)
	_texto(v, titulo, 20, F_BOLD)
	var pant := _pantalla(v, 16)
	var l := _texto(pant, texto, 15, F_MED, P_TINTA)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 560
	var pie := _fila(v, 8)
	_texto(pie, tr("CORREO_FIRMA"), 12, F_SEMI, C_TENUE_OSC).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_OK.darkened(0.25)
	bs.set_corner_radius_all(6)
	bs.border_width_bottom = 4
	bs.border_color = bs.bg_color.darkened(0.3)
	bs.content_margin_left = 18; bs.content_margin_right = 18; bs.content_margin_top = 8; bs.content_margin_bottom = 8
	b.add_theme_stylebox_override("panel", bs)
	pie.add_child(b)
	_texto(b, tr("CORREO_CONTINUAR"), 15, F_BOLD, Color.WHITE)
	_clic(b, cerrar_correo)
	p.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

func cerrar_correo() -> void:
	if _correo:
		_correo.queue_free()
		_correo = null
		juego.tutorial.cerrar_correo()

## Pulsador que se puede apretar.
func _boton(padre: Control, icono: String, tapa: Color, lado: int, activo: bool, accion: Callable) -> Panel:
	var b := _pulsador(padre, icono, tapa, lado, activo)
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: accion.call())
	return b

func _clic(c: Control, accion: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: accion.call())

func _vaciar(c: Control) -> void:
	for h in c.get_children():
		c.remove_child(h)        # fuera ya: si no, el tamaño mínimo cuenta los viejos y el panel crece
		h.queue_free()

# ================================================================== barra superior
func _barra_superior_juego(raiz: Control) -> void:
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
	_texto(nm, tr("HUD_SEDE_1"), 11, F_MED, Color(1, 1, 1, 0.8))
	_hueco(h)
	var vd := _visor(h, tr("HUD_FONDOS"), "dinero", C_AMBAR)
	_lbl_dinero = _texto(vd, "", 16, F_BOLD, P_TINTA)
	_lbl_ingresos = _texto(vd, "", 12, F_SEMI, C_OK)
	var ve := _visor(h, tr("HUD_ENERGIA"), "energia", C_AMARILLO)
	_lbl_energia = _texto(ve, "", 15, F_SEMI, P_TINTA)
	_bar_energia = _barra(ve, 0.0, P_TINTA, 7, 60)
	var vp := _visor(h, tr("HUD_PROPAGACION"), "cepa", C_ZOMBI)
	_lbl_prop = _texto(vp, "", 15, F_BOLD, C_ZOMBI)
	var vc := _visor(h, tr("HUD_CURA"), "cura", C_CURA)
	_lbl_cura = _texto(vc, "", 15, F_SEMI, C_CURA)
	_bar_cura = _barra(vc, 0.0, C_CURA, 7, 50)
	var cdia := _columna(h, 2)
	cdia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_lbl_dia = _texto(cdia, "", 10, F_BOLD, C_TENUE_OSC)
	var pd := _pantalla(cdia, 0)
	var md := MarginContainer.new()
	md.add_theme_constant_override("margin_left", 8)
	md.add_theme_constant_override("margin_right", 10)
	md.add_theme_constant_override("margin_top", 2)
	md.add_theme_constant_override("margin_bottom", 2)
	pd.add_child(md)
	var hd := _fila(md, 8)
	hd.add_child(IconoHUD.new("fecha", P_TENUE, 16))
	_lbl_hora = _texto(hd, "", 15, F_SEMI, P_TINTA)
	_hueco(h)
	var vel := _fila(h, 6)
	for i in 4:
		var mult: float = [0.0, 1.0, 2.0, 3.0][i]
		_vel.append(_boton(vel, ["pausa", "play", "rapido", "rapido"][i], [C_AMBAR, C_OK, C_ACENTO, C_ACENTO][i], 30, false,
			func(): juego.velocidad = mult))
	var sep := ColorRect.new()
	sep.color = C_BISEL_SOMBRA
	sep.custom_minimum_size = Vector2(2, 34)
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(sep)
	_boton(h, "quitar", C_ROJO, 30, false, func(): juego.modo_quitar())
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
	_teletipo = _texto(clip, "", 12, F_SEMI, C_AMBAR)
	_teletipo.position = Vector2(400, -2)

# ================================================================== paneles que cambian
func _refrescar(forzar := false) -> void:
	if juego == null:
		return
	var f := juego.fab
	# objetivo
	var fo := str([juego.hito(0), juego.hito(1), juego.hito(2), juego.tutorial.paso_actual()])
	if forzar or _firmas.get("obj") != fo:
		_firmas["obj"] = fo
		_vaciar(_obj_caja)
		_franja(_obj_caja, tr("HUD_OBJETIVO"), "hitos")
		_texto(_obj_caja, tr("HUD_FASE_1"), 15, F_BOLD)
		var pant := _pantalla(_obj_caja, 10)
		var lista := _columna(pant, 10)
		var iconos := ["tubo_plasma", "tubo_adn", "vial_mutacion"]
		for i in Juego.HITOS.size():
			var hv := juego.hito(i)
			var fila := _fila(lista, 10)
			_bandeja(fila, iconos[i], 34)
			var c := _columna(fila, 4)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var arriba := _fila(c, 6)
			var hecho := hv.x >= hv.y
			var l := _texto(arriba, tr(Juego.HITOS[i][2]), 12, F_MED, P_TENUE if hecho else P_TINTA)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if hecho:
				arriba.add_child(IconoHUD.new("check", C_OK, 16))
			else:
				_texto(arriba, "%d/%d" % [hv.x, hv.y], 13, F_BOLD, P_TINTA)
			_barra(c, float(hv.x) / hv.y, C_OK if hecho else P_TINTA, 6)
		var pc := PanelContainer.new()
		var pcs := StyleBoxFlat.new()
		pcs.bg_color = Color(0.98, 0.86, 0.36, 0.35)
		pcs.set_corner_radius_all(5)
		pcs.set_content_margin_all(8)
		pc.add_theme_stylebox_override("panel", pcs)
		_obj_caja.add_child(pc)
		var cf := _fila(pc, 8)
		var bombilla := IconoHUD.new("punto", C_AMBAR, 12)
		bombilla.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		cf.add_child(bombilla)
		var nt := juego.tutorial.numero()
		var lc := _texto(cf, ("%d/%d · " % [nt.x, nt.y]) + tr(juego.tutorial.paso_actual()), 12, F_SEMI, C_TINTA_OSC)
		lc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rec := _fila(_obj_caja, 8)
		rec.add_child(IconoHUD.new("flecha", C_TENUE_OSC, 13))
		var lr := _texto(rec, tr("HUD_PREMIOS"), 11, F_MED, C_TENUE_OSC)
		lr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# máquina seleccionada
	var sel = juego.seleccion
	var fm := ""
	if sel is Fabrica.MaquinaSim:
		fm = "%s|%s|%s|%s" % [sel.get_instance_id(), sel.receta, str(sel.entrada), str(sel.salida.size())]
	elif sel is Fabrica.Almacen or sel is Fabrica.Extractor:
		fm = "%s|%s" % [sel.get_instance_id(), str(sel.contenido.size() if sel is Fabrica.Almacen else sel.listo)]
	elif sel is Fabrica.Estacion:
		fm = "%s|%s|%s|%d|%d" % [sel.get_instance_id(), sel.modo, sel.listo, juego.zombis_libres, int(juego.fab.dinero >= 250)]
	elif sel is Fabrica.MuelleEnvio:
		fm = "muelle|%s" % str(juego.fab.vendido)
	if forzar or _firmas.get("maq") != fm:
		_firmas["maq"] = fm
		_panel_seleccion(sel)
	# construcción
	var fc := "%s|%s|%d|%s" % [juego.categoria, str(juego.herramienta), _hover, juego.quitando]
	if forzar or _firmas.get("cons") != fc:
		_firmas["cons"] = fc
		_barra_construccion_juego()
	# manos del científico y zombis disponibles
	var fi := "%s|%d|%d" % [juego.mano_obj, juego.mano_n, juego.zombis_libres]
	if forzar or _firmas.get("inv") != fi:
		_firmas["inv"] = fi
		_vaciar(_inv_caja)
		var cab := _franja(_inv_caja, tr("HUD_MANOS").to_upper())
		_texto(cab, "%d/%d" % [juego.mano_n, Juego.MANOS_MAX], 12, F_BOLD, Color.WHITE)
		var fila := _fila(_inv_caja, 6)
		for k in Juego.MANOS_MAX:
			_bandeja(fila, Fabrica.base(juego.mano_obj) if k < juego.mano_n else "", 50)
		if juego.mano_n > 0:
			_texto(_inv_caja, tr("HUD_AYUDA_MANOS"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if juego.liberado:
			var zf := _fila(_inv_caja, 8)
			zf.add_child(IconoHUD.new("cepa", Color(0.3, 0.6, 0.15), 16))
			_texto(zf, tr("HUD_ZOMBIS") % juego.zombis_libres, 12, F_BOLD, C_TINTA_OSC)

func _panel_seleccion(sel) -> void:
	_vaciar(_maq_caja)
	_maq_prog = null
	_maq_estado = null
	if sel is Fabrica.Estacion:
		_panel_estacion(sel)
		return
	if sel is Fabrica.MuelleEnvio:
		_panel_muelle()
		return
	if not (sel is Fabrica.MaquinaSim or sel is Fabrica.Almacen or sel is Fabrica.Extractor):
		_maq_panel.visible = false
		return
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	var icono := "almacen"
	var nombre := tr("CONS_ALMACEN")
	if sel is Fabrica.MaquinaSim:
		icono = sel.tipo
		nombre = tr("MAQ_" + sel.tipo.to_upper())
	elif sel is Fabrica.Extractor:
		icono = Fabrica.base(sel.objeto)
		nombre = tr("CONS_" + {"extractor_sangre": "EXTRACTOR", "recolector": "RECOLECTOR", "bomba": "BOMBA"}[sel.tipo])
	_bandeja(cab, icono, 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, nombre, 17, F_BOLD)
	_maq_estado = _texto(cc, "", 11, F_BOLD, Color(0.15, 0.6, 0.3))
	if sel is Fabrica.Almacen:
		var pa := _pantalla(_maq_caja, 10)
		_texto(pa, "%d / %d" % [sel.contenido.size(), sel.capacidad], 18, F_BOLD, P_TINTA)
		_texto(_maq_caja, tr("HUD_AYUDA_RECOGER"), 11, F_MED, C_TENUE_OSC)
		return
	if sel is Fabrica.Extractor:
		var pe := _pantalla(_maq_caja, 10)
		var fe := _fila(pe, 10)
		fe.add_child(IconoHUD.new("reloj", P_TENUE, 16))
		_maq_prog = _barra(fe, 0.0, P_TINTA, 8, 200)
		_texto(fe, "%s s" % String.num(sel.cada, 1).replace(".", ","), 13, F_SEMI, P_TENUE)
		return
	# receta
	var r: Dictionary = Fabrica.datos.recetas[sel.receta]
	_franja(_maq_caja, tr("HUD_RECETA").to_upper())
	var rc := _pantalla(_maq_caja, 10)
	var rf := _fila(rc, 8)
	for o in r.entradas:
		_bandeja(rf, o, 46, int(r.entradas[o]))
	var mid := _columna(rf, 4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	var fl := IconoHUD.new("flecha", P_TENUE, 18)
	fl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mid.add_child(fl)
	_maq_prog = _barra(mid, 0.0, P_TINTA, 8)
	var tf := _fila(mid, 4)
	tf.alignment = BoxContainer.ALIGNMENT_CENTER
	tf.add_child(IconoHUD.new("reloj", P_TENUE, 12))
	_texto(tf, "%s s" % String.num(float(r.tiempo), 1).replace(".", ","), 12, F_SEMI, P_TENUE)
	if r.salidas.is_empty():
		_bandeja(rf, "cepa_icono", 46)
	for o in r.salidas:
		_bandeja(rf, o, 46, int(r.salidas[o]))
	if r.has("mutacion"):
		_texto(_maq_caja, tr("MUT_" + str(r.mutacion).to_upper()), 13, F_BOLD, Color(0.2, 0.5, 0.15))
	# recetas para elegir (biorreactor)
	var recetas: Array = Fabrica.datos.maquinas[sel.tipo].recetas
	if recetas.size() > 1:
		_texto(_maq_caja, tr("HUD_ELEGIR_MUTACION").to_upper(), 10, F_BOLD, C_TENUE_OSC)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		_maq_caja.add_child(grid)
		for rid in recetas:
			var rr: Dictionary = Fabrica.datos.recetas[rid]
			var hecha: bool = rr.get("mutacion", "") in juego.fab.mutaciones_hechas
			var b := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = C_ACENTO if rid == sel.receta else (C_CARCASA_OSC if not hecha else Color(0.75, 0.85, 0.7))
			bs.set_corner_radius_all(5)
			bs.border_width_bottom = 3
			bs.border_color = bs.bg_color.darkened(0.25)
			bs.content_margin_left = 6; bs.content_margin_right = 6; bs.content_margin_top = 3; bs.content_margin_bottom = 3
			b.add_theme_stylebox_override("panel", bs)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(b)
			var bf := _fila(b, 4)
			for o in rr.entradas:
				for k in int(rr.entradas[o]):
					var t := TextureRect.new()
					t.texture = _icono(o)
					t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					t.custom_minimum_size = Vector2(18, 18)
					bf.add_child(t)
			var lt := _texto(bf, tr("MUT_" + str(rr.mutacion).to_upper()), 11, F_BOLD, Color.WHITE if rid == sel.receta else C_GRAFITO)
			lt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if hecha:
				bf.add_child(IconoHUD.new("check", Color(0.2, 0.55, 0.2), 12))
			_clic(b, func(): juego.elegir_receta(rid))
	# tolva y salida
	for fila_d in [["HUD_ENTRADA", sel.entrada], ["HUD_SALIDA", {}]]:
		var f := _fila(_maq_caja, 8)
		var l := _texto(f, tr(fila_d[0]).to_upper(), 10, F_BOLD, C_TENUE_OSC)
		l.custom_minimum_size.x = 58
		var huecos := _fila(f, 2)
		var objs: Array = []
		if fila_d[0] == "HUD_ENTRADA":
			for o in sel.entrada:
				for k in int(sel.entrada[o]):
					objs.append(o)
		else:
			objs = sel.salida.map(func(x): return Fabrica.base(x))
		for i in 10:
			var hp := Panel.new()
			hp.custom_minimum_size = Vector2(20, 28)
			var hs := _estilo_bandeja()
			hs.set_corner_radius_all(3)
			if i >= objs.size():
				hs.bg_color = C_CARCASA_OSC
			hp.add_theme_stylebox_override("panel", hs)
			huecos.add_child(hp)
			if i < objs.size():
				var t := TextureRect.new()
				t.texture = _icono(objs[i])
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 1)
				hp.add_child(t)
	_texto(_maq_caja, tr("HUD_AYUDA_MAQUINA2"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _panel_estacion(e: Fabrica.Estacion) -> void:
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	_bandeja(cab, e.tipo, 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("EST_" + e.tipo.to_upper()), 17, F_BOLD)
	_maq_estado = _texto(cc, tr("MODO_" + e.modo.to_upper()), 11, F_BOLD, Color(0.15, 0.6, 0.3))
	var pe := _pantalla(_maq_caja, 10)
	var fe := _fila(pe, 10)
	_bandeja(fe, e.objeto, 46)
	var mid := _columna(fe, 4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_maq_prog = _barra(mid, 0.0, P_TINTA, 8)
	_texto(mid, "%s s" % String.num(e.duracion(), 1).replace(".", ","), 12, F_SEMI, P_TENUE)
	_texto(_maq_caja, tr("AYUDA_EST_" + e.modo.to_upper()), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# progresión: mejora con máquina → zombi
	if e.modo == "mano":
		var m: Array = Juego.MEJORA[e.tipo]
		_accion(_maq_caja, tr(m[0]), "%s €" % _miles(m[1]), juego.fab.dinero >= float(m[1]), func(): juego.mejorar(e))
	elif e.modo == "maquina":
		_accion(_maq_caja, tr("HUD_ASIGNAR_ZOMBI"), tr("HUD_ZOMBIS") % juego.zombis_libres, juego.zombis_libres > 0, func(): juego.asignar_zombi(e))

func _panel_muelle() -> void:
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	_bandeja(cab, "caja_vacunas", 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("CONS_MUELLE"), 17, F_BOLD)
	_texto(cc, tr("HUD_COMPRA"), 11, F_BOLD, Color(0.15, 0.6, 0.3))
	var pe := _pantalla(_maq_caja, 10)
	var lista := _columna(pe, 6)
	for o in Fabrica.datos.ventas:
		var f := _fila(lista, 10)
		_bandeja(f, o, 36)
		var l := _texto(f, "%d €" % int(Fabrica.datos.ventas[o]), 15, F_BOLD, C_AMBAR)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_texto(f, "× %d" % int(juego.fab.vendido.get(o, 0)), 13, F_SEMI, P_TENUE)
	_texto(_maq_caja, tr("AYUDA_MUELLE"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## Botón de acción grande del panel (pulsador + texto + precio).
func _accion(padre: Control, texto: String, precio: String, activo: bool, accion: Callable) -> void:
	var b := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = C_ACENTO if activo else C_CARCASA_OSC
	bs.set_corner_radius_all(6)
	bs.border_width_bottom = 4
	bs.border_color = bs.bg_color.darkened(0.25)
	bs.content_margin_left = 12; bs.content_margin_right = 12; bs.content_margin_top = 6; bs.content_margin_bottom = 6
	b.add_theme_stylebox_override("panel", bs)
	padre.add_child(b)
	var f := _fila(b, 8)
	var l := _texto(f, texto, 13, F_BOLD, Color.WHITE if activo else C_TENUE_OSC)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto(f, precio, 13, F_BOLD, Color.WHITE if activo else C_TENUE_OSC)
	if activo:
		_clic(b, accion)

func _barra_construccion_juego() -> void:
	_vaciar(_cons_caja)
	var lista: Array = Juego.CATALOGO[juego.categoria]
	var mostrar := _hover if _hover >= 0 else -1
	if mostrar < 0 and not juego.herramienta.is_empty():
		mostrar = lista.find(juego.herramienta)
	if mostrar >= 0 and mostrar < lista.size():
		var e: Array = lista[mostrar]
		var ficha := _carcasa(_cons_caja, 10)
		ficha.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ficha.custom_minimum_size = Vector2(440, 0)
		var fp := _pantalla(ficha, 12)
		var fv := _columna(fp, 6)
		var ft := _fila(fv, 10)
		var t := _texto(ft, tr(e[2]), 16, F_BOLD, P_TINTA)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_texto(ft, "%s €" % _miles(e[3]), 15, F_BOLD, C_AMBAR)
		var d := _texto(fv, tr("DESC_" + str(e[0]).to_upper()), 12, F_MED, P_TENUE)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var fr := _fila(fv, 8)
		if e[5] == "estacion":
			fr.add_child(IconoHUD.new("flecha", P_TENUE, 14))
			_bandeja(fr, Fabrica.datos.estaciones[e[6]].objeto, 34)
		if e[5] == "maquina":
			var r: Dictionary = Fabrica.datos.recetas[Fabrica.datos.maquinas[e[6]].recetas[0]]
			for o in r.entradas:
				_bandeja(fr, o, 34, int(r.entradas[o]))
			var fl := IconoHUD.new("flecha", P_TENUE, 14)
			fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			fr.add_child(fl)
			for o in r.salidas:
				_bandeja(fr, o, 34, int(r.salidas[o]))
		_hueco(fr)
		_texto(fr, tr("HUD_TECLAS_CONSTRUIR"), 11, F_SEMI, P_TENUE)
	var barra := _carcasa(_cons_caja, 10)
	barra.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bv := _columna(barra, 6)
	var tabs := _fila(bv, 4)
	for cat in Juego.CATALOGO:
		var t := PanelContainer.new()
		var activa: bool = cat == juego.categoria
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
		_clic(t, func(): juego.categoria = cat; juego.cancelar())
	var fila := _fila(bv, 6)
	_casillas.clear()
	for i in 9:
		var hay := i < lista.size()
		var e: Array = lista[i] if hay else []
		var c := _bandeja(fila, e[1] if hay else "", 64)
		var elegida: bool = hay and juego.herramienta == e
		c.add_theme_stylebox_override("panel", _estilo_bandeja(elegida))
		var num := _texto(c, str(i + 1), 11, F_BOLD, Color(0.3, 0.33, 0.34))
		num.position = Vector2(6, 2)
		if hay:
			var pv := PanelContainer.new()
			var pvs := StyleBoxFlat.new()
			pvs.bg_color = Color(P_FONDO, 0.92)
			pvs.set_corner_radius_all(3)
			pvs.content_margin_left = 3; pvs.content_margin_right = 3
			pv.add_theme_stylebox_override("panel", pvs)
			c.add_child(pv)
			var asequible: bool = juego.fab.dinero >= float(e[3])
			_texto(pv, "%s€" % _miles(e[3]), 10, F_BOLD, C_AMBAR if asequible else C_ROJO)
			pv.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 3)
			pv.grow_horizontal = Control.GROW_DIRECTION_BOTH
			pv.grow_vertical = Control.GROW_DIRECTION_BEGIN
			_clic(c, func(): juego.seleccionar_herramienta(e))
			c.mouse_entered.connect(func(): _hover = i)
			c.mouse_exited.connect(func(): if _hover == i: _hover = -1)
		else:
			c.modulate = Color(1, 1, 1, 0.45)
		_casillas.append(c)
	_franja_peligro(bv)
	_cons_caja.reset_size()
	_anclar.call_deferred(_cons_caja, Control.PRESET_CENTER_BOTTOM)

func _unhandled_input(ev: InputEvent) -> void:
	if juego == null:
		return
	if ev is InputEventKey and ev.pressed and not ev.echo:
		var k: int = (ev as InputEventKey).keycode
		var lista: Array = Juego.CATALOGO[juego.categoria]
		if k >= KEY_1 and k <= KEY_9 and k - KEY_1 < lista.size():
			juego.seleccionar_herramienta(lista[k - KEY_1])
			get_viewport().set_input_as_handled()

# ================================================================== vivo
func _process(dt: float) -> void:
	_t += dt
	if juego == null:
		return
	var f := juego.fab
	_lbl_dinero.text = "%s €" % _miles(f.dinero)
	_lbl_ingresos.text = ("+%s" % _miles(juego.ingresos_min)) + tr("HUD_POR_MIN")
	var kw := 0.0
	for e in f.entidades:
		kw += _kw(e)
	_lbl_energia.text = "%s/60 kW" % String.num(kw, 1).replace(".", ",")
	_bar_energia.value = kw / 60.0
	_lbl_prop.text = "%s %%" % String.num(juego.propagacion * 100.0, 2).replace(".", ",")
	_lbl_cura.text = "%d %%" % int(juego.cura * 100)
	_bar_cura.value = juego.cura
	_lbl_dia.text = (tr("HUD_DIA") % juego.dia()).to_upper()
	_lbl_hora.text = "%02d:%02d" % [juego.hora() / 60, juego.hora() % 60]
	for i in _vel.size():
		var activo: bool = is_equal_approx(juego.velocidad, [0.0, 1.0, 2.0, 3.0][i])
		var s: StyleBoxFlat = _vel[i].get_theme_stylebox("panel")
		var tapa: Color = [C_AMBAR, C_OK, C_ACENTO, C_ACENTO][i]
		s.bg_color = tapa if activo else tapa.lerp(C_CARCASA_OSC, 0.3)
	# teletipo: avisos de la partida delante de las noticias
	var texto := "      ◆      ".join(_avisos + [tr("HUD_NOTICIA_1"), tr("HUD_NOTICIA_2"), tr("HUD_NOTICIA_3")])
	if _teletipo.text != texto:
		_teletipo.text = texto
	var ancho := _teletipo.get_minimum_size().x
	_teletipo.position.x = 400.0 - fmod(_t * 60.0, ancho + 800.0)
	# progreso de la máquina seleccionada
	var sel = juego.seleccion
	if _maq_prog and (sel is Fabrica.MaquinaSim or sel is Fabrica.Extractor or sel is Fabrica.Estacion):
		_maq_prog.value = sel.fraccion()
	if _maq_estado and sel is Fabrica.MaquinaSim:
		var claves := ["HUD_APAGADA", "HUD_TRABAJANDO", "HUD_SIN_MATERIAL", "HUD_SALIDA_LLENA"]
		_maq_estado.text = tr(claves[sel.estado])
		_maq_estado.add_theme_color_override("font_color", Color(0.15, 0.6, 0.3) if sel.estado == 1 else Color(0.75, 0.5, 0.05))
	_t_refresco += dt
	if _t_refresco > 0.15:
		_t_refresco = 0.0
		_refrescar()

func _kw(e) -> float:
	if e is Fabrica.Cinta:
		return 0.1
	for cat in Juego.CATALOGO:
		for en in Juego.CATALOGO[cat]:
			if (e is Fabrica.MaquinaSim and en[6] == e.tipo) or (e is Fabrica.Brazo and en[5] == "brazo") \
					or (e is Fabrica.Divisor and en[5] == "divisor") or (e is Fabrica.Extractor and en[0] == e.tipo):
				return float(en[4])
	return 0.0
