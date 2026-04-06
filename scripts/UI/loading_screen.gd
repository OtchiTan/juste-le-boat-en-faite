extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true
	add_to_group("loading_screen")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func close_loading_screen() -> void:		
	visible = false
