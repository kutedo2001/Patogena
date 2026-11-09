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
			caja(Vector3(0.92, 0.06, 0.52), Vector3(0, 0.34, 0), C_CHASIS)
			caja(Vector3(0.88, 0.05, 0.48), Vector3(0, 0.39, 0), Color(0.55, 0.75, 0.8))
			caja(Vector3(0.22, 0.06, 0.4), Vector3(-0.32, 0.44, 0), Color(0.92, 0.94, 0.95))   # almohada
			for x in [-0.4, 0.4]:
				for z in [-0.2, 0.2]:
					cilindro(0.02, 0.32, Vector3(x, 0.16, z), C_GRAFITO)
			cilindro(0.015, 1.0, Vector3(-0.42, 0.5, -0.32), C_GRAFITO)                       # gotero
			caja(Vector3(0.1, 0.16, 0.04), Vector3(-0.42, 1.0, -0.32), Color(0.75, 0.1, 0.12))
			caja(Vector3(0.16, 0.1, 0.16), Vector3(0.42, 0.06, 0.0), C_ACENTO)                # boca de salida
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
			caja(Vector3(0.2, 0.7, 0.2), Vector3(0.1, 0.35, 0.38), C_CHASIS, _maquina)
			caja(Vector3(0.5, 0.06, 0.06), Vector3(0.0, 0.7, 0.22), C_AMARILLO, _maquina)
			cilindro(0.012, 0.15, Vector3(-0.22, 0.6, 0.1), Color(0.8, 0.85, 0.9), _maquina)
		"incubadora":
			caja(Vector3(0.5, 0.25, 0.4), Vector3(0, 1.08, 0), C_GRAFITO, _maquina)
			caja(Vector3(0.06, 0.4, 0.06), Vector3(0.2, 1.3, 0), C_AMARILLO, _maquina)
		"toma_agua":
			caja(Vector3(0.3, 0.35, 0.3), Vector3(-0.3, 0.18, 0.3), C_ACENTO, _maquina)
			cilindro(0.08, 0.06, Vector3(-0.3, 0.38, 0.3), C_GRAFITO, _maquina)

func actualizar(e: Fabrica.Entidad, t: float) -> void:
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
		_producto.scale = Vector3.ONE * 2.0
		_producto.position = Vector3(0.38, 0.42 if tipo == "camilla" else 0.97, 0.15)
		add_child(_producto)

## Pacientes: entran andando por la puerta en los últimos segundos de la espera, se tumban y,
## al acabar la extracción, se levantan y se van por la puerta.
func _pacientes(est: Fabrica.Estacion, _t: float) -> void:
	var puerta := Vector3(juego.PUERTA.x, 0, juego.PUERTA.y)
	var cama := global_position
	if est.atendidos > _atendidos:
		_atendidos = est.atendidos
		if _paciente:
			_paciente.reparent(juego)
			_paciente.estilo = ""
			_paciente.position = cama + Vector3(0, 0, 0.5)
			_paciente.poner("walk")
			_yendo.append([_paciente, _paciente.position, puerta, 0.0])
			_paciente = null
	if _paciente == null and (est.paciente or est.espera < 3.0):
		_paciente = Personaje.new()
		_paciente.variante = ["paciente_m", "paciente_f"][randi() % 2]
		_paciente.animacion = "walk"
		juego.add_child(_paciente)
		_paciente.position = puerta
		_yendo.append([_paciente, puerta, cama + Vector3(0, 0, 0.5), 0.0])
	if _paciente and est.paciente and _paciente.get_parent() != self:
		# llegado: tumbado (sentado de lado) en la camilla
		for y in _yendo:
			if y[0] == _paciente:
				_yendo.erase(y)
				break
		_paciente.reparent(self)
		_paciente.position = Vector3(0.0, 0.38, 0.02)
		_paciente.rotation = Vector3(0, PI * 0.5, 0)
		_paciente.poner("sit")
	var dt := get_process_delta_time() * juego.velocidad
	for y in _yendo.duplicate():
		var p: Personaje = y[0]
		if not is_instance_valid(p):
			_yendo.erase(y)
			continue
		var desde: Vector3 = y[1]
		var hasta: Vector3 = y[2]
		y[3] += dt * 1.0 / maxf(desde.distance_to(hasta), 0.1)
		p.position = desde.lerp(hasta, clampf(y[3], 0.0, 1.0))
		var d := hasta - desde
		p.rotation.y = atan2(d.x, d.z)
		if y[3] >= 1.0:
			_yendo.erase(y)
			if hasta.distance_to(puerta) < 0.1:
				p.queue_free()
			else:
				p.poner("idle")
