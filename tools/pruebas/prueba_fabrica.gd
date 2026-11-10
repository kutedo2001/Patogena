extends SceneTree
## Bot sin pantalla de la simulación (P4.1). Uso:
##   godot --headless -s tools/pruebas/prueba_fabrica.gd
## Monta las dos cadenas de la pantalla objetivo, simula 5 minutos de juego lo más rápido
## posible y comprueba producción, mutaciones, brazo, divisor y almacén.

var fallos := 0
var hechas := 0

func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	_cadenas()
	_brazo_divisor_almacen()
	_bloqueo()
	_ascensor_y_hub()
	_pacientes_y_energia()
	_tuberias_y_capsulas()
	if hechas < 16:
		fallos += 1
		print("  FALLO solo se hicieron %d comprobaciones de 12" % hechas)
	print("Tiempo real total: %d ms" % (Time.get_ticks_msec() - t0))
	print("PRUEBA FABRICA: %s" % ("OK" if fallos == 0 else "%d FALLOS" % fallos))
	quit(0 if fallos == 0 else 1)

func comprobar(cond: bool, texto: String) -> void:
	hechas += 1
	print(("  ok    " if cond else "  FALLO ") + texto)
	if not cond:
		fallos += 1

func _simular(f: Fabrica, segundos: float) -> void:
	for i in int(segundos / Fabrica.PASO):
		f.paso()

## La cadena profunda de las vacunas (V1.13): cultivo → ADN → biorreactor (viriones, con medio de
## cultivo) → envasadora (con suero) → cajas. Recetas elegibles que fabrican sin parar.
func _cadenas() -> void:
	print("Cadena profunda de vacunas (5 min de juego):")
	var f := Fabrica.new()
	f.poner_fuente(Vector2i(-2, 1), 0, "placa_petri", 2.0)
	f.poner_cinta(Vector2i(-1, 1), 0)
	var sq := f.poner_maquina("secuenciador", Vector2i(0, 0))
	f.poner_cinta(Vector2i(2, 1), 3)
	f.poner_linea([Vector2i(2, 0), Vector2i(3, 0)], 1, 0)
	f.poner_fuente(Vector2i(3, 2), 3, "medio_cultivo", 3.0)
	f.poner_cinta(Vector2i(3, 1), 0)
	var br := f.poner_maquina("biorreactor", Vector2i(4, 0))
	f.poner_cinta(Vector2i(6, 1), 3)
	f.poner_linea([Vector2i(6, 0), Vector2i(7, 0)], 1, 0)
	f.poner_fuente(Vector2i(7, 2), 3, "bolsa_suero", 2.0)
	f.poner_cinta(Vector2i(7, 1), 0)
	var ev := f.poner_maquina("envasadora", Vector2i(8, 0))
	var palet := f.poner_almacen(Vector2i(10, 1))
	comprobar(sq != null and br != null and ev != null and palet != null, "todo se coloca sin solaparse")
	var malo := Fabrica.new()
	malo.poner_fuente(Vector2i(-1, 0), 0, "garrafa_agua", 1.0)
	var mz2 := malo.poner_maquina("mezcladora", Vector2i(0, 0))
	for i in 100: malo.paso()
	comprobar(mz2.entrada.is_empty(), "la mezcladora no acepta agua por la boca del reactivo")
	var t0 := Time.get_ticks_msec()
	_simular(f, 300.0)
	var ms := Time.get_ticks_msec() - t0
	print("    producido: ", f.producido)
	comprobar(f.producido.get("viriones", 0) >= 25, "el biorreactor cultiva viriones sin parar (%d)" % f.producido.get("viriones", 0))
	comprobar(palet.contenido.size() >= 40 and palet.contenido[0] == "caja_vacunas", "llegan cajas de vacunas al palé sin atascos (%d)" % palet.contenido.size())
	comprobar(ms < 3000, "5 min de juego se simulan en menos de 3 s (%d ms)" % ms)
	# la misma centrífuga cambia de producto: hematíes y plaquetas
	var g := Fabrica.new()
	g.poner_fuente(Vector2i(0, 0), 0, "tubo_sangre", 1.0)
	g.poner_cinta(Vector2i(1, 0), 0)
	var cf := g.poner_maquina("centrifuga", Vector2i(2, 0))
	cf.poner_receta("hematies")
	var al := g.poner_almacen(Vector2i(3, 0))
	_simular(g, 30.0)
	comprobar(al.contenido.count("hematies") >= 5, "la centrífuga con la receta de hematíes los hace (%d)" % al.contenido.count("hematies"))
	cf.poner_receta("plaquetas")
	_simular(g, 30.0)
	comprobar(al.contenido.count("plaquetas") >= 3, "y cambiada a plaquetas, plaquetas (%d)" % al.contenido.count("plaquetas"))

