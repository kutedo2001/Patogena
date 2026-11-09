class_name EstacionVista
extends Provisional
## Dibujo de una estación de extracción (provisional de la puerta 4): camilla con pacientes que
## llegan por la puerta, se tumban y se van; incubadora con el cultivo creciendo; toma de agua
## con la garrafa llenándose. Con la mejora aparece la máquina; con un zombi, el zombi operándola.
## El producto hecho se ve encima hasta que alguien lo coge.

var juego: Juego
var _paciente: Personaje
var _yendo: Array = []            # [personaje, desde, hasta, t]
var _atendidos := 0
var _maquina: Node3D
var _zombi: Personaje
var _producto: Node3D
var _producto_nombre := ""
var _placa: MeshInstance3D
var _agua: MeshInstance3D
var _modo := ""

static func crear_estacion(e: Fabrica.Estacion, pos: Vector3, j: Juego) -> EstacionVista:
	var v := EstacionVista.new()
	v.juego = j
	v.tipo = e.tipo
	v.position = pos
	v.rotation.y = VistaFabrica.giro_y(e.giro)
	v._montar()
	return v

func _montar() -> void:
	match tipo:
		"camilla":
			_montar_camilla()
			return
		"incubadora":
			caja(Vector3(0.8, 0.9, 0.7), Vector3(0, 0.45, 0), C_CHASIS)
			caja(Vector3(0.6, 0.5, 0.02), Vector3(0, 0.5, -0.36), Color(0.2, 0.3, 0.32))
			caja(Vector3(0.82, 0.06, 0.72), Vector3(0, 0.92, 0), C_ACENTO)
			_placa = cilindro(0.16, 0.03, Vector3(0, 0.45, -0.2), Color(0.55, 0.85, 0.35))
		"toma_agua":
			cilindro(0.05, 1.2, Vector3(-0.3, 0.6, 0), Color(0.55, 0.6, 0.62))
			caja(Vector3(0.4, 0.05, 0.08), Vector3(-0.12, 1.15, 0), Color(0.55, 0.6, 0.62))
			cilindro(0.03, 0.12, Vector3(0.05, 1.08, 0), C_GRAFITO)
			caja(Vector3(0.5, 0.06, 0.5), Vector3(0.05, 0.03, 0), C_GRAFITO)
			cilindro(0.13, 0.3, Vector3(0.05, 0.21, 0), Color(0.85, 0.92, 0.95, 1.0))
			_agua = cilindro(0.12, 0.28, Vector3(0.05, 0.21, 0), Color(0.45, 0.7, 1.0))
	luz(Vector3(0.38, 0.62 if tipo != "toma_agua" else 0.25, 0.3))

func _maquina_visual() -> void:
	_maquina = Node3D.new()
	add_child(_maquina)
	match tipo:
		"camilla":
			_montar_extractor()
		"incubadora":
			caja(Vector3(0.5, 0.25, 0.4), Vector3(0, 1.08, 0), C_GRAFITO, _maquina)
			caja(Vector3(0.06, 0.4, 0.06), Vector3(0.2, 1.3, 0), C_AMARILLO, _maquina)
		"toma_agua":
			caja(Vector3(0.3, 0.35, 0.3), Vector3(-0.3, 0.18, 0.3), C_ACENTO, _maquina)
			cilindro(0.08, 0.06, Vector3(-0.3, 0.38, 0.3), C_GRAFITO, _maquina)

