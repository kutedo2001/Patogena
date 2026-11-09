extends Node3D
## Escena principal. En la puerta 3 monta la sala, la cámara y unos volúmenes
## de escala provisionales (gris, con baliza) para juzgar densidad y proporción.

@onready var sala: Node3D = $Sala
@onready var camara: Node3D = $RigCamara

## Duración del ciclo animado por tipo de máquina (para que los procesos se lean; la receta real la fijará P4).
const CICLO_VISUAL := {
	PantallaMaquina.Tipo.CENTRIFUGA: 3.0, PantallaMaquina.Tipo.SECUENCIADOR: 6.0, PantallaMaquina.Tipo.BIORREACTOR: 9.0,
	PantallaMaquina.Tipo.MEZCLADORA: 7.0, PantallaMaquina.Tipo.ENVASADORA: 12.0, PantallaMaquina.Tipo.CEPA: 8.0,
}

## Laboratorio nivel 2 de la pantalla objetivo (P3.9): dos cadenas reales conectadas por cintas.
## Casillas de 1 m [n, n+1]; las máquinas de 2×2 se centran en enteros, las de 1×1 y 3×3 en n+0,5.
## Entrada siempre por −X y salida por +X (giro 0).
const MAQUINAS := [
	# [modelo, centro (x, z), giro, estado, pantalla]
	# cadena de la cepa (norte): sangre → centrífugas → plasma → biorreactores → viales → cámara de cepa
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-8.5, -3.5), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.CENTRIFUGA],
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-8.5, -5.5), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.CENTRIFUGA],
	["res://assets/modelos/maquinas/centrifuga.glb", Vector2(-8.5, -1.5), 0.0, Maquina.Estado.SIN_MATERIAL, PantallaMaquina.Tipo.CENTRIFUGA],
	["res://assets/modelos/maquinas/biorreactor.glb", Vector2(-5.0, -4.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.BIORREACTOR],
	["res://assets/modelos/maquinas/biorreactor.glb", Vector2(-5.0, -6.0), 0.0, Maquina.Estado.AVERIA, PantallaMaquina.Tipo.BIORREACTOR],
	["res://assets/modelos/maquinas/camara_cepa.glb", Vector2(1.5, -3.5), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.CEPA],
	# cadena de vacunas (sur): cultivo → secuenciador → ADN; agua + reactivo → mezcladora → suero; → envasadora → cajas
	["res://assets/modelos/maquinas/secuenciador.glb", Vector2(-4.0, 1.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.SECUENCIADOR],
	["res://assets/modelos/maquinas/mezcladora.glb", Vector2(-4.0, 4.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.MEZCLADORA],
	["res://assets/modelos/maquinas/envasadora.glb", Vector2(1.0, 1.0), 0.0, Maquina.Estado.TRABAJANDO, PantallaMaquina.Tipo.ENVASADORA],
]

## Los productos se dibujan a 2,5× su tamaño real para que se lean con la cámara del juego.
const ESCALA_OBJETOS := 2.5
const OBJETOS := []

const PRODUCTOS := ["tubo_sangre", "tubo_plasma", "placa_petri", "tubo_adn", "garrafa_agua", "frasco_reactivo", "bolsa_suero",
	"proteina", "vector", "neurotoxina", "capside", "nucleo_zombi", "vial_mutacion", "caja_vacunas"]

## Recorrido en casillas; los objetos entran en la máquina al final y salen de la anterior al principio.
const CINTAS := [
	[[Vector2i(-12, -4), Vector2i(-11, -4), Vector2i(-10, -4)], ["tubo_sangre", "tubo_sangre", "tubo_sangre"]],
	[[Vector2i(-12, -6), Vector2i(-11, -6), Vector2i(-10, -6)], ["tubo_sangre", "tubo_sangre"]],
	[[Vector2i(-12, -2), Vector2i(-11, -2), Vector2i(-10, -2)], []],                                   # vacía: centrífuga sin material
	[[Vector2i(-8, -4), Vector2i(-7, -4)], ["tubo_plasma", "tubo_plasma"]],
	[[Vector2i(-8, -6), Vector2i(-7, -6)], ["tubo_plasma"]],
	[[Vector2i(-4, -4), Vector2i(-3, -4), Vector2i(-2, -4), Vector2i(-1, -4)], ["vial_mutacion", "vial_mutacion"]],
	[[Vector2i(-4, -6), Vector2i(-3, -6), Vector2i(-3, -5)], []],                                      # biorreactor averiado
	[[Vector2i(-11, 1), Vector2i(-10, 1), Vector2i(-9, 1), Vector2i(-8, 1), Vector2i(-7, 1), Vector2i(-6, 1)], ["placa_petri", "placa_petri", "placa_petri", "placa_petri"]],
	[[Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(-2, 0), Vector2i(-1, 0)], ["tubo_adn", "tubo_adn"]],
	[[Vector2i(-11, 4), Vector2i(-10, 4), Vector2i(-9, 4), Vector2i(-8, 4), Vector2i(-7, 4), Vector2i(-6, 4)], ["garrafa_agua", "frasco_reactivo", "garrafa_agua", "frasco_reactivo"]],
	[[Vector2i(-3, 3), Vector2i(-2, 3), Vector2i(-2, 2)], ["bolsa_suero"]],
	[[Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1)], ["caja_vacunas", "caja_vacunas", "caja_vacunas"]],
]

func _montar_cintas() -> void:
	for c in CINTAS:
		var celdas: Array[Vector2i] = []
		celdas.assign(c[0])
		_linea(1, celdas, false, c[1])
	_palet_envio(Vector3(7.6, 0, 1.5))

## Palé de cajas de vacunas al final de la línea (muelle de envío provisional).
func _palet_envio(pos: Vector3) -> void:
	var palet := Node3D.new()
	palet.position = pos
	add_child(palet)
	var madera := StandardMaterial3D.new()
	madera.albedo_color = Color(0.62, 0.48, 0.3)
	madera.roughness = 0.85
	for k in 3:
		var t := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.9, 0.025, 0.16)
		t.mesh = bm
		t.material_override = madera
		t.position = Vector3(0, 0.11, -0.36 + k * 0.36)
		palet.add_child(t)
		var taco := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(0.9, 0.1, 0.1)
		taco.mesh = tb
		taco.material_override = madera
		taco.position = Vector3(0, 0.05, -0.36 + k * 0.36)
		palet.add_child(taco)
	var caja: PackedScene = load("res://assets/modelos/objetos/caja_vacunas.glb")
	for i in 3:
		for j in 3:
			for h in 2 if (i + j) % 2 == 0 else 1:
				var c: Node3D = caja.instantiate()
				Materiales.ajustar(c)
				c.scale = Vector3.ONE * ESCALA_OBJETOS
				c.position = Vector3(-0.28 + i * 0.28, 0.125 + h * 0.2, -0.28 + j * 0.28)
				c.rotation.y = randf_range(-0.08, 0.08)
				palet.add_child(c)

