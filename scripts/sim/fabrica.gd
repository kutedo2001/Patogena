class_name Fabrica
extends RefCounted
## Simulación de la fábrica (P4.1): datos puros, sin dibujo, a 20 pasos por segundo.
## La rejilla son casillas de 1 m (Vector2i). Cada casilla tiene como mucho una entidad:
## cinta, máquina (ocupa varias), brazo, divisor, almacén o fuente.
## Convenio de giro: 0 = +X, 1 = +Z, 2 = −X, 3 = −Z (un paso = 90°).
## El dibujo (escena 3D) solo lee el estado; el bot la juega sin pantalla y muy rápido.

const PASO := 1.0 / 20.0
## Líquidos (V1.9): solo van por tuberías, nunca por cintas.
const FLUIDOS := ["sangre_l"]

static func es_fluido(o: String) -> bool:
	return Fabrica.base(o) in FLUIDOS
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]

static var datos := {}

var celdas := {}                 # Vector2i → Entidad
var entidades: Array = []        # en orden de actualización
var producido := {}              # objeto → unidades fabricadas
var mutaciones := 0
var mutaciones_hechas: Array[String] = []   # en orden de inyección
var nodos := {}                  # Vector2i → tipo de nodo de extracción ("donante", "incubadora", "agua")
var dinero := 0.0
var vendido := {}
var ingresos := 0.0              # lo cobrado por ventas
var vendidas_con := {}           # mutación → cajas de vacunas vendidas con ella
var desechados := 0              # viales con una mutación repetida (se tiran)
# --- pacientes (V1.8): llegan por la puerta a la sala de espera; las camillas los llaman
const LLEGADA_BASE := 7.0        # s entre pacientes sin campañas
var espera_pacientes := 1        # sentados esperando (el primero ya está)
var llegados := 0
var _t_llegada := 0.0
var campana_mult := 1.0          # campaña en curso (multiplica la llegada)
var campana_t := 0.0             # s que le quedan
var contrato_mult := 1.0         # contratos con hospitales (permanente)
# --- energía (V1.8): la red da 20 kW; los generadores suman. Si falta, todo va más lento.
const RED_KW := 20.0
var demanda_kw := 0.0
var factor_energia := 1.0

func capacidad_espera() -> int:
	var n := 2
	for e in entidades:
		if e is SalaEspera:
			n += SalaEspera.ASIENTOS
	return n

func llegada_cada() -> float:
	return LLEGADA_BASE / (campana_mult * contrato_mult)

func capacidad_kw() -> float:
	var kw := RED_KW
	for e in entidades:
		if e is Generador:
			kw += e.kw_actual
	return kw

static func base(objeto: String) -> String:
	var i := objeto.find(":")
	return objeto if i < 0 else objeto.left(i)

static func etiqueta(objeto: String) -> String:
	var i := objeto.find(":")
	return "" if i < 0 else objeto.substr(i + 1)
var tiempo := 0.0
var _acum := 0.0

static func cargar_datos() -> void:
	if not datos.is_empty():
		return
	var f := FileAccess.open("res://datos/fabrica.json", FileAccess.READ)
	datos = JSON.parse_string(f.get_as_text())

func _init() -> void:
	cargar_datos()

static func girar(v: Vector2i, giro: int) -> Vector2i:
	for i in posmod(giro, 4):
		v = Vector2i(-v.y, v.x)
	return v

# ------------------------------------------------------------------ construir
func libre(cs: Array) -> bool:
	for c in cs:
		if celdas.has(c):
			return false
	return true

func _alta(e: Entidad) -> Entidad:
	if not libre(e.casillas):
		return null
	for c in e.casillas:
		celdas[c] = e
	entidades.append(e)
	_ordenar()
	return e

func poner_cinta(c: Vector2i, giro: int, nivel := 1) -> Cinta:
	return _alta(Cinta.new(c, giro, nivel)) as Cinta

## Pone una línea de cintas por una lista de casillas contiguas (la dirección sale de la vecina).
func poner_linea(cs: Array, nivel := 1, giro_final := -1) -> void:
	for i in cs.size():
		var d: Vector2i
		if i < cs.size() - 1:
			d = cs[i + 1] - cs[i]
		elif giro_final >= 0:
			d = DIRS[giro_final]
		else:
			d = cs[i] - cs[i - 1]
		poner_cinta(cs[i], DIRS.find(d), nivel)

