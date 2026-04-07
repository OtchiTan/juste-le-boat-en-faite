extends CanvasLayer

@onready var label = $PanelContainer/VBoxContainer/Label

func _ready():
	visible = false
	GameManager.game_won.connect(_on_game_won)

func _on_game_won():
	visible = true
	get_tree().paused = true
	label.text = "VICTOIRE !"


func _on_button_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/UI/MainMenu.tscn")
