class_name MapaHUD
extends Control
## Mini mapa del mundo en matriz de puntos: gris = sano, verde = infectado. El foco
## de infección crece desde la península ibérica (datos de muestra hasta la simulación).

const MAPA := [
	"..........................................................",
	".....XXXXXXXX........XX.......XXXXXXXXXXXXXXXXXXXX........",
	"...XXXXXXXXXXXXX....XXX....XXXXXXXXXXXXXXXXXXXXXXXXXX.....",
	"..XXXXXXXXXXXXXX.........XXXXXXXXXXXXXXXXXXXXXXXXXXXXX....",
	"....XXXXXXXXXXXX........XXXXXXXXXXXXXXXXXXXXXXXXXXXX......",
	".....XXXXXXXXXX.........XXXXXXXXXXXXXXXXXXXXXXXXXX.X......",
	"......XXXXXXXX.........XXXXXXXXXXXXXXXXXXXXXXXXXX.........",
	".......XXXXX...........XXXXXXXXXXXXXXXXXXXXXXXX..X........",
	"........XXX............XXXXXXXXXX..XXXXXXXXXXX..XX........",
	".........XX.XX.........XXXXXXXXXXX...XXXXXX...............",
	"............XXXXX.......XXXXXXXXXX....XXX..XX.............",
	"............XXXXXXX......XXXXXXXX......X...XXX............",
	".............XXXXXX.......XXXXXX............XXXX..........",
	"..............XXXXX.......XXXXXX..............X...........",
	"..............XXXX........XXXXX...........XXXXXX..........",
	"..............XXX..........XXX............XXXXXXX.........",
	"..............XX...........XX..............XXXXX..........",
	"..............X.................................XX........",
]
const FOCO := Vector2(23.5, 6.0)   # península ibérica

var infeccion := 0.05   # 0..1, radio del foco relativo
var _t := 0.0

func _process(dt: float) -> void:
	_t += dt
	queue_redraw()

func _draw() -> void:
	var filas := MAPA.size()
	var cols: int = MAPA[0].length()
	var paso := minf(size.x / cols, size.y / filas)
	var r := paso * 0.36
	var o := (size - Vector2(cols, filas) * paso) * 0.5 + Vector2(paso, paso) * 0.5
	var radio := 1.2 + infeccion * 30.0
	for y in filas:
		var fila: String = MAPA[y]
		for x in cols:
			if fila[x] != "X":
				continue
			var d := Vector2(x, y * 1.15).distance_to(Vector2(FOCO.x, FOCO.y * 1.15))
			var c := Color(0.5, 0.58, 0.62)
			if d < radio:
				var borde := clampf((radio - d) / 1.5, 0.0, 1.0)
				c = c.lerp(Color(0.55, 0.85, 0.25), borde)
			draw_circle(o + Vector2(x, y) * paso, r, c)
	# pulso en el foco
	var pc := o + FOCO * paso
	var k := fmod(_t * 0.8, 1.0)
	draw_arc(pc, paso * (1.0 + k * 4.0), 0, TAU, 24, Color(0.6, 0.95, 0.3, 0.7 * (1.0 - k)), 1.5, true)
