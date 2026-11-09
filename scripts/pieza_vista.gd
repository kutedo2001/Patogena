class_name PiezaVista
extends Provisional
## Piezas de la etapa 1–2 con modelo detallado (V1.8): sala de espera con pacientes sentados,
## generador diésel (ventilador, pistones, humo) y generador de biogás de sangre (agitador,
## nivel de sangre en la mirilla, antorcha que se enciende al quemar).

const MODELOS := {
	"sala_espera": "res://assets/modelos/estaciones/sala_espera.glb",
	"generador": "res://assets/modelos/estaciones/generador.glb",
	"biogas": "res://assets/modelos/estaciones/biogas.glb",
	"capsula": "res://assets/modelos/estaciones/capsula.glb",
	"granja": "res://assets/modelos/estaciones/granja.glb",
	"deposito": "res://assets/modelos/estaciones/deposito.glb",
}

var juego: Juego
var _modelo: Node3D
var _nodos := {}
var _sentados: Array[Personaje] = []
var _asientos: Array[Node3D] = []
var _torre := {}
var _humo: GPUParticles3D
var _t := 0.0
var indice_sala := 0          # qué sala es (para repartir a los que esperan)

static func crear_pieza(e: Fabrica.Entidad, pos: Vector3, j: Juego) -> PiezaVista:
	var v := PiezaVista.new()
	v.juego = j
	v.tipo = "sala_espera" if e is Fabrica.SalaEspera else ("deposito" if e is Fabrica.Deposito else e.tipo)
	v.position = pos
	v.rotation.y = VistaFabrica.giro_y(e.giro)
	v._montar()
	return v

func _montar() -> void:
	_modelo = load(MODELOS[tipo]).instantiate()
	Materiales.ajustar(_modelo)
	add_child(_modelo)
	for n in ["ventilador", "piston_0", "piston_1", "piston_2", "piston_3", "escape", "agitador", "liquido", "llama"]:
		var x := _modelo.find_child(n, true, false)
		if x:
			_nodos[n] = x
	for n in ["baliza_v", "baliza_a", "baliza_r"]:
		var mi := _modelo.find_child(n, true, false) as MeshInstance3D
		if mi:
			var m := mat(Color(0.1, 0.1, 0.1), 0.3, 0.0)
			m.emission_enabled = true
			mi.material_override = m
			_torre[n] = m
	if tipo in ["capsula", "granja"]:
		for k in 4:
			var h := _modelo.find_child("humano%d" % k, true, false) as Node3D
			if h:
				_asientos.append(h)
			var lq := _modelo.find_child("liquido_bolsa%d" % k, true, false) as Node3D
			if lq:
				_nodos["bolsa%d" % k] = lq
	if tipo == "sala_espera":
		for k in 4:
			var a := _modelo.find_child("asiento%d" % k, true, false) as Node3D
			if a:
				_asientos.append(a)
	if _nodos.has("escape"):
		_humo = _particulas_humo()
		_nodos["escape"].add_child(_humo)

