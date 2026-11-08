extends Node3D
## Escena principal. En la puerta 3 monta la sala, la cámara y unos volúmenes
## de escala provisionales (gris, con baliza) para juzgar densidad y proporción.

@onready var titulo: Label = $HUD/Titulo
@onready var sala: Node3D = $Sala
@onready var camara: Node3D = $RigCamara

const ESCALAS := [
	# [posición casilla, tamaño en casillas (x, alto, z), acento de familia]
	[Vector2(-6, -4), Vector3(1, 1.2, 1), Color(0.29, 0.58, 0.54)],
	[Vector2(-4, -4), Vector3(1, 1.2, 1), Color(0.29, 0.58, 0.54)],
	[Vector2(-1, -3.5), Vector3(2, 1.8, 2), Color(0.85, 0.45, 0.2)],
	[Vector2(3, -3), Vector3(3, 2.4, 3), Color(0.55, 0.35, 0.65)],
	[Vector2(-5, 2), Vector3(2, 1.8, 2), Color(0.25, 0.45, 0.75)],
]

func _ready() -> void:
	titulo.text = tr("JUEGO_TITULO")
	_igualar_renderizadores()
	sala.camara = camara
	for e in ESCALAS:
		_volumen(e[0], e[1], e[2])

func _volumen(casilla: Vector2, t: Vector3, acento: Color) -> void:
	var raiz := Node3D.new()
	raiz.position = Vector3(casilla.x, 0, casilla.y)
	add_child(raiz)
	var cuerpo := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(t.x - 0.1, t.y, t.z - 0.1)
	cuerpo.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.82, 0.8, 0.76)
	m.roughness = 0.6
	cuerpo.material_override = m
	cuerpo.position.y = t.y / 2.0
	raiz.add_child(cuerpo)
	var tapa := MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(t.x - 0.04, 0.12, t.z - 0.04)
	tapa.mesh = tb
	var ma := StandardMaterial3D.new()
	ma.albedo_color = acento
	ma.roughness = 0.5
	tapa.material_override = ma
	tapa.position.y = t.y + 0.06
	raiz.add_child(tapa)
	var baliza := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.14
	sm.height = 0.2
	baliza.mesh = sm
	var mb := StandardMaterial3D.new()
	mb.albedo_color = Color(0.3, 1.0, 0.45)
	mb.emission_enabled = true
	mb.emission = Color(0.3, 1.0, 0.45)
	mb.emission_energy_multiplier = 3.0
	baliza.material_override = mb
	baliza.position = Vector3(t.x / 2.0 - 0.3, t.y + 0.2, t.z / 2.0 - 0.3)
	raiz.add_child(baliza)

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