func actualizar(e: Fabrica.Entidad, t: float) -> void:
	if not is_inside_tree():
		return
	var est := e as Fabrica.Estacion
	if est.modo != _modo:
		_modo = est.modo
		if _modo != "mano" and _maquina == null:
			_maquina_visual()
		if _modo == "zombi" and _zombi == null:
			_zombi = Personaje.new()
			_zombi.variante = "zombi"
			_zombi.animacion = "interact-right"
			_zombi.position = Vector3(0.1, 0, 0.62)
			_zombi.rotation.y = PI
			add_child(_zombi)
	if _luz:
		var c := Color(0.3, 1.0, 0.45) if (est.trabajando or est.modo == "zombi") and est.lista_para_trabajar() \
			else (Color(1.0, 0.7, 0.1) if est.listo != "" or not est.lista_para_trabajar() else Color(0.35, 0.6, 1.0))
		_luz.emission = c
		_luz.albedo_color = c
	if _placa:
		var k := clampf(est.crecimiento / maxf(est._crece(), 0.01), 0.05, 1.0)
		_placa.scale = Vector3(k, 1, k)
	if _agua:
		var k2 := est.progreso / est.duracion() if est.listo == "" else 1.0
		_agua.scale.y = maxf(k2, 0.02)
		_agua.position.y = 0.07 + 0.14 * _agua.scale.y
	_producto_encima(est.listo)
	if tipo == "camilla":
		_pacientes(est, t)
		_extraccion(est)

func _producto_encima(o: String) -> void:
	var b := Fabrica.base(o)
	if b == _producto_nombre:
		return
	_producto_nombre = b
	if _producto:
		_producto.queue_free()
		_producto = null
	if b != "":
		_producto = load("res://assets/modelos/objetos/%s.glb" % b).instantiate()
		Materiales.ajustar(_producto)
		_producto.scale = Vector3.ONE * (1.0 if tipo == "camilla" else 2.0)
		_producto.position = Vector3(0.18, 0.3, 0.2) if tipo == "camilla" else Vector3(0.38, 0.97, 0.15)
		add_child(_producto)

## Pacientes: entran andando por la puerta en los últimos segundos de la espera y se tumban; con la
## extracción hecha se incorporan mareados, se sujetan el brazo y se van por la puerta tambaleándose.
func _pacientes(est: Fabrica.Estacion, _t: float) -> void:
	var puerta := juego.puerta_pacientes()
	var lado := to_global(Vector3(0.05, 0, 0.62))
	var dt := get_process_delta_time() * juego.velocidad
	if est.atendidos > _atendidos:
		_atendidos = est.atendidos
		if _paciente:
			_incorporado = _paciente
			_incorporado.estilo = "incorporado"
			_incorporado.poner("sit")
			_incorporado.position = Vector3(0.0, 0.25, 0.1)
			_incorporado.rotation = Vector3.ZERO
			_incorporado.sobresalto = 0.0
			_t_incorporado = 0.0
			_paciente = null
	if _incorporado:
		_t_incorporado += dt
		if _t_incorporado > 1.8:
			_incorporado.reparent(juego)
			_incorporado.estilo = "mareado"
			_incorporado.position = lado
			_incorporado.poner("walk")
			_incorporado.velocidad_anim = 0.7
			_yendo.append([_incorporado, lado, puerta, 0.0, 0.6])
			_incorporado = null
	if _paciente == null and _incorporado == null and (est.paciente or est.llamado):
		_paciente = Personaje.new()
		_paciente.variante = ["paciente_m", "paciente_f"][randi() % 2] if not "--demo_m" in OS.get_cmdline_user_args() else "paciente_m"
		_paciente.animacion = "walk"
		juego.add_child(_paciente)
		var origen := juego.origen_paciente(lado)
		_paciente.position = origen
		_yendo.append([_paciente, origen, lado, 0.0, 1.0])
	if _paciente and est.paciente and _paciente.get_parent() != self:
		for y in _yendo:
			if y[0] == _paciente:
				_yendo.erase(y)
				break
		_paciente.reparent(self)
		_paciente.estilo = "tumbado"
		_paciente.poner("idle")
		_paciente.position = POS_TUMBADO
		_paciente.rotation = Vector3(0, PI * 0.5, 0)
		_tirita_en_brazo(_paciente)
	for y in _yendo.duplicate():
		var p: Personaje = y[0]
		if not is_instance_valid(p):
			_yendo.erase(y)
			continue
		var desde: Vector3 = y[1]
		var hasta: Vector3 = y[2]
		y[3] += dt * float(y[4]) / maxf(desde.distance_to(hasta), 0.1)
		var k := clampf(y[3], 0.0, 1.0)
		var d := hasta - desde
		var lat := Vector3(-d.z, 0, d.x).normalized() * (sin(k * 22.0) * 0.12 if p.estilo == "mareado" else 0.0)
		p.position = desde.lerp(hasta, k) + lat
		p.rotation.y = atan2(d.x, d.z) + (sin(k * 22.0 + 1.0) * 0.4 if p.estilo == "mareado" else 0.0)
		if y[3] >= 1.0:
			_yendo.erase(y)
			if hasta.distance_to(puerta) < 0.1:
				p.queue_free()
			else:
				p.poner("idle")

