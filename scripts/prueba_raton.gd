class_name PruebaRaton
extends Node
## Prueba con entrada real (nuevo inicio): recorre el tutorial como un jugador, con eventos
## de ratón y teclado, hasta automatizar la camilla con un zombi. «-- --prueba_raton».

var juego: Juego
var hud: HUD
var fallos := 0
var _captura := ""

func _ready() -> void:
	Input.use_accumulated_input = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--captura_final="):
			_captura = a.trim_prefix("--captura_final=")
	_guion.call_deferred()

func comprobar(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		print("        estado: manos=%s×%d pos=%s ruta=%d trabajando=%s producido=%s dinero=%.0f paso=%s" % [juego.mano_obj, juego.mano_n, juego.pos, juego._ruta.size(), juego._trabajando, juego.fab.producido, juego.fab.dinero, juego.tutorial.paso_actual()])
	if not c:
		fallos += 1

func _pantalla(c: Vector2i) -> Vector2:
	return get_viewport().get_camera_3d().unproject_position(Vector3(c.x + 0.5, 0, c.y + 0.5))

func _raton(c: Vector2i, boton := MOUSE_BUTTON_LEFT, pulsado := true) -> void:
	var m := InputEventMouseMotion.new()
	m.position = _pantalla(c)
	Input.parse_input_event(m)
	var e := InputEventMouseButton.new()
	e.button_index = boton
	e.pressed = pulsado
	e.position = _pantalla(c)
	Input.parse_input_event(e)

func _clic(c: Vector2i, boton := MOUSE_BUTTON_LEFT) -> void:
	_raton(c, boton, true)
	await get_tree().process_frame
	_raton(c, boton, false)
	await get_tree().process_frame

func _tecla(k: Key, segundos := 0.0) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	if segundos > 0.0:
		await get_tree().create_timer(segundos).timeout
	else:
		await get_tree().process_frame
	var u := InputEventKey.new()
	u.keycode = k
	u.pressed = false
	Input.parse_input_event(u)
	await get_tree().process_frame

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

## Espera hasta que se cumpla la condición (máx. s segundos reales).
func _hasta(cond: Callable, s: float) -> bool:
	var t := 0.0
	while t < s:
		if cond.call():
			return true
		await get_tree().process_frame
		t += get_process_delta_time()
	return cond.call()

func _correo() -> void:
	await _esperar(0.3)
	if hud._correo != null:
		hud.cerrar_correo()
		await get_tree().process_frame

func _construir(cat: String, n: Key, c: Vector2i) -> void:
	juego.categoria = cat
	await _tecla(n)
	await _clic(c)
	await _clic(Vector2i(0, 0), MOUSE_BUTTON_RIGHT)

func _guion() -> void:
	await _esperar(1.0)
	juego.camara._t_manual = -1e9     # cámara quieta (no sigue) para que los clics caigan donde se calcula
	Engine.time_scale = 3.0           # la prueba va a ×3 (temporizadores y simulación escalados)
	var f := juego.fab
	print("Prueba del nuevo inicio con ratón y teclado:")
	comprobar(hud._correo != null and juego.velocidad > 0.0, "empieza con LISA en un bocadillo y el juego sin pausa")
	await _correo()
	await _tecla(KEY_W, 1.2)
	comprobar(juego.tutorial.paso_actual() == "PASO_CAMILLA", "moverse con WASD pasa al paso de la camilla")
	await _construir("HUD_CAT_EXTRACCION", KEY_1, Vector2i(-2, 1))
	var cam: Fabrica.Estacion = f.celdas.get(Vector2i(-2, 1))
	comprobar(cam != null, "camilla construida")
	await _correo()
	# clic derecho: solo abre el panel
	var p_antes := juego.pos
	await _clic(Vector2i(-2, 1), MOUSE_BUTTON_RIGHT)
	await _esperar(0.5)
	comprobar(juego.seleccion == cam and juego.pos.distance_to(p_antes) < 0.05, "clic derecho en la camilla: abre su panel sin moverse")
	# clic izquierdo: el científico va y saca sangre
	await _clic(Vector2i(-2, 1))
	if "--seq_camilla" in OS.get_cmdline_user_args():
		for i in 160:
			await get_tree().create_timer(0.1).timeout
			get_viewport().get_texture().get_image().save_png("/tmp/rc/f_%03d.png" % i)
	var ok := await _hasta(func(): return juego.cuenta_mochila("tubo_sangre") >= 1, 25.0)
	comprobar(ok and juego.mano_obj == "tubo_sangre", "clic en la camilla: va, espera al paciente, saca sangre y la lleva en la mano")
	await _construir("HUD_CAT_PROCESADO", KEY_1, Vector2i(0, 1))
	var cf: Fabrica.MaquinaSim = f.celdas.get(Vector2i(0, 1))
	comprobar(cf != null, "centrífuga construida")
	await _clic(Vector2i(0, 1))
	ok = await _hasta(func(): return juego.cuenta_mochila("tubo_sangre") == 0, 10.0)
	comprobar(ok, "clic en la centrífuga con la sangre en la mano: la mete")
	await _hasta(func(): return juego.tutorial.paso_actual() == "PASO_ELEGIR_MEJORA", 12.0)
	comprobar(hud._correo != null, "con el primer plasma LISA habla de la sala de cepas")
	await _correo()
	# sala de cepas: clic derecho abre su panel; el árbol se abre y se elige la tos
	await _clic(Vector2i(5, -6), MOUSE_BUTTON_RIGHT)
	await _esperar(0.5)
	comprobar(juego.seleccion is Fabrica.SalaCepas, "clic derecho en la sala de cepas: abre su panel")
	hud.abrir_cepas()
	await _esperar(0.5)
	comprobar(hud._cepas_modal != null and hud._cepas_modal.is_inside_tree(), "se abre el árbol de la cepa a pantalla completa")
	if _captura != "":
		hud._cepas_sel = "tos"
		hud.abrir_cepas()
		await _esperar(0.6)
		get_viewport().get_texture().get_image().save_png(_captura.get_basename() + "_cepas.png")
	juego.elegir_mejora("tos")
	hud.cerrar_cepas()
	comprobar(f.cepa_actual == "tos", "mejora «Tos» elegida")
	# 10 plasmas a la sala con un clic (Mayús+clic: todo lo que pida)
	juego.mochila[1] = {"o": "tubo_plasma", "n": 10}
	juego.mano_i = 1
	var d_antes := f.dinero
	await _clic(Vector2i(4, -6))
	var ok_l := await _hasta(func(): return f.cepa_sintesis >= 0.0, 20.0)
	comprobar(ok_l, "clic en la sala con 10 plasmas: se entregan y falta sintetizar")
	await _clic(Vector2i(4, -6))
	var ok_p := await _hasta(func(): return juego.pos.distance_to(Vector2(juego._cepa.puesto()) + Vector2(0.5, 0.5)) < 0.7, 20.0)
	comprobar(ok_p, "otro clic: el científico entra por la puerta de la sala y se pone en la mesa")
	var ok_t := await _hasta(func(): return "tos" in f.cepa_hechas, 25.0)
	comprobar(ok_t, "trabajando en la mesa sintetiza la cepa y la tos queda aplicada")
	comprobar(juego.desbloqueadas.has("secuenciador") and f.dinero >= d_antes + 400.0, "la tos desbloquea máquinas y LISA paga 400 €")
	await _esperar(0.5)
	await _correo()
	# recetas elegibles: la centrífuga cambia a hematíes sin perder lo cargado (B7)
	cf.entrada["tubo_sangre"] = 2
	cf.salida.clear()                 # lo hecho antes se queda en la salida si nadie lo recoge
	cf.progreso = -1.0
	var antes: Dictionary = cf.entrada.duplicate()
	juego.seleccion = cf
	juego.elegir_receta("hematies")
	comprobar(cf.receta == "hematies" and cf.entrada == antes, "la centrífuga cambia a hematíes sin perder la sangre cargada")
	ok = await _hasta(func(): return f.producido.get("hematies", 0) >= 1, 20.0)
	comprobar(ok, "y fabrica hematíes")
	juego.elegir_receta("plasma")
	# vender en el muelle: plasma y la primera caja de vacunas (libera el virus)
	juego.mochila[2] = {"o": "tubo_plasma", "n": 1}
	juego.mano_i = 2
	var ing := f.ingresos
	await _clic(Vector2i(5, 5))
	ok = await _hasta(func(): return f.ingresos > ing, 15.0)
	comprobar(ok, "clic en el muelle con plasma en la mano: lo vende")
	juego.mochila[2] = {"o": "caja_vacunas", "n": 4}
	juego.mano_i = 2
	await _clic(Vector2i(5, 5))
	ok = await _hasta(func(): return f.vacunas_vendidas >= 4, 15.0)
	await _esperar(0.5)
	comprobar(ok and juego.liberado and juego.mundo.total("i") > 0.0, "vender vacunas infecta en la región de destino")
	await _correo()
	# mejora de la camilla, cinta hasta la centrífuga y zombi
	juego.seleccion = cam
	juego.mejorar(cam)
	comprobar(cam.modo == "maquina", "mejora de la camilla con el extractor")
	juego.categoria = "HUD_CAT_LOGISTICA"
	await _tecla(KEY_1)
	_raton(Vector2i(-1, 1))
	await get_tree().process_frame
	_raton(Vector2i(-1, 1), MOUSE_BUTTON_LEFT, false)
	await get_tree().process_frame
	juego.cancelar()
	comprobar(f.celdas.get(Vector2i(-1, 1)) is Fabrica.Cinta, "cinta de la camilla a la centrífuga")
	juego.velocidad = 3.0
	ok = await _hasta(func(): return juego.zombis_libres > 0, 30.0)
	comprobar(ok, "llega un zombi trabajador tras liberar el virus")
	juego.asignar_zombi(cam)
	cf.salida.clear()
	var p0: int = f.producido.get("tubo_plasma", 0)
	ok = await _hasta(func(): return f.producido.get("tubo_plasma", 0) >= p0 + 2, 30.0)
	comprobar(cam.modo == "zombi" and ok, "con el zombi la camilla trabaja sola y la sangre llega por cinta")
	juego.velocidad = 1.0
	var d := f.dinero
	juego.modo_quitar()
	await _clic(Vector2i(-1, 1))
	juego.cancelar()
	comprobar(not f.celdas.has(Vector2i(-1, 1)) and is_equal_approx(f.dinero, d + 5.0), "quitar devuelve el 100 %")
	# arrastre real con el ratón: de la bandeja de las manos a la centrífuga
	juego.velocidad = 1.0
	juego.mochila[0] = {"o": "tubo_sangre", "n": 1}
	juego.mano_i = 0
	(f.celdas[Vector2i(0, 1)] as Fabrica.MaquinaSim).entrada.clear()   # sitio en la tolva
	await _esperar(0.5)
	var ranura: Control = null
	for c in hud._inv_caja.find_children("*", "Panel", true, false):
		if (c as Control).mouse_default_cursor_shape == Control.CURSOR_DRAG:
			ranura = c
			break
	comprobar(ranura != null, "la sangre de las manos se puede arrastrar")
	if ranura:
		var a := ranura.get_global_rect().get_center()
		var b2 := _pantalla(Vector2i(0, 1))
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		ev.position = a
		var m0 := InputEventMouseMotion.new()
		m0.position = a
		Input.parse_input_event(m0)
		await get_tree().process_frame
		Input.parse_input_event(ev)
		await get_tree().process_frame
		for k in 12:
			var m := InputEventMouseMotion.new()
			m.position = a.lerp(b2, (k + 1) / 12.0)
			m.relative = (b2 - a) / 12.0
			m.global_position = m.position
			Input.warp_mouse(m.position)    # el soltar usa la posición real del puntero
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(m)
			await get_tree().process_frame
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		up.position = b2
		up.global_position = b2
		Input.parse_input_event(up)
		await get_tree().process_frame
		var ok2 := await _hasta(func(): return juego.mano_n == 0, 10.0)
		comprobar(ok2, "arrastre real con el ratón hasta la centrífuga: el científico la deja")
	# ficha al pasar el puntero
	juego.seleccion = null
	var mm := InputEventMouseMotion.new()
	mm.position = _pantalla(Vector2i(0, 1))
	Input.parse_input_event(mm)
	await _esperar(0.4)
	comprobar(hud._ficha_flotante != null and hud._ficha_flotante.visible and hud._ff_titulo.text != "", "al pasar el puntero sale qué es y qué hace (%s)" % (hud._ff_titulo.text if hud._ff_titulo else ""))
	if _captura != "":
		get_viewport().get_texture().get_image().save_png(_captura.get_basename() + "_ficha.png")
		juego.camara.distancia = 34.0
		juego.camara._dist_obj = 34.0
		juego.seleccion = f.celdas.get(Vector2i(5, -6))
		await _esperar(1.5)
		get_viewport().get_texture().get_image().save_png(_captura.get_basename() + "_general.png")
	# comprar una parcela: clic en el terreno oscuro y comprar desde su panel
	f.dinero += 3000.0
	await _clic(Vector2i(9, 2))
	comprobar(juego.parcela_sel == juego.parcela_de(Vector2i(9, 2)), "clic en una parcela sin comprar: enseña su panel")
	var d0 := f.dinero
	var precio := juego.precio_parcela(juego.parcela_sel)
	juego.comprar_parcela(juego.parcela_sel)
	comprobar(juego.comprada(Vector2i(9, 2)) and is_equal_approx(f.dinero, d0 - precio), "parcela comprada por %d €" % precio)
	# guardar y cargar: la fábrica vuelve igual
	var n_ent := f.entidades.size()
	var din := f.dinero
	var hechas: Array = f.cepa_hechas.duplicate()
	Guardado.guardar(juego)
	f.dinero = 0.0
	Guardado.cargar(juego)
	comprobar(f.entidades.size() == n_ent and is_equal_approx(f.dinero, din) and f.cepa_hechas == hechas,
		"guardar y cargar deja la fábrica igual (%d piezas, %d €)" % [f.entidades.size(), int(f.dinero)])
	Guardado.borrar()
	print("PRUEBA RATON: %s" % ("OK" if fallos == 0 else "%d FALLOS" % fallos))
	if _captura != "":
		juego.seleccion = cam
		await _esperar(1.0)
		get_viewport().get_texture().get_image().save_png(_captura)
		juego.categoria = "HUD_CAT_PROCESADO"
		await _tecla(KEY_2)
		var m := InputEventMouseMotion.new()
		m.position = _pantalla(Vector2i(-2, 1))
		Input.parse_input_event(m)
		await _esperar(0.6)
		get_viewport().get_texture().get_image().save_png(_captura.get_basename() + "_construir.png")
	get_tree().quit(0 if fallos == 0 else 1)
