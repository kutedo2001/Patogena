class_name Planta
extends RefCounted
## Operación del laboratorio (R2.3–R2.5) sobre el edificio (Hospital): personal que va a su puesto, pacientes que
## entran, esperan sentados, se tumban en la camilla y se van; máquinas con bocas fijas (llenadora de gradillas,
## centrífuga de paso, muelle de venta); cintas que llevan las gradillas y cruzan paredes por pasamuros; becarios
## que lo llevan a mano mientras no hay cinta. Simulación pura a pasos fijos: la vista solo dibuja este estado.

const PASO := 0.05
var h: Hospital
var personas: Array = []
var maquinas := {}          # Objeto.id → Equipo
var cintas := {}            # Vector2i → Cinta
var pasamuros := {}         # clave de borde → true
var plasma_l := 0.0
var ventas := {}            # objeto → unidades vendidas
var ingresos := 0.0
var atendidos := 0
var tiempo := 0.0
var reputacion := 1.0
var _acum := 0.0
var _t_llegada := 2.0
var _id := 0
var R := {}                 # ritmo
var P := {}                 # precios

func _init(hospital: Hospital) -> void:
	h = hospital
	R = Hospital.datos.ritmo
	P = Hospital.datos.precios

# ------------------------------------------------------------------ clases
class Persona:
	var id := 0
	var rol := ""               # paciente, cientifico, tecnico, becario
	var modelo := ""
	var pos := Vector2()        # en casillas (centro de casilla = +0,5)
	var ruta: Array = []        # casillas por recorrer
	var estado := ""
	var t := 0.0
	var lleva := ""             # objeto en las manos
	var sala: Hospital.Sala = null
	var objeto: Hospital.Objeto = null    # mueble o máquina en uso / destino
	var asiento := -1
	var sitio := Vector2i(-999, -999)   # paciente de pie: casilla reservada para esperar
	var destino: Hospital.Objeto = null   # becario: adónde lo lleva
	var mira := Vector2i(0, 1)
	var anim := "Idle_A"
	func casilla() -> Vector2i:
		return Vector2i(floori(pos.x), floori(pos.y))

class Equipo:
	var o: Hospital.Objeto
	var entrada: Array = []     # objetos esperando a entrar (se ven en la tolva)
	var salida: Array = []      # objetos hechos esperando a salir
	var tubos := 0              # llenadora: tubos en la gradilla abierta
	var proceso := -1.0         # ≥0: segundos de proceso del objeto actual
	var actual := ""
	var trabajando := false

class Cinta:
	var c := Vector2i()
	var dir := Vector2i(1, 0)
	var items: Array = []       # [objeto, avance 0..1]

static func clave_borde(a: Vector2i, b: Vector2i) -> Array:
	return [mini(a.x, b.x), mini(a.y, b.y), maxi(a.x, b.x), maxi(a.y, b.y)]

# ------------------------------------------------------------------ construir (pasa por aquí para crear el estado de máquinas y cintas)
func poner(tipo: String, origen: Vector2i, giro: int) -> Hospital.Objeto:
	if tipo == "cinta":
		return poner_cinta(origen, giro)
	var o := h.poner_objeto(tipo, origen, giro)
	if o and Hospital.datos.objetos[tipo].has("bocas") or (o and tipo == "camilla"):
		var m := Equipo.new()
		m.o = o
		maquinas[o.id] = m
	return o

## Cinta en c hacia DIRS[giro]. Si apunta a través de una pared, pone un pasamuros (no en una puerta).
func validar_cinta(c: Vector2i, giro: int) -> Array:
	var e := h.validar_objeto("cinta", c, 0)
	if not e.is_empty():
		return e
	var n: Vector2i = c + Hospital.DIRS[giro]
	if h.pared(c, n):
		for s in h.salas:
			if (s.puerta == c and s.fuera() == n) or (s.puerta == n and s.fuera() == c):
				return ["HUB_E_PUERTA"]
		if h.dinero < float(P.pasamuros) + 20.0:
			return ["HUB_E_DINERO"]
	return []

