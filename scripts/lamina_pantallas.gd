extends Control
## Lámina de revisión: las tres pantallas en sus estados, a tamaño grande.

func _ready() -> void:
	var tipos := [[PantallaMaquina.Tipo.CENTRIFUGA, 2.4], [PantallaMaquina.Tipo.SECUENCIADOR, 2.3], [PantallaMaquina.Tipo.BIORREACTOR, 1.4]]
	var estados := [1, 2, 3]
	var y := 20.0
	for t in tipos:
		var x := 20.0
		var w := 600.0
		var h: float = w / t[1]
		if h > 330:
			h = 330.0
			w = h * t[1]
		for e in estados:
			var p := PantallaMaquina.new()
			p.tipo = t[0]
			p.estado = e
			p.velocidad = 1.0
			p.progreso = 0.62
			p.color_producto = Color(0.5, 0.95, 0.2)
			p.entradas = 0 if e == 2 else 4
			p.position = Vector2(x, y)
			p.size = Vector2(w, h)
			add_child(p)
			x += w + 20
		y += h + 20
