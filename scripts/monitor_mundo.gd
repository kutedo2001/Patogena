class_name MonitorMundo
extends Node3D
## Monitor del mundo colgado en la pared: modelo de Blender + pantalla viva (PantallaMundo).

var _baliza: Node3D
var juego: Juego
var _ui: PantallaMundo

func _ready() -> void:
	var m: Node3D = load("res://assets/modelos/mobiliario/monitor_mundo.glb").instantiate()
	Materiales.ajustar(m)
	add_child(m)
	_baliza = m.find_child("gira_baliza", true, false)
	var pant := m.find_child("pantalla", true, false) as MeshInstance3D
	if pant == null:
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(1024, 430)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var ui := PantallaMundo.new()
	_ui = ui
	ui.size = Vector2(vp.size)
	vp.add_child(ui)
	add_child(vp)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = vp.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = vp.get_texture()
	mat.emission_energy_multiplier = 1.3
	mat.roughness = 0.2
	mat.metallic_specular = 0.6
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	pant.material_override = mat

func _process(dt: float) -> void:
	if _baliza:
		_baliza.rotate_y(dt * 5.0)
	if juego and _ui:
		_ui.propagacion = juego.propagacion
		_ui.cura = juego.cura
		_ui.real = true
		_ui.mundo = juego.mundo