func poner_cinta(c: Vector2i, giro: int) -> Hospital.Objeto:
	if not validar_cinta(c, giro).is_empty():
		return null
	var o := h.poner_objeto("cinta", c, 0)
	o.giro = giro
	var ci := Cinta.new()
	ci.c = c
	ci.dir = Hospital.DIRS[giro]
	cintas[c] = ci
	var n: Vector2i = c + ci.dir
	if h.pared(c, n):
		_pasamuros(c, n)
	# la salida de una máquina pegada a la pared también necesita su pasamuros para llegar a esta cinta
	for m in maquinas.values():
		for b in bocas(m.o):
			if b.c == c and h.pared(b.c, b.dentro):
				_pasamuros(b.c, b.dentro)
	return o

func _pasamuros(a: Vector2i, b: Vector2i) -> void:
	if not pasamuros.has(clave_borde(a, b)):
		pasamuros[clave_borde(a, b)] = true
		h.dinero -= float(P.pasamuros)

func quitar(o: Hospital.Objeto) -> void:
	if o.tipo == "cinta":
		cintas.erase(o.origen)
	maquinas.erase(o.id)
	h.quitar_objeto(o)

func vender_sala(s: Hospital.Sala) -> void:
	for o in h.objetos_de(s):
		maquinas.erase(o.id)
		if o.tipo == "cinta":
			cintas.erase(o.origen)
	for p in personas:
		if p.objeto and p.objeto.sala == s:
			if p.rol == "paciente":
				p.objeto = null
				_ir(p, h.entrada, "saliendo")
			else:
				p.objeto = null
				p.sala = null
				p.ruta = []
				p.estado = "libre"
	h.vender_sala(s)

func contratar(rol: String) -> Persona:
	var d: Dictionary = Hospital.datos.personal[rol]
	if h.dinero < float(d.precio):
		return null
	h.dinero -= float(d.precio)
	var p := _nueva(rol, d.modelos[_id % d.modelos.size()])
	p.estado = "libre"
	return p

func _nueva(rol: String, modelo: String) -> Persona:
	var p := Persona.new()
	_id += 1
	p.id = _id
	p.rol = rol
	p.modelo = modelo
	p.pos = Vector2(h.entrada) + Vector2(0.5, 0.5)
	personas.append(p)
	return p

# ------------------------------------------------------------------ bocas
## Bocas del objeto en coordenadas del edificio: {c (casilla de fuera), dir (sentido del flujo), tipo, acepta, dentro}
func bocas(o: Hospital.Objeto) -> Array:
	var r := []
	for b in o.dato().get("bocas", []):
		var c: Vector2i = o.origen + Hospital.girar(Vector2i(int(b.c[0]), int(b.c[1])), o.giro)
		var d: Vector2i = Hospital.girar(Hospital.DIRS[int(b.dir)], o.giro)
		r.append({"c": c, "dir": d, "tipo": b.tipo, "acepta": b.get("acepta", "*"), "dentro": c + d if b.tipo == "entrada" else c - d})
	return r

func acepta(m: Equipo, objeto: String) -> bool:
	match m.o.tipo:
		"centrifuga":
			return objeto == "gradilla_sangre" and m.entrada.size() < 3
		"muelle":
			return true
	return false

func meter(m: Equipo, objeto: String) -> void:
	if m.o.tipo == "muelle":
		_vender(objeto)
	else:
		m.entrada.append(objeto)

func _vender(objeto: String) -> void:
	var precio := float(P.get(objeto, 10))
	h.dinero += precio
	ingresos += precio
	ventas[objeto] = int(ventas.get(objeto, 0)) + 1

# ------------------------------------------------------------------ simulación
func avanzar(dt: float) -> void:
	_acum += dt
	while _acum >= PASO:
		_acum -= PASO
		paso(PASO)

func paso(dt: float) -> void:
	tiempo += dt
	_llegadas(dt)
	_asignar()
	for p in personas.duplicate():
		_persona(p, dt)
	for m in maquinas.values():
		_maquina(m, dt)
	_cintas(dt)
	# sueldos y plasma (se vende solo por la tubería de la red)
	for p in personas:
		if p.rol != "paciente":
			h.dinero -= float(Hospital.datos.personal[p.rol].sueldo_min) / 60.0 * dt
	if plasma_l > 1.0:
		var v := floorf(plasma_l)
		plasma_l -= v
		h.dinero += v * float(P.plasma_l)
		ingresos += v * float(P.plasma_l)
		ventas["plasma_l"] = int(ventas.get("plasma_l", 0)) + int(v)

