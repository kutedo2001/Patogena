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

## Las dos cadenas de la pantalla objetivo, con fuentes en lugar de extractores.
func _cadenas() -> void:
	print("Cadenas de la pantalla objetivo (5 min de juego):")
	var f := montar_cadenas()
	var cf: Fabrica.MaquinaSim = f.celdas[Vector2i(-9, -4)]
	var br: Fabrica.MaquinaSim = f.celdas[Vector2i(-6, -5)]
	var cepa: Fabrica.MaquinaSim = f.celdas[Vector2i(0, -5)]
	var sq: Fabrica.MaquinaSim = f.celdas[Vector2i(-5, 0)]
	var malo := Fabrica.new()
	malo.poner_fuente(Vector2i(-1, 0), 0, "garrafa_agua", 1.0)
	var mz2 := malo.poner_maquina("mezcladora", Vector2i(0, 0))
	for i in 100: malo.paso()
	comprobar(mz2.entrada.is_empty(), "la mezcladora no acepta agua por la boca del reactivo")
	var mz: Fabrica.MaquinaSim = f.celdas[Vector2i(-5, 3)]
	var ev: Fabrica.MaquinaSim = f.celdas[Vector2i(0, 0)]
	var palet: Fabrica.Almacen = f.celdas[Vector2i(7, 1)]
	comprobar(cf != null and br != null and cepa != null and sq != null and mz != null and ev != null and palet != null, "todo se coloca sin solaparse")
	var t0 := Time.get_ticks_msec()
	var primera := -1.0
	for i in int(300.0 / Fabrica.PASO):
		f.paso()
		if primera < 0.0 and f.mutaciones > 0:
			primera = f.tiempo
	var ms := Time.get_ticks_msec() - t0
	print("    producido: ", f.producido)
	print("    primera mutación a los %.1f s · palé con %d cajas · %d ms reales (×%d)" % [primera, palet.contenido.size(), ms, int(300000.0 / maxf(ms, 1))])
	comprobar(f.producido.get("tubo_plasma", 0) > 0, "las centrífugas hacen plasma")
	comprobar(f.mutaciones >= 1, "la cámara de cepa recibe al menos una mutación")
	comprobar(f.producido.get("tubo_adn", 0) > 0 and f.producido.get("bolsa_suero", 0) > 0, "secuenciador y mezcladora producen")
	comprobar(palet.contenido.size() >= 30 and palet.contenido[0] == "caja_vacunas:tos", "las cajas de vacunas llevan la mutación y llegan al palé sin atascos (≥30)")
	comprobar(ms < 3000, "5 min de juego se simulan en menos de 3 s (×100)")

## Las dos cadenas de la pantalla objetivo con fuentes en lugar de extractores (también la usa la vista esquemática).
static func montar_cadenas() -> Fabrica:
	var f := Fabrica.new()
	# cepa: sangre → centrífuga → plasma → biorreactor → vial → cámara de cepa
	f.poner_fuente(Vector2i(-13, -4), 0, "tubo_sangre", 1.5)
	f.poner_linea([Vector2i(-12, -4), Vector2i(-11, -4), Vector2i(-10, -4)])
	f.poner_maquina("centrifuga", Vector2i(-9, -4))
	f.poner_linea([Vector2i(-8, -4), Vector2i(-7, -4)])
	f.poner_maquina("biorreactor", Vector2i(-6, -5))
	f.poner_linea([Vector2i(-4, -4), Vector2i(-3, -4), Vector2i(-2, -4), Vector2i(-1, -4)])
	f.poner_maquina("camara_cepa", Vector2i(0, -5))
	# vacunas: cultivo → secuenciador → ADN; agua + reactivo → mezcladora → suero; → envasadora
	f.poner_fuente(Vector2i(-12, 1), 0, "placa_petri", 2.0)
	f.poner_linea([Vector2i(-11, 1), Vector2i(-10, 1), Vector2i(-9, 1), Vector2i(-8, 1), Vector2i(-7, 1), Vector2i(-6, 1)])
	f.poner_maquina("secuenciador", Vector2i(-5, 0))
	f.poner_linea([Vector2i(-3, 1), Vector2i(-3, 0)], 1, 3)
	f.poner_almacen(Vector2i(-3, -1))                                   # el ADN se guarda (irá a mutaciones)
	f.poner_fuente(Vector2i(-2, 0), 0, "vial_mutacion:tos", 4.0)      # viales con mutación para las vacunas
	f.poner_cinta(Vector2i(-1, 0), 0)
	f.poner_fuente(Vector2i(-12, 4), 0, "garrafa_agua", 3.0)
	f.poner_linea([Vector2i(-11, 4), Vector2i(-10, 4), Vector2i(-9, 4), Vector2i(-8, 4), Vector2i(-7, 4)])
	f.poner_cinta(Vector2i(-6, 4), 0)
	f.poner_fuente(Vector2i(-8, 2), 1, "frasco_reactivo", 3.0)       # el reactivo entra por la otra casilla de la cara
	f.poner_linea([Vector2i(-8, 3), Vector2i(-7, 3), Vector2i(-6, 3)], 1, 0)
	f.poner_maquina("mezcladora", Vector2i(-5, 3))
	f.poner_linea([Vector2i(-3, 3), Vector2i(-2, 3), Vector2i(-1, 3), Vector2i(-1, 2), Vector2i(-1, 1)], 1, 0)   # suero a su boca
	f.poner_maquina("envasadora", Vector2i(0, 0))
	f.poner_linea([Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1)])
	f.poner_almacen(Vector2i(7, 1))
	return f

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

## El ascensor acepta solo lo que pide la fase y la completa; el hub vende vacunas con mutación.
func _ascensor_y_hub() -> void:
	print("Ascensor de pedidos y hub:")
	var f := Fabrica.new()
	var a := f.poner_ascensor(Vector2i(0, 0))
	f.poner_fuente(Vector2i(-2, 0), 0, "tubo_plasma", 0.3)
	f.poner_cinta(Vector2i(-1, 0), 0)
	comprobar(not a.aceptar(f, "tubo_sangre", 0, Vector2i(0, 0)), "el ascensor no acepta lo que no pide")
	_simular(f, 40.0)
	comprobar(a.completadas == 1 and a.fase == 1, "30 plasmas completan la fase 1")
	var h := f.poner_muelle_envio(Vector2i(5, 5))
	for i in 10:
		h.aceptar(f, "caja_vacunas:tos", 0, Vector2i(5, 5))
	comprobar(f.vendidas_con.get("tos", 0) == 10 and h.viajes == 1, "10 vacunas de tos vendidas, una furgoneta sale (%d €)" % int(f.ingresos))