# ------------------------------------------------------------------ camilla de extracción (V1.7)
const POS_TUMBADO := Vector3(0.2, 0.33, -0.01)   # pies del paciente tumbado (cabeza hacia −X)
const PUNTO_BRAZO := 0.55                          # dónde se pincha, de hombro (0) a mano (1)
const KIT := 1.6                                   # el kit se dibuja grande, como los productos
var _modelo: Node3D
var _kit: Node3D
var _kit_sangre: Node3D
var _kit_tapa: Node3D
var _torniquete: Node3D
var _algodon: Node3D
var _tirita: Node3D
var _ecg: ShaderMaterial
var _incorporado: Personaje
var _t_incorporado := 0.0
var _extractor: Node3D
var _hombro: Node3D
var _codo: Node3D
var _gota: GPUParticles3D
var _pinchado := false
var _t_vista := 0.0

func _montar_camilla() -> void:
	_modelo = load("res://assets/modelos/estaciones/camilla.glb").instantiate()
	Materiales.ajustar(_modelo)
	add_child(_modelo)
	_luz = mat(Color(0.3, 1.0, 0.45), 0.3, 2.0)
	var b := _modelo.find_child("baliza", true, false) as MeshInstance3D
	if b:
		b.material_override = _luz
	var pan := _modelo.find_child("pantalla", true, false) as MeshInstance3D
	if pan:
		_ecg = ShaderMaterial.new()
		_ecg.shader = preload("res://assets/shaders/ecg.gdshader")
		pan.material_override = _ecg
	var kit := load("res://assets/modelos/estaciones/kit_extraccion.glb").instantiate() as Node3D
	Materiales.ajustar(kit)
	add_child(kit)
	_kit = kit.find_child("kit", true, false)
	_kit_sangre = kit.find_child("sangre_kit", true, false)
	_kit_tapa = kit.find_child("tapa_aguja", true, false)
	_torniquete = kit.find_child("torniquete", true, false)
	_algodon = kit.find_child("algodon", true, false)
	_tirita = kit.find_child("tirita", true, false)
	for n in [_kit, _kit_tapa, _torniquete, _algodon, _tirita]:
		n.reparent(self)
	kit.queue_free()
	_gota = _particulas_gota()
	add_child(_gota)

func _montar_extractor() -> void:
	_extractor = load("res://assets/modelos/estaciones/extractor_camilla.glb").instantiate()
	Materiales.ajustar(_extractor)
	_extractor.position = Vector3(0.1, 0.22, 0.18)
	add_child(_extractor)
	_maquina = _extractor
	_hombro = _extractor.find_child("hombro", true, false)
	_codo = _extractor.find_child("codo", true, false)

func _particulas_gota() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 14
	p.lifetime = 0.5
	p.one_shot = true
	p.explosiveness = 0.9
	p.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 50.0
	pm.initial_velocity_min = 0.15
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, -2.5, 0)
	p.process_material = pm
	var q := SphereMesh.new()
	q.radius = 0.004
	q.height = 0.008
	q.radial_segments = 6
	q.rings = 3
	q.material = mat(Personaje.C_SANGRE, 0.2, 0.3)
	p.draw_pass_1 = q
	return p