func poner_maquina(tipo: String, origen: Vector2i, giro := 0) -> MaquinaSim:
	return _alta(MaquinaSim.new(tipo, origen, giro)) as MaquinaSim

func poner_brazo(c: Vector2i, giro: int, filtro := "") -> Brazo:
	return _alta(Brazo.new(c, giro, filtro)) as Brazo

func poner_divisor(c: Vector2i, giro: int) -> Divisor:
	return _alta(Divisor.new(c, giro)) as Divisor

func poner_almacen(c: Vector2i, giro := -1) -> Almacen:
	return _alta(Almacen.new(c, giro)) as Almacen

func poner_fuente(c: Vector2i, giro: int, objeto: String, cada: float) -> Fuente:
	return _alta(Fuente.new(c, giro, objeto, cada)) as Fuente

func poner_extractor(c: Vector2i, giro: int) -> Extractor:
	if not nodos.has(c):
		return null
	return _alta(Extractor.new(c, giro, nodos[c])) as Extractor

func poner_estacion(tipo: String, c: Vector2i, giro: int) -> Estacion:
	return _alta(Estacion.new(tipo, c, giro)) as Estacion

func poner_muelle_envio(c: Vector2i) -> MuelleEnvio:
	return _alta(MuelleEnvio.new(c)) as MuelleEnvio

func poner_ascensor(c: Vector2i) -> Ascensor:
	return _alta(Ascensor.new(c)) as Ascensor

func poner_tuberia(c: Vector2i, giro: int) -> Tuberia:
	return _alta(Tuberia.new(c, giro)) as Tuberia

func poner_linea_tuberia(cs: Array, giro_final := -1) -> void:
	for i in cs.size():
		var g: int = giro_final
		if i < cs.size() - 1:
			g = DIRS.find(cs[i + 1] - cs[i])
		elif g < 0 and cs.size() > 1:
			g = DIRS.find(cs[i] - cs[i - 1])
		poner_tuberia(cs[i], maxi(g, 0))

func poner_capsula(tipo: String, c: Vector2i, giro: int) -> Capsula:
	return _alta(Capsula.new(tipo, c, giro)) as Capsula

func poner_deposito(c: Vector2i, giro: int) -> Deposito:
	return _alta(Deposito.new(c, giro)) as Deposito

func poner_sala_espera(c: Vector2i, giro: int) -> SalaEspera:
	return _alta(SalaEspera.new(c, giro)) as SalaEspera

func poner_generador(tipo: String, c: Vector2i, giro: int) -> Generador:
	return _alta(Generador.new(tipo, c, giro)) as Generador

func quitar(c: Vector2i) -> Entidad:
	var e: Entidad = celdas.get(c)
	if e == null:
		return null
	for x in e.casillas:
		celdas.erase(x)
	entidades.erase(e)
	return e

## Las cintas se actualizan desde el final de cada línea hacia atrás para que no queden huecos.
func _ordenar() -> void:
	var cintas: Array = []
	var resto: Array = []
	for e in entidades:
		(cintas if e is Cinta else resto).append(e)
	var prof := {}
	for e in cintas:
		prof[e] = _profundidad(e, 0)
	cintas.sort_custom(func(a, b): return prof[a] < prof[b])
	entidades = resto + cintas

func _profundidad(e: Cinta, n: int) -> int:
	if n > 400:
		return n
	var sig = celdas.get(e.casillas[0] + DIRS[e.giro])
	if sig is Cinta:
		return _profundidad(sig, n + 1)
	return n

# ------------------------------------------------------------------ avanzar
func avanzar(dt: float) -> void:
	_acum += dt
	while _acum >= PASO:
		_acum -= PASO
		paso()

func paso() -> void:
	tiempo += PASO
	_pacientes(PASO)
	var cap := capacidad_kw()
	factor_energia = 1.0 if demanda_kw <= cap else clampf(cap / maxf(demanda_kw, 0.01), 0.2, 1.0)
	for e in entidades:
		e.paso(self, PASO)

