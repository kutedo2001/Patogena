class_name Juego
extends Node3D
## Partida (puerta 4, nuevo inicio tras la prueba de Edu): el jugador es un científico que se
## mueve con WASD o clic y al principio lo hace todo a mano; construye estaciones de extracción
## (camilla, incubadora, toma de agua) que mejora con máquinas y luego pone a cargo de zombis.
## Une la simulación (Fabrica), su dibujo (VistaFabrica), la construcción, la venta, las
## mutaciones, los hitos y el tutorial. El HUD solo lee de aquí y llama a sus funciones públicas.

signal aviso(clave: String)
signal anuncio(titulo: String, texto: String)

## Nave de 48 × 32 casillas dividida en parcelas de 8 × 8 (6 × 4). Se empieza con las 4 del
## centro (16 × 16); el resto se compran con dinero, más caras cuanto más lejos.
const ANCHO := 48
const FONDO := 32
const PARCELA := 8
const PARCELAS := Vector2i(6, 4)
const SALA := Rect2i(-24, -16, 48, 32)        # se puede andar
const INICIALES := [Vector2i(2, 1), Vector2i(3, 1), Vector2i(2, 2), Vector2i(3, 2)]
const DINERO_INICIAL := 1000.0
const SEG_POR_DIA := 60.0
const VEL_CIENTIFICO := 3.0
const MOCHILA_CASILLAS := 12
const PILA_MAX := 20
const PUERTA := Vector2(-24.6, 0.5)           # puerta de pacientes (pared oeste)
const ESPERA_ZOMBIS := Vector2(-7.4, 6.6)     # donde esperan los convertidos

## [id, icono, clave de nombre, coste, kW, clase, extra]
const CATALOGO := {
	"HUD_CAT_EXTRACCION": [
		["camilla", "camilla", "EST_CAMILLA", 100, 0.0, "estacion", "camilla"],
		["incubadora", "incubadora", "EST_INCUBADORA", 150, 1.0, "estacion", "incubadora"],
		["toma_agua", "toma_agua", "EST_TOMA_AGUA", 80, 0.5, "estacion", "toma_agua"],
		["sala_espera", "sala_espera", "CONS_SALA_ESPERA", 120, 0.0, "sala_espera", ""],
		["capsula", "capsula", "CONS_CAPSULA", 900, 2.0, "capsula", "capsula"],
		["granja", "granja", "CONS_GRANJA", 4000, 6.0, "capsula", "granja"],
	],
	"HUD_CAT_PROCESADO": [
		["centrifuga", "centrifuga", "MAQ_CENTRIFUGA", 300, 4.5, "maquina", "centrifuga"],
		["secuenciador", "secuenciador", "MAQ_SECUENCIADOR", 500, 6.0, "maquina", "secuenciador"],
		["mezcladora", "mezcladora", "MAQ_MEZCLADORA", 400, 3.0, "maquina", "mezcladora"],
		["centrifuga_ind", "centrifuga_ind", "MAQ_CENTRIFUGA_IND", 1800, 12.0, "maquina", "centrifuga_ind"],
		["sintetizador", "sintetizador", "MAQ_SINTETIZADOR", 900, 7.0, "maquina", "sintetizador"],
		["destilador", "destilador", "MAQ_DESTILADOR", 1100, 6.0, "maquina", "destilador"],
	],
	"HUD_CAT_PRODUCTO": [
		["biorreactor", "biorreactor", "MAQ_BIORREACTOR", 600, 9.0, "maquina", "biorreactor"],
		["envasadora", "envasadora", "MAQ_ENVASADORA", 600, 5.0, "maquina", "envasadora"],
		["impresora", "impresora", "MAQ_IMPRESORA", 2500, 10.0, "maquina", "impresora"],
		["fusionador", "fusionador", "MAQ_FUSIONADOR", 6000, 20.0, "maquina", "fusionador"],
	],
	"HUD_CAT_LOGISTICA": [
		["cinta", "cinta_recta_mk1", "MAQ_CINTA_MK1", 5, 0.1, "cinta", ""],
		["brazo", "brazo", "CONS_BRAZO", 50, 0.5, "brazo", ""],
		["divisor", "divisor", "CONS_DIVISOR", 40, 0.2, "divisor", ""],
		["almacen", "almacen", "CONS_ALMACEN", 80, 0.0, "almacen", ""],
		["tuberia", "tuberia", "CONS_TUBERIA", 12, 0.0, "tuberia", ""],
		["deposito", "deposito", "CONS_DEPOSITO", 200, 0.0, "deposito", ""],
	],
	"HUD_CAT_ENERGIA": [
		["generador", "generador", "CONS_GENERADOR", 400, 0.0, "generador", "generador"],
		["biogas", "biogas", "CONS_BIOGAS", 1500, 0.0, "generador", "biogas"],
	],
}
## Campañas de donantes: [clave, coste, multiplicador de llegada, segundos (0 = permanente)]
const CAMPANAS := [["CAMP_BOCADILLO", 60, 2.0, 60.0], ["CAMP_ANALISIS", 250, 3.0, 120.0], ["CAMP_HOSPITAL", 1500, 1.5, 0.0]]
const MEJORA := {"camilla": ["MEJ_EXTRACTOR", 250], "incubadora": ["MEJ_RECOLECTOR", 250], "toma_agua": ["MEJ_BOMBA", 150]}
## [objeto contado, cantidad, clave, premio de Dirección]
## Premio de LISA (inversores) al completar cada mejora de la cepa, según su nivel.
const PREMIO_MEJORA := [0, 400, 1200, 3000, 8000]

var fab: Fabrica
var vista: VistaFabrica
var camara: Node3D
var categoria := "HUD_CAT_EXTRACCION"
var herramienta: Array = []
var quitando := false
var giro := 0
var seleccion: Fabrica.Entidad
var propagacion := 0.0
var cura := 0.0
var liberado := false
var velocidad := 1.0
var ingresos_min := 0.0
var zombis_libres := 0
var hitos_pagados: Array[bool] = [false, false, false]
# científico
var cientifico: Personaje
var pos := Vector2(-2.5, 3.5)
## Mochila al estilo Factorio: casillas con pilas {o, n}; «mano_i» es la pila que lleva en la
## mano (se ve en el científico). mano_obj y mano_n son atajos de lectura de esa pila.
var mochila: Array = []
var mano_i := -1
var mano_obj: String:
	get: return mochila[mano_i].o if mano_i >= 0 and not mochila[mano_i].is_empty() else ""
var mano_n: int:
	get: return mochila[mano_i].n if mano_i >= 0 and not mochila[mano_i].is_empty() else 0