func asientos() -> Array:
	var r := []
	for o in h.objetos:
		if o.tipo == "banco":
			for i in int(o.dato().get("asientos", 3)):
				r.append([o, i])
	return r

## Sitio para esperar de pie: pasillo libre cerca de los bancos, pegado a una pared u objeto
## (no en medio del paso), sin tapar usos, puertas ni la entrada, y uno por persona.
func _sitio_de_pie(p: Persona) -> Vector2i:
	var prohibidas := {h.entrada: true}
	for o in h.objetos:
		for u in o.usos():
			prohibidas[u.c] = true
	for s in h.salas:
		prohibidas[s.fuera()] = true
	for q in personas:
		if q != p and q.sitio.x > -900:
			prohibidas[q.sitio] = true
	var origen := p.casilla()
	var bancos := h.objetos.filter(func(o): return o.tipo == "banco")
	if not bancos.is_empty():
		origen = _uso_libre_cerca(bancos[0])
	var dist := {origen: 0}
	var cola := [origen]
	var mejor := Vector2i(-999, -999)
	var pmin := INF
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		var d: int = dist[c]
		if d > 8:
			break
		if h.sala_en(c) == null and h.andable(c) and not cintas.has(c) and not prohibidas.has(c):
			var pegado := false
			for dd in Hospital.DIRS:
				var n: Vector2i = c + dd
				if not h.dentro(n) or h.pared(c, n) or not h.andable(n) or h.sala_en(n) != null:
					pegado = true
			var punt := float(d) + (0.0 if pegado else 4.0)
			if punt < pmin:
				pmin = punt
				mejor = c
		for dd in Hospital.DIRS:
			var n: Vector2i = c + dd
			if not dist.has(n) and h.dentro(n) and not h.pared(c, n) and h.andable(n):
				dist[n] = d + 1
				cola.append(n)
	return mejor

func _uso_libre_cerca(o: Hospital.Objeto) -> Vector2i:
	for u in o.usos():
		return u.c
	return o.origen

func _mira_a_bancos(p: Persona) -> Vector2i:
	var c := p.casilla()
	var rec := _buscar("recepcion")
	var meta := Vector2(h.entrada) if rec == null else Vector2(rec.origen)
	var bancos := h.objetos.filter(func(o): return o.tipo == "banco")
	if not bancos.is_empty():
		meta = Vector2((bancos[0] as Hospital.Objeto).origen)
	var v := meta - Vector2(c)
	if absf(v.x) > absf(v.y):
		return Vector2i(signi(int(v.x)), 0)
	return Vector2i(0, signi(int(v.y)) if v.y != 0 else 1)

func _ocupado(o: Hospital.Objeto, i: int) -> bool:
	for p in personas:
		if p.objeto == o and p.asiento == i:
			return true
	return false

func _llegadas(dt: float) -> void:
	_t_llegada -= dt
	var pacientes := personas.filter(func(p): return p.rol == "paciente").size()
	var camillas := h.objetos.filter(func(o): return o.tipo == "camilla").size()
	if camillas == 0:
		return
	if _t_llegada <= 0.0 and pacientes < asientos().size() + 3:
		_t_llegada = float(R.llegada_s) / reputacion
		var mods: Array = Hospital.datos.pacientes_modelos
		var p := _nueva("paciente", mods[randi() % mods.size()])
		var rec := _buscar("recepcion")
		if rec:
			_ir(p, _uso(rec, "paciente"), "a_recepcion")
			p.objeto = rec
		else:
			p.estado = "a_esperar"

func _buscar(tipo: String) -> Hospital.Objeto:
	for o in h.objetos:
		if o.tipo == tipo:
			return o
	return null

func _uso(o: Hospital.Objeto, quien: String) -> Vector2i:
	for u in o.usos():
		if u.quien == quien or u.quien == "todos":
			return u.c
	return o.origen

