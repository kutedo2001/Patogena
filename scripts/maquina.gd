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
@export var tipo_pantalla: PantallaMaquina.Tipo = PantallaMaquina.Tipo.CENTRIFUGA
@export var ciclo := 3.0              # segundos por pieza (lo fijará la receta)
@export var color_producto := Color(0.3, 0.9, 0.2)
@export var estado: Estado = Estado.TRABAJANDO:
	set(v):
		estado = v
		_t_estado = 0.0

var _rotor: Node3D
var _agitador: Node3D
var _cabezal: Node3D
var _liquido: Node3D
var _mat_baliza: StandardMaterial3D
var _torre := {}            # Estado -> material de su lente (torre de luces de 3 colores)
var _tapa: Node3D
var _puente: Node3D
var _carro: Node3D
var _pipeta: Node3D
var _pipeta_y0 := 0.0
var _estaciones: Array[Vector3] = []
var _burbujas: Array[Node3D] = []
var _burbuja_y0: Array[float] = []
var _giratorios: Array[Node3D] = []
# dosificadora: viales que se llenan uno a uno bajo una boquilla
var _llenados: Array[Node3D] = []
var _taponados: Array = []          # por vial, lista de piezas del tapón
var _vial_x: Array[float] = []      # x de cada vial dentro de la bandeja
var _bandeja: Node3D
var _bandeja_x0 := 0.0
var _boquilla: Node3D
var _boquilla_y0 := 0.0
var _gota: Node3D
var _gota_y0 := 0.0
# procesos por fases (mezcladora y siguientes): nodos con prefijo fijo
var _vaciar: Array[Node3D] = []
var _chorros: Array[Node3D] = []
var _llenar: Array[Node3D] = []
var _sellar: Array[Node3D] = []
var _sellar_y0: Array[float] = []
var _mat_resistencia: Array[StandardMaterial3D] = []
var _agujas: Array[Node3D] = []
var _nivel_vaso: Node3D
var _tapa_ang := 0.0
var _mat_pantalla: StandardMaterial3D
var _ui: PantallaMaquina
var _progreso := 0.0
var _cabezal_x0 := 0.0
var _liq_y0 := 0.0
var _vel_giro := 0.0      # 0..1, arranca y frena con inercia
var _t := 0.0
var _t_estado := 0.0

func _ready() -> void:
	if modelo:
		var inst := modelo.instantiate()
		Materiales.ajustar(inst)
		add_child(inst)
	_rotor = _buscar("rotor")
	_agitador = _buscar("agitador")
	_cabezal = _buscar("cabezal")
	_liquido = _buscar("liquido")
	if _cabezal:
		_cabezal_x0 = _cabezal.position.x
	if _liquido:
		_liq_y0 = _liquido.scale.y
	_mat_baliza = _material_propio(_buscar("baliza"))
	for par in [[Estado.TRABAJANDO, "baliza_v"], [Estado.SIN_MATERIAL, "baliza_a"], [Estado.AVERIA, "baliza_r"]]:
		var m := _material_propio(_buscar(par[1]))
		if m:
			m.emission_enabled = true
			_torre[par[0]] = m
	_tapa = _buscar("tapa")
	_puente = _buscar("puente")
	_carro = _buscar("carro")
	_pipeta = _buscar("pipeta")
	if _pipeta:
		_pipeta_y0 = _pipeta.position.y
	for n in find_children("burbuja*", "Node3D", true, false):
		_burbujas.append(n)
		_burbuja_y0.append((n as Node3D).position.y)
	for n in find_children("gira_*", "Node3D", true, false):
		_giratorios.append(n)
	for n in find_children("vaciar_*", "Node3D", true, false):
		_vaciar.append(n)
	for n in find_children("chorro_*", "Node3D", true, false):
		_chorros.append(n)
	for n in find_children("llenar_*", "Node3D", true, false):
		_llenar.append(n)
	for n in find_children("aguja_*", "Node3D", true, false):
		_agujas.append(n)
	for n in find_children("sellar_*", "Node3D", true, false):
		_sellar.append(n)
		_sellar_y0.append((n as Node3D).position.y)
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).get_active_material(0)
			if m and m.resource_name.begins_with("resistencia"):
				var c: StandardMaterial3D = m.duplicate()
				c.emission_enabled = true
				(mi as MeshInstance3D).material_override = c
				_mat_resistencia.append(c)
	_nivel_vaso = _buscar("nivel_vaso")
	_bandeja = _buscar("bandeja")
	_boquilla = _buscar("boquilla")
	_gota = _buscar("gota")
	if _bandeja and _boquilla:
		_bandeja_x0 = _bandeja.position.x
		_boquilla_y0 = _boquilla.position.y
		if _gota:
			_gota_y0 = _gota.position.y
		for i in 8:
			var l := _buscar("llenado%d" % i)
			if l == null:
				break
			_llenados.append(l)
			_vial_x.append((l.get_parent() as Node3D).position.x)
			_taponados.append(find_children("taponado%d_*" % i, "Node3D", true, false))
	for i in 8:
		var e := _buscar("estacion_%d" % i)
		if e == null:
			break
		_estaciones.append(e.position)
	_montar_pantalla(_buscar("pantalla") as MeshInstance3D)
	_t = randf() * 10.0

