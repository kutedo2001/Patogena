extends Node3D
## Escena principal. En la puerta 3 monta la sala, la cámara y unos volúmenes
## de escala provisionales (gris, con baliza) para juzgar densidad y proporción.

@onready var titulo: Label = $HUD/Titulo
@onready var sala: Node3D = $Sala
@onready var camara: Node3D = $RigCamara

## Duración del ciclo animado por tipo de máquina (para que los procesos se lean; la receta real la fijará P4).
const CICLO_VISUAL := {
	PantallaMaquina.Tipo.CENTRIFUGA: 3.0, PantallaMaquina.Tipo.SECUENCIADOR: 6.0, PantallaMaquina.Tipo.BIORREACTOR: 9.0,
	PantallaMaquina.Tipo.MEZCLADORA: 7.0, PantallaMaquina.Tipo.ENVASADORA: 12.0, PantallaMaquina.Tipo.CEPA: 8.0,
}

const MAQUINAS := [
	# [modelo, centro en metros (x, z), giro en grados, estado]
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-4.5, -2.5), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.CENTRIFUGA],
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-6.5, -2.5), 0.0, Maquina.Estado.AVERIA, PantallaMaquina.Tipo.CENTRIFUGA],
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-4.5, -4.5), 0.0, Maquina.Estado.SIN_MATERIAL, PantallaMaquina.Tipo.CENTRIFUGA],
	["res://assets/modelos/maquinas/secuenciador.glb", Vector2(-2.0, -3.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.SECUENCIADOR],
	["res://assets/modelos/maquinas/biorreactor.glb", Vector2(1.0, -3.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.BIORREACTOR],
	["res://assets/modelos/maquinas/biorreactor.glb", Vector2(4.0, -3.0), 0.0, Maquina.Estado.AVERIA, PantallaMaquina.Tipo.BIORREACTOR],
	["res://assets/modelos/maquinas/mezcladora.glb", Vector2(2.0, 1.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.MEZCLADORA],
	["res://assets/modelos/maquinas/envasadora.glb", Vector2(5.0, 1.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.ENVASADORA],
	["res://assets/modelos/maquinas/camara_cepa.glb", Vector2(8.5, -4.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.CEPA],
]

## Los productos se dibujan a 2,5× su tamaño real para que se lean con la cámara del juego.
const ESCALA_OBJETOS := 2.5
const OBJETOS := []

const PRODUCTOS := ["tubo_sangre", "tubo_plasma", "placa_petri", "tubo_adn", "garrafa_agua", "frasco_reactivo", "bolsa_suero",
	"proteina", "vector", "neurotoxina", "capside", "nucleo_zombi", "vial_mutacion", "caja_vacunas"]

func _montar_cintas() -> void:
	# Mk1 en bucle con los 14 productos; Mk2 y Mk3 rectas con algunos, para comparar
	var bucle: Array[Vector2i] = []
	for x in range(-8, 0):
		bucle.append(Vector2i(x, 3))
	for z in range(4, 7):
		bucle.append(Vector2i(-1, z))
	for x in range(-2, -9, -1):
		bucle.append(Vector2i(x, 6))
	for z in range(5, 3, -1):
		bucle.append(Vector2i(-8, z))
	_linea(1, bucle, true, PRODUCTOS)
	var r2: Array[Vector2i] = []
	for x in range(1, 10):
		r2.append(Vector2i(x, 4))
	_linea(2, r2, false, ["tubo_plasma", "tubo_adn", "bolsa_suero", "vial_mutacion"])
	var r3: Array[Vector2i] = []
	for x in range(1, 10):
		r3.append(Vector2i(x, 6))
	_linea(3, r3, false, ["caja_vacunas", "nucleo_zombi", "capside"])

func _linea(nivel: int, celdas: Array[Vector2i], cerrada: bool, productos: Array) -> void:
	var l := LineaCinta.new()
	l.nivel = nivel
	l.casillas = celdas
	l.cerrada = cerrada
	l.escala_objetos = ESCALA_OBJETOS
	add_child(l)
	var n := productos.size()
	var paso := minf(1.1, l.largo() / float(n))
	for i in n:
		l.poner(load("res://assets/modelos/objetos/%s.glb" % productos[i]), i * paso)

## Personajes de muestra (P3.7/P3.7b). Cada entrada: variante, pos (x, z), giro, animación y
## opciones: ruta (dos puntos), vel, estilo, amputado, rastro, rutina, alto.
const GENTE := [
	["investigador_m", Vector2(-4.5, -2.0), 180.0, "interact-right", {"rutina": [["interact-right", 4.0], ["pick-up", 1.6], ["interact-right", 3.0], ["emote-yes", 1.6]]}],
	["investigador_f", Vector2(-0.75, -2.3), -90.0, "interact-left", {"rutina": [["interact-left", 5.0], ["holding-both", 2.5], ["interact-left", 3.0]]}],
	["investigador_m", Vector2(1.0, -0.9), 0.0, "walk", {"ruta": [Vector2(-3.0, -0.9), Vector2(6.0, -0.9)]}],
	["paciente_m", Vector2(-10.9, -2.7), 90.0, "sit", {"alto": 0.3}],
	["paciente_f", Vector2(-10.9, -1.7), 90.0, "sit", {"alto": 0.3, "rutina": [["sit", 3.0], ["emote-no", 1.4]]}],
	# horda del corral de pruebas
	["zombi", Vector2(-9.0, 0.8), 30.0, "walk", {"ruta": [Vector2(-10.0, 0.4), Vector2(-7.0, 1.6)], "vel": 0.35, "estilo": "zombi"}],
	["zombi", Vector2(-8.0, -0.3), 0.0, "walk", {"ruta": [Vector2(-10.2, -0.5), Vector2(-7.4, -0.1)], "vel": 0.3, "estilo": "zombi", "amputado": ["arm-left"], "rastro": true}],
	["zombi", Vector2(-6.0, 1.9), 0.0, "idle", {"ruta": [Vector2(-6.8, 1.95), Vector2(-4.6, 1.75)], "vel": 0.12, "estilo": "arrastrar", "rastro": true}],
	["investigador_infectado", Vector2(-6.0, 0.4), 0.0, "walk", {"ruta": [Vector2(-6.2, -0.3), Vector2(-4.8, 1.0)], "vel": 0.3, "estilo": "zombi", "rastro": true}],
	["paciente_infectado", Vector2(-11.2, 1.2), 0.0, "walk", {"ruta": [Vector2(-11.3, 0.2), Vector2(-11.0, 2.2)], "vel": 0.28, "estilo": "zombi", "amputado": ["arm-right"]}],
	["zombi", Vector2(-9.0, 2.1), 0.0, "walk", {"ruta": [Vector2(-9.8, 2.15), Vector2(-8.0, 2.05)], "vel": 0.25, "estilo": "zombi", "amputado": ["head"], "rastro": true}],
	# mordisco: paciente en el suelo y zombi agachado encima
	["paciente_m", Vector2(-3.4, 1.35), 70.0, "die", {"bucle": false}],
	["zombi", Vector2(-3.45, 1.0), -20.0, "attack-melee-right", {"estilo": "comer", "vel_anim": 0.7}],
]
var _caminantes: Array = []   # [nodo, a, b, t, sentido, vel]

func _montar_gente() -> void:
	var banco: Node3D = load("res://assets/modelos/mobiliario/banco_espera.glb").instantiate()
	banco.position = Vector3(-10.85, 0, -2.2)
	banco.rotation_degrees.y = 90
	add_child(banco)
	for g in GENTE:
		var o: Dictionary = g[4]
		var p := Personaje.new()
		p.variante = g[0]
		p.animacion = g[3]
		p.estilo = o.get("estilo", "")
		p.amputado = PackedStringArray(o.get("amputado", []))
		p.rastro_sangre = o.get("rastro", false)
		p.rutina = o.get("rutina", [])
		p.bucle = o.get("bucle", true)
		p.velocidad_anim = o.get("vel_anim", 1.0)
		p.position = Vector3(g[1].x, o.get("alto", 0.0), g[1].y)
		p.rotation_degrees.y = g[2]
		add_child(p)
		if o.has("ruta"):
			_caminantes.append([p, o.ruta[0], o.ruta[1], randf(), 1.0, o.get("vel", 0.9)])
	# gore estilizado: charcos y salpicaduras en el corral y bajo el mordisco
	for d in [[Vector3(-8.4, 0, 1.2), 0.8, "sangre_charco"], [Vector3(-9.8, 0, 0.3), 0.45, "sangre_salpicadura"],
			[Vector3(-7.2, 0, 1.8), 0.4, "sangre_salpicadura"], [Vector3(-3.6, 0, 1.2), 1.0, "sangre_charco"],
			[Vector3(-2.6, 0, 0.8), 0.5, "sangre_salpicadura"], [Vector3(-8.9, 0, 2.1), 0.5, "sangre_salpicadura"]]:
		var dc := Decal.new()
		dc.texture_albedo = load("res://assets/texturas/%s.png" % d[2])
		dc.size = Vector3(d[1], 0.4, d[1])
		dc.position = d[0]
		dc.rotation.y = randf() * TAU
		add_child(dc)

func _process(dt: float) -> void:
	for c in _caminantes:
		var p: Node3D = c[0]
		var a: Vector2 = c[1]
		var b: Vector2 = c[2]
		var largo := a.distance_to(b)
		var v := 0.35 if (p as Personaje).variante == "zombi" else 0.9
		c[3] += c[4] * v * dt / largo
		if c[3] > 1.0 or c[3] < 0.0:
			c[4] = -c[4]
			c[3] = clampf(c[3], 0.0, 1.0)
		var pos := a.lerp(b, c[3])
		p.position = Vector3(pos.x, 0, pos.y)
		var dir: Vector2 = (b - a) * float(c[4])
		p.rotation.y = atan2(dir.x, dir.y)

func _ready() -> void:
	titulo.text = tr("JUEGO_TITULO")
	_igualar_renderizadores()
	sala.camara = camara
	for e in MAQUINAS:
		var m := Maquina.new()
		m.modelo = load(e[0])
		m.position = Vector3(e[1].x, 0, e[1].y)
		m.rotation_degrees.y = e[2]
		m.estado = e[3]
		m.tipo_pantalla = e[4]
		m.ciclo = CICLO_VISUAL.get(e[4], 3.0)
		add_child(m)
	_montar_cintas()
	_montar_gente()
	for o in OBJETOS:
		var n: Node3D = load(o[0]).instantiate()
		Materiales.ajustar(n)
		n.position = o[1]
		n.rotation_degrees.y = o[2]
		n.scale = Vector3.ONE * ESCALA_OBJETOS
		add_child(n)

## Compatibility (web/móvil) en Godot 4.3 no pasa a lineal el color de fondo ni
## el ambiente y no tiene SSAO: se compensa para que se vea como en PC (B1).
const AJ_EXPOSICION := 0.88

func _igualar_renderizadores() -> void:
	if RenderingServer.get_rendering_device() != null:  # con RenderingDevice = Forward+ o Mobile
		return
	var env: Environment = $Entorno.environment
	# Godot 4.7: Compatibility sale un 14 % más claro; se iguala el brillo medio con Forward+ (B1)
	env.adjustment_enabled = true
	env.adjustment_brightness = AJ_EXPOSICION
