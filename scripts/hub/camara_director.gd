class_name CamaraDirector
extends Node3D
## Cámara de director (R2.2), como Two Point: perspectiva FOV 32°, inclinación 52°, girada 45° respecto a la
## rejilla y giro en pasos de 90° (Q/E). Rueda = zoom; WASD / flechas / botón central arrastrando = mover.

const INCLINACION := 52.0
const DIST_MIN := 4.0
const DIST_MAX := 30.0
var limites := Rect2(-4, -4, 24, 20)
var distancia := 13.0
var _dist_obj := 13.0
var giro := 45.0
var _giro_obj := 45.0
var _arrastrando := false
var cam: Camera3D

func _ready() -> void:
	cam = Camera3D.new()
	cam.fov = 32.0
	cam.near = 0.3
	cam.far = 200.0
	add_child(cam)
	cam.current = true
	_aplicar()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist_obj = clampf(_dist_obj * 0.88, DIST_MIN, DIST_MAX)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist_obj = clampf(_dist_obj / 0.88, DIST_MIN, DIST_MAX)
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_MIDDLE:
		_arrastrando = ev.pressed
	elif ev is InputEventMouseMotion and _arrastrando:
		_desplazar(-ev.relative * distancia * 0.0016)
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_Q:
			_giro_obj -= 90.0
		elif ev.keycode == KEY_E:
			_giro_obj += 90.0

func _desplazar(d: Vector2) -> void:
	var m := Basis(Vector3.UP, deg_to_rad(giro)) * Vector3(d.x, 0, d.y)
	position.x = clampf(position.x + m.x, limites.position.x, limites.end.x)
	position.z = clampf(position.z + m.z, limites.position.y, limites.end.y)

func _process(dt: float) -> void:
	var v := Vector2(Input.get_axis("ui_left", "ui_right") + float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		Input.get_axis("ui_up", "ui_down") + float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
	if v != Vector2.ZERO:
		_desplazar(v.limit_length(1.0) * 10.0 * dt * distancia / 13.0)
	var k := 1.0 - exp(-12.0 * dt)
	distancia = lerpf(distancia, _dist_obj, k)
	giro = lerpf(giro, _giro_obj, k)
	_aplicar()

func fijar(centro: Vector3, dist: float) -> void:
	position = Vector3(centro.x, 0, centro.z)
	distancia = dist
	_dist_obj = dist
	_aplicar()

func _aplicar() -> void:
	rotation_degrees.y = giro
	var inc := deg_to_rad(INCLINACION)
	cam.position = Vector3(0, sin(inc), cos(inc)) * distancia
	cam.rotation_degrees = Vector3(-INCLINACION, 0, 0)

## Punto del suelo (y=0) bajo una posición de pantalla.
func suelo_bajo(p: Vector2) -> Vector3:
	var o := cam.project_ray_origin(p)
	var d := cam.project_ray_normal(p)
	if absf(d.y) < 1e-4:
		return Vector3.ZERO
	return o + d * (-o.y / d.y)