func _linea(nivel: int, celdas: Array[Vector2i], cerrada: bool, productos: Array) -> void:
	var l := LineaCinta.new()
	l.nivel = nivel
	l.casillas = celdas
	l.cerrada = cerrada
	l.escala_objetos = ESCALA_OBJETOS
	add_child(l)
	var n := productos.size()
	var paso := minf(1.1, l.largo() / float(n))
	for i in n:
		l.poner(load("res://assets/modelos/objetos/%s.glb" % productos[i]), i * paso)

## Personajes de muestra (P3.7/P3.7b). Cada entrada: variante, pos (x, z), giro, animación y
## opciones: ruta (dos puntos), vel, estilo, amputado, rastro, rutina, alto.
const GENTE := [
	["investigador_m", Vector2(-8.5, -2.95), 180.0, "interact-right", {"rutina": [["interact-right", 4.0], ["pick-up", 1.6], ["interact-right", 3.0], ["emote-yes", 1.6]]}],
	["investigador_f", Vector2(-4.3, 2.3), 180.0, "interact-left", {"rutina": [["interact-left", 5.0], ["holding-both", 2.5], ["interact-left", 3.0]]}],
	["investigador_m", Vector2(-1.0, -1.0), 0.0, "walk", {"ruta": [Vector2(-4.0, -1.0), Vector2(6.0, -1.0)]}],
	["investigador_f", Vector2(1.3, 2.3), 180.0, "interact-right", {"rutina": [["interact-right", 3.5], ["pick-up", 1.6], ["interact-right", 4.0]]}],
	["paciente_m", Vector2(-10.9, -2.7), 90.0, "sit", {"alto": 0.3}],
	["paciente_f", Vector2(-10.9, -1.7), 90.0, "sit", {"alto": 0.3, "rutina": [["sit", 3.0], ["emote-no", 1.4]]}],
	# corral de pruebas (bajo el monitor del mundo)
	["zombi", Vector2(5.0, -5.5), 30.0, "walk", {"ruta": [Vector2(4.0, -5.8), Vector2(7.6, -5.0)], "vel": 0.35, "estilo": "zombi"}],
	["zombi", Vector2(6.0, -4.0), 0.0, "walk", {"ruta": [Vector2(7.8, -3.8), Vector2(4.2, -4.2)], "vel": 0.3, "estilo": "zombi", "amputado": ["arm-left"], "rastro": true}],
	["zombi", Vector2(8.0, -6.4), 0.0, "idle", {"ruta": [Vector2(8.6, -6.4), Vector2(6.4, -6.6)], "vel": 0.12, "estilo": "arrastrar", "rastro": true}],
	["investigador_infectado", Vector2(9.0, -5.0), 0.0, "walk", {"ruta": [Vector2(9.2, -3.6), Vector2(8.8, -5.4)], "vel": 0.3, "estilo": "zombi", "rastro": true}],
	["paciente_infectado", Vector2(4.0, -3.6), 0.0, "walk", {"ruta": [Vector2(3.6, -3.5), Vector2(5.6, -3.4)], "vel": 0.28, "estilo": "zombi", "amputado": ["arm-right"]}],
	["zombi", Vector2(6.6, -5.4), 0.0, "walk", {"ruta": [Vector2(5.8, -6.0), Vector2(6.9, -4.7)], "vel": 0.25, "estilo": "zombi", "amputado": ["head"], "rastro": true}],
	# mordisco
	["paciente_m", Vector2(9.6, -4.4), 70.0, "die", {"bucle": false}],
	["zombi", Vector2(9.45, -4.75), -20.0, "attack-melee-right", {"estilo": "comer", "vel_anim": 0.7}],
]
var _caminantes: Array = []   # [nodo, a, b, t, sentido, vel]