func _ir(p: Persona, meta: Vector2i, estado: String) -> bool:
	var cam := h.camino(p.casilla(), meta)
	if cam.is_empty():
		return false
	cam.pop_front()
	p.ruta = cam
	p.estado = estado
	return true

## Casilla libre vecina de un objeto, alcanzable (para coger o dejar cosas).
func _junto_a(p: Persona, o: Hospital.Objeto) -> Vector2i:
	var mejor := Vector2i(-999, -999)
	var dmin := INF
	for c in o.celdas():
		for d in Hospital.DIRS:
			var n: Vector2i = c + d
			if n in o.celdas() or not h.andable(n) or h.pared(c, n) or cintas.has(n):
				continue
			var dist := Vector2(n).distance_squared_to(p.pos)
			if dist < dmin:
				dmin = dist
				mejor = n
	return mejor

## Personal libre a su puesto: un científico por camilla, un técnico por centrífuga (o un científico si no hay).
func _asignar() -> void:
	for o in h.objetos:
		var quien := ""
		if o.tipo == "camilla":
			quien = "cientifico"
		elif o.tipo == "centrifuga":
			quien = "tecnico"
		else:
			continue
		var ya := false
		for p in personas:
			if p.objeto == o and p.rol != "paciente":
				ya = true
		if ya:
			continue
		var candidato: Persona = null
		for p in personas:
			if p.estado == "libre" and (p.rol == quien or (quien == "tecnico" and p.rol == "cientifico")):
				candidato = p
				break
		if candidato:
			candidato.objeto = o
			candidato.sala = o.sala
			_ir(candidato, _uso(o, quien), "a_puesto")

func _llegar(p: Persona, dt: float) -> bool:
	if p.ruta.is_empty():
		return true
	var meta := Vector2(p.ruta[0]) + Vector2(0.5, 0.5)
	var d := meta - p.pos
	var paso := float(R.andar) * dt
	if d.length() <= paso:
		p.pos = meta
		p.ruta.pop_front()
	else:
		p.pos += d.normalized() * paso
		p.mira = Vector2i(roundi(d.normalized().x), roundi(d.normalized().y))
	p.anim = "Walking_A" if p.lleva == "" else "Walking_C"
	return p.ruta.is_empty()

