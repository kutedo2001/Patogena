class_name PruebaRaton
extends Node
## Prueba con entrada real (P4.2–P4.4): manda eventos de ratón y teclado como un jugador
## y comprueba el resultado. Se activa con «-- --prueba_raton»; imprime y cierra.
##   1. Extrae sangre a mano manteniendo el clic sobre un donante.
##   2. Construye una centrífuga y un biorreactor, tiende cintas arrastrando.
##   3. Echa la sangre a mano en la centrífuga, recoge el plasma y lo echa al biorreactor.
##   4. Pone un extractor en el donante y deja que la cadena llegue sola a la cámara de cepa.
##   5. Quita una cinta (devolución del 100 %) y prueba un pedido de reactivo.

var juego: Juego
var fallos := 0
var _captura := ""

func _ready() -> void:
	Input.use_accumulated_input = false   # que cada evento llegue en su orden, como un ratón real
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--captura_final="):
			_captura = a.trim_prefix("--captura_final=")
	_guion.call_deferred()

func comprobar(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALLO ") + t)
	if not c:
		fallos += 1

func _pantalla(c: Vector2i) -> Vector2:
	var cam := get_viewport().get_camera_3d()
	return cam.unproject_position(Vector3(c.x + 0.5, 0, c.y + 0.5))

func _raton(c: Vector2i, boton := MOUSE_BUTTON_LEFT, pulsado := true) -> void:
	var m := InputEventMouseMotion.new()
	m.position = _pantalla(c)
	Input.parse_input_event(m)
	var e := InputEventMouseButton.new()
	e.button_index = boton
	e.pressed = pulsado
	e.position = _pantalla(c)
	Input.parse_input_event(e)

func _mover(c: Vector2i) -> void:
	var m := InputEventMouseMotion.new()
	m.position = _pantalla(c)
	Input.parse_input_event(m)

func _clic(c: Vector2i, boton := MOUSE_BUTTON_LEFT) -> void:
	_raton(c, boton, true)

	await get_tree().process_frame
	_raton(c, boton, false)
	await get_tree().process_frame

func _tecla(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await get_tree().process_frame

func _esperar(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _guion() -> void:
	await _esperar(1.0)
	var f := juego.fab
	print("Prueba con ratón y teclado:")
	# 1. extracción a mano
	_raton(Vector2i(-7, -4))
	await _esperar(2.3)
	_raton(Vector2i(-7, -4), MOUSE_BUTTON_LEFT, false)
	await get_tree().process_frame
	comprobar(juego.inventario.get("tubo_sangre", 0) >= 2, "extracción a mano: %d tubos de sangre" % juego.inventario.get("tubo_sangre", 0))
	# 2. centrífuga con la tecla 1 y clic; biorreactor desde su categoría
	var dinero0 := f.dinero
	juego.categoria = "HUD_CAT_PROCESADO"
	await _tecla(KEY_1)
	_mover(Vector2i(-3, -4))
	await _esperar(0.2)
	await _clic(Vector2i(-3, -4))
	comprobar(f.celdas.get(Vector2i(-3, -4)) is Fabrica.MaquinaSim, "centrífuga construida con clic")
	comprobar(is_equal_approx(f.dinero, dinero0 - 300.0), "se cobra la centrífuga (300 €)")
	juego.categoria = "HUD_CAT_PRODUCTO"
	await _tecla(KEY_1)
	await _clic(Vector2i(1, -5))
	comprobar(f.celdas.get(Vector2i(2, -4)) is Fabrica.MaquinaSim, "biorreactor 2×2 construido")
	# cintas arrastrando: centrífuga → biorreactor, biorreactor → cámara de cepa
	juego.categoria = "HUD_CAT_LOGISTICA"
	await _tecla(KEY_1)
	_raton(Vector2i(-2, -4))
	await get_tree().process_frame
	_mover(Vector2i(-1, -4))
	await get_tree().process_frame
	_raton(Vector2i(0, -4), MOUSE_BUTTON_LEFT, false)
	await get_tree().process_frame
	await _clic(Vector2i(3, -4))
	comprobar(f.celdas.get(Vector2i(-2, -4)) is Fabrica.Cinta and f.celdas.get(Vector2i(0, -4)) is Fabrica.Cinta, "cinta de 3 casillas tendida arrastrando")
	await _clic(Vector2i(0, 0), MOUSE_BUTTON_RIGHT)       # cancelar herramienta
	comprobar(juego.herramienta.is_empty(), "clic derecho cancela la herramienta")
	# 3. a mano: sangre a la centrífuga, recoger plasma
	await _clic(Vector2i(-3, -4))
	comprobar(juego.inventario.get("tubo_sangre", 0) == 0, "la sangre se echa en la centrífuga con un clic")
	await _esperar(7.0)
	comprobar(f.producido.get("tubo_plasma", 0) >= 2, "la centrífuga hace plasma (%d)" % f.producido.get("tubo_plasma", 0))
	# 4. extractor sobre el donante y cinta hasta la centrífuga
	juego.categoria = "HUD_CAT_EXTRACCION"
	await _tecla(KEY_1)
	await _clic(Vector2i(-7, -4))
	comprobar(f.celdas.get(Vector2i(-7, -4)) is Fabrica.Extractor, "extractor sobre el donante")
	juego.categoria = "HUD_CAT_LOGISTICA"
	await _tecla(KEY_1)
	_raton(Vector2i(-6, -4))
	await get_tree().process_frame
	_raton(Vector2i(-4, -4), MOUSE_BUTTON_LEFT, false)
	await get_tree().process_frame
	await _clic(Vector2i(0, 0), MOUSE_BUTTON_RIGHT)
	juego.velocidad = 3.0
	await _esperar(25.0)
	comprobar(f.producido.get("vial_mutacion", 0) >= 1, "el biorreactor hace un vial (%d)" % f.producido.get("vial_mutacion", 0))
	comprobar(f.mutaciones >= 1 and juego.liberado, "primera mutación en la cámara de cepa y virus liberado")
	comprobar(juego.hito(0).x > 0 and juego.hito(2).x == 1, "los hitos avanzan (plasma %d/10, mutación %d/1)" % [juego.hito(0).x, juego.hito(2).x])
	# un segundo vial igual se rechaza
	await _esperar(8.0)
	comprobar(f.mutaciones == 1 and f.desechados >= 1, "la cámara desecha la misma mutación repetida sin atascarse")
	# cambiar receta desde el panel (API) da una segunda mutación con plasma
	juego.seleccion = f.celdas[Vector2i(1, -5)]
	juego.elegir_receta("estornudos")
	await _esperar(30.0)
	comprobar(f.mutaciones >= 2, "otra receta de mutación llega a la cámara (%d)" % f.mutaciones)
	juego.velocidad = 1.0
	# 5. quitar con devolución y pedido
	var d1 := f.dinero
	juego.categoria = "HUD_CAT_LOGISTICA"
	await _tecla(KEY_1)
	await _clic(Vector2i(0, 2))
	await _clic(Vector2i(0, 0), MOUSE_BUTTON_RIGHT)
	await _clic(Vector2i(0, 2), MOUSE_BUTTON_RIGHT)
	comprobar(not f.celdas.has(Vector2i(0, 2)) and is_equal_approx(f.dinero, d1), "quitar en los primeros 10 s devuelve el 100 %")
	var d2 := f.dinero
	await _clic(Vector2i(-6, 4))
	comprobar(juego.pedidos_en_camino() == 1 and is_equal_approx(f.dinero, d2 - 14.0), "pedido de reactivo desde el terminal")
	print("PRUEBA RATON: %s" % ("OK" if fallos == 0 else "%d FALLOS" % fallos))
	if _captura != "":
		juego.seleccion = f.celdas[Vector2i(1, -5)]
		await _esperar(1.0)
		get_viewport().get_texture().get_image().save_png(_captura)
		# segunda captura: construyendo (fantasma y ficha) y arrastrando una cinta
		juego.categoria = "HUD_CAT_PROCESADO"
		await _tecla(KEY_2)
		_mover(Vector2i(-3, 0))
		await _esperar(0.6)
		get_viewport().get_texture().get_image().save_png(_captura.get_basename() + "_construir.png")
	get_tree().quit(0 if fallos == 0 else 1)