var _ruta: Array = []                 # casillas por las que ir
var _objetivo: Fabrica.Entidad        # con qué interactuar al llegar
var _objetivo_terminal := false
var _trabajando: Fabrica.Estacion
var _andado := 0.0
# construcción
var _cel := Vector2i.ZERO
var _arrastre := false
var _inicio := Vector2i.ZERO
var _fantasma: Node3D
var _fantasma_cintas: Array[Node3D] = []
var _mat_ok: StandardMaterial3D
var _mat_mal: StandardMaterial3D
var _huella: Array[MeshInstance3D] = []
var _anillo: MeshInstance3D
var _flechas: Array[MeshInstance3D] = []
var _mat_entra: StandardMaterial3D
var _mat_sale: StandardMaterial3D
# resto
var _pedidos: Array = []
var _muelle_carga: Fabrica.Almacen
var _terminal := Vector2i(-6, 7)
var compradas := {}                  # parcela → true
var mundo := Mundo.new()
var muelle: Fabrica.MuelleEnvio
var desbloqueadas := {}              # id del catálogo → true
var _vendidas_previas := 0
var _parcelas_vis := {}              # parcela → nodo con la marca de «se vende»
var _cepa: Fabrica.SalaCepas
var _ventas_hist: Array = []
var _ultimo_ingreso := 0.0
var _desechados := 0
var _n_mut := 0
var _t_zombi := 0.0
var _zombis_espera: Array[Personaje] = []
var _carga: Node3D                    # lo que lleva en las manos (dibujo)
var _carga_nombre := ""
var tutorial: Tutorial
var parcela_sel := Vector2i(-1, -1)  # parcela sin comprar elegida (el HUD enseña su precio)

func _ready() -> void:
	fab = Fabrica.new()
	fab.dinero = DINERO_INICIAL
	for i in MOCHILA_CASILLAS:
		mochila.append({})
	vista = VistaFabrica.new()
	vista.fab = fab
	vista.juego = self
	add_child(vista)
	_montar_nivel_1()
	_mat_ok = _mat_fantasma(Color(0.3, 0.85, 0.5))
	_mat_mal = _mat_fantasma(Color(0.95, 0.3, 0.25))
	_mat_entra = Provisional.mat(Color(0.3, 0.95, 0.45), 0.5, 1.2)
	_mat_sale = Provisional.mat(Color(1.0, 0.6, 0.15), 0.5, 1.2)
	for m in [_mat_entra, _mat_sale]:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anillo = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.95
	tm.outer_radius = 1.03
	tm.rings = 48
	_anillo.mesh = tm
	var am := Provisional.mat(Color(0.25, 0.71, 0.66), 0.5, 1.5)
	am.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_anillo.material_override = am
	_anillo.visible = false
	add_child(_anillo)
	cientifico = Personaje.new()
	cientifico.variante = "investigador_m"
	cientifico.animacion = "idle"
	add_child(cientifico)
	cientifico.position = Vector3(pos.x, 0, pos.y)
	var args := OS.get_cmdline_user_args()
	inicio_pendiente = Guardado.hay_partida() and not ("--sin_tutorial" in args or "--prueba_raton" in args or "--nueva" in args)
	tutorial = Tutorial.new()
	tutorial.juego = self
	add_child(tutorial)
	if "--demo_piezas" in OS.get_cmdline_user_args():
		_demo_piezas()
	if "--demo_camilla" in OS.get_cmdline_user_args():
		_demo = fab.poner_estacion("camilla", Vector2i(-2, 1), 0)
		pos = Vector2(-1.5, 2.5)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--demo_k="):
				_demo_k = float(a.trim_prefix("--demo_k="))
				_demo.paciente = true

func _mat_fantasma(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c, 0.5)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.15
	return m

# ------------------------------------------------------------------ nivel 1
func _montar_nivel_1() -> void:
	for p in INICIALES:
		compradas[p] = true
	for id in Fabrica.datos.inicio_desbloqueado:
		desbloqueadas[id] = true
	_cepa = fab.poner_sala_cepas(Vector2i(4, -7))
	muelle = fab.poner_muelle_envio(Vector2i(5, 5))
	_muelle_carga = fab.poner_almacen(Vector2i(-7, 7), 0)
	_muelle_carga.carga = true
	# terminal de pedidos, puerta de pacientes y muelle de carga (modelos detallados, V1.11)
	var t := Provisional.new()
	t.position = Vector3(_terminal.x + 0.5, 0, _terminal.y + 0.5)
	add_child(t)
	t.modelo("terminal")
	var pu := Provisional.new()
	pu.position = Vector3(SALA.position.x - 0.02, 0, 0.5)
	add_child(pu)
	pu.modelo("puerta")
	_marcar_parcelas()

# ------------------------------------------------------------------ parcelas
func parcela_de(c: Vector2i) -> Vector2i:
	return Vector2i(floori(float(c.x - SALA.position.x) / PARCELA), floori(float(c.y - SALA.position.y) / PARCELA))

func comprada(c: Vector2i) -> bool:
	return compradas.has(parcela_de(c))

func rect_parcela(p: Vector2i) -> Rect2i:
	return Rect2i(SALA.position + p * PARCELA, Vector2i(PARCELA, PARCELA))

## Precio: 600 € la primera, ×1,6 cada una; las de los extremos piden 4 mejoras de la cepa.
func precio_parcela(p: Vector2i) -> int:
	return int(600.0 * pow(1.6, compradas.size() - INICIALES.size()))

func fase_parcela(p: Vector2i) -> int:
	return 4 if p.x == 0 or p.x == PARCELAS.x - 1 else 0

func comprable(p: Vector2i) -> bool:
	if compradas.has(p) or p.x < 0 or p.y < 0 or p.x >= PARCELAS.x or p.y >= PARCELAS.y:
		return false
	for d in Fabrica.DIRS:
		if compradas.has(p + d):
			return true
	return false

func comprar_parcela(p: Vector2i) -> void:
	if not comprable(p):
		return
	if fab.cepa_hechas.size() < fase_parcela(p):
		aviso.emit("AVISO_PARCELA_FASE")
		return
	var precio := precio_parcela(p)
	if fab.dinero < precio:
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= precio
	compradas[p] = true
	anuncio.emit(tr("ANUNCIO_PARCELA_T"), tr("ANUNCIO_PARCELA"))
	_marcar_parcelas()

## Las parcelas sin comprar se ven oscurecidas y con una valla y un poste de «se vende» (sin texto).
func _marcar_parcelas() -> void:
	for p in _parcelas_vis:
		_parcelas_vis[p].queue_free()
	_parcelas_vis.clear()
	for x in PARCELAS.x:
		for z in PARCELAS.y:
			var p := Vector2i(x, z)
			if compradas.has(p):
				continue
			var r := rect_parcela(p)
			var n := Node3D.new()
			n.position = Vector3(r.position.x + PARCELA * 0.5, 0, r.position.y + PARCELA * 0.5)
			add_child(n)
			var mi := MeshInstance3D.new()
			var pm := PlaneMesh.new()
			pm.size = Vector2(PARCELA - 0.06, PARCELA - 0.06)
			mi.mesh = pm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.05, 0.06, 0.07, 0.55) if comprable(p) else Color(0.02, 0.02, 0.03, 0.75)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mi.material_override = m
			mi.position.y = 0.02
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(mi)
			if comprable(p):
				var pv := Provisional.new()
				n.add_child(pv)
				pv.cilindro(0.04, 1.2, Vector3(0, 0.6, 0), Provisional.C_GRAFITO)
				pv.caja(Vector3(0.7, 0.45, 0.04), Vector3(0, 1.15, 0), Provisional.C_AMARILLO)
				pv.caja(Vector3(0.3, 0.3, 0.05), Vector3(0, 1.15, 0), Color(0.29, 0.58, 0.54))
			_parcelas_vis[p] = n

# ------------------------------------------------------------------ ascensor y catálogo
func desbloqueada(entrada: Array) -> bool:
	return desbloqueadas.has(entrada[0])