func _montar_gente() -> void:
	var banco: Node3D = load("res://assets/modelos/mobiliario/banco_espera.glb").instantiate()
	banco.position = Vector3(-10.85, 0, -2.2)
	banco.rotation_degrees.y = 90
	add_child(banco)
	for g in GENTE:
		var o: Dictionary = g[4]
		var p := Personaje.new()
		p.variante = g[0]
		p.animacion = g[3]
		p.estilo = o.get("estilo", "")
		p.amputado = PackedStringArray(o.get("amputado", []))
		p.rastro_sangre = o.get("rastro", false)
		p.rutina = o.get("rutina", [])
		p.bucle = o.get("bucle", true)
		p.velocidad_anim = o.get("vel_anim", 1.0)
		p.position = Vector3(g[1].x, o.get("alto", 0.0), g[1].y)
		p.rotation_degrees.y = g[2]
		add_child(p)
		if o.has("ruta"):
			_caminantes.append([p, o.ruta[0], o.ruta[1], randf(), 1.0, o.get("vel", 0.9)])
	_corral(Vector2i(3, -7), Vector2i(10, -2), 5)
	# gore estilizado: charcos y salpicaduras en el corral y bajo el mordisco
	for d in [[Vector3(5.4, 0, -5.1), 0.8, "sangre_charco"], [Vector3(4.2, 0, -5.9), 0.45, "sangre_salpicadura"],
			[Vector3(7.4, 0, -4.4), 0.4, "sangre_salpicadura"], [Vector3(9.4, 0, -4.5), 1.0, "sangre_charco"],
			[Vector3(10.1, 0, -5.0), 0.5, "sangre_salpicadura"], [Vector3(6.6, 0, -5.4), 0.5, "sangre_salpicadura"]]:
		var dc := Mancha.crear(load("res://assets/texturas/%s.png" % d[2]), d[1])
		dc.position = d[0]
		dc.rotation.y = randf() * TAU
		add_child(dc)

