class_name Maquina
extends Node3D
## Máquina colocada en el laboratorio. Carga su modelo (glTF hecho por script de
## Blender) y anima las piezas con nombre fijo según el estado:
## rotor y agitador giran, cabezal va y viene, líquido burbujea, pantalla parpadea,
## baliza cambia de color (verde trabaja, ámbar falta material, rojo avería).

enum Estado { APAGADA, TRABAJANDO, SIN_MATERIAL, AVERIA }

const COLOR_BALIZA := {
	Estado.APAGADA: Color(0.25, 0.27, 0.28),
	Estado.TRABAJANDO: Color(0.3, 1.0, 0.45),
	Estado.SIN_MATERIAL: Color(1.0, 0.7, 0.1),
	Estado.AVERIA: Color(1.0, 0.18, 0.12),
}

@export var modelo: PackedScene
@export var estado: Estado = Estado.TRABAJANDO:
	set(v):
		estado = v
		_t_estado = 0.0

var _rotor: Node3D
var _agitador: Node3D
var _cabezal: Node3D
var _liquido: Node3D
var _mat_baliza: StandardMaterial3D
var _mat_pantalla: StandardMaterial3D
var _cabezal_x0 := 0.0
var _liq_y0 := 0.0
var _vel_giro := 0.0      # 0..1, arranca y frena con inercia
var _t := 0.0
var _t_estado := 0.0

func _ready() -> void:
	if modelo:
		add_child(modelo.instantiate())
	_rotor = _buscar("rotor")
	_agitador = _buscar("agitador")
	_cabezal = _buscar("cabezal")
	_liquido = _buscar("liquido")
	if _cabezal:
		_cabezal_x0 = _cabezal.position.x
	if _liquido:
		_liq_y0 = _liquido.scale.y
	_mat_baliza = _material_propio(_buscar("baliza"))
	_mat_pantalla = _material_propio(_buscar("pantalla"))
	_t = randf() * 10.0

func _buscar(nombre: String) -> Node3D:
	var r := find_child(nombre, true, false)
	return r as Node3D

func _material_propio(n: Node3D) -> StandardMaterial3D:
	var mi := n as MeshInstance3D
	if mi == null or mi.mesh == null:
		return null
	var m := mi.get_active_material(0)
	if not (m is StandardMaterial3D):
		return null
	var copia: StandardMaterial3D = m.duplicate()
	mi.material_override = copia
	return copia

func _process(dt: float) -> void:
	_t += dt
	_t_estado += dt
	var trabaja := estado == Estado.TRABAJANDO
	_vel_giro = move_toward(_vel_giro, 1.0 if trabaja else 0.0, dt * (0.8 if trabaja else 0.5))
	if _rotor:
		_rotor.rotate_y(_vel_giro * TAU * 6.0 * dt)
	if _agitador:
		_agitador.rotate_y(_vel_giro * TAU * 0.8 * dt)
	if _cabezal:
		var objetivo := _cabezal_x0 + sin(_t * 1.7) * 0.5 if trabaja else _cabezal.position.x
		_cabezal.position.x = lerpf(_cabezal.position.x, objetivo, 1.0 - exp(-8.0 * dt))
	if _liquido:
		_liquido.scale.y = _liq_y0 * (1.0 + sin(_t * 3.1) * 0.015 * _vel_giro)
	if _mat_pantalla:
		_mat_pantalla.emission_energy_multiplier = (1.4 + sin(_t * 9.0) * 0.25) if trabaja else 0.15
	if _mat_baliza:
		var c: Color = COLOR_BALIZA[estado]
		var brillo := 4.0
		match estado:
			Estado.SIN_MATERIAL:
				brillo = 1.5 + 2.5 * (0.5 + 0.5 * sin(_t_estado * 4.0))
			Estado.AVERIA:
				brillo = 4.5 if fmod(_t_estado, 0.5) < 0.25 else 0.4
			Estado.APAGADA:
				brillo = 0.0
		_mat_baliza.albedo_color = c
		_mat_baliza.emission = c
		_mat_baliza.emission_energy_multiplier = brillo