## Pantalla viva: un SubViewport con PantallaMaquina cuya textura se pinta en la malla.
func _montar_pantalla(mi: MeshInstance3D) -> void:
	if mi == null:
		return
	var tam := mi.get_aabb().size
	var lados := [tam.x, tam.y, tam.z]
	lados.sort()
	var aspecto: float = lados[2] / maxf(lados[1], 0.001)
	var vp := SubViewport.new()
	vp.size = Vector2i(384, int(384.0 / aspecto))
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	_ui = PantallaMaquina.new()
	_ui.tipo = tipo_pantalla
	_ui.color_producto = color_producto
	_ui.size = Vector2(vp.size)
	vp.add_child(_ui)
	add_child(vp)
	var m := StandardMaterial3D.new()
	m.albedo_texture = vp.get_texture()
	m.emission_enabled = true
	m.emission_texture = vp.get_texture()
	m.emission_energy_multiplier = 1.3
	m.roughness = 0.25
	m.metallic_specular = 0.6
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mi.material_override = m
	_mat_pantalla = null

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
	if trabaja:
		_progreso = fmod(_progreso + dt / ciclo, 1.0)
	if _ui:
		_ui.estado = estado
		_ui.progreso = _progreso
		_ui.velocidad = _vel_giro
	for g in _giratorios:
		g.rotate_object_local(Vector3.UP, _vel_giro * TAU * 0.7 * dt)
	for i in _burbujas.size():
		var b := _burbujas[i]
		b.position.y += (0.25 + 0.1 * float(i % 3)) * dt * maxf(_vel_giro, 0.0)
		b.position.x += sin(_t * 3.0 + i) * 0.02 * dt
		if b.position.y > _burbuja_y0[i] + 0.55:
			b.position.y = _burbuja_y0[i] - 0.15
		b.visible = _vel_giro > 0.05
	if _puente and _carro and _estaciones.size() >= 2:
		_mover_portico(dt, trabaja)
	if not _llenados.is_empty():
		_dosificar(dt, trabaja)
	_procesos_por_fases(trabaja)
	if _tapa:
		# la tapa se abre cuando la máquina espera material (se ve el rotor vacío esperando)
		var objetivo := deg_to_rad(68.0) if estado == Estado.SIN_MATERIAL else 0.0
		_tapa_ang = lerpf(_tapa_ang, objetivo, 1.0 - exp(-4.0 * dt))
		_tapa.rotation.x = -_tapa_ang
	if not _torre.is_empty():
		for e in _torre:
			var m: StandardMaterial3D = _torre[e]
			var on: bool = e == estado
			var brillo := 0.0
			if on:
				brillo = 3.0
				if estado == Estado.SIN_MATERIAL:
					brillo = 1.0 + 2.5 * (0.5 + 0.5 * sin(_t_estado * 4.0))
				elif estado == Estado.AVERIA:
					brillo = 4.0 if fmod(_t_estado, 0.5) < 0.25 else 0.3
			m.emission_energy_multiplier = brillo
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

