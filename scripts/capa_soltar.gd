class_name CapaSoltar
extends Control
## Capa a pantalla completa, detrás de los paneles del HUD, que solo atrapa el ratón mientras
## se arrastra algo: al soltar sobre el mundo, el científico lleva lo arrastrado ahí.

var juego: Juego

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_BEGIN:
		mouse_filter = Control.MOUSE_FILTER_STOP
	elif what == NOTIFICATION_DRAG_END:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func _can_drop_data(_p: Vector2, d: Variant) -> bool:
	return d is Dictionary and d.has("de")

func _drop_data(p: Vector2, d: Variant) -> void:
	var c = juego._casilla_raton(get_global_transform_with_canvas() * p)
	if c == null:
		return
	soltar_en(juego.fab.celdas.get(c), d)

## También lo usa la prueba automática.
func soltar_en(e, d: Dictionary) -> void:
	if e == null:
		return
	var tareas: Array = []
	if d.has("i"):
		juego.mano_i = d.i              # la casilla arrastrada pasa a la mano
	if d.de is Fabrica.Entidad:
		tareas.append(["coger", d.de, d.get("objeto", "")])
	if not (d.de is Fabrica.Entidad) or e != d.de:
		tareas.append(["dejar", e])
	juego.encargar(tareas)
