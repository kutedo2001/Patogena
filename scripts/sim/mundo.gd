class_name Mundo
extends RefCounted
## El mundo (V1.10): 12 regiones con población, clima y riqueza. Las cajas de vacunas vendidas
## infectan a gente en la región de destino; la cepa (mejoras de la sala de cepas) decide lo rápido
## que se contagia, en qué climas, cuánto se nota y si convierte en zombis. Los países ricos
## investigan la cura; si llega al 100 % se pierde. Se gana con el 90 % del mundo zombi.
## Población en millones; tiempo en segundos de juego.

const CONTAGIO_BASE := 0.00003      # por segundo, sin mejoras (duplica en ~6 h; las mejoras lo multiplican)
const VIAJES := 0.0000006           # contagio entre regiones
const CURA_BASE := 0.0001           # equilibrado con tools/balance_mundo.py: partida normal ~7,5 h con la cura al ~78 %
const DETECCION := 1.0              # millones de infectados para que se den cuenta

var regiones: Array = []            # [{id, pob, clima, riqueza, s, i, z}]
var cura := 0.0
var detectado := false
var efectos := {}                   # suma de efectos de la cepa
var victoria := false
var derrota := false

func _init() -> void:
	Fabrica.cargar_datos()
	for r in Fabrica.datos.mundo.regiones:
		regiones.append({"id": r.id, "pob": float(r.pob), "clima": r.clima, "riqueza": float(r.riqueza),
			"s": float(r.pob), "i": 0.0, "z": 0.0, "x": float(r.x), "y": float(r.y)})

static func efectos_de(hechas: Array) -> Dictionary:
	var e := {"contagio": 0.0, "deteccion": 0.0, "zombificacion": 0.0, "resistencia": 0.0, "frio": 0, "calido": 0, "humedo": 0}
	for m in Fabrica.datos.cepa.mejoras:
		if m.id in hechas:
			for k in m.efecto:
				e[k] = e.get(k, 0) + m.efecto[k]
	return e

func total(campo: String) -> float:
	var t := 0.0
	for r in regiones:
		t += float(r[campo])
	return t

func poblacion() -> float:
	return total("pob")

func fraccion_zombi() -> float:
	return total("z") / poblacion()

func fraccion_infectada() -> float:
	return (total("i") + total("z")) / poblacion()

func region(id: String) -> Dictionary:
	for r in regiones:
		if r.id == id:
			return r
	return regiones[0]

## Gente infectada al llegar las vacunas (millones).
func sembrar(id: String, millones: float) -> void:
	var r := region(id)
	var n := minf(millones, float(r.s))
	r.s -= n
	r.i += n

func _clima(r: Dictionary) -> float:
	match str(r.clima):
		"frio": return 1.0 if efectos.get("frio", 0) > 0 else 0.35
		"calido": return 1.0 if efectos.get("calido", 0) > 0 else 0.45
		"humedo": return 1.0 if efectos.get("humedo", 0) > 0 else 0.55
	return 1.0

func paso(dt: float) -> void:
	if victoria or derrota:
		return
	var c := CONTAGIO_BASE * (1.0 + float(efectos.get("contagio", 0.0)) * 3.0)
	var zb := float(efectos.get("zombificacion", 0.0))
	var viajeros := 0.0
	for r in regiones:
		viajeros += float(r.i) + float(r.z) * 0.5
	for r in regiones:
		var pob: float = r.pob
		var s: float = r.s
		var activos: float = float(r.i) + float(r.z) * 1.5    # los zombis muerden: contagian más
		var nuevos := c * _clima(r) * activos * s / pob * dt
		nuevos += VIAJES * (1.0 + float(efectos.get("contagio", 0.0))) * viajeros * s / pob * dt * _clima(r)
		nuevos = minf(nuevos, s)
		r.s = s - nuevos
		r.i = float(r.i) + nuevos
		var conv := minf(float(r.i), zb * float(r.i) * dt)
		r.i = float(r.i) - conv
		r.z = float(r.z) + conv
	if not detectado and total("i") + total("z") >= DETECCION:
		detectado = true
	if detectado:
		var investigan := 0.0
		for r in regiones:
			investigan += float(r.riqueza) * float(r.s) / float(r.pob) * float(r.pob)
		investigan /= poblacion()
		var det := clampf(0.35 + float(efectos.get("deteccion", 0.0)), 0.1, 1.5)
		cura = minf(1.0, cura + CURA_BASE * det * investigan * 2.0 / (1.0 + float(efectos.get("resistencia", 0.0)) * 1.5) * dt)
	if fraccion_zombi() >= float(Fabrica.datos.mundo.victoria):
		victoria = true
	elif cura >= 1.0:
		derrota = true
