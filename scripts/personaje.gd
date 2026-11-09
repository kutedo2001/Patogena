class_name Personaje
extends Node3D
## Personaje del pack CC0 Kenney Mini Characters, recoloreado por variante
## (bata, pijama de paciente, zombi) y con su animación. Nunca se esculpen por código.

const MODELOS := {
	"investigador_m": "res://assets/personajes/character-male-a.glb",
	"investigador_f": "res://assets/personajes/character-female-e.glb",
	"paciente_m": "res://assets/personajes/character-male-a.glb",
	"paciente_f": "res://assets/personajes/character-female-d.glb",
	"zombi": "res://assets/personajes/character-zombie.glb",
}
const ESCALA := 0.62          # el pack mide ~1,45 m; el becario mide 0,9 casillas

@export var variante := "investigador_m"
@export var animacion := "idle"
@export var velocidad_anim := 1.0
var _ap: AnimationPlayer

func _ready() -> void:
	var m: Node3D = load(MODELOS[variante]).instantiate()
	m.scale = Vector3.ONE * ESCALA
	add_child(m)
	var tex: Texture2D = load("res://assets/personajes/Textures/%s.png" % variante)
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.roughness = 0.75
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		(mi as MeshInstance3D).material_override = mat
	var aps := m.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_ap = aps[0]
		poner(animacion)
		_ap.seek(randf() * 0.8, true)

func poner(nombre: String, bucle := true) -> void:
	if _ap == null or not _ap.has_animation(nombre):
		return
	var a := _ap.get_animation(nombre)
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	_ap.play(nombre, 0.2, velocidad_anim)
