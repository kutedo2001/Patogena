class_name Tutorial
extends Node3D
## Tutorial con historia (P4.12, rehecho en V1.14): correos de LISA que presentan el plan y
## dan cada paso, una marca que flota sobre el objetivo en el mundo y una condición para pasar.
## El HUD muestra el correo y el paso actual; el juego se pausa mientras se lee un correo.

signal correo(titulo: String, texto: String)

## [clave del correo (o ""), clave del paso, condición, dónde marcar]
var pasos: Array = []
var i := -1
var juego: Juego
var leyendo := false
var _marca: Node3D
var _t := 0.0
var _x0 := Vector2.ZERO

func _ready() -> void:
	pasos = [
		["CORREO_BIENVENIDA", "PASO_MOVER", func(): return juego._andado > 2.5, func(): return null],
		["", "PASO_CAMILLA", func(): return juego.hay("camilla"), func(): return Vector3(-5.5, 0, -2.5), ["HUD_CAT_EXTRACCION", "camilla"]],
		["CORREO_PACIENTE", "PASO_SANGRE", func(): return juego.fab.producido.get("tubo_sangre", 0) >= 1, func(): return _donde("camilla")],
		["", "PASO_CENTRIFUGA", func(): return juego.hay("centrifuga"), func(): return Vector3(-2.5, 0, -2.5), ["HUD_CAT_PROCESADO", "centrifuga"]],
		["", "PASO_PLASMA", func(): return juego.fab.producido.get("tubo_plasma", 0) >= 1, func(): return _donde("centrifuga")],
		["CORREO_CEPAS", "PASO_ELEGIR_MEJORA", func(): return juego.fab.cepa_actual != "" or not juego.fab.cepa_hechas.is_empty(), func(): return _sala()],
		["", "PASO_ENTREGAR", func(): return juego.fab.cepa_sintesis >= 0.0 or not juego.fab.cepa_hechas.is_empty(), func(): return _sala()],
		["", "PASO_SINTETIZAR", func(): return not juego.fab.cepa_hechas.is_empty(), func(): return _sala()],
		["CORREO_AUTOMATIZAR", "PASO_MEJORA", func(): return _modo("maquina") or _modo("zombi"), func(): return _donde("camilla")],
		["", "PASO_CINTA", func(): return _cintas() >= 3, func(): return null, ["HUD_CAT_LOGISTICA", "cinta"]],
		["CORREO_ADN", "PASO_ADN", func(): return juego.fab.producido.get("tubo_adn", 0) >= 1, func(): return null, ["HUD_CAT_EXTRACCION", "incubadora"]],
		["", "PASO_FIEBRE", func(): return "fiebre" in juego.fab.cepa_hechas, func(): return _sala()],
		["CORREO_VIRIONES", "PASO_VIRIONES", func(): return juego.fab.producido.get("viriones", 0) >= 1, func(): return _donde("biorreactor")],
		["", "PASO_FRIO", func(): return "frio" in juego.fab.cepa_hechas, func(): return _sala()],
		["CORREO_VACUNAS", "PASO_VENDER", func(): return juego.fab.vacunas_vendidas >= 1, func(): return Vector3(6.0, 0, 6.0)],
		["CORREO_LIBERADO", "PASO_ZOMBI", func(): return _modo("zombi"), func(): return Vector3(juego.ESPERA_ZOMBIS.x, 0, juego.ESPERA_ZOMBIS.y) if juego.zombis_libres > 0 else null],
		["CORREO_FIN", "PASO_LIBRE", func(): return false, func(): return null],
	]
	_marca = Node3D.new()
	add_child(_marca)
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(0.4, 0.45, 0.4)
	mi.mesh = pm
	mi.rotation.z = PI          # punta hacia abajo
	var m := Provisional.mat(Color(1.0, 0.8, 0.2), 0.4, 1.5)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marca.add_child(mi)
	if "--sin_tutorial" in OS.get_cmdline_user_args():
		i = pasos.size() - 1
		return
	if not juego.inicio_pendiente:
		siguiente.call_deferred()

## Al cargar una partida: sigue en el paso guardado sin volver a enseñar el correo.
func saltar_a(n: int) -> void:
	i = clampi(n, 0, pasos.size() - 1)
	leyendo = false

func _sala():
	for e in juego.fab.entidades:
		if e is Fabrica.SalaCepas:
			return juego.vista.centro(e)
	return null

func _donde(t: String):
	for e in juego.fab.entidades:
		if (e is Fabrica.Estacion and e.tipo == t) or (e is Fabrica.MaquinaSim and e.tipo == t):
			return juego.vista.centro(e)
	return null

func _modo(m: String) -> bool:
	for e in juego.fab.entidades:
		if e is Fabrica.Estacion and e.modo == m:
			return true
	return false

func _cintas() -> int:
	var n := 0
	for e in juego.fab.entidades:
		if e is Fabrica.Cinta:
			n += 1
	return n

func paso_actual() -> String:
	return pasos[i][1] if i >= 0 and i < pasos.size() else ""

func numero() -> Vector2i:
	return Vector2i(mini(i + 1, pasos.size() - 1), pasos.size() - 1)

func siguiente() -> void:
	i += 1
	if i >= pasos.size():
		return
	if pasos[i][0] != "":
		# LISA habla sin parar el juego (V1.18)
		if pasos[i][0] == "CORREO_ADN":
			juego.fab.dinero += 300.0      # «Hemos ingresado fondos para la primera adquisición»
		correo.emit(tr(pasos[i][0] + "_T"), tr(pasos[i][0]))

func cerrar_correo() -> void:
	leyendo = false

## Saltar el tutorial: el juego sigue libre, con el objetivo final.
func saltar() -> void:
	i = pasos.size() - 1
	leyendo = false

## Botón de la barra que hay que pulsar en este paso: [categoría, id] o [] si no toca construir.
func objetivo_hud() -> Array:
	if i < 0 or i >= pasos.size():
		return []
	return pasos[i][4] if pasos[i].size() > 4 else []

func _process(dt: float) -> void:
	_t += dt
	if i < 0 or i >= pasos.size():
		_marca.visible = false
		return
	if not leyendo and pasos[i][2].call():
		siguiente()
		return
	var donde = pasos[i][3].call()
	_marca.visible = donde != null and not leyendo
	if donde != null:
		_marca.position = (donde as Vector3) + Vector3(0, 2.2 + 0.15 * sin(_t * 4.0), 0)
		_marca.rotation.y = _t * 1.5
