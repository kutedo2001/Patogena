class_name Guardado
extends RefCounted
## Guardar y cargar la partida (V1.11): la fábrica entera, la mochila, las parcelas, la cepa, el mundo
## y el tutorial en user://partida.json. Se guarda solo cada minuto y al salir.

const RUTA := "user://partida.json"
const VERSION := 1

static func hay_partida() -> bool:
	return FileAccess.file_exists(RUTA)

static func borrar() -> void:
	if hay_partida():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(RUTA))

static func _v(c: Vector2i) -> Array:
	return [c.x, c.y]

static func _c(a) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))

static func guardar(j: Juego) -> void:
	var f := j.fab
	var ents: Array = []
	for e in f.entidades:
		var d := {"c": _v(e.casillas[0]), "g": e.giro}
		if e is Fabrica.Tuberia:
			d.t = "tuberia"; d.o = e.objetos
		elif e is Fabrica.Cinta:
			d.t = "cinta"; d.n = e.nivel; d.o = e.objetos
		elif e is Fabrica.MaquinaSim:
			if e == j._cepa:
				continue
			d.t = "maquina"; d.tipo = e.tipo; d.org = _v(e.origen); d.r = e.receta; d.en = e.entrada; d.sa = e.salida; d.p = e.progreso
		elif e is Fabrica.Brazo:
			d.t = "brazo"; d.fl = e.filtro; d.m = e.mano
		elif e is Fabrica.Divisor:
			d.t = "divisor"
		elif e is Fabrica.Almacen:
			d.t = "almacen"; d.co = e.contenido
		elif e is Fabrica.Estacion:
			d.t = "estacion"; d.tipo = e.tipo; d.modo = e.modo; d.li = e.listo; d.p = e.progreso; d.cr = e.crecimiento
		elif e is Fabrica.SalaEspera:
			d.t = "sala_espera"
		elif e is Fabrica.Generador:
			d.t = "generador"; d.tipo = e.tipo; d.cb = e.combustible
		elif e is Fabrica.Capsula:
			d.t = "capsula"; d.tipo = e.tipo; d.h = e.humanos; d.su = e.suero; d.nu = e.nutricion
		elif e is Fabrica.Deposito:
			d.t = "deposito"; d.l = e.litros
		elif e is Fabrica.MuelleEnvio:
			d.t = "muelle"; d.de = e.destino; d.ca = e.carga; d.vi = e.viajes
		else:
			continue
		ents.append(d)
	var regs: Array = []
	for r in j.mundo.regiones:
		regs.append([r.s, r.i, r.z])
	var mochila: Array = []
	for m in j.mochila:
		mochila.append(m)
	var compradas: Array = []
	for p in j.compradas:
		compradas.append(_v(p))
	var datos := {
		"version": VERSION, "ents": ents, "dinero": f.dinero, "ingresos": f.ingresos, "tiempo": f.tiempo,
		"producido": f.producido, "vendido": f.vendido, "vacunas": f.vacunas_vendidas, "destinos": f.vendidas_destino,
		"cepa_hechas": f.cepa_hechas, "cepa_actual": f.cepa_actual, "cepa_entregado": f.cepa_entregado,
		"espera": f.espera_pacientes, "campana": [f.campana_mult, f.campana_t, f.contrato_mult],
		"compradas": compradas, "desbloqueadas": j.desbloqueadas.keys(), "mochila": mochila, "mano": j.mano_i,
		"pos": [j.pos.x, j.pos.y], "zombis": j.zombis_libres, "liberado": j.liberado, "fases": j._fases_vistas,
		"vend_dest": j._vendidas_dest, "vend_prev": j._vendidas_previas, "tutorial": j.tutorial.i,
		"mundo": {"regs": regs, "cura": j.mundo.cura, "detectado": j.mundo.detectado}, "muelle_carga": j._muelle_carga.contenido,
	}
	var fa := FileAccess.open(RUTA, FileAccess.WRITE)
	if fa:
		fa.store_string(JSON.stringify(datos))