## Al completar una mejora de la cepa: se desbloquean sus máquinas, LISA paga y se anuncia.
func _revisar_cepa() -> void:
	while _fases_vistas < fab.cepa_hechas.size():
		var m := Fabrica.mejora(fab.cepa_hechas[_fases_vistas])
		var nombres: Array = []
		for id in m.desbloquea:
			desbloqueadas[id] = true
			for cat in CATALOGO:
				for en in CATALOGO[cat]:
					if en[0] == id:
						nombres.append(tr(en[2]))
		Sonido.tocar("mejora")
		var premio: int = PREMIO_MEJORA[int(m.nivel)]
		fab.dinero += premio
		_fases_vistas += 1
		var txt := tr("DESC_MEJ_" + str(m.id).to_upper())
		if not nombres.is_empty():
			txt += "\n" + tr("ANUNCIO_DESBLOQUEA") % ", ".join(nombres)
		anuncio.emit(tr("ANUNCIO_MEJORA_T") % tr("MEJ_" + str(m.id).to_upper()), txt + "  ·  +%d €" % premio)
		_marcar_parcelas()
		if not liberado and fab.vacunas_vendidas > 0:
			liberado = true

var _fases_vistas := 0
var _vendidas_dest := {}
var _final_visto := false
signal final(ganado: bool)
var _demo: Fabrica.Estacion
## Hay partida guardada y el HUD pregunta si continuar (el tutorial espera).
var inicio_pendiente := false
var _t_guardar := 0.0
var _apagon := false
var _demo_k := -1.0

# ------------------------------------------------------------------ bucle
func _process(dt: float) -> void:
	if _demo and _demo_k >= 0.0 and _demo.paciente:
		_demo.progreso = _demo_k * _demo.duracion()
		velocidad = 0.0
		_trabajando = _demo
	var dtj := dt * velocidad
	_t_guardar += dt
	if _t_guardar > 60.0 and not inicio_pendiente and puede_guardar():
		_t_guardar = 0.0
		Guardado.guardar(self)
	var kw := 0.0
	for e in fab.entidades:
		kw += kw_de(e)
	fab.demanda_kw = kw
	if kw > fab.capacidad_kw() + 0.01 and not _apagon:
		_apagon = true
		anuncio.emit(tr("ANUNCIO_ENERGIA_T"), tr("ANUNCIO_ENERGIA"))
	elif kw <= fab.capacidad_kw():
		_apagon = false
	fab.avanzar(dtj)
	_cola_puerta()
	if _demo and _demo.paciente and _trabajando == null and _tareas.is_empty() and _ruta.is_empty():
		if _demo.listo != "":
			_demo.listo = ""
		encargar([["trabajar", _demo]])
	_mover_cientifico(dt)
	if _trabajando:
		if _trabajando.listo != "":
			var est := _trabajando
			_trabajando = null
			_coger_de(est)
		elif cerca(_trabajando):
			_trabajando.trabajar(fab, dtj)
		else:
			_trabajando = null
	for p in _pedidos.duplicate():
		if fab.tiempo >= p[0]:
			for k in int(p[2]):
				_muelle_carga.contenido.append(p[1])
			_pedidos.erase(p)
			aviso.emit("AVISO_PEDIDO")
	if fab.desechados > _desechados:
		_desechados = fab.desechados
		anuncio.emit(tr("ANUNCIO_REPETIDA_T"), tr("ANUNCIO_REPETIDA"))
	# mundo: las vacunas vendidas infectan en su destino; la cepa decide el resto
	if fab.vacunas_vendidas > _vendidas_previas:
		for reg in fab.vendidas_destino:
			var antes: int = _vendidas_dest.get(reg, 0)
			var ahora: int = fab.vendidas_destino[reg]
			if ahora > antes:
				mundo.sembrar(reg, (ahora - antes) * float(Fabrica.datos.mundo.por_caja))
				_vendidas_dest[reg] = ahora
		_vendidas_previas = fab.vacunas_vendidas
		if not liberado:
			liberado = true
			aviso.emit("AVISO_LIBERADO")
	mundo.efectos = Mundo.efectos_de(fab.cepa_hechas)
	mundo.paso(dtj)
	propagacion = mundo.fraccion_infectada()
	cura = mundo.cura
	if liberado:
		_t_zombi += dtj
		var tope := 6 + int(mundo.fraccion_zombi() * 60.0)
		if _t_zombi >= 40.0 and zombis_libres < tope:
			_t_zombi = 0.0
			_llega_zombi()
	_revisar_cepa()
	if mundo.victoria and not _final_visto:
		_final_visto = true
		final.emit(true)
	elif mundo.derrota and not _final_visto:
		_final_visto = true
		final.emit(false)
	if fab.ingresos > _ultimo_ingreso:
		Sonido.tocar("vender", 0.6)
		_ventas_hist.append([fab.tiempo, fab.ingresos - _ultimo_ingreso])
	_ultimo_ingreso = fab.ingresos
	while not _ventas_hist.is_empty() and fab.tiempo - _ventas_hist[0][0] > 60.0:
		_ventas_hist.pop_front()
	ingresos_min = 0.0
	for v in _ventas_hist:
		ingresos_min += v[1]
	_actualizar_anillo()
	_actualizar_fantasma()
	_actualizar_flechas()
	_actualizar_carga()

func _actualizar_anillo() -> void:
	var e = seleccion if seleccion != null else (_trabajando if _trabajando else null)
	if e == null:
		_anillo.visible = false
		return
	_anillo.visible = true
	var c := vista.centro(e)
	var t := _tam(e)
	var r := 0.45 + 0.25 * maxf(t.x, t.y)
	var pulso := 1.0 + 0.03 * sin(fab.tiempo * 6.0)
	_anillo.position = Vector3(c.x, 0.03, c.z)
	_anillo.scale = Vector3(r * pulso, 0.05, r * pulso)

func _tam(e: Fabrica.Entidad) -> Vector2i:
	return e.tam if e is Fabrica.MaquinaSim else Vector2i.ONE

func dia() -> int:
	return 1 + int(fab.tiempo / SEG_POR_DIA)

func hora() -> int:
	return int(fmod(fab.tiempo, SEG_POR_DIA) / SEG_POR_DIA * 24.0 * 60.0 + 8 * 60) % 1440

## Progreso de la mejora elegida: [entregado, pedido] en total de unidades.
func progreso_cepa() -> Vector2i:
	if fab.cepa_actual == "":
		return Vector2i.ZERO
	var m := Fabrica.mejora(fab.cepa_actual)
	var hecho := 0
	var total := 0
	for o in m.pide:
		total += int(m.pide[o])
		hecho += mini(int(fab.cepa_entregado.get(o, 0)), int(m.pide[o]))
	return Vector2i(hecho, total)

func elegir_mejora(id: String) -> void:
	fab.elegir_mejora(id)

func hay(t: String) -> bool:
	for e in fab.entidades:
		if (e is Fabrica.MaquinaSim and e.tipo == t) or (e is Fabrica.Estacion and e.tipo == t):
			return true
	return false

