extends CanvasLayer

@onready var label = $Label

func _ready():
	visible = false
	
	GameManager.game_over.connect(_on_game_over)

func _on_game_over():
	visible = true
	label.text = "DÉFAITE !"
