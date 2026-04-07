extends CanvasLayer

@onready var label = $PanelContainer/VBoxContainer/Label
func _ready():
	visible = false
	GameManager.game_over.connect(_on_game_over)

func _on_game_over():
	visible = true
	get_tree().paused = true
	label.text = "DÉFAITE !"


func _on_button_main_menu_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/UI/MainMenu.tscn")
