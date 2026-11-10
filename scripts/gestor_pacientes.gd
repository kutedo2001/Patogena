class_name GestorPacientes
extends Node3D
## Pacientes como personas que se mueven de verdad (V1.20): entran por la puerta de la pared oeste,
## van a un asiento libre de una sala de espera (o hacen cola de pie junto a la puerta) y, cuando una
## camilla o cápsula los llama, se levantan y van andando hasta ella. Nadie aparece de la nada.
## La simulación solo cuenta cuántos esperan; aquí se mueven las mismas personas de sitio en sitio.

const VEL := 1.1
var juego: Juego
var _agentes: Array = []      # {p: Personaje, estado: "entra"|"espera"|"va", sitio: Node3D|Vector3, ruta: Array}

func _puerta_fuera() -> Vector3:
	return juego.puerta_pacientes() + Vector3(-0.8, 0, 0)

func _puerta_dentro() -> Vector3:
	return juego.puerta_pacientes() + Vector3(1.0, 0, 0)

## Sitios para esperar: asientos libres de las salas, después la cola junto a la puerta.
func _sitio_libre():
	var usados := {}
	for a in _agentes:
		if a.estado != "va":
			usados[a.sitio] = true
	for v in juego.vista.get_children():
		if v is PiezaVista and v.tipo == "sala_espera":
			for s in v.asientos():
				if not usados.has(s):
					return s
	for k in 8:
		var c := _puerta_dentro() + Vector3(0.45 * k, 0, 0.9 + (k % 2) * 0.15)
		if not usados.has(c):
			return c
	return _puerta_dentro()

func _pos_sitio(s) -> Vector3:
	return (s as Node3D).global_position if s is Node3D else s

func _process(dt: float) -> void:
	if juego == null:
		return
	var esperando := 0
	for a in _agentes:
		if a.estado != "va":
			esperando += 1
	# llegan los que faltan (entran andando por la puerta)
	while esperando < juego.fab.espera_pacientes:
		var p := Personaje.new()
		p.variante = ["paciente_m", "paciente_f"][randi() % 2]
		p.animacion = "walk"
		juego.add_child(p)
		p.position = _puerta_fuera()
		var s = _sitio_libre()
		_agentes.append({"p": p, "estado": "entra", "sitio": s, "ruta": [_puerta_dentro(), _pos_sitio(s)]})
		esperando += 1
	var vdt := dt * juego.velocidad
	for a in _agentes.duplicate():
		var p: Personaje = a.p
		if not is_instance_valid(p):
			_agentes.erase(a)
			continue
		if a.ruta.is_empty():
			continue
		var meta: Vector3 = a.ruta[0]
		var d := meta - p.global_position
		d.y = 0
		var paso := VEL * vdt
		if d.length() <= paso:
			p.global_position = Vector3(meta.x, p.global_position.y, meta.z)
			a.ruta.pop_front()
			if a.ruta.is_empty():
				_llega(a)
		else:
			p.global_position += d.normalized() * paso
			p.rotation.y = atan2(d.x, d.z)

func _llega(a: Dictionary) -> void:
	var p: Personaje = a.p
	if a.get("salir", false):
		p.queue_free()
		_agentes.erase(a)
		return
	if a.estado == "entra":
		a.estado = "espera"
		if a.sitio is Node3D:
			p.reparent(a.sitio)
			p.position = Vector3.ZERO
			p.rotation = Vector3.ZERO
			p.poner("sit")
		else:
			p.rotation.y = -PI * 0.5
			p.poner("idle")
	elif a.estado == "va" and a.has("al_llegar"):
		var fn: Callable = a.al_llegar
		_agentes.erase(a)
		fn.call(p)

func _ultimo_esperando():
	for i in range(_agentes.size() - 1, -1, -1):
		if _agentes[i].estado != "va":
			return _agentes[i]
	return null

func reclamar_agente(a: Dictionary) -> void:
	var p: Personaje = a.p
	if p.get_parent() != juego:
		p.reparent(juego)
	p.rotation = Vector3.ZERO
	p.poner("walk")

## Una camilla o cápsula llama a alguien: el que esté sentado más cerca se levanta y va hasta destino;
## al llegar se llama a al_llegar(persona). Si aún no había nadie dentro (desfase), entra por la puerta.
func llamar(destino: Vector3, al_llegar: Callable) -> void:
	var mejor = null
	var dmin := INF
	for a in _agentes:
		if a.estado == "espera" or a.estado == "entra":
			var dd: float = (a.p as Personaje).global_position.distance_to(destino)
			if dd < dmin:
				dmin = dd
				mejor = a
	if mejor == null:
		var p := Personaje.new()
		p.variante = ["paciente_m", "paciente_f"][randi() % 2]
		juego.add_child(p)
		p.position = _puerta_fuera()
		mejor = {"p": p, "estado": "va", "sitio": null, "ruta": [_puerta_dentro(), destino]}
		_agentes.append(mejor)
	else:
		mejor.ruta = [destino]
	reclamar_agente(mejor)
	mejor.estado = "va"
	mejor["al_llegar"] = al_llegar

## Alguien sale por la puerta andando desde donde esté (paciente atendido, mareado).
func despedir(p: Personaje) -> void:
	if p.get_parent() != juego:
		p.reparent(juego)
	p.poner("walk")
	_agentes.append({"p": p, "estado": "va", "sitio": null, "ruta": [_puerta_dentro(), _puerta_fuera()], "salir": true})
