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
	if juego.tutorial.leyendo:
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
	var f := juego.fab
	print("Prueba del nuevo inicio con ratón y teclado:")
	comprobar(juego.tutorial.leyendo, "empieza con el correo de bienvenida y el juego en pausa")
	await _correo()
	await _tecla(KEY_W, 1.2)
	comprobar(juego.tutorial.paso_actual() == "PASO_CAMILLA", "moverse con WASD pasa al paso de la camilla")
	await _construir("HUD_CAT_EXTRACCION", KEY_1, Vector2i(-2, 1))
	var cam: Fabrica.Estacion = f.celdas.get(Vector2i(-2, 1))
	comprobar(cam != null, "camilla construida")
	await _correo()
	# extraer: clic en la camilla, el científico va, espera al paciente y saca sangre
	await _clic(Vector2i(-2, 1))
	var ok := await _hasta(func(): return juego.mano_n >= 1, 25.0)
	comprobar(ok and juego.mano_obj == "tubo_sangre", "el científico va a la camilla, espera al paciente y saca sangre")
	await _construir("HUD_CAT_PROCESADO", KEY_1, Vector2i(0, 1))
	comprobar(f.celdas.get(Vector2i(0, 1)) is Fabrica.MaquinaSim, "centrífuga construida")
	await _clic(Vector2i(0, 1))
	ok = await _hasta(func(): return juego.mano_n == 0, 10.0)
	comprobar(ok, "deja la sangre en la centrífuga al hacer clic")
	await _hasta(func(): return juego.tutorial.leyendo, 8.0)
	comprobar(juego.tutorial.leyendo, "con el primer plasma llega el correo del biorreactor")
	await _correo()
	# segunda sangre
	await _clic(Vector2i(-2, 1))
	await _hasta(func(): return juego.mano_n >= 1, 25.0)
	await _clic(Vector2i(0, 1))
	await _hasta(func(): return juego.mano_n == 0, 10.0)
	ok = await _hasta(func(): return f.producido.get("tubo_plasma", 0) >= 2, 15.0)
	comprobar(ok, "la centrífuga trabaja sola y hace 2 plasmas sin clic")
	await _correo()
	await _construir("HUD_CAT_PRODUCTO", KEY_1, Vector2i(2, 0))
	comprobar(f.celdas.get(Vector2i(3, 1)) is Fabrica.MaquinaSim, "biorreactor construido")
	await _clic(Vector2i(0, 1))
	await _hasta(func(): return juego.mano_n >= 2, 10.0)
	comprobar(juego.mano_obj == "tubo_plasma" and juego.mano_n == 2, "recoge 2 plasmas de la centrífuga (se ven en las manos)")
	await _clic(Vector2i(2, 0))
	ok = await _hasta(func(): return f.producido.get("vial_mutacion", 0) >= 1, 20.0)
	comprobar(ok, "el biorreactor hace el vial solo")
	await _clic(Vector2i(2, 0))
	await _hasta(func(): return juego.mano_obj.begins_with("vial"), 10.0)
	await _clic(Vector2i(4, -3))
	ok = await _hasta(func(): return f.mutaciones >= 1, 15.0)
	comprobar(ok and juego.liberado, "lleva el vial a la cámara de cepa: primera mutación y virus liberado")
	comprobar(juego.hitos_pagados[2], "Dirección paga el hito de la primera mutación")
	await _correo()
	# vender: más sangre → plasma → muelle
	await _clic(Vector2i(-2, 1))
	await _hasta(func(): return juego.mano_n >= 1, 25.0)
	await _clic(Vector2i(0, 1))
	await _esperar(5.0)
	await _clic(Vector2i(0, 1))
	await _hasta(func(): return juego.mano_obj == "tubo_plasma", 10.0)
	var ing := f.ingresos
	await _clic(Vector2i(6, 4))
	ok = await _hasta(func(): return f.ingresos > ing, 15.0)
	comprobar(ok, "vende plasma en el muelle de envío")
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
	await _clic(Vector2i(0, 0), MOUSE_BUTTON_RIGHT)
	comprobar(f.celdas.get(Vector2i(-1, 1)) is Fabrica.Cinta, "cinta de la camilla a la centrífuga")
	juego.velocidad = 3.0
	ok = await _hasta(func(): return juego.zombis_libres > 0, 30.0)
	comprobar(ok, "llega un zombi trabajador tras liberar el virus")
	juego.asignar_zombi(cam)
	var p0: int = f.producido.get("tubo_plasma", 0)
	ok = await _hasta(func(): return f.producido.get("tubo_plasma", 0) >= p0 + 2, 30.0)
	comprobar(cam.modo == "zombi" and ok, "con el zombi la camilla trabaja sola y la sangre llega por cinta")
	juego.velocidad = 1.0
	var d := f.dinero
	await _clic(Vector2i(-1, 1), MOUSE_BUTTON_RIGHT)
	comprobar(not f.celdas.has(Vector2i(-1, 1)) and is_equal_approx(f.dinero, d + 5.0), "quitar devuelve el 100 %")
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