func _pacientes(dt: float) -> void:
	if campana_t > 0.0:
		campana_t -= dt
		if campana_t <= 0.0:
			campana_mult = 1.0
	if espera_pacientes >= capacidad_espera():
		_t_llegada = 0.0
		return
	_t_llegada += dt
	if _t_llegada >= llegada_cada():
		_t_llegada = 0.0
		espera_pacientes += 1
		llegados += 1

## Una camilla libre llama al siguiente de la sala de espera.
func llamar_paciente() -> bool:
	if espera_pacientes <= 0:
		return false
	espera_pacientes -= 1
	return true

func lanzar_campana(mult: float, segundos: float) -> void:
	campana_mult = maxf(campana_mult, mult)
	campana_t = maxf(campana_t, segundos)

## Entrega un objeto a la casilla c viniendo en la dirección d (giro). true si lo acepta.
func entregar(c: Vector2i, objeto: String, d: int) -> bool:
	var e: Entidad = celdas.get(c)
	return e != null and e.aceptar(self, objeto, d, c)

func anotar(objeto: String, n := 1) -> void:
	producido[objeto] = producido.get(objeto, 0) + n

# ================================================================== entidades
class Entidad:
	var casillas: Array = []
	var giro := 0
	func paso(_f: Fabrica, _dt: float) -> void: pass
	func aceptar(_f: Fabrica, _o: String, _d: int, _c: Vector2i) -> bool: return false
	## Saca un objeto para un brazo ("" si no hay).
	func sacar(_filtro: String) -> String: return ""

## Cinta: los objetos avanzan de 0 a 1 por la casilla con una separación mínima.
class Cinta extends Entidad:
	var nivel := 1
	var objetos: Array = []      # [[objeto, pos]], el primero es el de delante
	var v := 0.5
	var sep := 0.5
	func _init(c: Vector2i, g: int, n: int) -> void:
		casillas = [c]
		giro = g
		nivel = n
		var d: Dictionary = Fabrica.datos.cintas[str(n)]
		v = d.velocidad
		sep = d.separacion
	func paso(f: Fabrica, dt: float) -> void:
		var i := 0
		while i < objetos.size():
			var tope := 1.0 if i == 0 else float(objetos[i - 1][1]) - sep
			var pos: float = minf(float(objetos[i][1]) + v * dt, tope)
			if i == 0 and pos >= 1.0 and f.entregar(casillas[0] + Fabrica.DIRS[giro], objetos[0][0], giro):
				objetos.pop_front()
				continue
			objetos[i][1] = maxf(pos, float(objetos[i][1]))
			i += 1
	func aceptar(_f: Fabrica, o: String, d: int, _c: Vector2i) -> bool:
		if d == posmod(giro + 2, 4):
			return false                       # no se entra por la salida
		if Fabrica.es_fluido(o) != (self is Tuberia):
			return false                       # líquidos por tubería; objetos por cinta
		var entra := 0.0 if d == giro else 0.5 # carga lateral: a mitad de casilla
		for x in objetos:
			if absf(float(x[1]) - entra) < sep:
				return false
		objetos.append([o, entra])
		objetos.sort_custom(func(a, b): return a[1] > b[1])
		return true
	func sacar(filtro: String) -> String:
		for i in objetos.size():
			if filtro == "" or objetos[i][0] == filtro:
				var o: String = objetos[i][0]
				objetos.remove_at(i)
				return o
		return ""

