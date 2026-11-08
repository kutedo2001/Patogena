extends Node3D
## Escena principal provisional (P3.2): comprueba que el proyecto arranca,
## dibuja y exporta. La cámara, luz y suelo definitivos llegan en P3.3.

@onready var titulo: Label = $HUD/Titulo

func _ready() -> void:
	titulo.text = tr("JUEGO_TITULO")