## Un brazo saca de una cinta a una máquina, un divisor reparte en tres y un almacén guarda y saca.
func _brazo_divisor_almacen() -> void:
	print("Brazo, divisor y almacén:")
	var f := Fabrica.new()
	f.poner_fuente(Vector2i(0, 0), 0, "tubo_sangre", 1.0)
	f.poner_linea([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], 1, 0)
	var div := f.poner_divisor(Vector2i(4, 0), 0)
	var a := f.poner_almacen(Vector2i(5, 0))
	var b := f.poner_almacen(Vector2i(4, 1))
	var c := f.poner_almacen(Vector2i(4, -1))
	_simular(f, 30.0)
	comprobar(div != null and a.contenido.size() > 3 and b.contenido.size() > 3 and c.contenido.size() > 3,
		"el divisor reparte en los tres lados (%d / %d / %d)" % [a.contenido.size(), b.contenido.size(), c.contenido.size()])
	var g := Fabrica.new()
	var alm := g.poner_almacen(Vector2i(0, 0))
	for i in 10:
		alm.contenido.append("tubo_sangre")
	var brazo := g.poner_brazo(Vector2i(1, 0), 0)
	var cf := g.poner_maquina("centrifuga", Vector2i(2, 0))
	var brazo2 := g.poner_brazo(Vector2i(3, 0), 0, "tubo_plasma")
	var salida := g.poner_almacen(Vector2i(4, 0))
	_simular(g, 40.0)
	comprobar(brazo != null and brazo2 != null and cf != null, "brazos y máquina colocados")
	comprobar(salida.contenido.size() >= 8, "brazo → centrífuga → brazo con filtro → almacén (%d plasmas)" % salida.contenido.size())

## Si la salida se llena la máquina se para (ámbar) y no pierde objetos.
func _bloqueo() -> void:
	print("Bloqueo y conservación:")
	var f := Fabrica.new()
	f.poner_fuente(Vector2i(0, 0), 0, "tubo_sangre", 0.5)
	f.poner_cinta(Vector2i(1, 0), 0)
	var cf := f.poner_maquina("centrifuga", Vector2i(2, 0))
	f.poner_cinta(Vector2i(3, 0), 0)      # termina en nada: se llena
	_simular(f, 60.0)
	comprobar(cf.estado == Fabrica.MaquinaSim.Estado.SALIDA_LLENA, "la centrífuga queda en SALIDA_LLENA")
	var en_cinta: int = (f.celdas[Vector2i(3, 0)] as Fabrica.Cinta).objetos.size()
	comprobar(f.producido.tubo_plasma == en_cinta + cf.salida.size(), "no se pierde ningún plasma (%d hechos)" % f.producido.tubo_plasma)
	var q := f.quitar(Vector2i(2, 0))
	comprobar(q == cf and not f.celdas.has(Vector2i(2, 0)), "quitar libera las casillas")

