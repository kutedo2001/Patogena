class_name Personaje
extends Node3D
## Personaje del pack CC0 Kenney Mini Characters, recoloreado por variante y con
## retoques de animación por hueso (andar de zombi, arrastrarse), amputaciones con
## muñón y goteo de sangre. Las personas nunca se esculpen por código: el cuerpo es
## siempre el del pack; los muñones y la sangre son efectos encima.

const MODELOS := {
	"investigador_m": "res://assets/personajes/character-male-a.glb",
	"investigador_f": "res://assets/personajes/character-female-e.glb",
	"paciente_m": "res://assets/personajes/character-male-a.glb",
	"paciente_f": "res://assets/personajes/character-female-d.glb",
	"zombi": "res://assets/personajes/character-zombie.glb",
	"investigador_infectado": "res://assets/personajes/character-male-a.glb",
	"paciente_infectado": "res://assets/personajes/character-female-d.glb",
}
const ESCALA := 0.62          # el pack mide ~1,45 m; el becario mide 0,9 casillas
const C_SANGRE := Color(0.69, 0.12, 0.13)   # dentro del rango de la guía (#9E1B1B–#C42626)

@export var variante := "investigador_m"
@export var animacion := "idle"
@export var velocidad_anim := 1.0
## «zombi» (brazos al frente, cabeceo, cojera), «arrastrar» (sin piernas, por el suelo) o vacío
@export var estilo := ""
## huesos amputados: "arm-left", "arm-right", "head", "legs"
@export var amputado: PackedStringArray = []
@export var bucle := true
@export var rastro_sangre := false      # deja gotas en el suelo al moverse
## secuencia de animaciones que se alternan: [[nombre, segundos], ...]
@export var rutina: Array = []
## tumbado: 0..1 intensidad del respingo al pincharle; mirar_brazo: gira la cabeza hacia el brazo
var sobresalto := 0.0
var mirar_brazo := 0.0

var _ap: AnimationPlayer
var _esq: Skeleton3D
var _modelo: Node3D
var _t := 0.0
var _fase := randf() * 10.0
var _rutina_i := 0
var _rutina_t := 0.0
var _hueso := {}
var _ultimo_rastro := Vector3.INF
var _gotas: Array[Node3D] = []

func _ready() -> void:
	_modelo = load(MODELOS[variante]).instantiate()
	_modelo.scale = Vector3.ONE * ESCALA
	add_child(_modelo)
	var tex: Texture2D = load("res://assets/personajes/Textures/%s.png" % variante)
	for mi in _modelo.find_children("*", "MeshInstance3D", true, false):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.roughness = 0.75
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		(mi as MeshInstance3D).material_override = mat
	var sk := _modelo.find_children("*", "Skeleton3D", true, false)
	if not sk.is_empty():
		_esq = sk[0]
		for n in ["root", "torso", "head", "arm-left", "arm-right", "leg-left", "leg-right"]:
			_hueso[n] = _esq.find_bone(n)
	var aps := _modelo.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_ap = aps[0]
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		if not rutina.is_empty():
			animacion = rutina[0][0]
		poner(animacion, bucle)
		if bucle:
			_ap.seek(randf() * 0.8, true)
		else:
			_ap.seek(_ap.current_animation_length - 0.01, true)
	if estilo == "arrastrar" and not amputado.has("legs"):
		amputado.append("legs")
	for h in amputado:
		_munon(h)

func poner(nombre: String, bucle := true) -> void:
	if _ap == null or not _ap.has_animation(nombre):
		return
	var a := _ap.get_animation(nombre)
	a.loop_mode = Animation.LOOP_LINEAR if bucle else Animation.LOOP_NONE
	_ap.play(nombre, 0.25, velocidad_anim)