# ------------------------------------------------------------------ zombis trabajadores
func _llega_zombi() -> void:
	zombis_libres += 1
	Sonido.tocar("zombi", 0.6)
	var z := Personaje.new()
	z.variante = ["zombi", "paciente_infectado", "investigador_infectado"][randi() % 3]
	z.animacion = "idle"
	z.estilo = "zombi"
	add_child(z)
	z.position = Vector3(ESPERA_ZOMBIS.x + (_zombis_espera.size() % 3) * 0.45, 0, ESPERA_ZOMBIS.y - (_zombis_espera.size() / 3) * 0.5)
	z.rotation.y = PI * 0.5
	_zombis_espera.append(z)
	aviso.emit("AVISO_ZOMBI")

func mejorar(e: Fabrica.Estacion) -> void:
	var m: Array = MEJORA[e.tipo]
	if e.modo != "mano":
		return
	if fab.dinero < float(m[1]):
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= float(m[1])
	e.modo = "maquina"

func asignar_zombi(e: Fabrica.Estacion) -> void:
	if e.modo != "maquina" or zombis_libres <= 0:
		return
	zombis_libres -= 1
	var z: Personaje = _zombis_espera.pop_back()
	if z:
		z.queue_free()
	e.modo = "zombi"

# ------------------------------------------------------------------ científico
## Al lado: a menos de 0,95 casillas del borde de la entidad.
func cerca(e: Fabrica.Entidad) -> bool:
	for c in e.casillas:
		var q := Vector2(clampf(pos.x, c.x, c.x + 1.0), clampf(pos.y, c.y, c.y + 1.0))
		if q.distance_to(pos) < 0.95:
			return true
	return false

func _celda(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x), floori(p.y))

func andable(c: Vector2i) -> bool:
	if not SALA.has_point(c):
		return false
	var e = fab.celdas.get(c)
	return e == null or e is Fabrica.Cinta

## Entidad bajo el ratón (para la ficha flotante del HUD).
func bajo_raton():
	if _cel == _terminal:
		return "terminal"
	var e = fab.celdas.get(_cel)
	if e == null and SALA.has_point(_cel) and not comprada(_cel):
		return "parcela"
	return e

func _mover_cientifico(dt: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W): dir.y -= 1
	if Input.is_key_pressed(KEY_S): dir.y += 1
	if Input.is_key_pressed(KEY_A): dir.x -= 1
	if Input.is_key_pressed(KEY_D): dir.x += 1
	if dir != Vector2.ZERO:
		_ruta.clear()
		_objetivo = null
		_tareas.clear()
		_trabajando = null
		var g: float = deg_to_rad(camara.giro) if camara else 0.0
		dir = dir.normalized().rotated(-g)
	elif not _ruta.is_empty():
		var meta := Vector2(_ruta[0].x + 0.5, _ruta[0].y + 0.5)
		if pos.distance_to(meta) < 0.12:
			_ruta.pop_front()
			if _ruta.is_empty():
				_llegar()
		else:
			dir = (meta - pos).normalized()
	var mov := dir * VEL_CIENTIFICO * dt
	if not _ruta.is_empty() and dir != Vector2.ZERO:
		var meta2 := Vector2(_ruta[0].x + 0.5, _ruta[0].y + 0.5)
		if mov.length() > pos.distance_to(meta2):
			mov = meta2 - pos            # no pasarse del punto (con pasos grandes oscilaba)
	if mov != Vector2.ZERO:
		var nueva := pos + mov
		# deslizar por las paredes y máquinas
		if not andable(_celda(nueva + dir * 0.2)):
			nueva = pos + Vector2(mov.x, 0)
			if not andable(_celda(nueva + Vector2(signf(mov.x), 0) * 0.2)):
				nueva = pos + Vector2(0, mov.y)
				if not andable(_celda(nueva + Vector2(0, signf(mov.y)) * 0.2)):
					nueva = pos
		_andado += pos.distance_to(nueva)
		pos = nueva
		cientifico.rotation.y = atan2(dir.x, dir.y)
	cientifico.position = Vector3(pos.x, 0, pos.y)
	if mov == Vector2.ZERO and _trabajando:
		var cen := Vector2(_trabajando.casillas[0]) + Vector2(0.5, 0.5)
		var lt = _lado_trabajo(_trabajando)
		if lt != null:
			# pegado al borde de la camilla, junto al brazo del paciente
			var d := Vector2(Fabrica.DIRS[(_trabajando.giro + 1) % 4])
			var punto := cen + d * 0.56 + Vector2(-d.y, d.x) * 0.05
			pos = pos.lerp(punto, minf(1.0, dt * 6.0))
			cientifico.position = Vector3(pos.x, 0, pos.y)
		cientifico.rotation.y = lerp_angle(cientifico.rotation.y, atan2(cen.x - pos.x, cen.y - pos.y), minf(1.0, dt * 10.0))
	var anim := "walk" if mov != Vector2.ZERO else ("interact-right" if _trabajando and _trabajando.trabajando else ("holding-both" if mano_n > 0 else "idle"))
	if cientifico.animacion != anim:
		cientifico.animacion = anim
		cientifico.poner(anim)

## Camino por casillas (BFS) hasta la casilla destino o hasta una vecina de la entidad.
## Muestra de las piezas de la etapa 1–3 para láminas y capturas.
func _demo_piezas() -> void:
	for p in [Vector2i(1, 1), Vector2i(4, 1), Vector2i(1, 2), Vector2i(4, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(4, 0), Vector2i(3, 0), Vector2i(5, 1), Vector2i(5, 2)]:
		compradas[p] = true
	fab.espera_pacientes = 6
	fab.poner_sala_espera(Vector2i(-6, -3), 0)
	fab.poner_generador("generador", Vector2i(-6, 0), 0)
	var bio := fab.poner_generador("biogas", Vector2i(-6, 3), 0)
	for i in 6:
		bio.aceptar(fab, "tubo_sangre", -1, Vector2i.ZERO)
	var cap := fab.poner_capsula("capsula", Vector2i(-2, -3), 0)
	for i in 4:
		cap.aceptar(fab, "bolsa_suero", -1, Vector2i.ZERO)
	fab.poner_linea_tuberia([Vector2i(-1, -3), Vector2i(0, -3), Vector2i(0, -2)])
	var ci := fab.poner_maquina("centrifuga_ind", Vector2i(0, -1), 0)
	ci.poner_receta("plasma_ind")
	var gr := fab.poner_capsula("granja", Vector2i(-3, 1), 0)
	for i in 16:
		gr.aceptar(fab, "bolsa_suero", -1, Vector2i.ZERO)
	fab.poner_linea_tuberia([Vector2i(-2, 1), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)])
	var dep := fab.poner_deposito(Vector2i(2, 2), 0)
	fab.poner_estacion("camilla", Vector2i(3, -3), 0)
	fab.poner_estacion("incubadora", Vector2i(5, -3), 0)
	fab.poner_estacion("toma_agua", Vector2i(7, -3), 0)
	fab.poner_brazo(Vector2i(5, -1), 0)
	fab.poner_divisor(Vector2i(7, -1), 0)
	var al := fab.poner_almacen(Vector2i(9, -1), 0)
	for i in 30:
		al.contenido.append("tubo_plasma")
	fab.poner_maquina("sintetizador", Vector2i(4, 1), 0)
	fab.poner_maquina("destilador", Vector2i(7, 1), 0)
	fab.poner_maquina("impresora", Vector2i(4, 4), 0)
	fab.poner_maquina("fusionador", Vector2i(7, 4), 0)
	fab.poner_fuente(Vector2i(0, 5), 0, "tubo_sangre", 1.2)
	fab.poner_linea([Vector2i(1, 5), Vector2i(2, 5)])
	fab.poner_maquina("centrifuga", Vector2i(3, 5), 0)
	fab.poner_linea([Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5)])