## Valla del corral de pruebas entre dos esquinas (casillas), con hueco de puerta en el lado sur.
func _corral(a: Vector2i, b: Vector2i, puerta_x: int) -> void:
	var tramo: PackedScene = load("res://assets/modelos/mobiliario/valla.glb")
	var aviso: PackedScene = load("res://assets/modelos/mobiliario/valla_aviso.glb")
	var poste: PackedScene = load("res://assets/modelos/mobiliario/valla_poste.glb")
	var k := 0
	for x in range(a.x, b.x):
		for z in [a.y, b.y]:
			if z == b.y and x == puerta_x:
				continue
			var t: Node3D = (aviso if k % 3 == 1 else tramo).instantiate()
			t.position = Vector3(x + 0.5, 0, z)
			if z == b.y:
				t.rotation_degrees.y = 180
			add_child(t)
			k += 1
	for z in range(a.y, b.y):
		for x in [a.x, b.x]:
			var t: Node3D = (aviso if k % 3 == 1 else tramo).instantiate()
			t.position = Vector3(x, 0, z + 0.5)
			t.rotation_degrees.y = 90 if x == a.x else -90
			add_child(t)
			k += 1
	for c in [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(a.x, b.y), Vector2(b.x, b.y), Vector2(puerta_x + 1, b.y)]:
		var pp: Node3D = poste.instantiate()
		pp.position = Vector3(c.x, 0, c.y)
		add_child(pp)

## Marcas de interfaz en el mundo (sin texto): anillo de la máquina seleccionada en el HUD y
## fantasma verde de la construcción elegida en la barra, con su huella en el suelo.
var _anillo: MeshInstance3D
var _fantasma_mat: StandardMaterial3D

func _seleccion_y_fantasma() -> void:
	_anillo = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.98
	tm.outer_radius = 1.06
	tm.rings = 48
	_anillo.mesh = tm
	_anillo.scale = Vector3(1, 0.05, 1)
	var am := StandardMaterial3D.new()
	am.albedo_color = Color(0.25, 0.71, 0.66)
	am.emission_enabled = true
	am.emission = Color(0.25, 0.71, 0.66)
	am.emission_energy_multiplier = 1.5
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anillo.material_override = am
	_anillo.position = Vector3(-8.5, 0.02, -3.5)
	_anillo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_anillo)
	_anillo.visible = not ("--vista=general" in OS.get_cmdline_user_args())
	# fantasma
	var f: Node3D = load("res://assets/modelos/maquinas/centrifuga.glb").instantiate()
	_fantasma_mat = StandardMaterial3D.new()
	_fantasma_mat.albedo_color = Color(0.3, 0.85, 0.5, 0.55)
	_fantasma_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS   # solo la cara delantera: se lee la forma
	_fantasma_mat.emission_enabled = true
	_fantasma_mat.emission = Color(0.2, 0.8, 0.4)
	_fantasma_mat.emission_energy_multiplier = 0.12
	_fantasma_mat.roughness = 0.6
	_fantasma_mat.cull_mode = BaseMaterial3D.CULL_BACK
	for mi in f.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = _fantasma_mat
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.position = Vector3(-6.0, 0, -1.0)
	add_child(f)
	# huella 2×2 en el suelo con borde
	for i in 2:
		for j in 2:
			var c := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(0.94, 0.94)
			c.mesh = pm
			var cm := StandardMaterial3D.new()
			cm.albedo_color = Color(0.3, 0.9, 0.5, 0.22)
			cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			c.material_override = cm
			c.position = Vector3(-6.5 + i, 0.015, -1.5 + j)
			add_child(c)