## Máquina con receta: entra por la cara −X local, saca por la +X en la fila de salida.
class MaquinaSim extends Entidad:
	enum Estado { APAGADA, TRABAJANDO, SIN_MATERIAL, SALIDA_LLENA, REPETIDA }
	var tipo := ""
	var origen := Vector2i.ZERO
	var tam := Vector2i.ONE
	var receta := ""
	var entrada := {}            # objeto → unidades en la tolva
	var salida: Array = []       # objetos hechos esperando
	var progreso := 0.0          # segundos de la pieza actual (−1 = parada)
	var estado := Estado.SIN_MATERIAL
	var casilla_salida := Vector2i.ZERO
	var _r := {}
	func _init(t: String, o: Vector2i, g: int) -> void:
		tipo = t
		origen = o
		giro = g
		var d: Dictionary = Fabrica.datos.maquinas[t]
		tam = Vector2i(d.tam[0], d.tam[1])
		var locales: Array = []
		for i in tam.x:
			for j in tam.y:
				locales.append(Vector2i(i, j))
		var rot: Array = locales.map(func(v): return Fabrica.girar(v, g))
		var minimo := Vector2i(rot.map(func(v): return v.x).min(), rot.map(func(v): return v.y).min())
		casillas = rot.map(func(v): return o + v - minimo)
		casilla_salida = o + Fabrica.girar(Vector2i(tam.x - 1, int(d.salida)), g) - minimo + Fabrica.DIRS[g]
		# bocas de entrada: casilla de la máquina en la cara −X local de cada fila, con su filtro
		for b in d.get("entradas", []):
			bocas.append([o + Fabrica.girar(Vector2i(0, int(b[0])), g) - minimo, str(b[1])])
		poner_receta(d.recetas[0])
		progreso = -1.0
	## Cambiar de receta no pierde nada (B7): la tanda en curso devuelve sus ingredientes a la
	## tolva y lo que la receta nueva no usa sale por la salida.
	func poner_receta(r: String) -> void:
		if not _r.is_empty() and progreso >= 0.0:
			for o in _r.entradas:
				entrada[o] = entrada.get(o, 0) + int(_r.entradas[o])
		receta = r
		_r = Fabrica.datos.recetas[r]
		progreso = -1.0
		for o in entrada.keys():
			if not _r.entradas.has(o):
				for k in int(entrada[o]):
					salida.append(o)
				entrada.erase(o)
	## La mutación de esta receta ya está registrada en la cámara de cepa (B9).
	func repetida(f: Fabrica) -> bool:
		return _r.has("mutacion") and str(_r.mutacion) in f.mutaciones_hechas
	func duracion() -> float:
		return float(_r.tiempo)
	var etiquetas: Array[String] = []   # mutaciones de los viales en la tolva (cepa y envasadora)
	var bocas: Array = []                # [casilla, filtro] por donde entra cada ingrediente
	## Boca por la que entraría o (desde fuera, en dirección d, a la casilla c). null si ninguna.
	func boca(o: String, d: int, c: Vector2i):
		for b in bocas:
			if b[0] == c and d == giro and (b[1] == "" or b[1] == Fabrica.base(o)):
				return b
		return null
	func _cabe(o: String) -> bool:
		var n: int = _r.entradas.get(Fabrica.base(o), 0)
		return n > 0 and entrada.get(Fabrica.base(o), 0) < maxi(4 * n, 4)   # tolva: hasta 4 recetas
	## También lo usa el jugador al echar objetos a mano (d = −1: entra por cualquier lado).
	func aceptar(f: Fabrica, o: String, d: int, c: Vector2i) -> bool:
		if not _cabe(o):
			return false
		if d != -1 and (boca(o, d, c) == null if not bocas.is_empty() else d != giro):
			return false
		if _r.has("cuenta"):
			var et := Fabrica.etiqueta(o)
			if et == "":
				return false
			if et in f.mutaciones_hechas or et in etiquetas:
				f.desechados += 1               # mutación ya registrada: el vial se desecha y no atasca
				return true
			etiquetas.append(et)
		elif _r.has("hereda") and Fabrica.base(o) == _r.hereda:
			etiquetas.append(Fabrica.etiqueta(o))
		entrada[Fabrica.base(o)] = entrada.get(Fabrica.base(o), 0) + 1
		return true
	func paso(f: Fabrica, dt: float) -> void:
		if progreso < 0.0 and repetida(f):
			estado = Estado.REPETIDA          # no fabrica una mutación que ya existe
			if not salida.is_empty() and f.entregar(casilla_salida, salida[0], giro):
				salida.pop_front()
			return
		if progreso < 0.0:
			var hay := true
			for o in _r.entradas:
				hay = hay and entrada.get(o, 0) >= int(_r.entradas[o])
			var sitio := salida.size() + _total_salida() <= maxi(4, 2 * _total_salida())
			if hay and sitio:
				for o in _r.entradas:
					entrada[o] -= int(_r.entradas[o])
				progreso = 0.0
			estado = Estado.SIN_MATERIAL if not hay else (Estado.SALIDA_LLENA if not sitio else Estado.TRABAJANDO)
		if progreso >= 0.0:
			estado = Estado.TRABAJANDO
			progreso += dt * f.factor_energia
			if progreso >= float(_r.tiempo):
				progreso = -1.0
				var heredada := ""
				if _r.has("hereda") and not etiquetas.is_empty():
					heredada = etiquetas.pop_front()
				for o in _r.salidas:
					var nombre: String = o + (":" + _r.mutacion if _r.has("mutacion") else (":" + heredada if heredada != "" else ""))
					for k in int(_r.salidas[o]):
						salida.append(nombre)
					f.anotar(o, int(_r.salidas[o]))
				if _r.has("cuenta") and not etiquetas.is_empty():
					f.mutaciones += 1
					f.mutaciones_hechas.append(etiquetas.pop_front())
					f.anotar(_r.cuenta)
		if not salida.is_empty() and f.entregar(casilla_salida, salida[0], giro):
			salida.pop_front()
	func _total_salida() -> int:
		var n := 0
		for o in _r.salidas:
			n += int(_r.salidas[o])
		return n
	func sacar(filtro: String) -> String:
		for i in salida.size():
			if filtro == "" or salida[i] == filtro:
				var o: String = salida[i]
				salida.remove_at(i)
				return o
		return ""
	func fraccion() -> float:
		return clampf(progreso / float(_r.tiempo), 0.0, 1.0) if progreso >= 0.0 else 0.0