func puede_guardar() -> bool:
	var args := OS.get_cmdline_user_args()
	return _demo == null and not ("--prueba_raton" in args or "--demo_piezas" in args or "--escaparate" in args)

## Decisión del jugador al arrancar con partida guardada.
func empezar(continuar: bool) -> void:
	inicio_pendiente = false
	if continuar and Guardado.cargar(self):
		return
	Guardado.borrar()
	tutorial.siguiente()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not inicio_pendiente and puede_guardar():
		Guardado.guardar(self)

## Por dónde entran y salen los pacientes (en la demo de la camilla, cerca para el GIF).
func puerta_pacientes() -> Vector3:
	if _demo:
		return Vector3(-5.5, 0, 2.5)
	return Vector3(PUERTA.x, 0, PUERTA.y)

## De dónde sale el paciente que llama una camilla: la sala de espera más cercana o la puerta.
func origen_paciente(cerca_de: Vector3) -> Vector3:
	var mejor := puerta_pacientes()
	var d := INF
	for e in fab.entidades:
		if e is Fabrica.SalaEspera:
			var c := vista.centro(e) + Vector3(0, 0, 0.6).rotated(Vector3.UP, VistaFabrica.giro_y(e.giro))
			if c.distance_to(cerca_de) < d:
				d = c.distance_to(cerca_de)
				mejor = c
	return mejor

## Los que esperan sin asiento hacen cola de pie junto a la puerta.
var _cola: Array[Personaje] = []
func _cola_puerta() -> void:
	var salas := 0
	for e in fab.entidades:
		if e is Fabrica.SalaEspera:
			salas += 1
	var n := clampi(fab.espera_pacientes - salas * Fabrica.SalaEspera.ASIENTOS, 0, 4)
	while _cola.size() < n:
		var p := Personaje.new()
		p.variante = ["paciente_m", "paciente_f"][randi() % 2]
		p.animacion = "idle"
		add_child(p)
		var k := _cola.size()
		p.position = puerta_pacientes() + Vector3(1.0 + k * 0.45, 0, 0.6 + (k % 2) * 0.15)
		p.rotation.y = -PI * 0.5
		_cola.append(p)
	while _cola.size() > n:
		_cola.pop_back().queue_free()

## La camilla se trabaja desde su lado de trabajo (donde el paciente extiende el brazo).
func _lado_trabajo(e: Fabrica.Entidad):
	if e is Fabrica.Estacion and e.tipo == "camilla" and e.modo == "mano":
		var c: Vector2i = e.casillas[0] + Fabrica.DIRS[(e.giro + 1) % 4]
		if andable(c):
			return c
	return null

func ir_a(destino: Vector2i, e: Fabrica.Entidad = null) -> void:
	_trabajando = null
	_objetivo = e
	var metas := {}
	if e != null:
		for c in e.casillas:
			for d in Fabrica.DIRS:
				if andable(c + d) and not e.casillas.has(c + d):
					metas[c + d] = true
	elif andable(destino):
		metas[destino] = true
	var lado_trabajo = _lado_trabajo(e)
	if lado_trabajo != null:
		metas = {lado_trabajo: true}
	var inicio := _celda(pos)
	if metas.has(inicio) or (e != null and lado_trabajo == null and cerca(e)):
		_ruta.clear()
		_llegar()
		return
	var previo := {inicio: inicio}
	var cola: Array = [inicio]
	var fin = null
	while not cola.is_empty():
		var c: Vector2i = cola.pop_front()
		if metas.has(c):
			fin = c
			break
		for d in Fabrica.DIRS:
			var n: Vector2i = c + d
			if not previo.has(n) and andable(n):
				previo[n] = c
				cola.append(n)
	_ruta.clear()
	if fin == null:
		aviso.emit("AVISO_NO_LLEGA")
		return
	var c2: Vector2i = fin
	while c2 != inicio:
		_ruta.push_front(c2)
		c2 = previo[c2]

func _llegar() -> void:
	if _objetivo_terminal:
		_objetivo_terminal = false
		pedir("frasco_reactivo")
		return
	_objetivo = null
	if _tareas.is_empty():
		return
	var t: Array = _tareas.pop_front()
	var e: Fabrica.Entidad = t[1]
	if not fab.entidades.has(e):
		_tareas.clear()
		return
	match t[0]:
		"dejar": _dejar_en(e, t.size() > 2 and t[2])
		"coger": _coger_de(e, t[2] if t.size() > 2 else "")
		"trabajar": _trabajar(e)
		"usar": usar(e, t.size() > 2 and t[2])
	if not _tareas.is_empty():
		ir_a(_tareas[0][1].casillas[0], _tareas[0][1])

## Encargos al científico (desde el HUD: arrastrar o botones). Cada tarea: ["dejar", e],
## ["coger", e, filtro] o ["trabajar", e]. Va andando a cada sitio y la hace al llegar.
var _tareas: Array = []

func encargar(tareas: Array) -> void:
	_tareas = tareas.duplicate()
	if not _tareas.is_empty():
		ir_a(_tareas[0][1].casillas[0], _tareas[0][1])

func _trabajar(e: Fabrica.Entidad) -> void:
	if not (e is Fabrica.Estacion):
		return
	if e.listo != "":
		_coger_de(e)
	elif e.modo == "zombi":
		aviso.emit("AVISO_ZOMBI_TRABAJA")
	else:
		_trabajando = e
		if e.tipo == "camilla" and not e.paciente:
			aviso.emit("AVISO_ESPERA_PACIENTE")

## Deja lo de la mano en e. Con «todo», además todo lo de la mochila que e acepte.
func _dejar_en(e: Fabrica.Entidad, todo := false) -> int:
	var d := e.giro if e is Fabrica.Cinta else -1
	var dejados := 0
	var orden: Array = []
	if mano_i >= 0:
		orden.append(mano_i)
	if todo:
		for i in MOCHILA_CASILLAS:
			if i != mano_i:
				orden.append(i)
	for i in orden:
		while not mochila[i].is_empty() and e.aceptar(fab, mochila[i].o, d, e.casillas[0]):
			_gastar(i)
			dejados += 1
	if mano_i >= 0 and mochila[mano_i].is_empty():
		mano_i = -1
	return dejados

## Recoge lo hecho por e (o lo de dentro de un almacén) a la mochila.
func _coger_de(e: Fabrica.Entidad, filtro := "") -> int:
	var cogidos := 0
	while true:
		var o := e.sacar(filtro)
		if o == "":
			break
		if meter_mochila(o) == 0:
			_devolver(e, o)
			break
		cogidos += 1
		if mano_i < 0:
			for i in MOCHILA_CASILLAS:
				if not mochila[i].is_empty() and mochila[i].o == o:
					mano_i = i          # con las manos vacías, lo recogido pasa a la mano
					break
	return cogidos

func _devolver(e: Fabrica.Entidad, o: String) -> void:
	if e is Fabrica.MaquinaSim:
		e.salida.push_front(o)
	elif e is Fabrica.Almacen:
		e.contenido.push_front(o)
	elif e is Fabrica.Estacion:
		e.listo = o

