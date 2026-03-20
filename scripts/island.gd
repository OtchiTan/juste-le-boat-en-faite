extends Node

var island_owner : int = -1
var island_id : int
@onready var castle_player: Sprite2D = $castle_player
@onready var castle_ai: Sprite2D = $castle_ai

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.register_island(self)
	update_visual()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func change_owner(new_owner:int, isNeededToAwaitReady:bool)->void:
	island_owner = new_owner
	if isNeededToAwaitReady: # sinon ça plante la 1ere fois parce certais trucs sont pas chargésé
		await ready
	update_visual()
	
func update_visual() ->void:
	if island_owner == 0:
		castle_player.visible = true
		castle_ai.visible = false
	else:
		castle_player.visible = false
		castle_ai.visible = true
	
	
	
