extends CanvasLayer

@onready var progress_bar: ProgressBar = $ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = true
	add_to_group("loading_screen")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func close_loading_screen() -> void:
	progress_bar.value = 100
	
	await get_tree().create_timer(0.5).timeout
	
	visible = false