## Brazo: coge de la casilla de detrás y deja en la de delante (filtro opcional).
class Brazo extends Entidad:
	var filtro := ""
	var mano := ""
	var t := 0.0
	var ciclo := 1.2
	func _init(c: Vector2i, g: int, fl: String) -> void:
		casillas = [c]
		giro = g
		filtro = fl
		ciclo = Fabrica.datos.brazo.ciclo
	func paso(f: Fabrica, dt: float) -> void:
		var c: Vector2i = casillas[0]
		if mano == "":
			t = maxf(t - dt, 0.0)               # vuelve hacia el origen
			if t <= 0.0:
				var e: Entidad = f.celdas.get(c - Fabrica.DIRS[giro])
				if e != null:
					mano = e.sacar(filtro)
		else:
			t = minf(t + dt, ciclo * 0.5)
			if t >= ciclo * 0.5 and f.entregar(c + Fabrica.DIRS[giro], mano, giro):
				mano = ""
	func fase() -> float:
		return t / (ciclo * 0.5)

## Divisor: reparte por turnos entre delante, izquierda y derecha.
class Divisor extends Entidad:
	var hueco := ""
	var turno := 0
	var t := 0.0
	func _init(c: Vector2i, g: int) -> void:
		casillas = [c]
		giro = g
	func aceptar(_f: Fabrica, o: String, d: int, _c: Vector2i) -> bool:
		if hueco != "" or d == posmod(giro + 2, 4):
			return false
		hueco = o
		return true
	func paso(f: Fabrica, dt: float) -> void:
		t += dt
		if hueco == "" or t < float(Fabrica.datos.divisor.cada):
			return
		for k in 3:
			var g := posmod(giro + [0, 1, -1][(turno + k) % 3], 4)
			var c2: Vector2i = casillas[0] + Fabrica.DIRS[g]
			if f.entregar(c2, hueco, g):
				hueco = ""
				turno = (turno + k + 1) % 3
				t = 0.0
				return

