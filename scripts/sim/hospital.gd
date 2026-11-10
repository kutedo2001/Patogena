class_name Hospital
extends RefCounted
## Edificio del rediseño 2.0 (R2.1), estilo Two Point Hospital: parcela por casillas, salas rectangulares con
## paredes en los bordes y una puerta, objetos con huella (casillas que ocupan) y puntos de uso (casillas desde
## las que se usan, con su animación), pasillo con sus propios objetos y caminos por casillas.
## Simulación pura (sin nodos): la vista la dibuja y las pruebas la manejan sin interfaz.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
static var datos := {}

var parcela := Rect2i()
var entrada := Vector2i()        # casilla de la puerta del edificio (por ahí entran los pacientes)
var salas: Array = []
var objetos: Array = []
var dinero := 6000.0
var _sala_de := {}               # Vector2i → Sala
var _obj_de := {}                # Vector2i → Objeto
var _id := 0

static func cargar() -> void:
	if datos.is_empty():
		datos = JSON.parse_string(FileAccess.get_file_as_string("res://datos/hub.json"))

func _init() -> void:
	cargar()
	var p: Array = datos.parcela_inicial
	parcela = Rect2i(int(p[0]), int(p[1]), int(p[2]), int(p[3]))
	entrada = Vector2i(parcela.position.x + parcela.size.x / 2, parcela.end.y - 1)

# ------------------------------------------------------------------ clases
class Sala:
	var id := 0
	var tipo := ""
	var rect := Rect2i()
	var puerta := Vector2i()     # casilla interior junto a la puerta
	var lado := 1                # dirección hacia fuera de la puerta (índice de DIRS)
	func fuera() -> Vector2i:
		return puerta + Hospital.DIRS[lado]
	func tiene(c: Vector2i) -> bool:
		return rect.has_point(c)

class Objeto:
	var id := 0
	var tipo := ""
	var origen := Vector2i()
	var giro := 0
	var sala: Sala = null
	func dato() -> Dictionary:
		return Hospital.datos.objetos[tipo]
	func celdas() -> Array:
		return Hospital.huella(tipo, origen, giro)
	## Puntos de uso en coordenadas del edificio: {c, mira (hacia dónde mira quien lo usa), anim, quien, ...}
	func usos() -> Array:
		var r := []
		for u in dato().get("uso", []):
			var l := Vector2i(int(u.c[0]), int(u.c[1]))
			var d: Dictionary = u.duplicate()
			d.c = origen + Hospital.girar(l, giro)
			r.append(d)
		return r

static func girar(v: Vector2i, g: int) -> Vector2i:
	match ((g % 4) + 4) % 4:
		1: return Vector2i(-v.y, v.x)
		2: return Vector2i(-v.x, -v.y)
		3: return Vector2i(v.y, -v.x)
	return v

static func huella(tipo: String, origen: Vector2i, giro: int) -> Array:
	var t: Array = datos.objetos[tipo].tam
	var r := []
	for i in int(t[0]):
		for j in int(t[1]):
			r.append(origen + girar(Vector2i(i, j), giro))
	return r

# ------------------------------------------------------------------ consultas
func sala_en(c: Vector2i) -> Sala:
	return _sala_de.get(c)

func objeto_en(c: Vector2i) -> Objeto:
	return _obj_de.get(c)

func dentro(c: Vector2i) -> bool:
	return parcela.has_point(c)

## ¿Hay pared entre dos casillas vecinas? Entre zonas distintas siempre, salvo por una puerta.
func pared(a: Vector2i, b: Vector2i) -> bool:
	var sa: Sala = _sala_de.get(a)
	var sb: Sala = _sala_de.get(b)
	if sa == sb:
		return false
	for s in [sa, sb]:
		if s != null and ((s.puerta == a and s.fuera() == b) or (s.puerta == b and s.fuera() == a)):
			return false
	return true

func andable(c: Vector2i) -> bool:
	return dentro(c) and not _obj_de.has(c)

## Camino por casillas (BFS) de a a b; [] si no hay. Las personas no atraviesan objetos ni paredes.
func camino(a: Vector2i, b: Vector2i, ignorar: Array = []) -> Array:
	if a == b:
		return [a]
	var previo := {a: a}
	var cola := [a]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		for d in DIRS:
			var n: Vector2i = c + d
			if previo.has(n) or pared(c, n):
				continue
			if n != b and not (andable(n) or n in ignorar):
				continue
			if n == b and not (andable(n) or n in ignorar):
				continue
			previo[n] = c
			if n == b:
				var r := [b]
				var k := c
				while k != a:
					r.push_front(k)
					k = previo[k]
				r.push_front(a)
				return r
			cola.append(n)
	return []

func completa(s: Sala) -> bool:
	return faltan(s).is_empty()

func faltan(s: Sala) -> Array:
	var r: Array = (datos.salas[s.tipo].obligatorios as Array).duplicate()
	for o in objetos:
		if o.sala == s and o.tipo in r:
			r.erase(o.tipo)
	return r

func objetos_de(s: Sala) -> Array:
	return objetos.filter(func(o): return o.sala == s)

# ------------------------------------------------------------------ salas
func precio_sala(rect: Rect2i) -> float:
	return float(datos.precio_casilla_sala) * rect.get_area()

## Lista de problemas del plano (vacía = vale). Códigos para tr(): HUB_E_*.
func validar_sala(tipo: String, rect: Rect2i) -> Array:
	var e := []
	var m: Array = datos.salas[tipo].min
	var w := rect.size.x
	var h := rect.size.y
	if not ((w >= int(m[0]) and h >= int(m[1])) or (w >= int(m[1]) and h >= int(m[0]))):
		e.append("HUB_E_PEQUENA")
	if not parcela.encloses(rect):
		e.append("HUB_E_FUERA")
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var c := Vector2i(x, y)
			if _sala_de.has(c):
				e.append("HUB_E_OTRA_SALA")
				return e
			if _obj_de.has(c):
				e.append("HUB_E_OBJETO")
				return e
			if c == entrada:
				e.append("HUB_E_ENTRADA")
				return e
	if dinero < precio_sala(rect):
		e.append("HUB_E_DINERO")
	return e