func _process(dt: float) -> void:
	if not escaparate:
		return
	if _anillo:
		var k := 1.0 + 0.04 * sin(Time.get_ticks_msec() * 0.004)
		_anillo.scale = Vector3(k, 0.05, k)
		_fantasma_mat.albedo_color.a = 0.55 + 0.08 * sin(Time.get_ticks_msec() * 0.005)
	for c in _caminantes:
		var p: Node3D = c[0]
		var a: Vector2 = c[1]
		var b: Vector2 = c[2]
		var largo := a.distance_to(b)
		var v := 0.35 if (p as Personaje).variante == "zombi" else 0.9
		c[3] += c[4] * v * dt / largo
		if c[3] > 1.0 or c[3] < 0.0:
			c[4] = -c[4]
			c[3] = clampf(c[3], 0.0, 1.0)
		var pos := a.lerp(b, c[3])
		p.position = Vector3(pos.x, 0, pos.y)
		var dir: Vector2 = (b - a) * float(c[4])
		p.rotation.y = atan2(dir.x, dir.y)

## «-- --escaparate»: la pantalla objetivo de la puerta 3 (nivel 2 de muestra, datos falsos).
## Sin él: la partida (puerta 4), con el laboratorio nivel 1 vacío para construir.
var escaparate := "--escaparate" in OS.get_cmdline_user_args()

func _enter_tree() -> void:
	if not escaparate:
		$Sala.ancho = Juego.ANCHO
		$Sala.fondo = Juego.FONDO

func _ready() -> void:
	_igualar_renderizadores()
	sala.camara = camara
	if not escaparate:
		_partida()
		return
	add_child(HUDEscaparate.new())
	_seleccion_y_fantasma()
	var monitor := MonitorMundo.new()
	monitor.position = Vector3(4.0, 0, -8.0)
	add_child(monitor)
	for e in MAQUINAS:
		var m := Maquina.new()
		m.modelo = load(e[0])
		m.position = Vector3(e[1].x, 0, e[1].y)
		m.rotation_degrees.y = e[2]
		m.estado = e[3]
		m.tipo_pantalla = e[4]
		m.ciclo = CICLO_VISUAL.get(e[4], 3.0)
		add_child(m)
	_montar_cintas()
	_montar_gente()
	for o in OBJETOS:
		var n: Node3D = load(o[0]).instantiate()
		Materiales.ajustar(n)
		n.position = o[1]
		n.rotation_degrees.y = o[2]
		n.scale = Vector3.ONE * ESCALA_OBJETOS
		add_child(n)

func _partida() -> void:
	var juego := Juego.new()
	juego.camara = camara
	add_child(juego)
	var hud := HUD.new()
	hud.juego = juego
	add_child(hud)
	if "--prueba_raton" in OS.get_cmdline_user_args():
		var pr := PruebaRaton.new()
		pr.juego = juego
		pr.hud = hud
		add_child(pr)
	var monitor := MonitorMundo.new()
	monitor.juego = juego
	monitor.position = Vector3(2.0, 0, -Juego.FONDO / 2.0)
	add_child(monitor)
	var tieso := false
	for a in OS.get_cmdline_user_args():
		tieso = tieso or a.begins_with("--centro=") or a.begins_with("--dist=")
	if not tieso:
		camara.seguir = juego.cientifico
		camara.position = Vector3(0, 0, 0.5)
		camara.distancia = 21.0
		camara._dist_obj = 21.0

## Compatibility (web/móvil) en Godot 4.3 no pasa a lineal el color de fondo ni
## el ambiente y no tiene SSAO: se compensa para que se vea como en PC (B1).
const AJ_EXPOSICION := 0.88

func _igualar_renderizadores() -> void:
	if RenderingServer.get_rendering_device() != null:  # con RenderingDevice = Forward+ o Mobile
		return
	var env: Environment = $Entorno.environment
	# Godot 4.7: Compatibility sale un 14 % más claro; se iguala el brillo medio con Forward+ (B1)
	env.adjustment_enabled = true
	env.adjustment_brightness = AJ_EXPOSICION
