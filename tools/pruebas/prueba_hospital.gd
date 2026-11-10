extends SceneTree
## Pruebas sin interfaz del edificio (R2.1): godot --headless -s tools/pruebas/prueba_hospital.gd
var fallos := 0

func comprobar(ok: bool, texto: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + texto)
	if not ok:
		fallos += 1

func _initialize() -> void:
	var h := Hospital.new()
	comprobar(h.parcela.size == Vector2i(16, 11) and h.entrada == Vector2i(8, 10), "parcela 16×11 con entrada abajo en el centro")
	# plano demasiado pequeño, fuera y bueno
	comprobar("HUB_E_PEQUENA" in h.validar_sala("extraccion", Rect2i(1, 1, 2, 3)), "una extracción de 2×3 es pequeña")
	comprobar("HUB_E_FUERA" in h.validar_sala("extraccion", Rect2i(14, 1, 3, 3)), "salirse de la parcela no vale")
	comprobar(h.validar_sala("extraccion", Rect2i(1, 1, 3, 3)).is_empty(), "una extracción de 3×3 vale (también girada)")
	comprobar(h.validar_sala("lab_sangre", Rect2i(5, 1, 3, 4)).is_empty(), "un laboratorio de 3×4 vale girado")
	# puerta
	comprobar(h.construir_sala("extraccion", Rect2i(1, 1, 3, 3), Vector2i(2, 2), 1) == null, "la puerta tiene que estar en el borde")
	var dinero0 := h.dinero
	var ex := h.construir_sala("extraccion", Rect2i(1, 1, 3, 3), Vector2i(2, 3), 1)
	comprobar(ex != null and is_equal_approx(h.dinero, dinero0 - 9 * 40), "extracción construida con la puerta abajo (360 €)")
	comprobar("HUB_E_OTRA_SALA" in h.validar_sala("lab_sangre", Rect2i(3, 1, 4, 3)), "no se pisan dos salas")
	var lab := h.construir_sala("lab_sangre", Rect2i(4, 1, 5, 4), Vector2i(5, 4), 1)
	comprobar(lab != null, "laboratorio pegado a la extracción (comparten pared)")
	comprobar(h.pared(Vector2i(3, 2), Vector2i(4, 2)), "entre las dos salas hay pared")
	comprobar(not h.pared(Vector2i(2, 3), Vector2i(2, 4)), "por la puerta se pasa")
	comprobar(h.pared(Vector2i(1, 3), Vector2i(1, 4)), "por el resto del borde no")
	var cam := h.camino(h.entrada, Vector2i(2, 2))
	comprobar(cam.size() > 0 and Vector2i(2, 3) in cam, "de la entrada al centro de la extracción se entra por la puerta (%d pasos)" % cam.size())
	# objetos
	comprobar(not h.completa(ex) and h.faltan(ex) == ["camilla", "llenadora_gradillas"], "le faltan la camilla y la llenadora")
	comprobar("HUB_E_ZONA" in h.validar_objeto("centrifuga", Vector2i(1, 1), 0), "una centrífuga no va en la extracción")
	comprobar("HUB_E_USO" in h.validar_objeto("camilla", Vector2i(1, 1), 0), "camilla pegada a la pared: no queda sitio para el científico")
	var c := h.poner_objeto("camilla", Vector2i(3, 1), 0)
	comprobar(c != null, "camilla con su sitio de trabajo a la izquierda")
	comprobar("HUB_E_OCUPADO" in h.validar_objeto("carrito_extraccion", Vector2i(3, 2), 0), "no se pone un objeto encima de otro")
	comprobar("HUB_E_PUERTA" in h.validar_objeto("carrito_extraccion", Vector2i(2, 3), 0), "no se tapa la puerta")
	comprobar("HUB_E_USO" in h.validar_objeto("carrito_extraccion", Vector2i(2, 1), 0), "no se tapa el sitio de trabajo de la camilla")
	h.poner_objeto("carrito_extraccion", Vector2i(1, 1), 0)
	comprobar(not h.completa(ex), "el carrito no basta")
	h.poner_objeto("llenadora_gradillas", Vector2i(1, 2), 0)
	comprobar(h.completa(ex), "con camilla y llenadora la extracción está completa")
	# no cortar caminos
	comprobar("HUB_E_CAMINO" in h.validar_objeto("planta", Vector2i(2, 4), 0) or "HUB_E_PUERTA" in h.validar_objeto("planta", Vector2i(2, 4), 0), "no se tapa la salida de una puerta")
	var cf := h.poner_objeto("centrifuga", Vector2i(6, 1), 0)
	comprobar(cf != null and h.completa(lab), "centrífuga en el laboratorio con su consola delante")
	comprobar("HUB_E_USO" in h.validar_objeto("planta", Vector2i(6, 3), 0), "no se tapa la consola de la centrífuga")
	# pasillo
	comprobar(h.poner_objeto("banco", Vector2i(10, 5), 0) != null, "banco en el pasillo")
	comprobar("HUB_E_ZONA" in h.validar_objeto("banco", Vector2i(7, 3), 0), "el banco no va en el laboratorio")
	comprobar(h.poner_objeto("recepcion", Vector2i(12, 8), 0) != null, "recepción en el pasillo con sitio detrás y delante")
	# vender
	var d1 := h.dinero
	h.vender_sala(lab)
	comprobar(h.salas.size() == 1 and h.objeto_en(Vector2i(6, 1)) == null and h.dinero > d1, "vender el laboratorio devuelve dinero y quita sus objetos")
	print("PRUEBA HOSPITAL: ", "OK" if fallos == 0 else "%d FALLOS" % fallos)
	quit(1 if fallos else 0)