## Almacén: acepta de cualquier lado; si tiene giro, saca por ese lado.
class Almacen extends Entidad:
	var contenido: Array = []
	var capacidad := 50
	var t := 0.0
	func _init(c: Vector2i, g: int) -> void:
		casillas = [c]
		giro = g
		capacidad = Fabrica.datos.almacen.capacidad
	func aceptar(_f: Fabrica, o: String, _d: int, _c: Vector2i) -> bool:
		if contenido.size() >= capacidad:
			return false
		contenido.append(o)
		return true
	func paso(f: Fabrica, dt: float) -> void:
		if giro < 0 or contenido.is_empty():
			return
		t += dt
		if t >= float(Fabrica.datos.almacen.salida_cada) and f.entregar(casillas[0] + Fabrica.DIRS[giro], contenido[0], giro):
			contenido.pop_front()
			t = 0.0
	func sacar(filtro: String) -> String:
		for i in contenido.size():
			if filtro == "" or contenido[i] == filtro:
				var o: String = contenido[i]
				contenido.remove_at(i)
				return o
		return ""

## Fuente provisional (hasta los extractores de P4.3): suelta un objeto cada cierto tiempo.
class Fuente extends Entidad:
	var objeto := ""
	var cada := 1.0
	var t := 0.0
	func _init(c: Vector2i, g: int, o: String, s: float) -> void:
		casillas = [c]
		giro = g
		objeto = o
		cada = s
	func paso(f: Fabrica, dt: float) -> void:
		t += dt
		if t >= cada and f.entregar(casillas[0] + Fabrica.DIRS[giro], objeto, giro):
			t = 0.0

## Extractor sobre un nodo (donante, incubadora, toma de agua): saca su materia prima cada cierto tiempo.
class Extractor extends Entidad:
	var tipo := ""
	var objeto := ""
	var cada := 4.0
	var t := 0.0
	var listo := ""
	func _init(c: Vector2i, g: int, nodo: String) -> void:
		casillas = [c]
		giro = g
		var dn: Dictionary = Fabrica.datos.nodos[nodo]
		objeto = dn.objeto
		tipo = dn.extractor
		cada = Fabrica.datos.extractores[tipo].cada
	func paso(f: Fabrica, dt: float) -> void:
		if listo == "":
			t += dt
			if t >= cada:
				t = 0.0
				listo = objeto
				f.anotar(objeto)
		if listo != "" and f.entregar(casillas[0] + Fabrica.DIRS[giro], listo, giro):
			listo = ""
	func sacar(filtro: String) -> String:
		if listo != "" and (filtro == "" or filtro == listo):
			var o := listo
			listo = ""
			return o
		return ""
	func fraccion() -> float:
		return 1.0 if listo != "" else t / cada

## Muelle de envío: vende lo que le llega (cajas de vacunas) y suma el dinero.
class MuelleEnvio extends Entidad:
	var carga := 0                 # cajas cargadas en la furgoneta (sale con 8)
	var viajes := 0
	func _init(c: Vector2i) -> void:
		casillas = [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]
	func aceptar(f: Fabrica, o: String, _d: int, _c: Vector2i) -> bool:
		var precio: float = Fabrica.datos.ventas.get(Fabrica.base(o), 0)
		if precio <= 0.0:
			return false
		f.dinero += precio
		f.ingresos += precio
		carga += 1
		if carga >= 8:
			carga = 0
			viajes += 1
		var et := Fabrica.etiqueta(o)
		if et != "":
			f.vendidas_con[et] = f.vendidas_con.get(et, 0) + 1   # vender vacunas = propagar esa mutación
		f.vendido[Fabrica.base(o)] = f.vendido.get(Fabrica.base(o), 0) + 1
		return true

