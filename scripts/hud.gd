class_name HUD
extends HUDEscaparate
## HUD de la partida (puerta 4): mismas piezas que el escaparate, con datos vivos de Juego.
## Los paneles que cambian de forma (objetivo, máquina, construcción, inventario) se rehacen
## solo cuando cambia su «firma»; las cifras que se mueven se actualizan cada fotograma.

var juego: Juego
var _capa: CapaSoltar
var _ficha_flotante: PanelContainer
var _ff_titulo: Label
var _ff_texto: Label
var _ff_firma := ""
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
	_capa = CapaSoltar.new()
	_capa.juego = juego
	_raiz.add_child(_capa)
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
		juego.anuncio.connect(mostrar_anuncio)
		juego.final.connect(mostrar_final)
		if juego.inicio_pendiente:
			_preguntar_continuar.call_deferred()
		juego.tutorial.correo.connect(_mostrar_correo)
		juego.aviso.connect(func(k: String): _avisos.push_front(tr(k)); _avisos.resize(mini(_avisos.size(), 3)); if k.begins_with("AVISO_NO") or k == "AVISO_SIN_DINERO": Sonido.tocar("error"))
	_refrescar(true)

var _correo: Control
var _anuncio: PanelContainer
var _anuncio_t := 0.0

## Anuncio grande arriba en el centro para los momentos importantes (mutación, hito, venta…).
func mostrar_anuncio(titulo: String, texto: String) -> void:
	Sonido.tocar("anuncio")
	if _anuncio:
		_anuncio.queue_free()
	_anuncio = _carcasa(_raiz, 14)
	_anuncio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := _columna(_anuncio, 6)
	var f := _franja(v, titulo.to_upper(), "cepa")
	f.alignment = BoxContainer.ALIGNMENT_CENTER
	var p := _pantalla(v, 12)
	var l := _texto(p, texto, 18, F_BOLD, P_TINTA)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = 460
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_anuncio_t = 4.5
	_anuncio.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 110)
	_anuncio.grow_horizontal = Control.GROW_DIRECTION_BOTH

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
	b.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: Sonido.tocar("pulsador"); accion.call())
	return b

func _clic(c: Control, accion: Callable) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	c.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: Sonido.tocar("clic"); accion.call())