static func cargar(j: Juego) -> bool:
	if not hay_partida():
		return false
	var fa := FileAccess.open(RUTA, FileAccess.READ)
	var d = JSON.parse_string(fa.get_as_text())
	if not (d is Dictionary) or int(d.get("version", 0)) != VERSION:
		return false
	var f := j.fab
	# las fijas (sala de cepas, muelle, muelle de carga) ya están; se quitan las demás y se reponen
	for e in f.entidades.duplicate():
		if e != j._cepa and e != j._muelle_carga and not e is Fabrica.MuelleEnvio:
			f.quitar(e.casillas[0])
	for x in d.ents:
		var c := _c(x.c)
		var g := int(x.g)
		match str(x.t):
			"cinta":
				var e := f.poner_cinta(c, g, int(x.n))
				if e: e.objetos = x.o
			"tuberia":
				var e2 := f.poner_tuberia(c, g)
				if e2: e2.objetos = x.o
			"maquina":
				var m := f.poner_maquina(str(x.tipo), _c(x.org), g)
				if m:
					m.poner_receta(str(x.r))
					m.entrada = {}
					for k in x.en: m.entrada[k] = int(x.en[k])
					m.salida = x.sa
					m.progreso = float(x.p)
			"brazo":
				var b := f.poner_brazo(c, g, str(x.fl))
				if b: b.mano = str(x.m)
			"divisor": f.poner_divisor(c, g)
			"almacen":
				var a := f.poner_almacen(c, g)
				if a: a.contenido = x.co
			"estacion":
				var es := f.poner_estacion(str(x.tipo), c, g)
				if es:
					es.modo = str(x.modo); es.listo = str(x.li); es.progreso = float(x.p); es.crecimiento = float(x.cr)
			"sala_espera": f.poner_sala_espera(c, g)
			"generador":
				var ge := f.poner_generador(str(x.tipo), c, g)
				if ge: ge.combustible = int(x.cb)
			"capsula":
				var ca := f.poner_capsula(str(x.tipo), c, g)
				if ca: ca.humanos = int(x.h); ca.suero = int(x.su); ca.nutricion = float(x.nu)
			"deposito":
				var de := f.poner_deposito(c, g)
				if de: de.litros = int(x.l)
			"muelle":
				j.muelle.destino = str(x.de); j.muelle.carga = int(x.ca); j.muelle.viajes = int(x.vi)
	f.dinero = float(d.dinero); f.ingresos = float(d.ingresos); f.tiempo = float(d.tiempo)
	f.producido = d.producido; f.vendido = d.vendido; f.vacunas_vendidas = int(d.vacunas); f.vendidas_destino = d.destinos
	f.cepa_hechas = d.cepa_hechas; f.cepa_actual = str(d.cepa_actual); f.cepa_entregado = d.cepa_entregado
	f.espera_pacientes = int(d.espera)
	f.campana_mult = float(d.campana[0]); f.campana_t = float(d.campana[1]); f.contrato_mult = float(d.campana[2])
	j.compradas.clear()
	for p in d.compradas:
		j.compradas[_c(p)] = true
	j.desbloqueadas.clear()
	for k in d.desbloqueadas:
		j.desbloqueadas[k] = true
	for i in mini(j.mochila.size(), d.mochila.size()):
		var m: Dictionary = d.mochila[i]
		j.mochila[i] = {} if m.is_empty() else {"o": str(m.o), "n": int(m.n)}
	j.mano_i = int(d.mano)
	j.pos = Vector2(float(d.pos[0]), float(d.pos[1]))
	j.liberado = bool(d.liberado)
	j._fases_vistas = int(d.fases)
	j._vendidas_dest = d.vend_dest
	j._vendidas_previas = int(d.vend_prev)
	for i in mini(j.mundo.regiones.size(), d.mundo.regs.size()):
		var r: Dictionary = j.mundo.regiones[i]
		r.s = float(d.mundo.regs[i][0]); r.i = float(d.mundo.regs[i][1]); r.z = float(d.mundo.regs[i][2])
	j.mundo.cura = float(d.mundo.cura)
	j.mundo.detectado = bool(d.mundo.detectado)
	j._muelle_carga.contenido = d.muelle_carga
	for k in int(d.zombis):
		j._llega_zombi()
	j.tutorial.saltar_a(int(d.tutorial))
	j._marcar_parcelas()
	return true