## Estación de extracción (camilla, incubadora, toma de agua). Modos: «mano» (trabaja el
## científico), «maquina» (el científico con la mejora, más rápido) y «zombi» (un zombi opera
## la máquina: trabaja solo y saca el producto por su boca hacia la cinta).
class Estacion extends Entidad:
	var tipo := ""
	var objeto := ""
	var modo := "mano"
	var listo := ""              # producto hecho esperando a que lo cojan o salga
	var progreso := 0.0          # trabajo hecho de la pieza actual (s)
	var crecimiento := 0.0       # incubadora: el cultivo crece solo
	var paciente := false        # camilla: hay un paciente tumbado
	var espera := 0.0            # camilla: tiempo hasta que llega el siguiente
	var atendidos := 0
	var trabajando := false      # el científico está trabajando en ella este paso
	var llamado := false         # camilla: un paciente viene andando desde la sala de espera
	var _d := {}
	func _init(t: String, c: Vector2i, g: int) -> void:
		tipo = t
		casillas = [c]
		giro = g
		_d = Fabrica.datos.estaciones[t]
		objeto = _d.objeto
		espera = 2.0
	func duracion() -> float:
		return float(_d.trabajo["maquina" if modo != "mano" else "mano"])
	func lista_para_trabajar() -> bool:
		if listo != "":
			return false
		if tipo == "camilla":
			return paciente
		if tipo == "incubadora":
			return crecimiento >= _crece()
		return true
	func _crece() -> float:
		return float(_d.crece["maquina" if modo != "mano" else "mano"])
	## El científico trabaja dt segundos en la estación (la llama Juego mientras trabaja).
	func trabajar(f: Fabrica, dt: float) -> void:
		trabajando = true
		_avanzar(f, dt)
	func _avanzar(f: Fabrica, dt: float) -> void:
		if not lista_para_trabajar():
			return
		progreso += dt * (f.factor_energia if modo != "mano" else 1.0)
		if progreso >= duracion():
			progreso = 0.0
			listo = objeto
			f.anotar(objeto)
			if tipo == "camilla":
				paciente = false
				atendidos += 1
			elif tipo == "incubadora":
				crecimiento = 0.0
	func paso(f: Fabrica, dt: float) -> void:
		if tipo == "camilla" and not paciente:
			if not llamado and listo == "" and f.llamar_paciente():
				llamado = true
				espera = float(_d.llegada)
			if llamado:
				espera -= dt
				if espera <= 0.0:
					paciente = true
					llamado = false
		if tipo == "incubadora" and crecimiento < _crece():
			crecimiento += dt
		if modo == "zombi":
			_avanzar(f, dt)
			if listo != "" and f.entregar(casillas[0] + Fabrica.DIRS[giro], listo, giro):
				listo = ""
		trabajando = false
	func sacar(filtro: String) -> String:
		if listo != "" and (filtro == "" or filtro == listo):
			var o := listo
			listo = ""
			return o
		return ""
	func fraccion() -> float:
		if tipo == "incubadora" and crecimiento < _crece():
			return crecimiento / _crece()
		return progreso / duracion()

## Ascensor de pedidos (como el ascensor espacial de Satisfactory): 2×2, acepta por cualquier lado
## lo que pida la fase actual; al completarla sube la cápsula y se desbloquean máquinas.
class Ascensor extends Entidad:
	var fase := 0
	var entregado := {}
	var completadas := 0
	var subiendo := 0.0            # >0 mientras sube la cápsula (s)
	func _init(c: Vector2i) -> void:
		casillas = [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]
	func pide() -> Dictionary:
		var fs: Array = Fabrica.datos.fases
		return fs[fase].pide if fase < fs.size() else {}
	func falta(o: String) -> int:
		return int(pide().get(Fabrica.base(o), 0)) - int(entregado.get(Fabrica.base(o), 0))
	func aceptar(_f: Fabrica, o: String, _d: int, _c: Vector2i) -> bool:
		if subiendo > 0.0 or falta(o) <= 0:
			return false
		entregado[Fabrica.base(o)] = entregado.get(Fabrica.base(o), 0) + 1
		return true
	func completa() -> bool:
		var p := pide()
		if p.is_empty():
			return false
		for o in p:
			if int(entregado.get(o, 0)) < int(p[o]):
				return false
		return true
	func paso(_f: Fabrica, dt: float) -> void:
		if subiendo > 0.0:
			subiendo -= dt
			if subiendo <= 0.0:
				subiendo = 0.0
		elif completa():
			completadas += 1
			fase += 1
			entregado.clear()
			subiendo = 6.0

## Sala de espera (V1.8): 2×1, cuatro asientos más para los pacientes que llegan por la puerta.
class SalaEspera extends Entidad:
	const ASIENTOS := 4
	func _init(c: Vector2i, g: int) -> void:
		giro = g
		casillas = [c, c + Fabrica.girar(Vector2i(1, 0), g)]