func _persona(p: Persona, dt: float) -> void:
	match p.estado:
		"a_recepcion":
			if _llegar(p, dt):
				p.estado = "recepcion"
				p.t = float(R.recepcion_s)
				p.anim = "Idle_B"
		"recepcion":
			p.t -= dt
			if p.t <= 0.0:
				p.objeto = null
				p.estado = "a_esperar"
		"a_esperar":
			for a in asientos():
				if not _ocupado(a[0], a[1]):
					p.objeto = a[0]
					p.asiento = a[1]
					var frente: Vector2i = (a[0] as Hospital.Objeto).origen + Hospital.girar(Vector2i(1 if a[1] == 2 else 0, 1), (a[0] as Hospital.Objeto).giro)
					if _ir(p, frente, "a_sentarse"):
						return
					p.objeto = null
					p.asiento = -1
			var sitio := _sitio_de_pie(p)
			p.sitio = sitio
			if sitio.x < -900 or not _ir(p, sitio, "a_pie"):
				p.sitio = Vector2i(-999, -999)
				p.estado = "de_pie"
				p.anim = "Idle_A"
		"a_pie":
			if _llegar(p, dt):
				p.estado = "de_pie"
				p.anim = "Idle_A"
				p.mira = _mira_a_bancos(p)
		"a_sentarse":
			if _llegar(p, dt):
				p.estado = "esperando"
				p.anim = "Sit_Chair_Idle"
		"esperando", "de_pie":
			var cam := _camilla_libre()
			if cam:
				p.objeto = cam
				p.asiento = -1
				p.sitio = Vector2i(-999, -999)
				_ir(p, _junto_a(p, cam), "a_camilla")
				return
			var cola := _camilla_sin_cola()
			if cola:
				p.objeto = cola
				p.asiento = -1
				p.sitio = Vector2i(-999, -999)
				_ir(p, cola.sala.fuera(), "a_cola")
			elif p.estado == "de_pie":
				for a in asientos():       # en cuanto queda un asiento libre, a sentarse
					if not _ocupado(a[0], a[1]):
						p.sitio = Vector2i(-999, -999)
						p.estado = "a_esperar"
						return
		"a_cola":
			if _llegar(p, dt):
				p.estado = "en_cola"
				p.anim = "Idle_A"
				p.mira = cola_mira(p.objeto.sala)
		"en_cola":
			if _libre_para(p.objeto, p):
				_ir(p, _junto_a(p, p.objeto), "a_camilla")
		"a_camilla":
			if _llegar(p, dt):
				p.estado = "tumbado"
				p.anim = "Lie_Idle"
				p.t = float(R.extraccion_s)
		"tumbado":
			var m: Equipo = maquinas.get(p.objeto.id)
			var cient := _trabajador(p.objeto)
			if cient and cient.estado == "trabajando":
				p.t -= dt
				cient.anim = "Working_B"
			if p.t <= 0.0:
				atendidos += 1
				_tubo_a_llenadora(p.objeto.sala)
				p.objeto = null
				p.anim = "Walking_A"
				_ir(p, h.entrada, "saliendo")
		"saliendo":
			if _llegar(p, dt):
				personas.erase(p)
		"a_puesto":
			if _llegar(p, dt):
				p.estado = "trabajando"
				p.anim = "Working_A"
				var dentro: Vector2i = p.objeto.celdas()[0]
				p.mira = (dentro - p.casilla()).clamp(Vector2i(-1, -1), Vector2i(1, 1))
		"trabajando":
			if p.objeto.tipo == "centrifuga":
				var m2: Equipo = maquinas.get(p.objeto.id)
				p.anim = "Working_A" if m2 and m2.proceso >= 0.0 else "Idle_A"
		"libre":
			p.anim = "Idle_A"
			if p.rol == "becario":
				_buscar_transporte(p)
		"a_coger":
			if _llegar(p, dt):
				var m: Equipo = maquinas.get(p.objeto.id)
				if m and not m.salida.is_empty() and acepta(maquinas[p.destino.id], m.salida[0]):
					p.lleva = m.salida.pop_front()
					_ir(p, _junto_a(p, p.destino), "a_dejar")
				else:
					p.estado = "libre"
		"a_dejar":
			if _llegar(p, dt):
				var md: Equipo = maquinas.get(p.destino.id)
				if md and acepta(md, p.lleva):
					meter(md, p.lleva)
					p.lleva = ""
					p.estado = "libre"

func cola_mira(s: Hospital.Sala) -> Vector2i:
	return -Hospital.DIRS[s.lado]

## La camilla está libre para este paciente (no hay nadie tumbado ni yendo a tumbarse).
func _libre_para(o: Hospital.Objeto, yo: Persona) -> bool:
	var cient := _trabajador(o)
	if cient == null or cient.estado != "trabajando":
		return false
	for q in personas:
		if q != yo and q.rol == "paciente" and q.objeto == o and q.estado in ["a_camilla", "tumbado"]:
			return false
	var ll := _llenadora(o.sala)
	return not (ll and ll.salida.size() >= 2)

## Camilla con alguien dentro pero sin nadie esperando en su puerta.
func _camilla_sin_cola() -> Hospital.Objeto:
	for o in h.objetos:
		if o.tipo != "camilla" or _trabajador(o) == null:
			continue
		var cola := false
		for q in personas:
			if q.rol == "paciente" and q.objeto == o and q.estado in ["a_cola", "en_cola"]:
				cola = true
		if not cola:
			return o
	return null

func _trabajador(o: Hospital.Objeto) -> Persona:
	for q in personas:
		if q.objeto == o and q.rol != "paciente":
			return q
	return null

func _camilla_libre() -> Hospital.Objeto:
	for o in h.objetos:
		if o.tipo != "camilla":
			continue
		var cient := _trabajador(o)
		if cient == null or cient.estado != "trabajando":
			continue
		var ocupada := false
		for q in personas:
			if q.rol == "paciente" and q.objeto == o and q.estado in ["a_camilla", "tumbado", "a_cola", "en_cola"]:
				ocupada = true
		if ocupada:
			continue
		var ll := _llenadora(o.sala)
		if ll and ll.salida.size() >= 2:
			continue          # la llenadora está llena: no se saca más sangre
		return o
	return null