## Puertas posibles: casillas del borde con su lado hacia fuera, cuya casilla exterior es pasillo libre.
func puertas_posibles(rect: Rect2i) -> Array:
	var r := []
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			var c := Vector2i(x, y)
			for l in 4:
				var f: Vector2i = c + DIRS[l]
				if rect.has_point(f) or not dentro(f) or _sala_de.has(f) or _obj_de.has(f):
					continue
				r.append([c, l])
	return r

func construir_sala(tipo: String, rect: Rect2i, puerta: Vector2i, lado: int) -> Sala:
	if not validar_sala(tipo, rect).is_empty():
		return null
	var ok := false
	for p in puertas_posibles(rect):
		if p[0] == puerta and p[1] == lado:
			ok = true
	if not ok:
		return null
	var s := Sala.new()
	_id += 1
	s.id = _id
	s.tipo = tipo
	s.rect = rect
	s.puerta = puerta
	s.lado = lado
	salas.append(s)
	for x in range(rect.position.x, rect.end.x):
		for y in range(rect.position.y, rect.end.y):
			_sala_de[Vector2i(x, y)] = s
	if not _conectado():
		_quitar_sala(s)
		return null
	dinero -= precio_sala(rect)
	return s

func _quitar_sala(s: Sala) -> void:
	salas.erase(s)
	for x in range(s.rect.position.x, s.rect.end.x):
		for y in range(s.rect.position.y, s.rect.end.y):
			_sala_de.erase(Vector2i(x, y))

## Vende la sala: devuelve el 75 % de la obra y el 100 % de sus objetos.
func vender_sala(s: Sala) -> void:
	for o in objetos_de(s):
		quitar_objeto(o)
	dinero += precio_sala(s.rect) * 0.75
	_quitar_sala(s)

# ------------------------------------------------------------------ objetos
func zona_permitida(tipo: String, s: Sala) -> bool:
	var permitidas: Array = datos.objetos[tipo].salas
	if "*" in permitidas:
		return true
	return (s.tipo if s else "") in permitidas

## Problemas al colocar (vacía = vale). Comprueba huella, zona, usos libres y que no se corte ningún camino.
func validar_objeto(tipo: String, origen: Vector2i, giro: int) -> Array:
	var e := []
	var cs := huella(tipo, origen, giro)
	var zona: Sala = _sala_de.get(cs[0])
	for c in cs:
		if not dentro(c):
			return ["HUB_E_FUERA"]
		if _obj_de.has(c):
			return ["HUB_E_OCUPADO"]
		if _sala_de.get(c) != zona:
			return ["HUB_E_PARED"]
		if c == entrada or (zona and c == zona.puerta):
			return ["HUB_E_PUERTA"]
		for s in salas:
			if c == s.fuera():
				return ["HUB_E_PUERTA"]
	for otro in objetos:
		for u in otro.usos():
			if u.get("tumbado", false) or u.get("sentado", false):
				continue
			if u.c in cs:
				return ["HUB_E_USO"]
	if not zona_permitida(tipo, zona):
		e.append("HUB_E_ZONA")
	if dinero < float(datos.objetos[tipo].precio):
		e.append("HUB_E_DINERO")
	if not e.is_empty():
		return e
	# usos: dentro de la misma zona y libres
	var o := Objeto.new()
	o.tipo = tipo
	o.origen = origen
	o.giro = giro
	o.sala = zona
	for u in o.usos():
		if u.get("tumbado", false) or u.get("sentado", false):
			continue
		if not dentro(u.c) or _sala_de.get(u.c) != zona or _obj_de.has(u.c) or u.c in cs:
			return ["HUB_E_USO"]
	# probar a ponerlo y ver que todo sigue alcanzable
	for c in cs:
		_obj_de[c] = o
	objetos.append(o)
	var conectado := _conectado()
	objetos.erase(o)
	for c in cs:
		_obj_de.erase(c)
	if not conectado:
		e.append("HUB_E_CAMINO")
	return e

func poner_objeto(tipo: String, origen: Vector2i, giro: int) -> Objeto:
	if not validar_objeto(tipo, origen, giro).is_empty():
		return null
	var o := Objeto.new()
	_id += 1
	o.id = _id
	o.tipo = tipo
	o.origen = origen
	o.giro = giro
	o.sala = _sala_de.get(origen)
	for c in o.celdas():
		_obj_de[c] = o
	objetos.append(o)
	dinero -= float(datos.objetos[tipo].precio)
	return o

func quitar_objeto(o: Objeto) -> void:
	for c in o.celdas():
		_obj_de.erase(c)
	objetos.erase(o)
	dinero += float(datos.objetos[o.tipo].precio)

## Todo alcanzable desde la entrada: las puertas de todas las salas y los puntos de uso de pie de cada objeto.
func _conectado() -> bool:
	var vistos := {entrada: true}
	var cola := [entrada]
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		for d in DIRS:
			var n: Vector2i = c + d
			if vistos.has(n) or not andable(n) or pared(c, n):
				continue
			vistos[n] = true
			cola.append(n)
	for s in salas:
		if not vistos.has(s.puerta) or not vistos.has(s.fuera()):
			return false
	for o in objetos:
		for u in o.usos():
			if u.get("tumbado", false) or u.get("sentado", false):
				continue
			if not vistos.has(u.c):
				return false
	return true