## Clic en una entidad (estilo Factorio): mete lo de la mano; si no, recoge lo hecho.
## Mayús: mete todo lo que acepte de la mochila y recoge todo.
func usar(e: Fabrica.Entidad, todo := false) -> void:
	if e is Fabrica.Estacion:
		_trabajar(e)
		return
	var dejados := 0
	if mano_i >= 0 or todo:
		dejados = _dejar_en(e, todo)
	var cogidos := 0
	if dejados == 0 or todo:
		if not (e is Fabrica.MuelleEnvio or e is Fabrica.Cinta):
			cogidos = _coger_de(e)
	if dejados == 0 and cogidos == 0:
		if mano_i >= 0:
			aviso.emit("AVISO_NO_SE_VENDE" if e is Fabrica.MuelleEnvio else "AVISO_NO_ACEPTA")
		else:
			aviso.emit("AVISO_NADA_QUE_COGER")

# ------------------------------------------------------------------ mochila
## Mete n unidades de o en la mochila (primero en pilas iguales). Devuelve cuántas cupieron.
func meter_mochila(o: String, n := 1) -> int:
	var queda := n
	for pasada in 2:
		for i in MOCHILA_CASILLAS:
			if queda == 0:
				return n
			var c: Dictionary = mochila[i]
			if pasada == 0 and not c.is_empty() and c.o == o and c.n < PILA_MAX:
				var k := mini(PILA_MAX - c.n, queda)
				c.n += k
				queda -= k
			elif pasada == 1 and c.is_empty():
				var k2 := mini(PILA_MAX, queda)
				mochila[i] = {"o": o, "n": k2}
				queda -= k2
	if queda > 0:
		aviso.emit("AVISO_MOCHILA_LLENA")
	return n - queda

func hueco_mochila(o: String) -> int:
	var h := 0
	for c in mochila:
		if c.is_empty():
			h += PILA_MAX
		elif c.o == o:
			h += PILA_MAX - c.n
	return h

func cuenta_mochila(o: String) -> int:
	var n := 0
	for c in mochila:
		if not c.is_empty() and c.o == o:
			n += c.n
	return n

## Quita una unidad de la casilla i.
func _gastar(i: int) -> void:
	mochila[i].n -= 1
	if mochila[i].n <= 0:
		mochila[i] = {}

func elegir_mano(i: int) -> void:
	mano_i = -1 if mano_i == i or i < 0 or mochila[i].is_empty() else i

func soltar_mano() -> void:
	if mano_i >= 0:
		mochila[mano_i] = {}
	mano_i = -1

## Mueve una casilla de la mochila a otra (arrastrar dentro del panel).
func mover_casilla(a: int, b: int) -> void:
	var t: Dictionary = mochila[b]
	mochila[b] = mochila[a]
	mochila[a] = t
	if mano_i == a:
		mano_i = b
	elif mano_i == b:
		mano_i = a

func _actualizar_carga() -> void:
	var nombre := Fabrica.base(mano_obj) if mano_n > 0 else ""
	if nombre != _carga_nombre:
		_carga_nombre = nombre
		if _carga:
			_carga.queue_free()
			_carga = null
		if nombre != "":
			_carga = Node3D.new()
			add_child(_carga)
			var esc: PackedScene = load("res://assets/modelos/objetos/%s.glb" % nombre)
			for k in 4:
				var n: Node3D = esc.instantiate()
				Materiales.ajustar(n)
				n.scale = Vector3.ONE * 1.6
				n.position = Vector3(0, k * 0.09, 0)
				n.name = "o%d" % k
				_carga.add_child(n)
	if _carga:
		var f := Vector2(sin(cientifico.rotation.y), cos(cientifico.rotation.y))
		_carga.position = Vector3(pos.x + f.x * 0.22, 0.42, pos.y + f.y * 0.22)
		_carga.rotation.y = cientifico.rotation.y
		for k in 4:
			_carga.get_node("o%d" % k).visible = k < mano_n

# ------------------------------------------------------------------ herramientas (HUD)
func seleccionar_herramienta(entrada: Array) -> void:
	if not desbloqueada(entrada):
		aviso.emit("AVISO_BLOQUEADA")
		return
	herramienta = entrada
	quitando = false
	seleccion = null
	_crear_fantasma()

func modo_quitar() -> void:
	herramienta = []
	quitando = not quitando
	_crear_fantasma()

func cancelar() -> void:
	if herramienta.is_empty() and not quitando and seleccion == null:
		mano_i = -1                     # Esc sin nada más: vaciar la mano
	herramienta = []
	quitando = false
	_arrastre = false
	seleccion = null
	_crear_fantasma()

func elegir_receta(r: String) -> void:
	if seleccion is Fabrica.MaquinaSim:
		seleccion.poner_receta(r)

func pedir(objeto: String) -> void:
	var p: Dictionary = Fabrica.datos.pedidos[objeto]
	if fab.dinero < float(p.precio):
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= float(p.precio)
	_pedidos.append([fab.tiempo + randf_range(float(p.espera[0]), float(p.espera[1])), objeto, p.lote])
	aviso.emit("AVISO_PEDIDO_HECHO")

func pedidos_en_camino() -> int:
	return _pedidos.size()

# ------------------------------------------------------------------ ratón y teclado
func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var c = _casilla_raton((ev as InputEventMouseMotion).position)
		if c != null:
			_cel = c
	elif ev is InputEventMouseButton:
		var b := ev as InputEventMouseButton
		var c = _casilla_raton(b.position)
		if c != null:
			_cel = c
		if b.button_index == MOUSE_BUTTON_LEFT:
			if b.pressed:
				_pulsar()
			else:
				_soltar()
		elif b.button_index == MOUSE_BUTTON_RIGHT and b.pressed:
			if not herramienta.is_empty() or quitando:
				cancelar()
			else:
				seleccion = fab.celdas.get(_cel)    # abre (o cierra) su ventana
	elif ev is InputEventKey and ev.pressed and not ev.echo:
		match (ev as InputEventKey).keycode:
			KEY_R:
				giro = (giro + 1) % 4
			KEY_X:
				modo_quitar()
			KEY_ESCAPE:
				cancelar()
			KEY_SPACE:
				velocidad = 0.0 if velocidad > 0.0 else 1.0
			KEY_F:
				if mano_n > 0:
					soltar_mano()          # tirar lo que lleva

func _casilla_raton(p: Vector2):
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return null
	var o := cam.project_ray_origin(p)
	var d := cam.project_ray_normal(p)
	if absf(d.y) < 0.001:
		return null
	var q := o + d * (-o.y / d.y)
	return Vector2i(floori(q.x), floori(q.z))

func _pulsar() -> void:
	if quitando:
		_quitar(_cel)
		return
	if not herramienta.is_empty():
		if herramienta[5] in ["cinta", "tuberia"]:
			_arrastre = true
			_inicio = _cel
		else:
			_construir(_cel)
		return
	if _cel == _terminal:
		_objetivo_terminal = true
		ir_a(_cel + Vector2i(1, 0))
		return
	var e: Fabrica.Entidad = fab.celdas.get(_cel)
	if e == null and not comprada(_cel):
		parcela_sel = parcela_de(_cel)
		seleccion = null
		return
	if e == null:
		parcela_sel = Vector2i(-1, -1)
		_tareas.clear()
		ir_a(_cel)
	else:
		encargar([["usar", e, Input.is_key_pressed(KEY_SHIFT)]])