## La sala de cepas acepta solo lo que pide la mejora elegida y la completa; el hub vende vacunas.
func _ascensor_y_hub() -> void:
	print("Sala de cepas, hub y mundo:")
	var f := Fabrica.new()
	var sala := f.poner_sala_cepas(Vector2i(0, 0))
	comprobar(not f.mejora_disponible("estornudos"), "estornudos pide antes la tos")
	comprobar(not sala.aceptar(f, "tubo_plasma", 0, Vector2i(0, 0)), "sin mejora elegida no acepta nada")
	f.elegir_mejora("tos")
	comprobar(not sala.aceptar(f, "tubo_sangre", 0, Vector2i(0, 0)), "no acepta lo que no pide")
	comprobar(not sala.aceptar(f, "tubo_plasma", 0, Vector2i(0, 1)), "por cinta solo entra por el buzón")
	f.poner_fuente(Vector2i(-2, 3), 0, "tubo_plasma", 0.3)
	f.poner_cinta(Vector2i(-1, 3), 0)
	_simular(f, 16.0)
	comprobar(f.cepa_sintesis >= 0.0 and f.cepa_hechas.is_empty(), "10 plasmas por el buzón: lote completo, falta sintetizar")
	_simular(f, 30.0)
	comprobar(f.cepa_hechas.is_empty(), "sin el científico ni el robot la síntesis no avanza")
	f.sintetizar(21.0)
	comprobar("tos" in f.cepa_hechas and f.cepa_actual == "", "20 s de trabajo en la mesa completan la tos")
	var g := Fabrica.new()
	var sala2 := g.poner_sala_cepas(Vector2i(0, 0))
	g.cepa_robot = true
	g.elegir_mejora("tos")
	for i in 10:
		sala2.aceptar(g, "tubo_plasma", -1, Vector2i(3, 3))
	_simular(g, 40.0)
	comprobar("tos" in g.cepa_hechas, "con el robot de síntesis la mejora se completa sola")
	comprobar(f.mejora_disponible("estornudos"), "y ya se puede elegir estornudos")
	f.elegir_mejora("fiebre")
	for i in 5:
		sala.aceptar(f, "tubo_plasma", 0, Vector2i(0, 0))
	f.elegir_mejora("frio")
	comprobar(f.cepa_entregado.is_empty(), "cambiar a una mejora que no pide plasma no guarda el plasma")
	var h := f.poner_muelle_envio(Vector2i(5, 5))
	h.destino = "india"
	for i in 10:
		h.aceptar(f, "caja_vacunas", 0, Vector2i(5, 5))
	comprobar(f.vacunas_vendidas == 10 and f.vendidas_destino.get("india", 0) == 10 and h.viajes == 1, "10 vacunas a la India, una furgoneta sale (%d €)" % int(f.ingresos))
	# mundo
	var m := Mundo.new()
	m.sembrar("europa_occ", 1.0)
	m.efectos = Mundo.efectos_de(["tos"])
	for i in 600:
		m.paso(1.0)
	comprobar(m.total("i") > 1.0, "la cepa se contagia sola (%.2f millones en 10 min)" % m.total("i"))
	comprobar(m.detectado and m.cura > 0.0, "la detectan y empieza la cura (%.3f)" % m.cura)
	comprobar(m.region("europa_este").i > 0.0, "salta a otras regiones por los viajes")
	var z0 := m.total("z")
	m.efectos = Mundo.efectos_de(["tos", "fiebre", "nauseas", "insomnio", "mordisco"])
	for i in 60:
		m.paso(1.0)
	comprobar(z0 == 0.0 and m.total("z") > 0.0, "con el mordisco aparecen zombis")

