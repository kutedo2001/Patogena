extends SceneTree
## Pruebas sin interfaz de la operación (R2.3–R2.5): godot --headless -s tools/pruebas/prueba_planta.gd
var fallos := 0

func comprobar(ok: bool, texto: String) -> void:
	print(("  ok    " if ok else "  FALLO ") + texto)
	if not ok:
		fallos += 1

func _montar(p: Planta) -> void:
	var h := p.h
	h.dinero = 20000
	h.construir_sala("extraccion", Rect2i(9, 1, 3, 4), Vector2i(10, 4), 1)
	p.poner("camilla", Vector2i(11, 1), 0)
	p.poner("llenadora_gradillas", Vector2i(9, 2), 0)
	h.construir_sala("lab_sangre", Rect2i(3, 1, 6, 4), Vector2i(5, 4), 1)
	p.poner("centrifuga", Vector2i(5, 1), 0)
	p.poner("muelle", Vector2i(1, 2), 0)
	p.poner("banco", Vector2i(3, 6), 0)
	p.poner("banco", Vector2i(6, 6), 0)
	p.poner("recepcion", Vector2i(10, 8), 2)

func _simular(p: Planta, s: float) -> void:
	var t := 0.0
	while t < s:
		p.paso(Planta.PASO)
		t += Planta.PASO

func _initialize() -> void:
	seed(7)
	# --- a mano, con un becario
	var p := Planta.new(Hospital.new())
	_montar(p)
	comprobar(p.maquinas.size() == 4, "camilla, llenadora, centrífuga y muelle tienen estado de máquina")
	comprobar(p.contratar("cientifico") != null and p.contratar("tecnico") != null, "contratar científico y técnico")
	_simular(p, 15.0)
	var cient = p.personas.filter(func(q): return q.rol == "cientifico")[0]
	var tec = p.personas.filter(func(q): return q.rol == "tecnico")[0]
	comprobar(cient.estado == "trabajando" and cient.casilla() == Vector2i(10, 1), "el científico va a su sitio junto a la camilla (%s)" % cient.casilla())
	comprobar(tec.estado == "trabajando" and tec.casilla() == Vector2i(5, 3), "la técnica va a la consola de la centrífuga (%s)" % tec.casilla())
	var pac := p.personas.filter(func(q): return q.rol == "paciente")
	comprobar(pac.size() > 0, "llegan pacientes (%d)" % pac.size())
	_simular(p, 60.0)
	comprobar(p.atendidos >= 5, "se saca sangre a los pacientes (%d atendidos en 75 s)" % p.atendidos)
	var ll = p._llenadora(p.h.sala_en(Vector2i(10, 2)))
	comprobar(ll.salida.size() >= 1 or ll.tubos > 0, "la llenadora junta los tubos en gradillas (%d gradillas, %d tubos)" % [ll.salida.size(), ll.tubos])
	var sentados := p.personas.filter(func(q): return q.estado == "esperando").size()
	comprobar(sentados > 0, "hay pacientes esperando sentados (%d)" % sentados)
	comprobar(p.ventas.is_empty(), "sin becario ni cinta nada llega a la centrífuga ni se vende")
	p.contratar("becario")
	_simular(p, 120.0)
	comprobar(int(p.ventas.get("gradilla_hematies", 0)) >= 2, "con un becario las gradillas van a la centrífuga y los hematíes al muelle (%d vendidas)" % int(p.ventas.get("gradilla_hematies", 0)))
	comprobar(int(p.ventas.get("plasma_l", 0)) >= 6, "el plasma se vende por la tubería (%d l)" % int(p.ventas.get("plasma_l", 0)))
	# nadie se queda atascado ni atraviesa paredes: todas las personas en casillas andables
	var mal := 0
	for q in p.personas:
		if not p.h.dentro(q.casilla()):
			mal += 1
	comprobar(mal == 0, "todas las personas siguen dentro del edificio")
	# --- de pie, ordenados: sin científico se llena la sala de espera
	var pe := Planta.new(Hospital.new())
	_montar(pe)
	_simular(pe, 90.0)
	var de_pie := pe.personas.filter(func(q): return q.estado == "de_pie")
	var sitios := {}
	var mal_sitio := 0
	var usos := {}
	for o in pe.h.objetos:
		for u in o.usos():
			usos[u.c] = true
	for q in de_pie:
		var c: Vector2i = q.casilla()
		if sitios.has(c) or usos.has(c) or c == pe.h.entrada or pe.h.sala_en(c) != null:
			mal_sitio += 1
		sitios[c] = true
	comprobar(de_pie.size() >= 2 and mal_sitio == 0, "los que no tienen asiento esperan de pie cada uno en su casilla, sin tapar usos, puertas ni la entrada (%d de pie, %d mal)" % [de_pie.size(), mal_sitio])
	# --- con cintas y pasamuros
	var p2 := Planta.new(Hospital.new())
	_montar(p2)
	p2.contratar("cientifico")
	p2.contratar("tecnico")
	var d0 := p2.h.dinero
	comprobar(p2.poner_cinta(Vector2i(8, 2), 2) != null and p2.poner_cinta(Vector2i(7, 2), 2) != null, "cinta de la llenadora a la centrífuga")
	comprobar(p2.pasamuros.size() == 1, "la llenadora saca por la pared: se pone su pasamuros")
	comprobar(p2.poner_cinta(Vector2i(4, 2), 2) != null and p2.poner_cinta(Vector2i(3, 2), 2) != null and p2.poner_cinta(Vector2i(2, 2), 2) != null, "cinta de la centrífuga al muelle")
	comprobar(p2.pasamuros.size() == 2, "al cruzar la pared del laboratorio se pone otro (%d)" % p2.pasamuros.size())
	comprobar("HUB_E_PUERTA" in p2.validar_cinta(Vector2i(5, 4), 1), "una cinta no puede salir por una puerta")
	_simular(p2, 150.0)
	comprobar(int(p2.ventas.get("gradilla_hematies", 0)) >= 2, "sin becario, por cinta: %d gradillas de hematíes vendidas" % int(p2.ventas.get("gradilla_hematies", 0)))
	print("PRUEBA PLANTA: ", "OK" if fallos == 0 else "%d FALLOS" % fallos)
	quit(1 if fallos else 0)