func _llenadora(s: Hospital.Sala) -> Equipo:
	for m in maquinas.values():
		if m.o.tipo == "llenadora_gradillas" and m.o.sala == s:
			return m
	return null

func _tubo_a_llenadora(s: Hospital.Sala) -> void:
	var ll := _llenadora(s)
	if ll == null:
		return
	ll.tubos += 1
	if ll.tubos >= int(R.tubos_por_gradilla):
		ll.tubos = 0
		ll.salida.append("gradilla_sangre")

## Becario: lleva lo que espera en la salida de una máquina sin cinta a una máquina que lo acepte.
func _buscar_transporte(p: Persona) -> void:
	for m in maquinas.values():
		if m.salida.is_empty() or _salida_con_cinta(m):
			continue
		if _reservado(m):
			continue
		for md in maquinas.values():
			if md == m or not acepta(md, m.salida[0]):
				continue
			p.objeto = m.o
			p.destino = md.o
			if _ir(p, _junto_a(p, m.o), "a_coger"):
				return
	p.objeto = null
	p.destino = null

func _reservado(m: Equipo) -> bool:
	for q in personas:
		if q.rol == "becario" and q.estado == "a_coger" and q.objeto == m.o:
			return true
	return false

func _salida_con_cinta(m: Equipo) -> bool:
	for b in bocas(m.o):
		if b.tipo == "salida" and cintas.has(b.c):
			return true
	return false

func _maquina(m: Equipo, dt: float) -> void:
	# sacar lo hecho a la cinta de la boca de salida
	for b in bocas(m.o):
		if b.tipo == "salida" and not m.salida.is_empty() and cintas.has(b.c) and (not h.pared(b.c, b.dentro) or pasamuros.has(clave_borde(b.c, b.dentro))):
			var ci: Cinta = cintas[b.c]
			if _cabe(ci, 0.0):
				ci.items.append([m.salida.pop_front(), 0.0])
	if m.o.tipo == "centrifuga":
		var tec := _trabajador(m.o)
		m.trabajando = tec != null and tec.estado == "trabajando"
		if m.proceso < 0.0 and not m.entrada.is_empty() and m.salida.size() < 2 and m.trabajando:
			m.actual = m.entrada.pop_front()
			m.proceso = 0.0
		if m.proceso >= 0.0 and m.trabajando:
			m.proceso += dt
			if m.proceso >= float(R.centrifuga_s):
				m.proceso = -1.0
				m.actual = ""
				m.salida.append("gradilla_hematies")
				plasma_l += float(R.plasma_l_por_gradilla)

func _cabe(ci: Cinta, desde: float) -> bool:
	for it in ci.items:
		if absf(it[1] - desde) < 0.5:
			return false
	return true

## Las gradillas avanzan; al final de la casilla pasan a la siguiente cinta (por pasamuros si hay pared) o entran
## por la boca de una máquina que las acepte; si no, esperan (la cinta se para detrás).
func _cintas(dt: float) -> void:
	for ci in cintas.values():
		ci.items.sort_custom(func(a, b): return a[1] > b[1])
		for i in ci.items.size():
			var it: Array = ci.items[i]
			var tope: float = 1.0 if i == 0 else float(ci.items[i - 1][1]) - 0.5
			it[1] = minf(it[1] + float(R.cinta) * dt, tope)
		if ci.items.is_empty() or ci.items[0][1] < 1.0:
			continue
		var n: Vector2i = ci.c + ci.dir
		if h.pared(ci.c, n) and not pasamuros.has(clave_borde(ci.c, n)):
			continue
		var objeto: String = ci.items[0][0]
		if cintas.has(n):
			var sig: Cinta = cintas[n]
			if _cabe(sig, 0.0):
				sig.items.append([objeto, 0.0])
				ci.items.pop_front()
			continue
		var o := h.objeto_en(n)
		if o and maquinas.has(o.id):
			for b in bocas(o):
				if b.tipo == "entrada" and b.c == ci.c and b.dir == ci.dir and acepta(maquinas[o.id], objeto):
					meter(maquinas[o.id], objeto)
					ci.items.pop_front()
					break