# ------------------------------------------------------------------ muñones y sangre
func _material(c: Color, rug := 0.5, emis := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rug
	if emis > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emis
	return m

## Muñón en la articulación del hueso amputado: carne roja, hueso blanco asomando y goteo.
## Medidas en unidades del esqueleto del pack (cuerpo de ~0,67 de alto, brazos en T a lo largo de X).
func _munon(h: String) -> void:
	if _esq == null:
		return
	var huesos: Array = ["leg-left", "leg-right"] if h == "legs" else [h]
	for hn in huesos:
		var idx: int = _esq.find_bone(hn)
		if idx < 0:
			continue
		var padre: int = _esq.get_bone_parent(idx)
		var at := BoneAttachment3D.new()
		at.bone_idx = padre if padre >= 0 else idx
		_esq.add_child(at)
		var raiz := Node3D.new()
		raiz.position = _esq.get_bone_rest(idx).origin
		at.add_child(raiz)
		# eje hacia fuera del muñón: brazos de lado, cabeza arriba, piernas abajo
		var eje := Vector3.DOWN
		var r := 0.04
		if hn == "head":
			eje = Vector3.UP
			r = 0.075
		elif hn.begins_with("arm"):
			eje = Vector3(signf(raiz.position.x), 0, 0)
			r = 0.038
		var orient := Basis(Quaternion(Vector3.UP, eje))
		var carne := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = r * 0.85
		cm.bottom_radius = r
		cm.height = 0.022
		cm.radial_segments = 12
		carne.mesh = cm
		carne.material_override = _material(Color(0.6, 0.05, 0.07), 0.3, 0.12)
		carne.transform = Transform3D(orient, eje * 0.006)
		raiz.add_child(carne)
		var hb := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = r * 0.22
		bm.bottom_radius = r * 0.28
		bm.height = 0.04
		bm.radial_segments = 8
		hb.mesh = bm
		hb.material_override = _material(Color(0.95, 0.92, 0.82), 0.6)
		hb.transform = Transform3D(orient, eje * 0.03)
		raiz.add_child(hb)
		var gotas := _goteo(hn == "head")
		gotas.position = eje * 0.02
		raiz.add_child(gotas)

## Partículas de sangre: gotas que caen (o un chorrito que sale hacia arriba en el cuello).
func _goteo(fuente: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 24 if fuente else 10
	p.lifetime = 0.9
	p.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0) if fuente else Vector3(0, -1, 0)
	pm.spread = 25.0 if fuente else 10.0
	pm.initial_velocity_min = 0.35 if fuente else 0.02
	pm.initial_velocity_max = 0.6 if fuente else 0.08
	pm.gravity = Vector3(0, -2.5, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var q := SphereMesh.new()
	q.radius = 0.006
	q.height = 0.016
	q.radial_segments = 6
	q.rings = 3
	q.material = _material(C_SANGRE, 0.2, 0.2)
	p.draw_pass_1 = q
	return p

func _rastro() -> void:
	if not rastro_sangre:
		return
	var aqui := global_position
	if _ultimo_rastro.distance_to(aqui) < 0.35:
		return
	_ultimo_rastro = aqui
	var d := Mancha.crear(preload("res://assets/texturas/sangre_gota.png"), randf_range(0.12, 0.22))
	d.rotation.y = randf() * TAU
	get_parent().add_child(d)
	d.global_position = aqui + Vector3(randf_range(-0.08, 0.08), 0, randf_range(-0.08, 0.08))
	_gotas.append(d)
	if _gotas.size() > 40:
		_gotas.pop_front().queue_free()

## Punto del brazo en coordenadas globales: t = 0 hombro, 1 mano. El pack tiene un solo hueso
## por brazo y en reposo el brazo va a lo largo de X (izquierdo +X, derecho −X).
func punto_brazo(derecho: bool, t: float) -> Vector3:
	if _esq == null:
		return global_position
	var i: int = _hueso["arm-right" if derecho else "arm-left"]
	var p := _esq.get_bone_global_pose(i)
	var local := p.origin + p.basis * Vector3((-0.27 if derecho else 0.27) * t, 0.0, 0.0)
	return _esq.global_transform * local

# ------------------------------------------------------------------ animación por hueso
func _rot(h: String, eje: Vector3, grados: float) -> void:
	var i: int = _hueso.get(h, -1)
	if i < 0:
		return
	var q := _esq.get_bone_pose_rotation(i)
	_esq.set_bone_pose_rotation(i, q * Quaternion(eje, deg_to_rad(grados)))

func _fijar(h: String, q: Quaternion) -> void:
	var i: int = _hueso.get(h, -1)
	if i >= 0:
		_esq.set_bone_pose_rotation(i, q)

func _q(eje: Vector3, grados: float) -> Quaternion:
	return Quaternion(eje, deg_to_rad(grados))

func _ocultar(h: String) -> void:
	var i: int = _hueso.get(h, -1)
	if i >= 0:
		_esq.set_bone_pose_scale(i, Vector3.ONE * 0.001)

func _process(dt: float) -> void:
	_t += dt
	if _ap:
		if not rutina.is_empty():
			_rutina_t += dt
			if _rutina_t > float(rutina[_rutina_i][1]):
				_rutina_t = 0.0
				_rutina_i = (_rutina_i + 1) % rutina.size()
				poner(rutina[_rutina_i][0])
		_ap.advance(dt)
	if _esq == null:
		return
	var f := _t * 2.2 + _fase
	# El pack tiene los brazos en T a lo largo de X: brazo izquierdo = +X, derecho = -X; mira a +Z.
	match estilo:
		"zombi":
			# brazos rígidos al frente, algo caídos y desacompasados; cabeza ladeada que cabecea
			_fijar("arm-left", _q(Vector3.RIGHT, 18.0 + sin(f) * 7.0) * _q(Vector3.UP, -72.0 + sin(f * 0.6) * 5.0))
			_fijar("arm-right", _q(Vector3.RIGHT, 12.0 + sin(f + 1.3) * 9.0) * _q(Vector3.UP, 74.0 + sin(f * 0.7) * 5.0))
			_rot("head", Vector3.FORWARD, 16.0 + sin(f * 0.7) * 6.0)
			_rot("head", Vector3.RIGHT, 12.0 + sin(f * 1.1) * 6.0)
			_rot("torso", Vector3.FORWARD, sin(f) * 6.0)
			_rot("torso", Vector3.RIGHT, 8.0)
		"arrastrar":
			# boca abajo tirando de los brazos alternos; la cabeza levantada mirando al frente
			var a1 := 40.0 + sin(f) * 32.0
			var a2 := 40.0 + sin(f + PI) * 32.0
			_fijar("root", _q(Vector3.RIGHT, 88.0))
			_fijar("arm-left", _q(Vector3.RIGHT, a1) * _q(Vector3.BACK, 80.0))
			_fijar("arm-right", _q(Vector3.RIGHT, a2) * _q(Vector3.BACK, -80.0))
			_fijar("head", _q(Vector3.RIGHT, -22.0) * _q(Vector3.FORWARD, sin(f) * 6.0))
			_fijar("torso", _q(Vector3.FORWARD, sin(f) * 5.0))
			_modelo.position.y = 0.05
		"comer":
			# agachado sobre la víctima, cabeza hundida que tira, brazos sujetando
			_fijar("root", _q(Vector3.RIGHT, 26.0))
			_fijar("torso", _q(Vector3.RIGHT, 12.0 + sin(f * 2.5) * 4.0))
			_fijar("head", _q(Vector3.RIGHT, 28.0 + sin(f * 2.5) * 14.0) * _q(Vector3.UP, sin(f * 1.3) * 12.0))
			_fijar("arm-left", _q(Vector3.RIGHT, 45.0 + sin(f * 2.0) * 15.0) * _q(Vector3.UP, -80.0))
			_fijar("arm-right", _q(Vector3.RIGHT, 45.0 + sin(f * 2.0 + 1.0) * 15.0) * _q(Vector3.UP, 80.0))
			_fijar("leg-left", _q(Vector3.RIGHT, -45.0))
			_fijar("leg-right", _q(Vector3.RIGHT, -25.0))
			_modelo.position.y = -0.02
		"tumbado":
			# boca arriba en la camilla; brazo derecho extendido hacia el lado de trabajo
			# (sobre el reposabrazos) y el izquierdo junto al cuerpo. «sobresalto» (0..1) = pinchazo.
			var s := sobresalto
			_fijar("root", _q(Vector3.RIGHT, -90.0))
			_fijar("torso", _q(Vector3.RIGHT, -4.0 + sin(_t * 1.6) * 1.2))
			_fijar("head", _q(Vector3.FORWARD, -18.0 * mirar_brazo - s * 10.0 * sin(_t * 40.0)) * _q(Vector3.RIGHT, -12.0 - s * 14.0))
			_fijar("arm-left", _q(Vector3.BACK, -78.0))
			_fijar("arm-right", _q(Vector3.BACK, -8.0 + s * 6.0 * sin(_t * 33.0)) * _q(Vector3.UP, 4.0))
			_fijar("leg-left", _q(Vector3.FORWARD, 3.0))
			_fijar("leg-right", _q(Vector3.FORWARD, -3.0))
		"incorporado":
			# sentado en el borde de la camilla tras la extracción, mareado: cabeza que se balancea
			_rot("head", Vector3.FORWARD, sin(_t * 2.1) * 14.0)
			_rot("head", Vector3.RIGHT, 18.0 + sin(_t * 1.3) * 8.0)
			_rot("torso", Vector3.FORWARD, sin(_t * 1.7 + 0.5) * 9.0)
			_fijar("arm-left", _q(Vector3.BACK, 70.0))
			_fijar("arm-right", _q(Vector3.RIGHT, 30.0) * _q(Vector3.UP, 70.0))   # se sujeta el brazo pinchado
		"mareado":
			# andar inseguro: tronco que se tambalea y cabeza caída
			_rot("torso", Vector3.FORWARD, sin(_t * 2.6) * 10.0)
			_rot("head", Vector3.RIGHT, 14.0)
			_rot("head", Vector3.FORWARD, sin(_t * 1.9 + 1.0) * 12.0)
			_rot("arm-right", Vector3.UP, 55.0)
	for h in amputado:
		if h == "legs":
			_ocultar("leg-left")
			_ocultar("leg-right")
		else:
			_ocultar(h)
	_rastro()