## Pórtico cartesiano: recorre las estaciones (coger, dispensar, dejar) con bajadas
## de la pipeta, sincronizado con el progreso de la pieza.
func _mover_portico(dt: float, trabaja: bool) -> void:
	var n := _estaciones.size()
	var destino: Vector3
	var bajada := 0.0
	if trabaja:
		var tramo := _progreso * n            # n tramos: ir a la estación i y bajar
		var i := int(tramo) % n
		var u := tramo - floorf(tramo)
		var desde: Vector3 = _estaciones[(i - 1 + n) % n]
		var hasta: Vector3 = _estaciones[i]
		var mov := smoothstep(0.0, 0.6, u)
		destino = desde.lerp(hasta, mov)
		if u > 0.62:
			bajada = sin((u - 0.62) / 0.38 * PI)
	else:
		destino = _estaciones[0].lerp(_estaciones[n - 1], 0.5)
	var k := 1.0 - exp(-14.0 * dt)
	_puente.position.z = lerpf(_puente.position.z, destino.z, k)
	_carro.position.x = lerpf(_carro.position.x, destino.x, k)
	if _pipeta:
		_pipeta.position.y = lerpf(_pipeta.position.y, _pipeta_y0 - 0.12 * bajada, 1.0 - exp(-20.0 * dt))

## Dosificadora: la bandeja lleva cada vial bajo la boquilla, la boquilla baja,
## cae la gota, el nivel sube; al llenarse se pone el tapón. Al terminar la tanda
## los viales salen (se vacían) y empieza otra.
func _dosificar(dt: float, trabaja: bool) -> void:
	var n := _llenados.size()
	var t := _progreso * n
	var actual := mini(int(t), n - 1)
	var u := t - floorf(t)
	var k := 1.0 - exp(-10.0 * dt)
	# bandeja: el vial actual bajo la boquilla (la boquilla está en x = posición inicial de la bandeja)
	var objetivo_x := _bandeja_x0 - _vial_x[actual]
	_bandeja.position.x = lerpf(_bandeja.position.x, objetivo_x, k)
	var llenando := trabaja and u > 0.2 and u < 0.85
	var baja := 1.0 if (trabaja and u > 0.12 and u < 0.92) else 0.0
	_boquilla.position.y = lerpf(_boquilla.position.y, _boquilla_y0 - 0.055 * baja, 1.0 - exp(-14.0 * dt))
	for i in n:
		var nivel := 0.0
		if i < actual:
			nivel = 1.0
		elif i == actual:
			nivel = clampf((u - 0.2) / 0.65, 0.0, 1.0)
		var l := _llenados[i]
		l.scale.y = maxf(nivel, 0.001)
		l.visible = nivel > 0.002
		for p in _taponados[i]:
			(p as Node3D).visible = nivel >= 0.999 or (i == actual and u > 0.9)
	if _gota:
		_gota.visible = llenando
		if llenando:
			_gota.position.y = _gota_y0 - fmod(_t * 1.6, 0.06)

## Procesos por fases dentro de cada pieza (mezcladora…):
## 0–0,35 verter (chorros, depósitos que se vacían, el vaso sube) · 0,35–0,55 mezclar ·
## 0,55–0,85 llenar (bolsas que suben, el vaso baja) · 0,85–0,95 sellar (barra que baja al rojo).
func _procesos_por_fases(trabaja: bool) -> void:
	var p := _progreso
	for v in _vaciar:
		v.scale.y = lerpf(1.0, 0.35, smoothstep(0.0, 0.35, p))
	for c in _chorros:
		c.visible = trabaja and p > 0.03 and p < 0.33
	if _nivel_vaso:
		_nivel_vaso.scale.y = 0.45 + 0.55 * smoothstep(0.0, 0.35, p) - 0.55 * smoothstep(0.55, 0.85, p)
	for l in _llenar:
		var nv := smoothstep(0.55, 0.85, p) if p < 0.97 else 0.0
		l.scale.y = maxf(nv, 0.001)
		l.visible = nv > 0.002
	var golpe := 0.0
	if p > 0.85 and p < 0.95:
		golpe = sin((p - 0.85) / 0.1 * PI)
	for i in _sellar.size():
		_sellar[i].position.y = _sellar_y0[i] - 0.06 * golpe
	for m in _mat_resistencia:
		m.emission_energy_multiplier = 5.0 * golpe
	for a in _agujas:
		a.rotation.y = deg_to_rad(-40.0 + 70.0 * _vel_giro + sin(_t * 7.0) * 4.0 * _vel_giro)
