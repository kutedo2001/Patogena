class_name Sonido
extends Node
## Sonido del juego (V1.11): efectos sueltos con un grupo de reproductores, ambiente de la sala y
## música en bucle. Todo sintetizado por tools/sonidos.py. Volúmenes en las opciones (se guardan).

static var yo: Sonido
const EFECTOS := ["clic", "pulsador", "construir", "quitar", "vender", "error", "pinchazo", "tubo_lleno",
	"mejora", "anuncio", "furgoneta", "zombi"]

var vol_efectos := 0.8
var vol_musica := 0.5
var _flujos := {}
var _grupo: Array[AudioStreamPlayer] = []
var _musica: AudioStreamPlayer
var _ambiente: AudioStreamPlayer
var _ultimo := {}

func _ready() -> void:
	yo = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in EFECTOS:
		_flujos[n] = load("res://assets/sonido/%s.wav" % n)
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_grupo.append(p)
	_musica = _bucle("musica")
	_ambiente = _bucle("ambiente")
	aplicar_volumen()

func _bucle(nombre: String) -> AudioStreamPlayer:
	var w: AudioStreamWAV = load("res://assets/sonido/%s.wav" % nombre)
	w = w.duplicate()
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = int(w.data.size() / 2.0)      # 16 bits mono: 2 bytes por muestra
	var p := AudioStreamPlayer.new()
	p.stream = w
	add_child(p)
	p.play()
	return p

func aplicar_volumen() -> void:
	_musica.volume_db = linear_to_db(maxf(vol_musica * 0.55, 0.0001))
	_ambiente.volume_db = linear_to_db(maxf(vol_efectos * 0.35, 0.0001))

## Toca un efecto (no repite el mismo más de una vez cada 60 ms).
static func tocar(nombre: String, vol := 1.0, tono := 1.0) -> void:
	if yo == null or not yo._flujos.has(nombre):
		return
	var ahora := Time.get_ticks_msec()
	if ahora - int(yo._ultimo.get(nombre, -1000)) < 60:
		return
	yo._ultimo[nombre] = ahora
	for p in yo._grupo:
		if not p.playing:
			p.stream = yo._flujos[nombre]
			p.volume_db = linear_to_db(maxf(vol * yo.vol_efectos, 0.0001))
			p.pitch_scale = tono
			p.play()
			return