func _soltar() -> void:
	if not _arrastre:
		return
	_arrastre = false
	var ruta := _ruta_cinta(_inicio, _cel)
	var coste := ruta.size() * int(herramienta[3])
	if not _ruta_libre(ruta):
		return
	if fab.dinero < coste:
		aviso.emit("AVISO_SIN_DINERO")
		return
	fab.dinero -= coste
	if herramienta[5] == "tuberia":
		fab.poner_linea_tuberia(ruta, giro if ruta.size() == 1 else -1)
	else:
		fab.poner_linea(ruta, 1, giro if ruta.size() == 1 else -1)

func _ruta_cinta(a: Vector2i, b: Vector2i) -> Array:
	var r: Array = [a]
	var c := a
	while c.x != b.x:
		c.x += signi(b.x - a.x)
		r.append(c)
	while c.y != b.y:
		c.y += signi(b.y - a.y)
		r.append(c)
	return r

func _ruta_libre(r: Array) -> bool:
	for c in r:
		if not comprada(c) or fab.celdas.has(c) or c == _terminal:
			return false
	return true

func casillas_de(entrada: Array, origen: Vector2i, g := -1) -> Array:
	if g < 0:
		g = giro
	if entrada[5] == "maquina":
		var t: Array = Fabrica.datos.maquinas[entrada[6]].tam
		var w: int = t[0] if g % 2 == 0 else t[1]
		var h: int = t[1] if g % 2 == 0 else t[0]
		var cs: Array = []
		for i in w:
			for j in h:
				cs.append(origen + Vector2i(i, j))
		return cs
	if entrada[5] == "sala_espera":
		return [origen, origen + Fabrica.girar(Vector2i(1, 0), g)]
	if entrada[5] == "capsula" and entrada[6] == "granja":
		var cs2: Array = []
		for i in 4:
			cs2.append(origen + Fabrica.girar(Vector2i(0, i), g))
		return cs2
	if entrada[5] == "generador":
		return [origen, origen + Vector2i(1, 0), origen + Vector2i(0, 1), origen + Vector2i(1, 1)]
	return [origen]

func _valido(entrada: Array, origen: Vector2i) -> bool:
	if not desbloqueada(entrada):
		return false
	for c in casillas_de(entrada, origen):
		if not comprada(c) or fab.celdas.has(c) or c == _terminal or c == _celda(pos):
			return false
	return true

func _construir(c: Vector2i) -> void:
	if not _valido(herramienta, c):
		return
	if fab.dinero < float(herramienta[3]):
		aviso.emit("AVISO_SIN_DINERO")
		return
	var e: Fabrica.Entidad
	match herramienta[5]:
		"maquina": e = fab.poner_maquina(herramienta[6], c, giro)
		"estacion": e = fab.poner_estacion(herramienta[6], c, giro)
		"brazo": e = fab.poner_brazo(c, giro)
		"divisor": e = fab.poner_divisor(c, giro)
		"almacen": e = fab.poner_almacen(c, giro)
		"sala_espera": e = fab.poner_sala_espera(c, giro)
		"capsula": e = fab.poner_capsula(herramienta[6], c, giro)
		"deposito": e = fab.poner_deposito(c, giro)
		"generador": e = fab.poner_generador(herramienta[6], c, giro)
	if e:
		fab.dinero -= float(herramienta[3])
		Sonido.tocar("construir")

func coste_de(e: Fabrica.Entidad) -> float:
	var extra := 0.0
	if e is Fabrica.Estacion and e.modo != "mano":
		extra = float(MEJORA[e.tipo][1])
	for cat in CATALOGO:
		for en in CATALOGO[cat]:
			if (e is Fabrica.MaquinaSim and en[6] == e.tipo) or (e is Fabrica.Estacion and en[6] == e.tipo) \
					or (e is Fabrica.Cinta and not e is Fabrica.Tuberia and en[5] == "cinta") or (e is Fabrica.Brazo and en[5] == "brazo") \
					or (e is Fabrica.Divisor and en[5] == "divisor") or (e is Fabrica.Almacen and en[5] == "almacen") \
					or (e is Fabrica.SalaEspera and en[5] == "sala_espera") or (e is Fabrica.Generador and en[6] == e.tipo) \
					or (e is Fabrica.Capsula and en[6] == e.tipo) or (e is Fabrica.Deposito and en[5] == "deposito") \
					or (e is Fabrica.Tuberia and en[5] == "tuberia"):
				return float(en[3]) + extra
	return 0.0

func campana_disponible(c: Array) -> bool:
	if float(c[3]) <= 0.0:
		return fab.contrato_mult < 3.3       # hasta tres contratos
	return fab.campana_t <= 0.0

func campana(c: Array) -> void:
	if fab.dinero < float(c[1]) or not campana_disponible(c):
		return
	fab.dinero -= float(c[1])
	if float(c[3]) <= 0.0:
		fab.contrato_mult *= float(c[2])
	else:
		fab.lanzar_campana(float(c[2]), float(c[3]))
	aviso.emit("AVISO_CAMPANA")

## kW que consume una entidad (las estaciones solo con la máquina puesta).
static func kw_de(e) -> float:
	if e is Fabrica.Tuberia:
		return 0.0
	if e is Fabrica.Cinta:
		return 0.1
	if e is Fabrica.Capsula:
		return 2.0 * e.plazas if e.humanos > 0 else 0.0
	if e is Fabrica.Estacion and e.modo == "mano":
		return 0.0
	for cat in CATALOGO:
		for en in CATALOGO[cat]:
			if (e is Fabrica.MaquinaSim and en[6] == e.tipo) or (e is Fabrica.Brazo and en[5] == "brazo") \
					or (e is Fabrica.Divisor and en[5] == "divisor") or (e is Fabrica.Estacion and en[6] == e.tipo):
				return float(en[4]) + (1.5 if e is Fabrica.Estacion else 0.0)
	return 0.0

## Quitar devuelve el 100 % (lo pidió Edu); lo que llevaba dentro se pierde salvo en cintas.
func _quitar(c: Vector2i) -> void:
	var e: Fabrica.Entidad = fab.celdas.get(c)
	if e == null or e == _cepa or e == _muelle_carga or e is Fabrica.MuelleEnvio:
		return
	fab.dinero += coste_de(e)
	Sonido.tocar("quitar")
	# lo que tenía dentro vuelve a la mochila (B10)
	var dentro: Array = []
	if e is Fabrica.Cinta:
		dentro = e.objetos.map(func(x): return x[0])
	elif e is Fabrica.MaquinaSim:
		dentro = e.salida.duplicate()
		for o in e.entrada:
			for k in int(e.entrada[o]):
				dentro.append(o)
		if e.progreso >= 0.0:
			var r: Dictionary = Fabrica.datos.recetas[e.receta]
			for o in r.entradas:
				for k in int(r.entradas[o]):
					dentro.append(o)
	elif e is Fabrica.Almacen:
		dentro = e.contenido.duplicate()
	elif e is Fabrica.Estacion and e.listo != "":
		dentro = [e.listo]
	for o in dentro:
		meter_mochila(o)
	if e is Fabrica.Estacion and e.modo == "zombi":
		zombis_libres += 1
		_llega_zombi_vuelve()
	fab.quitar(c)
	if seleccion == e:
		seleccion = null
	if _trabajando == e:
		_trabajando = null

