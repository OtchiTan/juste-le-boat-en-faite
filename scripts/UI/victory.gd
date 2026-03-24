extends CanvasLayer

@onready var label = $Label

func _ready():
	visible = false
	GameManager.game_won.connect(_on_game_won)

func _on_game_won():
	visible = true
	label.text = "VICTOIRE !"
