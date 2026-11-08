extends Node3D
## Escena principal. En la puerta 3 monta la sala, la cámara y unos volúmenes
## de escala provisionales (gris, con baliza) para juzgar densidad y proporción.

@onready var titulo: Label = $HUD/Titulo
@onready var sala: Node3D = $Sala
@onready var camara: Node3D = $RigCamara

const MAQUINAS := [
	# [modelo, centro en metros (x, z), giro en grados, estado]
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-4.5, -2.5), 0.0, Maquina.Estado.TRABAJANDO],
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-4.5, -4.5), 0.0, Maquina.Estado.SIN_MATERIAL],
	["res://assets/modelos/maquinas/secuenciador.glb", Vector2(-2.0, -3.0), 0.0, Maquina.Estado.TRABAJANDO],
	["res://assets/modelos/maquinas/biorreactor.glb", Vector2(1.0, -3.0), 0.0, Maquina.Estado.TRABAJANDO],
	["res://assets/modelos/maquinas/biorreactor.glb", Vector2(4.0, -3.0), 0.0, Maquina.Estado.AVERIA],
]

## Los productos se dibujan a 2,5× su tamaño real para que se lean con la cámara del juego.
const ESCALA_OBJETOS := 2.5
const OBJETOS := [
	# muestrario provisional en el suelo (P3.4a) para ver los objetos con la cámara del juego
	["res://assets/modelos/objetos/gradilla.glb", Vector3(-6.3, 0, -1.9), 20.0],
	["res://assets/modelos/objetos/placa_petri.glb", Vector3(-5.6, 0, -1.1), 0.0],
	["res://assets/modelos/objetos/vial_mutacion.glb", Vector3(-6.6, 0, -1.0), 0.0],
	["res://assets/modelos/objetos/tubo_adn.glb", Vector3(-6.95, 0, -1.3), 0.0],
]

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
		add_child(m)
	for o in OBJETOS:
		var n: Node3D = load(o[0]).instantiate()
		Materiales.ajustar(n)
		n.position = o[1]
		n.rotation_degrees.y = o[2]
		n.scale = Vector3.ONE * ESCALA_OBJETOS
		add_child(n)

## Compatibility (web/móvil) en Godot 4.3 no pasa a lineal el color de fondo ni
## el ambiente y no tiene SSAO: se compensa para que se vea como en PC (B1).
func _igualar_renderizadores() -> void:
	if RenderingServer.get_rendering_device() != null:  # con RenderingDevice = Forward+ o Mobile
		return
	var env: Environment = $Entorno.environment
	# valores medidos comparando capturas píxel a píxel con Forward+
	env.background_color = env.background_color.srgb_to_linear() * 2.6
	env.ambient_light_color = env.ambient_light_color.srgb_to_linear()
	env.ambient_light_energy *= 1.75
	$Sol.light_energy *= 0.4
