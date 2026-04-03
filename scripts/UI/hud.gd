extends CanvasLayer

@export var life_label: Label
@export var island_label: Label
@export var gold_label: Label # À assigner dans l'inspecteur Godot

func _on_gold_changed(amount: int) -> void:
	gold_label.text = str(amount)

func _on_getDamage(i):
	life_label.text = str(i)

func update_island() -> void :
	var i = 0
	for island in GameManager.islands:
		if island.island_owner == 0 :
			i += 1
	island_label.text = str(i)

func _on_wind_change(newAngle:float) :
	$VBoxContainer/WindNode/TextureRect.rotation = newAngle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.update_life_hud.connect(_on_getDamage)
	GameManager.player_has_more_islands.connect(update_island)
	GameManager.wind_changed.connect(_on_wind_change)
	_on_wind_change(GameManager.wind_direction)
	GameManager.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(GameManager.player_gold) # Initialisation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
