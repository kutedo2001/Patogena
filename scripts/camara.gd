extends Node3D
## Cámara del juego: perspectiva FOV 30°, inclinación 50°, giro en pasos de 45°.
## Ratón: rueda = zoom, botón central o derecho arrastrando = mover; Q/E = girar;
## WASD / flechas = mover. Táctil: un dedo mueve, dos dedos hacen zoom.

const INCLINACION := 50.0
const FOV := 30.0
const DIST_MIN := 13.0   # ~12 casillas de ancho
const DIST_MAX := 42.0   # ~40 casillas de ancho
const VEL_MOVER := 14.0

@export var limites := Rect2(-12, -8, 24, 16)
var distancia := 21.0            # ~20 casillas de ancho a zoom medio
var _dist_obj := 21.0
var giro := 45.0
var _giro_obj := 45.0
var _arrastrando := false
var _toques := {}

@onready var cam: Camera3D = $Camara

func _ready() -> void:
	cam.fov = FOV
	cam.near = 0.5
	cam.far = 300.0
	for a in OS.get_cmdline_user_args():  # para capturas automáticas
		if a.begins_with("--giro="):
			giro = float(a.trim_prefix("--giro=")); _giro_obj = giro
		elif a.begins_with("--dist="):
			distancia = float(a.trim_prefix("--dist=")); _dist_obj = distancia
	_aplicar()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			_dist_obj = clampf(_dist_obj * 0.88, DIST_MIN, DIST_MAX)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			_dist_obj = clampf(_dist_obj / 0.88, DIST_MIN, DIST_MAX)
		elif ev.button_index in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			_arrastrando = ev.pressed
	elif ev is InputEventMouseMotion and _arrastrando:
		_mover_pantalla(ev.relative)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_Q:
			_giro_obj -= 45.0
		elif ev.keycode == KEY_E:
			_giro_obj += 45.0
	elif ev is InputEventScreenTouch:
		if ev.pressed:
			_toques[ev.index] = ev.position
		else:
			_toques.erase(ev.index)
	elif ev is InputEventScreenDrag:
		if _toques.size() == 1:
			_mover_pantalla(ev.relative)
		elif _toques.size() == 2 and _toques.has(ev.index):
			var otro: Vector2 = _toques[_toques.keys().filter(func(k): return k != ev.index)[0]]
			var antes: float = (_toques[ev.index] as Vector2).distance_to(otro)
			var ahora: float = ev.position.distance_to(otro)
			if ahora > 1.0:
				_dist_obj = clampf(_dist_obj * antes / ahora, DIST_MIN, DIST_MAX)
		_toques[ev.index] = ev.position

func _mover_pantalla(rel: Vector2) -> void:
	var escala := distancia * 0.0016
	_desplazar(Vector2(-rel.x, -rel.y) * escala)

func _desplazar(d: Vector2) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(giro))
	var mundo := b * Vector3(d.x, 0, d.y)
	position.x = clampf(position.x + mundo.x, limites.position.x, limites.end.x)
	position.z = clampf(position.z + mundo.z, limites.position.y, limites.end.y)

func _process(dt: float) -> void:
	var v := Vector2(
		Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		Input.get_axis("ui_up", "ui_down") + float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	if v != Vector2.ZERO:
		_desplazar(v.limit_length(1.0) * VEL_MOVER * dt * distancia / 21.0)
	var k := 1.0 - exp(-12.0 * dt)
	distancia = lerpf(distancia, _dist_obj, k)
	giro = lerpf(giro, _giro_obj, k)
	_aplicar()

func _aplicar() -> void:
	rotation_degrees.y = giro
	var inc := deg_to_rad(INCLINACION)
	cam.position = Vector3(0, sin(inc), cos(inc)) * distancia
	cam.rotation_degrees = Vector3(-INCLINACION, 0, 0)

## Dirección horizontal desde la que mira la cámara (para ocultar paredes cercanas).
func direccion_vista() -> Vector3:
	return (Basis(Vector3.UP, deg_to_rad(giro)) * Vector3(0, 0, 1)).normalized()
