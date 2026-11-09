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