## Generadores (V1.8). Diésel: 2×2, 40 kW siempre. Biogás: 2×2, quema un tubo de sangre cada 3 s
## y da 150 kW mientras tenga (acepta sangre por cualquier lado, hasta 10 en la tolva).
class Generador extends Entidad:
	var tipo := ""
	var kw_actual := 0.0
	var combustible := 0
	var quemando := 0.0
	func _init(t: String, c: Vector2i, g: int) -> void:
		tipo = t
		giro = g
		casillas = [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]
		kw_actual = 40.0 if t == "generador" else 0.0
	func aceptar(_f: Fabrica, o: String, _d: int, _c: Vector2i) -> bool:
		if tipo == "biogas" and Fabrica.base(o) in ["tubo_sangre", "sangre_l"] and combustible < 10:
			combustible += 1
			return true
		return false
	func paso(_f: Fabrica, dt: float) -> void:
		if tipo != "biogas":
			return
		if quemando <= 0.0 and combustible > 0:
			combustible -= 1
			quemando = 3.0
		if quemando > 0.0:
			quemando -= dt
			kw_actual = 150.0
		else:
			kw_actual = 0.0

## Tubería (V1.9): como una cinta pero solo para líquidos y mucho más rápida (8 l/s).
class Tuberia extends Cinta:
	func _init(c: Vector2i, g: int) -> void:
		casillas = [c]
		giro = g
		nivel = 9
		v = 2.0
		sep = 0.25
	func llenado() -> float:
		return clampf(objetos.size() / 4.0, 0.0, 1.0)

## Cápsula de donante (V1.9): retiene a un paciente de la sala de espera y le saca sangre sin parar
## (1 l/s por la boca de salida a una tubería) mientras le llegue suero (una bolsa cada 20 s).
## La granja (V1.10) es una hilera de cuatro: 4×1, cuatro humanos, cuatro veces todo.
class Capsula extends Entidad:
	const SUERO_CADA := 20.0
	var tipo := "capsula"
	var humanos := 0
	var plazas := 1
	var suero := 0               # bolsas en la tolva
	var nutricion := 0.0         # s de suero que le quedan
	var _t := 0.0
	var producido := 0
	func _init(t: String, c: Vector2i, g: int) -> void:
		tipo = t
		giro = g
		plazas = 4 if t == "granja" else 1
		casillas = [c]
		for i in range(1, plazas):
			casillas.append(c + Fabrica.girar(Vector2i(0, i), g))
	func salida() -> Vector2i:
		return casillas[0] + Fabrica.DIRS[giro]
	func activa() -> bool:
		return humanos > 0 and nutricion > 0.0
	func aceptar(_f: Fabrica, o: String, _d: int, _c: Vector2i) -> bool:
		if Fabrica.base(o) == "bolsa_suero" and suero < 4 * plazas:
			suero += 1
			return true
		return false
	func paso(f: Fabrica, dt: float) -> void:
		if humanos < plazas and f.llamar_paciente():
			humanos += 1
		if nutricion <= 0.0 and suero > 0 and humanos > 0:
			suero -= 1
			nutricion += SUERO_CADA          # una bolsa = 20 s de un humano
		if not activa():
			return
		nutricion -= dt * float(humanos)
		_t += dt * float(humanos)
		while _t >= 1.0:
			if not f.entregar(salida(), "sangre_l", giro):
				_t = 1.0
				break
			_t -= 1.0
			producido += 1
			f.anotar("sangre_l")
	func sacar(_filtro: String) -> String:
		return ""

## Depósito de líquido (V1.9): guarda hasta 200 l y los suelta a la tubería a la que mira.
class Deposito extends Entidad:
	var litros := 0
	const CAPACIDAD := 200
	var _t := 0.0
	func _init(c: Vector2i, g: int) -> void:
		casillas = [c]
		giro = g
	func aceptar(_f: Fabrica, o: String, _d: int, _c: Vector2i) -> bool:
		if Fabrica.es_fluido(o) and litros < CAPACIDAD:
			litros += 1
			return true
		return false
	func paso(f: Fabrica, dt: float) -> void:
		_t += dt
		while _t >= 0.125 and litros > 0:
			_t -= 0.125
			if not f.entregar(casillas[0] + Fabrica.DIRS[giro], "sangre_l", giro):
				_t = 0.0
				break
			litros -= 1
		if litros == 0:
			_t = 0.0