## V1.8: sala de espera, campañas y energía.
func _pacientes_y_energia() -> void:
	var f := Fabrica.new()
	f.espera_pacientes = 0
	_simular(f, 30.0)
	comprobar(f.espera_pacientes == 2, "sin sala caben 2 esperando (hay %d)" % f.espera_pacientes)
	f.poner_sala_espera(Vector2i(0, 0), 0)
	_simular(f, 30.0)
	comprobar(f.espera_pacientes == 6, "con una sala caben 6 (hay %d)" % f.espera_pacientes)
	var cam := f.poner_estacion("camilla", Vector2i(0, 3), 0)
	_simular(f, 0.1)
	comprobar(cam.llamado and f.espera_pacientes == 5, "la camilla llama a uno de la sala")
	_simular(f, 6.0)
	comprobar(cam.paciente, "el paciente llega andando y se tumba")
	var antes := f.llegada_cada()
	f.lanzar_campana(2.0, 60.0)
	comprobar(is_equal_approx(f.llegada_cada(), antes / 2.0), "la campaña duplica las llegadas")
	_simular(f, 61.0)
	comprobar(is_equal_approx(f.llegada_cada(), antes), "la campaña se acaba")
	f.demanda_kw = 40.0
	_simular(f, 0.1)
	comprobar(is_equal_approx(f.factor_energia, 0.5), "con 40 kW de 20 todo va a la mitad")
	f.poner_generador("generador", Vector2i(5, 5), 0)
	_simular(f, 0.1)
	comprobar(is_equal_approx(f.factor_energia, 1.0), "con un generador diésel vuelve a ir bien")
	var bio := f.poner_generador("biogas", Vector2i(8, 5), 0)
	comprobar(f.entregar(Vector2i(8, 5), "tubo_sangre", 0), "el biogás acepta sangre")
	_simular(f, 0.2)
	comprobar(bio.kw_actual == 150.0, "el biogás quemando da 150 kW")
	_simular(f, 4.0)
	comprobar(bio.kw_actual == 0.0, "sin sangre el biogás se apaga")

## V1.9: cápsula → tubería → centrífuga industrial → cinta con plasma; depósito.
func _tuberias_y_capsulas() -> void:
	var f := Fabrica.new()
	f.espera_pacientes = 4
	var cap := f.poner_capsula("capsula", Vector2i(0, 0), 0)
	f.poner_linea_tuberia([Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	var ci := f.poner_maquina("centrifuga_ind", Vector2i(4, 0), 0)
	ci.poner_receta("plasma_ind")
	var al := f.poner_almacen(Vector2i(6, 0), -1)
	for i in 3:
		cap.aceptar(f, "bolsa_suero", -1, Vector2i.ZERO)
	_simular(f, 30.0)
	comprobar(cap.humanos == 1, "la cápsula retiene a un paciente")
	comprobar(f.producido.get("sangre_l", 0) >= 25, "la cápsula da sangre por la tubería (%d l)" % f.producido.get("sangre_l", 0))
	comprobar(al.contenido.count("tubo_plasma") >= 10, "la centrífuga industrial saca plasma (%d)" % al.contenido.count("tubo_plasma"))
	comprobar(not f.entregar(Vector2i(1, 0), "tubo_sangre", 0), "por una tubería no entran objetos")
	var c2 := f.poner_cinta(Vector2i(0, 5), 0)
	comprobar(not c2.aceptar(f, "sangre_l", 0, Vector2i(0, 5)), "por una cinta no entran líquidos")
	_simular(f, 60.0)
	comprobar(not cap.activa(), "sin suero la cápsula para")
	var dep := f.poner_deposito(Vector2i(0, 8), 0)
	for i in 50:
		dep.aceptar(f, "sangre_l", -1, Vector2i.ZERO)
	f.poner_linea_tuberia([Vector2i(1, 8), Vector2i(2, 8)])
	var al2 := f.poner_generador("biogas", Vector2i(3, 8), 0)
	_simular(f, 5.0)
	comprobar(dep.litros < 50, "el depósito suelta sangre a la tubería")
	var granja := f.poner_capsula("granja", Vector2i(0, 12), 0)
	f.espera_pacientes = 4
	_simular(f, 1.0)
	comprobar(granja.humanos == 4 and granja.casillas.size() == 4, "la granja ocupa 4 casillas y retiene a 4")