## Tirita que el paciente se lleva puesta (oculta hasta que acaba la extracción).
func _tirita_en_brazo(p: Personaje) -> void:
	if p._esq == null:
		return
	var at := BoneAttachment3D.new()
	at.bone_name = "arm-right"
	p._esq.add_child(at)
	var t := _tirita.duplicate() as Node3D
	t.name = "tirita_puesta"
	at.add_child(t)
	var esc := p._esq.global_transform.basis.get_scale().x
	t.scale = Vector3.ONE * KIT / maxf(esc, 0.001)
	t.position = Vector3(-0.27 * PUNTO_BRAZO, 0.0, 0.035)
	t.rotation = Vector3(PI * 0.5, 0, 0)
	t.visible = false
	p.set_meta("tirita", t)

static func _suave(a: float, b: float, k: float) -> float:
	return smoothstep(a, b, k)

## Toda la extracción se dibuja con la fracción de trabajo k (0..1) de la camilla:
## torniquete y algodón → aguja destapada que se acerca → pinchazo (respingo y gota) → el tubo se
## llena con latido → se suelta el torniquete → se retira la aguja → algodón y tirita.
func _extraccion(est: Fabrica.Estacion) -> void:
	_t_vista += get_process_delta_time()
	var con_paciente := _paciente != null and _paciente.get_parent() == self
	var k := est.progreso / est.duracion() if con_paciente else 0.0
	var trabajando := con_paciente and k > 0.0
	# kit en reposo sobre la bandeja
	var bandeja := Vector3(0.2, 0.3, 0.19)
	var giro_kit := Basis(Vector3.UP, PI * 0.5)
	var p_kit := bandeja
	var pinchazo := Vector3.ZERO
	var eje := Vector3(0, 0, -1)
	if con_paciente:
		pinchazo = to_local(_paciente.punto_brazo(true, PUNTO_BRAZO)) + Vector3(0, 0.035, 0)
		var hombro := to_local(_paciente.punto_brazo(true, 0.0))
		eje = Vector3(hombro.x - pinchazo.x, 0, hombro.z - pinchazo.z).normalized()
	var listo_kit := pinchazo - eje * 0.075 * KIT + Vector3(0, 0.07 * KIT, 0)     # sobre el brazo, a punto
	var dentro := pinchazo - eje * 0.045 * KIT + Vector3(0, 0.012 * KIT, 0)       # aguja dentro de la vena
	var orient := Basis.looking_at(eje, Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(14.0)) if con_paciente else giro_kit
	var sangre := 0.0
	var tq := 0.0
	var alg := Vector3(9, 9, 9)
	var tirita := false
	var sobresalto := 0.0
	if trabajando:
		if k < 0.12:
			tq = _suave(0.0, 0.05, k)
			var w := _suave(0.04, 0.12, k)
			alg = pinchazo + eje * (0.02 * sin(w * 25.0)) + Vector3(0, 0.004, 0)
			p_kit = bandeja.lerp(listo_kit, _suave(0.06, 0.12, k) * 0.3)
		elif k < 0.25:
			tq = 1.0
			p_kit = bandeja.lerp(listo_kit, _suave(0.1, 0.25, k))
		elif k < 0.3:
			tq = 1.0
			p_kit = listo_kit.lerp(dentro, _suave(0.25, 0.29, k))
			sobresalto = 1.0 - _suave(0.27, 0.3, k) * 0.5
		elif k < 0.85:
			tq = 1.0 - _suave(0.58, 0.64, k)
			p_kit = dentro + Vector3(0, 0.0015 * sin(_t_vista * 7.0), 0)
			sangre = _suave(0.3, 0.84, k)
			sobresalto = maxf(0.0, 0.5 - (k - 0.3) * 4.0)
		elif k < 0.95:
			p_kit = dentro.lerp(listo_kit, _suave(0.85, 0.9, k))
			sangre = 1.0
			alg = pinchazo + Vector3(0, 0.004, 0)
			tirita = k > 0.91
		else:
			sangre = 1.0
			p_kit = listo_kit.lerp(bandeja, _suave(0.95, 1.0, k))
			tirita = true
		if k > 0.25 and not _pinchado:
			_pinchado = true
			_gota.position = pinchazo
			_gota.restart()
			_gota.emitting = true
	else:
		_pinchado = false
	if est.listo != "" or (k == 0.0 and _producto_nombre != ""):
		sangre = 0.0
	if p_kit.distance_to(bandeja) < 0.01:
		orient = giro_kit
	elif k >= 0.95:
		orient = orient.slerp(giro_kit, _suave(0.95, 1.0, k))
	_kit.transform = Transform3D(orient, p_kit).scaled_local(Vector3.ONE * KIT)
	_kit_sangre.scale = Vector3(1, maxf(sangre, 0.001), 1)
	_kit_sangre.visible = sangre > 0.01
	_kit_tapa.visible = not trabajando or k < 0.15
	_kit_tapa.transform = (Transform3D(orient, p_kit + orient * Vector3(0, 0, -0.06 * KIT)) if trabajando else Transform3D(giro_kit, bandeja + Vector3(-0.1, 0.0, 0.0))).scaled_local(Vector3.ONE * KIT)
	_torniquete.visible = tq > 0.01
	if _torniquete.visible:
		var p_tq := to_local(_paciente.punto_brazo(true, 0.25))
		_torniquete.transform = Transform3D(Basis.looking_at(eje, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), p_tq).scaled_local(Vector3.ONE * KIT * (0.6 + tq * 0.4))
	_algodon.visible = alg.x < 5.0
	if _algodon.visible:
		_algodon.position = alg
		_algodon.scale = Vector3.ONE * KIT
	_tirita.visible = tirita and con_paciente
	if _tirita.visible:
		_tirita.transform = Transform3D(Basis.looking_at(eje, Vector3.UP), pinchazo + Vector3(0, 0.002, 0)).scaled_local(Vector3.ONE * KIT)
	if con_paciente:
		_paciente.sobresalto = sobresalto
		_paciente.mirar_brazo = 1.0 if trabajando and k > 0.2 and k < 0.9 else 0.0
	if _incorporado and _incorporado.has_meta("tirita"):
		(_incorporado.get_meta("tirita") as Node3D).visible = true
	if _ecg:
		_ecg.set_shader_parameter("t", _t_vista)
		_ecg.set_shader_parameter("encendido", 1.0 if con_paciente or _incorporado else 0.0)
		_ecg.set_shader_parameter("pulso", 1.25 + sobresalto * 0.5 + sangre * 0.15)
		_ecg.set_shader_parameter("llenado", sangre)
	if _hombro:
		_ik_brazo(p_kit + Vector3(0, 0.05, 0) if trabajando else Vector3(0.18, 0.4, 0.3))

## IK de dos tramos en el plano horizontal para el brazo extractor (lleva el kit en la pinza).
func _ik_brazo(objetivo: Vector3) -> void:
	var L1 := 0.22 * _extractor.scale.x
	var L2 := 0.2 * _extractor.scale.x
	var o := to_global(objetivo)
	var h := _hombro.global_position
	var d2 := Vector2(o.x - h.x, o.z - h.z)
	var d := clampf(d2.length(), 0.05, L1 + L2 - 0.005)
	var ang := atan2(-d2.y, d2.x) - _extractor.global_rotation.y
	var a1 := acos(clampf((L1 * L1 + d * d - L2 * L2) / (2.0 * L1 * d), -1.0, 1.0))
	var a2 := acos(clampf((L1 * L1 + L2 * L2 - d * d) / (2.0 * L1 * L2), -1.0, 1.0))
	_hombro.rotation.y = ang + a1
	_codo.rotation.y = -(PI - a2)