func _llega_zombi_vuelve() -> void:
	zombis_libres -= 1
	_llega_zombi()

# ------------------------------------------------------------------ fantasma y bocas
func _crear_fantasma() -> void:
	if _fantasma:
		_fantasma.queue_free()
		_fantasma = null
	for h in _huella:
		h.queue_free()
	_huella.clear()
	if herramienta.is_empty():
		return
	var n: Node3D
	match herramienta[5]:
		"maquina": n = load(VistaFabrica.MODELO_MAQUINA[herramienta[6]]).instantiate()
		"cinta": n = load("res://assets/modelos/cintas/cinta_recta_mk1.glb").instantiate()
		"tuberia": n = load("res://assets/modelos/estaciones/tuberia_recta.glb").instantiate()
		_:
			var e: Fabrica.Entidad
			match herramienta[5]:
				"brazo": e = Fabrica.Brazo.new(Vector2i.ZERO, 0, "")
				"divisor": e = Fabrica.Divisor.new(Vector2i.ZERO, 0)
				"almacen": e = Fabrica.Almacen.new(Vector2i.ZERO, 0)
				"estacion": e = Fabrica.Estacion.new(herramienta[6], Vector2i.ZERO, 0)
				"sala_espera": e = Fabrica.SalaEspera.new(Vector2i.ZERO, 0)
				"generador": e = Fabrica.Generador.new(herramienta[6], Vector2i.ZERO, 0)
				"capsula": e = Fabrica.Capsula.new(herramienta[6], Vector2i.ZERO, 0)
				"deposito": e = Fabrica.Deposito.new(Vector2i.ZERO, 0)
			n = VistaFabrica.nodo_para(e, Vector3.ZERO, null)
	_fantasma = n
	add_child(n)
	for c in casillas_de(herramienta, Vector2i.ZERO):
		var h := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.94, 0.94)
		h.mesh = pm
		add_child(h)
		_huella.append(h)

func _actualizar_fantasma() -> void:
	for f in _fantasma_cintas:
		f.visible = false
	if _fantasma == null:
		return
	var ok := _valido(herramienta, _cel) and fab.dinero >= float(herramienta[3])
	var mat := _mat_ok if ok else _mat_mal
	for mi in _fantasma.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_override = mat
		(mi as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cs := casillas_de(herramienta, _cel)
	var s := Vector2.ZERO
	for c in cs:
		s += Vector2(c)
	s /= cs.size()
	_fantasma.position = Vector3(s.x + 0.5, 0, s.y + 0.5)
	_fantasma.rotation.y = VistaFabrica.giro_y(giro)
	for i in _huella.size():
		_huella[i].position = Vector3(cs[i].x + 0.5, 0.015, cs[i].y + 0.5)
		_huella[i].material_override = mat
	if _arrastre:
		var ruta := _ruta_cinta(_inicio, _cel)
		var libre := _ruta_libre(ruta) and fab.dinero >= ruta.size() * int(herramienta[3])
		_fantasma.visible = false
		while _fantasma_cintas.size() < ruta.size():
			var n: Node3D = load("res://assets/modelos/cintas/cinta_recta_mk1.glb").instantiate()
			add_child(n)
			_fantasma_cintas.append(n)
		for i in ruta.size():
			var f := _fantasma_cintas[i]
			f.visible = true
			f.position = Vector3(ruta[i].x + 0.5, 0, ruta[i].y + 0.5)
			var d: Vector2i = (ruta[i + 1] - ruta[i]) if i < ruta.size() - 1 else ((ruta[i] - ruta[i - 1]) if i > 0 else Fabrica.DIRS[giro])
			f.rotation.y = atan2(-float(d.y), float(d.x))
			for mi in f.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_override = _mat_ok if libre else _mat_mal
	else:
		_fantasma.visible = true

## Bocas: flecha verde donde entra y naranja donde sale. Se ven en el fantasma y, mientras
## se construye, en todas las máquinas y estaciones; si no, solo en lo seleccionado.
func bocas(entrada_o_entidad, origen := Vector2i.ZERO, g := 0) -> Array:
	var r: Array = []      # [casilla, dirección, sale]
	if entrada_o_entidad is Array:
		var en: Array = entrada_o_entidad
		if en[5] == "maquina":
			var m := Fabrica.MaquinaSim.new(en[6], origen, g)
			return bocas(m)
		if en[5] == "estacion":
			return [[origen + Fabrica.DIRS[g], g, true]]
		if en[5] == "brazo":
			return [[origen - Fabrica.DIRS[g], g, false], [origen + Fabrica.DIRS[g], g, true]]
		if en[5] == "almacen":
			return [[origen + Fabrica.DIRS[g], g, true]]
		return r
	var e: Fabrica.Entidad = entrada_o_entidad
	if e is Fabrica.MaquinaSim:
		for i in e.bocas.size():
			r.append([e.bocas[i][0] - Fabrica.DIRS[e.giro], e.giro, false, e.filtro_boca(i)])
		if not Fabrica.datos.recetas[e.receta].salidas.is_empty():
			r.append([e.casilla_salida, e.giro, true])
	elif e is Fabrica.Estacion or (e is Fabrica.Almacen and e.giro >= 0):
		r.append([e.casillas[0] + Fabrica.DIRS[e.giro], e.giro, true])
	elif e is Fabrica.Brazo:
		r.append([e.casillas[0] - Fabrica.DIRS[e.giro], e.giro, false])
		r.append([e.casillas[0] + Fabrica.DIRS[e.giro], e.giro, true])
	return r

func _actualizar_flechas() -> void:
	var lista: Array = []
	if not herramienta.is_empty():
		lista.append_array(bocas(herramienta, _cel, giro))
		for e in fab.entidades:
			if e is Fabrica.MaquinaSim or e is Fabrica.Estacion:
				lista.append_array(bocas(e))
	elif seleccion != null:
		lista.append_array(bocas(seleccion))
	while _flechas.size() < lista.size():
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(0.34, 0.3, 0.03)
		mi.mesh = pm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_flechas.append(mi)
	var pulso := 0.08 * sin(fab.tiempo * 5.0)
	for i in _flechas.size():
		var f := _flechas[i]
		f.visible = i < lista.size()
		if not f.visible:
			continue
		var b: Array = lista[i]
		var c: Vector2i = b[0]
		var d := Vector2(Fabrica.DIRS[b[1]])
		var centro := Vector2(c.x + 0.5, c.y + 0.5) + d * (0.15 + pulso if b[2] else -0.15 + pulso)
		f.position = Vector3(centro.x, 0.36, centro.y)
		# prisma tumbado apuntando en la dirección del flujo
		f.rotation = Vector3(-PI * 0.5, atan2(-d.x, -d.y), 0)
		f.material_override = _mat_sale if b[2] else _mat_entra
		var ic: Sprite3D = f.get_node_or_null("icono")
		var filtro: String = b[3] if b.size() > 3 else ""
		if filtro != "":
			if ic == null:
				ic = Sprite3D.new()
				ic.name = "icono"
				ic.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				ic.pixel_size = 0.0016
				ic.no_depth_test = true
				f.add_child(ic)
			ic.texture = load("res://assets/iconos/%s.png" % filtro)
			ic.visible = true
			ic.global_position = f.global_position + Vector3(0, 0.35, 0)
		elif ic:
			ic.visible = false