## Hace arrastrable una bandeja: data = {"de": "manos" | entidad, "objeto": nombre}.
func _arrastrable(c: Control, data: Dictionary, icono: String) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_DRAG
	var fn := func(_p):
		var t := TextureRect.new()
		t.texture = _icono(icono)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.size = Vector2(56, 56)
		t.position = -t.size * 0.5
		var r := Control.new()
		r.add_child(t)
		c.set_drag_preview(r)
		return data
	c.set_meta("drag_fn", fn)
	c.set_drag_forwarding(fn, Callable(), Callable())

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
	var fo := str([juego.progreso_cepa(), f.cepa_actual, f.cepa_hechas.size(), juego.tutorial.paso_actual()])
	if forzar or _firmas.get("obj") != fo:
		_firmas["obj"] = fo
		_vaciar(_obj_caja)
		_franja(_obj_caja, tr("HUD_CEPA"), "hitos")
		_texto(_obj_caja, tr("HUD_MEJORAS") % [f.cepa_hechas.size(), Fabrica.datos.cepa.mejoras.size()], 15, F_BOLD)
		var pant := _pantalla(_obj_caja, 10)
		var lista := _columna(pant, 8)
		if f.cepa_actual == "":
			var l0 := _texto(lista, tr("HUD_ELIGE_MEJORA"), 12, F_SEMI, P_TINTA)
			l0.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			var m := Fabrica.mejora(f.cepa_actual)
			_texto(lista, tr("MEJ_" + str(m.id).to_upper()), 13, F_BOLD, P_TINTA)
			for o in m.pide:
				var fila := _fila(lista, 10)
				_bandeja(fila, o, 30)
				var c := _columna(fila, 3)
				c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				var hecho := mini(int(f.cepa_entregado.get(o, 0)), int(m.pide[o]))
				_texto(c, "%s  %d/%d" % [tr("OBJ_" + str(o).to_upper()), hecho, int(m.pide[o])], 11, F_SEMI, P_TINTA)
				_barra(c, float(hecho) / float(m.pide[o]), C_OK if hecho >= int(m.pide[o]) else P_TINTA, 5)
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
		fm = "muelle|%s|%s" % [str(juego.fab.vendido), sel.destino]
	elif sel is Fabrica.SalaCepas:
		fm = "cepas|%s|%s|%d" % [juego.fab.cepa_actual, str(juego.fab.cepa_entregado), juego.fab.cepa_hechas.size()]
	if sel == null and juego.parcela_sel.x >= 0:
		fm = "parcela|%s|%d" % [juego.parcela_sel, int(juego.fab.dinero >= juego.precio_parcela(juego.parcela_sel))]
	if forzar or _firmas.get("maq") != fm:
		_firmas["maq"] = fm
		_panel_seleccion(sel)
	# construcción
	var fc := "%s|%s|%d|%s|%d" % [juego.categoria, str(juego.herramienta), _hover, juego.quitando, juego.desbloqueadas.size()]
	if forzar or _firmas.get("cons") != fc:
		_firmas["cons"] = fc
		_barra_construccion_juego()
	# mochila (la casilla de la mano resaltada) y zombis disponibles
	var fi := "%s|%d|%d" % [str(juego.mochila), juego.mano_i, juego.zombis_libres]
	if forzar or _firmas.get("inv") != fi:
		_firmas["inv"] = fi
		_vaciar(_inv_caja)
		var cab := _franja(_inv_caja, tr("HUD_MOCHILA").to_upper())
		var usadas := juego.mochila.filter(func(c): return not c.is_empty()).size()
		_texto(cab, "%d/%d" % [usadas, Juego.MOCHILA_CASILLAS], 12, F_BOLD, Color.WHITE)
		var grid := GridContainer.new()
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_inv_caja.add_child(grid)
		for i in Juego.MOCHILA_CASILLAS:
			var c: Dictionary = juego.mochila[i]
			var nombre: String = Fabrica.base(c.o) if not c.is_empty() else ""
			var b := _bandeja(grid, nombre, 50, c.n if not c.is_empty() else -1)
			if i == juego.mano_i:
				b.add_theme_stylebox_override("panel", _estilo_bandeja(true))
			var k := i
			b.mouse_filter = Control.MOUSE_FILTER_STOP
			if not c.is_empty():
				b.tooltip_text = tr("OBJ_" + nombre.to_upper()) + "\n" + tr("HUD_AYUDA_CASILLA")
				_arrastrable(b, {"de": "manos", "i": i, "objeto": c.o}, nombre)
			b.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: juego.elegir_mano(k))
			# soltar sobre una casilla: reordenar la mochila o ir a recoger de una máquina
			b.set_drag_forwarding(b.get_meta("drag_fn", Callable()),
				func(_p, d): return d is Dictionary and d.has("de"),
				func(_p, d):
					if d.de is String and d.has("i"):
						juego.mover_casilla(d.i, k)
					elif d.de is Fabrica.Entidad:
						juego.encargar([["coger", d.de, d.get("objeto", "")]]))
		var ayuda := tr("HUD_AYUDA_MOCHILA_MANO") if juego.mano_i >= 0 else tr("HUD_AYUDA_MOCHILA")
		_texto(_inv_caja, ayuda, 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		_panel_muelle(sel)
		return
	if sel is Fabrica.SalaCepas:
		_panel_sala_cepas()
		return
	if sel is Fabrica.SalaEspera:
		_panel_sala()
		return
	if sel is Fabrica.Generador:
		_panel_generador(sel)
		return
	if sel == null and juego.parcela_sel.x >= 0:
		_panel_parcela(juego.parcela_sel)
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
	# recetas para elegir: la máquina fabrica sin parar la que elijas (V1.13)
	var recetas: Array = Fabrica.datos.maquinas[sel.tipo].recetas
	if recetas.size() > 1:
		_texto(_maq_caja, tr("HUD_ELEGIR_RECETA").to_upper(), 10, F_BOLD, C_TENUE_OSC)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		_maq_caja.add_child(grid)
		for rid in recetas:
			var rr: Dictionary = Fabrica.datos.recetas[rid]
			var hecha := false
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
			var flecha := IconoHUD.new("flecha", C_GRAFITO, 10)
			bf.add_child(flecha)
			for o in rr.salidas:
				var t2 := TextureRect.new()
				t2.texture = _icono(o)
				t2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t2.custom_minimum_size = Vector2(22, 22)
				bf.add_child(t2)
			var lt := _texto(bf, tr("OBJ_" + str(rr.salidas.keys()[0]).to_upper()), 11, F_BOLD, Color.WHITE if rid == sel.receta else C_GRAFITO)
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
			if i < objs.size() and fila_d[0] == "HUD_SALIDA":
				_arrastrable(hp, {"de": sel, "objeto": sel.salida[i]}, objs[i])
			if i < objs.size():
				hp.tooltip_text = tr("OBJ_" + str(objs[i]).to_upper())
				var t := TextureRect.new()
				t.texture = _icono(objs[i])
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 1)
				hp.add_child(t)
	if not sel.salida.is_empty():
		_accion(_maq_caja, tr("HUD_RECOGER"), "%d" % sel.salida.size(), true, func(): juego.encargar([["coger", sel, ""]]))
	_texto(_maq_caja, tr("HUD_AYUDA_MAQUINA4"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

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
	var bp := _bandeja(fe, e.objeto, 46)
	bp.tooltip_text = tr("OBJ_" + e.objeto.to_upper())
	if e.listo != "":
		_arrastrable(bp, {"de": e, "objeto": e.listo}, e.objeto)
	else:
		bp.modulate = Color(1, 1, 1, 0.4)
	var mid := _columna(fe, 4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_maq_prog = _barra(mid, 0.0, P_TINTA, 8)
	_texto(mid, "%s s" % String.num(e.duracion(), 1).replace(".", ","), 12, F_SEMI, P_TENUE)
	if e.listo != "":
		_accion(_maq_caja, tr("HUD_RECOGER"), "1", true, func(): juego.encargar([["coger", e, ""]]))
	elif e.modo != "zombi":
		_accion(_maq_caja, tr("TRABAJAR_" + e.tipo.to_upper()), "", true, func(): juego.encargar([["trabajar", e]]))
	_texto(_maq_caja, tr("AYUDA_EST_" + e.modo.to_upper()), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if e.tipo == "camilla":
		_pacientes_y_campanas()
	# progresión: mejora con máquina → zombi
	if e.modo == "mano":
		var m: Array = Juego.MEJORA[e.tipo]
		_accion(_maq_caja, tr(m[0]), "%s €" % _miles(m[1]), juego.fab.dinero >= float(m[1]), func(): juego.mejorar(e))
	elif e.modo == "maquina":
		_accion(_maq_caja, tr("HUD_ASIGNAR_ZOMBI"), tr("HUD_ZOMBIS") % juego.zombis_libres, juego.zombis_libres > 0, func(): juego.asignar_zombi(e))

## Pacientes en la sala, ritmo de llegada y campañas para que vengan más (V1.8).
func _pacientes_y_campanas() -> void:
	var f := juego.fab
	_franja(_maq_caja, tr("HUD_PACIENTES"))
	var pe := _columna(_pantalla(_maq_caja, 8), 4)
	_texto(pe, tr("HUD_ESPERANDO") % [f.espera_pacientes, f.capacidad_espera()], 13, F_BOLD, P_TINTA)
	var txt := tr("HUD_LLEGA_CADA") % String.num(f.llegada_cada(), 1).replace(".", ",")
	if f.campana_t > 0.0:
		txt += "  ·  " + tr("HUD_CAMPANA_QUEDA") % int(ceil(f.campana_t))
	_texto(pe, txt, 11, F_SEMI, P_TENUE)
	for c in Juego.CAMPANAS:
		var cc: Array = c
		_accion(_maq_caja, tr(cc[0]), "%s €" % _miles(cc[1]), f.dinero >= float(cc[1]) and juego.campana_disponible(cc), func(): juego.campana(cc))

func _panel_sala() -> void:
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	_bandeja(cab, "sala_espera", 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("CONS_SALA_ESPERA"), 17, F_BOLD)
	_pacientes_y_campanas()
	_texto(_maq_caja, tr("AYUDA_SALA"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _panel_generador(g: Fabrica.Generador) -> void:
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	_bandeja(cab, g.tipo, 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("CONS_" + g.tipo.to_upper()), 17, F_BOLD)
	_maq_estado = _texto(cc, "%d kW" % int(g.kw_actual), 11, F_BOLD, Color(0.15, 0.6, 0.3))
	var pe := _columna(_pantalla(_maq_caja, 8), 4)
	var f := juego.fab
	_texto(pe, tr("HUD_RED") % [String.num(f.demanda_kw, 1).replace(".", ","), String.num(f.capacidad_kw(), 0)], 13, F_BOLD, P_TINTA)
	if g.tipo == "biogas":
		_texto(pe, tr("HUD_COMBUSTIBLE") % g.combustible, 11, F_SEMI, P_TENUE)
	_texto(_maq_caja, tr("AYUDA_" + g.tipo.to_upper()), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _panel_parcela(pc: Vector2i) -> void:
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	_bandeja(cab, "", 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("HUD_PARCELA"), 17, F_BOLD)
	_texto(cc, "8 × 8", 12, F_BOLD, C_TENUE_OSC)
	if not juego.comprable(pc):
		_texto(_maq_caja, tr("HUD_PARCELA_LEJOS"), 12, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	if juego.fab.cepa_hechas.size() < juego.fase_parcela(pc):
		_texto(_maq_caja, tr("HUD_PARCELA_FASE2"), 12, F_MED, C_TENUE_OSC)
		return
	var precio := juego.precio_parcela(pc)
	_accion(_maq_caja, tr("HUD_COMPRAR_PARCELA"), "%s €" % _miles(precio), juego.fab.dinero >= precio, func(): juego.comprar_parcela(pc); juego.parcela_sel = Vector2i(-1, -1))

func _panel_muelle(mu: Fabrica.MuelleEnvio) -> void:
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
	# destino de las vacunas: allí se infecta
	_franja(_maq_caja, tr("HUD_DESTINO"))
	var rej := GridContainer.new()
	rej.columns = 3
	rej.add_theme_constant_override("h_separation", 4)
	rej.add_theme_constant_override("v_separation", 4)
	_maq_caja.add_child(rej)
	for r in juego.mundo.regiones:
		var id: String = r.id
		var b := Button.new()
		b.text = tr("REG_" + id.to_upper())
		b.toggle_mode = true
		b.button_pressed = mu.destino == id
		b.add_theme_font_override("font", F_SEMI)
		b.add_theme_font_size_override("font_size", 10)
		b.custom_minimum_size = Vector2(0, 26)
		b.tooltip_text = tr("HUD_REGION_INFO") % [int(r.pob), tr("CLIMA_" + str(r.clima).to_upper()), int(100.0 * (r.i + r.z) / r.pob)]
		b.pressed.connect(func(): mu.destino = id; _firmas.erase("maq"))
		rej.add_child(b)
	_texto(_maq_caja, tr("AYUDA_MUELLE"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## Sala de cepas: resumen en el panel y botón que abre el árbol de mejoras (tipo Plague Inc).
func _panel_sala_cepas() -> void:
	_maq_panel.visible = true
	var cab := _fila(_maq_caja, 12)
	_bandeja(cab, "sala_cepas", 64)
	var cc := _columna(cab, 4)
	cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cc.alignment = BoxContainer.ALIGNMENT_CENTER
	_texto(cc, tr("CONS_SALA_CEPAS"), 17, F_BOLD)
	var f := juego.fab
	_texto(cc, (tr("HUD_MEJORAS") % [f.cepa_hechas.size(), Fabrica.datos.cepa.mejoras.size()]).to_upper(), 11, F_BOLD, Color(0.15, 0.6, 0.3))
	if f.cepa_actual != "":
		var m := Fabrica.mejora(f.cepa_actual)
		_franja(_maq_caja, tr("HUD_PIDE") + " · " + tr("MEJ_" + str(m.id).to_upper()))
		var pe := _pantalla(_maq_caja, 8)
		var lista := _columna(pe, 6)
		for o in m.pide:
			var fi := _fila(lista, 10)
			_bandeja(fi, o, 34)
			var c := _columna(fi, 3)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var hecho := mini(int(f.cepa_entregado.get(o, 0)), int(m.pide[o]))
			_texto(c, "%s  %d/%d" % [tr("OBJ_" + str(o).to_upper()), hecho, int(m.pide[o])], 12, F_BOLD, P_TINTA)
			_barra(c, float(hecho) / float(m.pide[o]), P_TINTA, 6)
	_accion(_maq_caja, tr("HUD_ABRIR_CEPAS"), "", true, func(): abrir_cepas())
	_texto(_maq_caja, tr("DESC_SALA_CEPAS"), 11, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

## Árbol de mejoras a pantalla completa: tres ramas en columnas, cuatro niveles; cada mejora con su
## estado (hecha, en curso, disponible, bloqueada), lo que pide, lo que hace y lo que desbloquea.
var _cepas_modal: Control
var _cepas_sel := ""
func abrir_cepas() -> void:
	if _cepas_modal:
		_cepas_modal.queue_free()
	var f := juego.fab
	if _cepas_sel == "":
		_cepas_sel = f.cepa_actual
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.04, 0.05, 0.82)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fondo)
	_cepas_modal = fondo
	var marco := _carcasa(fondo, 18)
	marco.custom_minimum_size = Vector2(1180, 640)
	marco.grow_horizontal = Control.GROW_DIRECTION_BOTH
	marco.grow_vertical = Control.GROW_DIRECTION_BOTH
	marco.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	var raiz := _columna(marco, 10)
	var cab := _fila(raiz, 10)
	_bandeja(cab, "sala_cepas", 48)
	var tt := _columna(cab, 2)
	tt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto(tt, tr("CONS_SALA_CEPAS"), 20, F_BOLD)
	var m := juego.mundo
	_texto(tt, tr("HUD_ESTADO_MUNDO") % [String.num(m.fraccion_infectada() * 100.0, 2).replace(".", ","),
		String.num(m.fraccion_zombi() * 100.0, 2).replace(".", ","), int(m.cura * 100.0)], 12, F_SEMI, C_TENUE_OSC)
	_boton(cab, "cerrar", C_ROJO, 40, true, func(): cerrar_cepas())
	var cuerpo := _fila(raiz, 14)
	cuerpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for rama in ["transmision", "sintomas", "resistencias"]:
		var col := _columna(cuerpo, 6)
		col.custom_minimum_size = Vector2(250, 0)
		_franja(col, tr("RAMA_" + rama.to_upper()))
		for mj in Fabrica.datos.cepa.mejoras:
			if mj.rama != rama:
				continue
			var id: String = mj.id
			var estado := "bloqueada"
			if id in f.cepa_hechas:
				estado = "hecha"
			elif id == f.cepa_actual:
				estado = "curso"
			elif f.mejora_disponible(id):
				estado = "libre"
			var b := PanelContainer.new()
			var bs := StyleBoxFlat.new()
			bs.bg_color = {"hecha": Color(0.25, 0.62, 0.42), "curso": C_AMBAR, "libre": C_ACENTO, "bloqueada": C_CARCASA_OSC}[estado]
			bs.set_corner_radius_all(5)
			bs.border_width_bottom = 3
			bs.border_color = bs.bg_color.darkened(0.3)
			if id == _cepas_sel:
				bs.border_width_left = 3; bs.border_width_right = 3; bs.border_width_top = 3
				bs.border_color = C_TINTA_OSC
			bs.content_margin_left = 10; bs.content_margin_right = 10; bs.content_margin_top = 4; bs.content_margin_bottom = 4
			b.add_theme_stylebox_override("panel", bs)
			col.add_child(b)
			var fb := _fila(b, 6)
			_texto(fb, "%s  ·  %s" % [["", "I", "II", "III", "IV"][int(mj.nivel)], tr("MEJ_" + id.to_upper())], 12, F_BOLD,
				Color.WHITE if estado != "bloqueada" else C_TENUE_OSC).size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if estado == "hecha":
				fb.add_child(IconoHUD.new("check", Color.WHITE, 14))
			_clic(b, func(): _cepas_sel = id; abrir_cepas())
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# detalle de la seleccionada
	var det := _pantalla(cuerpo, 10)
	det.custom_minimum_size = Vector2(330, 0)
	var dc := _columna(det, 8)
	if _cepas_sel == "":
		_texto(dc, tr("HUD_ELIGE_MEJORA"), 13, F_SEMI, P_TINTA).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		return
	var sel := Fabrica.mejora(_cepas_sel)
	_texto(dc, tr("MEJ_" + _cepas_sel.to_upper()), 18, F_BOLD, P_TINTA)
	_texto(dc, tr("DESC_MEJ_" + _cepas_sel.to_upper()), 12, F_MED, P_TENUE).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto(dc, tr("HUD_PIDE").to_upper(), 10, F_BOLD, P_TENUE)
	for o in sel.pide:
		var fi := _fila(dc, 8)
		_bandeja(fi, o, 30)
		var hecho := mini(int(f.cepa_entregado.get(o, 0)), int(sel.pide[o])) if f.cepa_actual == _cepas_sel else 0
		_texto(fi, "%s  %d/%d" % [tr("OBJ_" + str(o).to_upper()), hecho, int(sel.pide[o])], 12, F_SEMI, P_TINTA)
	if not sel.desbloquea.is_empty():
		_texto(dc, tr("HUD_DESBLOQUEA").to_upper(), 10, F_BOLD, P_TENUE)
		var fd := _fila(dc, 4)
		for id in sel.desbloquea:
			var ic: String = id
			for cat in Juego.CATALOGO:
				for en in Juego.CATALOGO[cat]:
					if en[0] == id:
						ic = en[1]
			_bandeja(fd, ic, 34).tooltip_text = tr("DESC_" + str(id).to_upper())
	if _cepas_sel in f.cepa_hechas:
		_texto(dc, tr("HUD_MEJORA_HECHA"), 13, F_BOLD, C_OK)
	elif _cepas_sel == f.cepa_actual:
		_texto(dc, tr("HUD_MEJORA_CURSO"), 12, F_SEMI, C_AMBAR).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	elif f.mejora_disponible(_cepas_sel):
		var id2 := _cepas_sel
		_accion(dc, tr("HUD_EMPEZAR_MEJORA"), "", true, func(): juego.elegir_mejora(id2); abrir_cepas())
	else:
		_texto(dc, tr("HUD_MEJORA_BLOQUEADA"), 12, F_SEMI, P_TENUE).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func cerrar_cepas() -> void:
	if _cepas_modal:
		_cepas_modal.queue_free()
		_cepas_modal = null

## Al arrancar con partida guardada: continuar o empezar de cero.
func _preguntar_continuar() -> void:
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.04, 0.05, 0.75)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fondo)
	var marco := _carcasa(fondo, 18)
	marco.custom_minimum_size = Vector2(520, 0)
	marco.grow_horizontal = Control.GROW_DIRECTION_BOTH
	marco.grow_vertical = Control.GROW_DIRECTION_BOTH
	marco.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	var c := _columna(marco, 12)
	_texto(c, tr("JUEGO_TITULO"), 26, F_BOLD)
	_texto(c, tr("MENU_HAY_PARTIDA"), 13, F_MED, C_TENUE_OSC).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_accion(c, tr("MENU_CONTINUAR"), "", true, func(): fondo.queue_free(); juego.empezar(true))
	_accion(c, tr("MENU_NUEVA"), "", true, func(): fondo.queue_free(); juego.empezar(false))

## Pantalla final: victoria (90 % zombi) o derrota (cura al 100 %).
func mostrar_final(ganado: bool) -> void:
	juego.velocidad = 0.0
	var fondo := ColorRect.new()
	fondo.color = Color(0.02, 0.04, 0.05, 0.85)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(fondo)
	var marco := _carcasa(fondo, 18)
	marco.custom_minimum_size = Vector2(640, 0)
	marco.grow_horizontal = Control.GROW_DIRECTION_BOTH
	marco.grow_vertical = Control.GROW_DIRECTION_BOTH
	marco.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	var c := _columna(marco, 12)
	_texto(c, tr("FINAL_GANA_T" if ganado else "FINAL_PIERDE_T"), 26, F_BOLD, C_ZOMBI.darkened(0.3) if ganado else C_ROJO)
	_texto(c, tr("FINAL_GANA" if ganado else "FINAL_PIERDE"), 14, F_MED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto(c, tr("FINAL_TIEMPO") % [juego.dia(), juego.fab.cepa_hechas.size()], 12, F_SEMI, C_TENUE_OSC)
	_accion(c, tr("FINAL_SEGUIR"), "", true, func(): fondo.queue_free(); juego.velocidad = 1.0)

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
			if not juego.desbloqueada(e):
				c.modulate = Color(0.55, 0.55, 0.55)
				var cand := IconoHUD.new("candado", C_GRAFITO, 14)
				cand.position = Vector2(45, 4)
				c.add_child(cand)
			pv.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 3)
			pv.grow_horizontal = Control.GROW_DIRECTION_BOTH
			pv.grow_vertical = Control.GROW_DIRECTION_BEGIN
			_clic(c, func(): juego.seleccionar_herramienta(e))
			c.tooltip_text = tr(e[2]) + "\n" + tr("DESC_" + str(e[0]).to_upper())
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
	var kw := f.demanda_kw
	var cap := f.capacidad_kw()
	_lbl_energia.text = "%s/%s kW" % [String.num(kw, 1).replace(".", ","), String.num(cap, 0)]
	_bar_energia.value = kw / maxf(cap, 1.0)
	_lbl_energia.add_theme_color_override("font_color", C_ROJO if kw > cap else P_TINTA)
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
		var claves := ["HUD_APAGADA", "HUD_TRABAJANDO", "HUD_SIN_MATERIAL", "HUD_SALIDA_LLENA", "HUD_REPETIDA"]
		_maq_estado.text = tr(claves[sel.estado])
		_maq_estado.add_theme_color_override("font_color", Color(0.15, 0.6, 0.3) if sel.estado == 1 else Color(0.75, 0.5, 0.05))
	_ficha_mundo()
	if _anuncio:
		_anuncio_t -= dt
		_anuncio.modulate.a = clampf(_anuncio_t, 0.0, 1.0)
		if _anuncio_t <= 0.0:
			_anuncio.queue_free()
			_anuncio = null
	_t_refresco += dt
	if _t_refresco > 0.15:
		_t_refresco = 0.0
		_refrescar()

## Ficha junto al puntero: qué es y qué hace lo que hay debajo (solo si no se está construyendo
## y el ratón no está sobre un panel). No es texto sobre el mundo: es un panel del HUD.
func _ficha_mundo() -> void:
	if _ficha_flotante == null:
		_ficha_flotante = _carcasa(_raiz, 10, false)
		_ficha_flotante.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ficha_flotante.custom_minimum_size = Vector2(280, 0)
		var v := _columna(_ficha_flotante, 4)
		_ff_titulo = _texto(v, "", 14, F_BOLD)
		_ff_texto = _texto(v, "", 12, F_MED, C_TENUE_OSC)
		_ff_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ff_texto.custom_minimum_size.x = 260
	var e = juego.bajo_raton()
	var sobre_hud := get_viewport().gui_get_hovered_control() != null
	if e == null or sobre_hud or not juego.herramienta.is_empty() or get_viewport().gui_is_dragging():
		_ficha_flotante.visible = false
		return
	var t := ""
	var d := ""
	if e is String and e == "parcela":
		var pc := juego.parcela_de(juego._cel)
		t = tr("HUD_PARCELA")
		d = ("%s €" % _miles(juego.precio_parcela(pc))) if juego.comprable(pc) else tr("HUD_PARCELA_LEJOS")
	elif e is String:
		t = tr("CONS_TERMINAL")
		d = tr("DESC_TERMINAL")
	elif e is Fabrica.MaquinaSim:
		t = tr("MAQ_" + e.tipo.to_upper())
		d = tr("DESC_" + e.tipo.to_upper()) + "\n" + tr(["HUD_APAGADA", "HUD_TRABAJANDO", "HUD_SIN_MATERIAL", "HUD_SALIDA_LLENA", "HUD_REPETIDA"][e.estado])
	elif e is Fabrica.Estacion:
		t = tr("EST_" + e.tipo.to_upper())
		d = tr("DESC_" + e.tipo.to_upper()) + "\n" + tr("MODO_" + e.modo.to_upper())
	elif e is Fabrica.Cinta:
		t = tr("MAQ_CINTA_MK1")
		d = tr("DESC_CINTA")
	elif e is Fabrica.MuelleEnvio:
		t = tr("CONS_MUELLE")
		d = tr("AYUDA_MUELLE")
	elif e is Fabrica.SalaCepas:
		t = tr("CONS_SALA_CEPAS")
		d = tr("DESC_SALA_CEPAS")
	elif e is Fabrica.Almacen:
		t = tr("CONS_ALMACEN")
		d = tr("DESC_ALMACEN") + "  (%d)" % e.contenido.size()
	elif e is Fabrica.Brazo:
		t = tr("CONS_BRAZO")
		d = tr("DESC_BRAZO")
	elif e is Fabrica.Divisor:
		t = tr("CONS_DIVISOR")
		d = tr("DESC_DIVISOR")
	_ff_titulo.text = t
	_ff_texto.text = d + "\n" + tr("HUD_CLIC_USAR")
	_ficha_flotante.visible = true
	_ficha_flotante.reset_size()
	var m := get_viewport().get_mouse_position() / get_window().content_scale_factor
	var tam := _ficha_flotante.size
	var vp := get_viewport().get_visible_rect().size
	_ficha_flotante.position = Vector2(clampf(m.x + 22, 0, vp.x - tam.x - 8), clampf(m.y + 22, 0, vp.y - tam.y - 8))

func _kw(e) -> float:
	return Juego.kw_de(e)

func _kw_viejo(e) -> float:
	if e is Fabrica.Cinta:
		return 0.1
	for cat in Juego.CATALOGO:
		for en in Juego.CATALOGO[cat]:
			if (e is Fabrica.MaquinaSim and en[6] == e.tipo) or (e is Fabrica.Brazo and en[5] == "brazo") \
					or (e is Fabrica.Divisor and en[5] == "divisor") or (e is Fabrica.Extractor and en[0] == e.tipo):
				return float(en[4])
	return 0.0
