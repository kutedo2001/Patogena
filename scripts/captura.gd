extends Node
## Autoload de herramientas: con `-- --captura=ruta.png [--esperar=N]` guarda
## una captura del viewport tras N fotogramas y cierra el juego.

var _ruta := ""
var _esperar := 30
var _secuencia := 0   # nº de fotogramas a guardar (ruta_000.png...) para hacer GIF
var _hechos := 0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--captura="):
			_ruta = a.trim_prefix("--captura=")
		elif a.begins_with("--secuencia="):
			_secuencia = int(a.trim_prefix("--secuencia="))
		elif a.begins_with("--esperar="):
			_esperar = int(a.trim_prefix("--esperar="))
	set_process(_ruta != "")

func _process(_dt: float) -> void:
	_esperar -= 1
	if _esperar > 0:
		return
	var img := get_viewport().get_texture().get_image()
	if _secuencia > 0:
		img.save_png(_ruta.get_basename() + "_%03d.png" % _hechos)
		_hechos += 1
		_esperar = 2
		if _hechos < _secuencia:
			return
		get_tree().quit(0)
		return
	var err := img.save_png(_ruta)
	print("captura: ", _ruta, " (", img.get_width(), "x", img.get_height(), ") err=", err)
	get_tree().quit(0 if err == OK else 1)