func _particulas_humo() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 24
	p.lifetime = 2.2
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.5
	pm.gravity = Vector3(0.05, 0.1, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var curva := Curve.new()
	curva.add_point(Vector2(0, 0.4))
	curva.add_point(Vector2(1, 2.2))
	var ct := CurveTexture.new()
	ct.curve = curva
	pm.scale_curve = ct
	var grad := Gradient.new()
	grad.set_color(0, Color(0.3, 0.3, 0.3, 0.5))
	grad.set_color(1, Color(0.5, 0.5, 0.5, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	p.process_material = pm
	var q := SphereMesh.new()
	q.radius = 0.05
	q.height = 0.1
	q.radial_segments = 8
	q.rings = 4
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	p.draw_pass_1 = q
	return p

func _luces(verde: bool, ambar: bool, rojo: bool) -> void:
	var cs := {"baliza_v": [verde, Color(0.2, 0.9, 0.35)], "baliza_a": [ambar, Color(1.0, 0.65, 0.08)], "baliza_r": [rojo, Color(0.95, 0.12, 0.1)]}
	for n in _torre:
		var on: bool = cs[n][0]
		var c: Color = cs[n][1]
		var m: StandardMaterial3D = _torre[n]
		m.albedo_color = c * (1.0 if on else 0.25)
		m.emission = c
		m.emission_energy_multiplier = 3.0 if on else 0.0

func actualizar(e: Fabrica.Entidad, _tt: float) -> void:
	var dt := get_process_delta_time() * (juego.velocidad if juego else 1.0)
	_t += dt
	if e is Fabrica.SalaEspera:
		_sala(e)
		return
	if e is Fabrica.Capsula:
		_capsula(e)
		return
	if e is Fabrica.Deposito:
		if _nodos.has("liquido"):
			_nodos["liquido"].scale = Vector3(1, clampf(float(e.litros) / Fabrica.Deposito.CAPACIDAD, 0.01, 1.0), 1)
		return
	var g := e as Fabrica.Generador
	var en_marcha := g.kw_actual > 0.0
	var sobrecarga := juego != null and juego.fab.demanda_kw > juego.fab.capacidad_kw()
	_luces(en_marcha and not sobrecarga, not en_marcha, sobrecarga)
	if _nodos.has("ventilador"):
		_nodos["ventilador"].rotate_object_local(Vector3.UP, dt * 18.0)
	for k in 4:
		var n: Node3D = _nodos.get("piston_%d" % k)
		if n:
			if not n.has_meta("y0"):
				n.set_meta("y0", n.position.y)
			n.position.y = float(n.get_meta("y0")) + (0.025 * sin(_t * 22.0 + k * PI * 0.5) if en_marcha else 0.0)
	if _humo:
		_humo.emitting = en_marcha
	if _nodos.has("agitador") and en_marcha:
		_nodos["agitador"].rotate_object_local(Vector3.UP, dt * 3.0)
	if _nodos.has("liquido"):
		var k2 := clampf(float(g.combustible) / 10.0, 0.03, 1.0)
		_nodos["liquido"].scale = Vector3(1, k2, 1)
	if _nodos.has("llama"):
		var ll: Node3D = _nodos["llama"]
		ll.visible = en_marcha
		ll.scale = Vector3.ONE * (1.0 + 0.15 * sin(_t * 17.0) + 0.1 * sin(_t * 29.0))

## Pacientes sentados: la primera sala sienta a los cuatro primeros que esperan, la segunda a los siguientes…
func _sala(_e: Fabrica.SalaEspera) -> void:
	if juego == null:
		return
	var n := clampi(juego.fab.espera_pacientes - indice_sala * Fabrica.SalaEspera.ASIENTOS, 0, Fabrica.SalaEspera.ASIENTOS)
	while _sentados.size() < n and _sentados.size() < _asientos.size():
		var p := Personaje.new()
		p.variante = ["paciente_m", "paciente_f"][randi() % 2]
		p.animacion = "sit"
		var a := _asientos[_sentados.size()]
		a.add_child(p)
		_sentados.append(p)
	while _sentados.size() > n:
		_sentados.pop_front().queue_free()

## Cápsulas: la persona flota dentro (de pie, cabeza caída, balanceo lento); la bolsa de suero baja;
## sin suero la luz pasa a ámbar.
func _capsula(c: Fabrica.Capsula) -> void:
	_luces(c.activa(), not c.activa() and c.humanos > 0, false)
	while _sentados.size() < c.humanos and _sentados.size() < _asientos.size():
		var p := Personaje.new()
		p.variante = ["paciente_m", "paciente_f"][randi() % 2]
		p.animacion = "idle"
		p.estilo = "mareado"
		p.velocidad_anim = 0.3
		_asientos[_sentados.size()].add_child(p)
		_sentados.append(p)
	for i in _sentados.size():
		var p := _sentados[i]
		p.position.y = 0.02 * sin(_t * 0.8 + i)
		p.rotation.y = 0.15 * sin(_t * 0.3 + i * 2.0)
	var k := clampf(c.nutricion / Fabrica.Capsula.SUERO_CADA + float(c.suero) / 4.0, 0.03, 1.0)
	for i in 4:
		if _nodos.has("bolsa%d" % i):
			_nodos["bolsa%d" % i].scale = Vector3(1, k, 1)
