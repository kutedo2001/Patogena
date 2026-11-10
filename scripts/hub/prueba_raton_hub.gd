extends Node
## Prueba con ratón real del modo director (R2.1): «godot escenas/hub.tscn -- --prueba_hub [--capturas=/tmp/h]».
## Pulsa el menú, arrastra planos, pone puertas, coloca objetos y comprueba la simulación tras cada paso.

var j: JuegoHub
var fallos := 0
var _cap := ""
var _n := 0

func _init(juego: JuegoHub) -> void:
	j = juego

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="):
			_cap = a.trim_prefix("--capturas=")
	_guion.call_deferred()

func comprobar(ok: bool, t: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + t)
	if not ok:
		fallos += 1

func _esperar(n := 3) -> void:
	for i in n:
		await get_tree().process_frame

func _pantalla(c: Vector2i) -> Vector2:
	return j.camara.cam.unproject_position(VistaHub.centro(c))

func _mover(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p
	m.global_position = p
	Input.parse_input_event(m)
	await _esperar(2)

func _boton(p: Vector2, pulsado: bool) -> void:
	var b := InputEventMouseButton.new()
	b.position = p
	b.global_position = p
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = pulsado
	Input.parse_input_event(b)
	await _esperar(2)

func _clic(p: Vector2) -> void:
	await _mover(p)
	await _boton(p, true)
	await _boton(p, false)

func _arrastrar(a: Vector2, b: Vector2) -> void:
	await _mover(a)
	await _boton(a, true)
	for k in range(1, 6):
		await _mover(a.lerp(b, k / 5.0))
	await _boton(b, false)

func _captura(nombre: String) -> void:
	if _cap == "":
		return
	await _esperar(4)
	_n += 1
	get_viewport().get_texture().get_image().save_png("%s_%02d_%s.png" % [_cap, _n, nombre])

func _guion() -> void:
	await _esperar(10)
	var alto := get_viewport().get_visible_rect().size.y
	print("Prueba del modo director con ratón real:")
	var d0 := j.h.dinero
	# 1. menú Salas → extracción
	await _clic(Vector2(210, alto - 110))
	comprobar(j.hud.catalogo == "salas", "el botón Salas abre el catálogo de salas")
	await _captura("catalogo_salas")
	await _clic(Vector2(24 + 16 + 100, alto - 346 + 16 + 60))
	comprobar(j.modo == "sala_plano" and j.tipo == "extraccion", "elegir la sala de extracción pasa a dibujar el plano")
	# 2. plano demasiado pequeño y luego bueno
	await _arrastrar(_pantalla(Vector2i(1, 1)), _pantalla(Vector2i(2, 2)))
	comprobar(j.modo == "sala_plano" and "HUB_E_PEQUENA" in j.errores, "un plano de 2×2 dice que es pequeño y no sigue")
	await _arrastrar(_pantalla(Vector2i(1, 1)), _pantalla(Vector2i(3, 3)))
	comprobar(j.modo == "sala_puerta" and j.plano == Rect2i(1, 1, 3, 3), "arrastrar 3×3 pasa a poner la puerta")
	await _captura("plano")
	# 3. puerta abajo en el centro
	await _mover(_pantalla(Vector2i(2, 4)))
	await _captura("puerta")
	await _clic(_pantalla(Vector2i(2, 4)))
	var ex: Hospital.Sala = j.h.sala_en(Vector2i(2, 2))
	comprobar(ex != null and ex.puerta == Vector2i(2, 3) and ex.lado == 1, "clic bajo la sala: puerta abajo y sala construida")
	comprobar(j.modo == "objeto" and j.tipo == "camilla", "y pasa sola a colocar la camilla (obligatoria)")
	# 4. camilla contra la pared izquierda: no cabe el científico
	await _clic(_pantalla(Vector2i(1, 1)))
	comprobar(j.h.objeto_en(Vector2i(1, 1)) == null and "HUB_E_USO" in j.errores, "camilla pegada a la pared: no se coloca y dice por qué")
	await _mover(_pantalla(Vector2i(3, 1)))
	await _captura("camilla_fantasma")
	await _clic(_pantalla(Vector2i(3, 1)))
	comprobar(j.h.objeto_en(Vector2i(3, 2)) != null and j.tipo == "carrito_extraccion", "camilla colocada; pasa al carrito")
	await _clic(_pantalla(Vector2i(1, 1)))
	comprobar(ex != null and j.h.completa(ex) and j.modo == "" and j.seleccion == ex, "con el carrito la sala queda completa y seleccionada")
	await _captura("extraccion_lista")
	# 5. laboratorio de sangre pegado
	await _clic(Vector2(210, alto - 110))
	await _clic(Vector2(24 + 16 + 230 + 100, alto - 346 + 16 + 60))
	await _arrastrar(_pantalla(Vector2i(4, 1)), _pantalla(Vector2i(8, 4)))
	await _clic(_pantalla(Vector2i(5, 5)))
	var lab: Hospital.Sala = j.h.sala_en(Vector2i(6, 2))
	comprobar(lab != null and j.tipo == "centrifuga", "laboratorio 5×4 construido; pasa a la centrífuga")
	await _clic(_pantalla(Vector2i(6, 1)))
	comprobar(j.h.completa(lab), "centrífuga colocada con su consola delante: laboratorio listo")
	# 6. pasillo: banco y planta
	await _clic(_pantalla(Vector2i(12, 7)))
	comprobar(j.seleccion == null, "clic en el pasillo quita la selección")
	await _clic(Vector2(314, alto - 110))
	comprobar(j.hud.catalogo == "objetos", "el botón Objetos abre los objetos del pasillo")
	await _captura("catalogo_objetos")
	j.empezar_objeto("banco")
	await _clic(_pantalla(Vector2i(10, 5)))
	j.empezar_objeto("planta")
	await _clic(_pantalla(Vector2i(9, 5)))
	await _clic(_pantalla(Vector2i(12, 5)))
	var tecla := InputEventKey.new()
	tecla.keycode = KEY_ESCAPE
	tecla.pressed = true
	Input.parse_input_event(tecla)
	await _esperar(3)
	comprobar(j.h.objeto_en(Vector2i(10, 5)) != null and j.h.objeto_en(Vector2i(12, 5)) != null and j.modo == "", "banco y plantas en el pasillo; Esc termina")
	comprobar(j.h.dinero < d0, "todo se ha cobrado (%d € gastados)" % int(d0 - j.h.dinero))
	await _captura("final")
	print("PRUEBA RATON HUB: ", "OK" if fallos == 0 else "%d FALLOS" % fallos)
	get_tree().quit(1 if fallos else 0)
