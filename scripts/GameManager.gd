extends Node


var boats = []
var islands = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func register_boat(boat):
	boats.append(boat)

func register_island(island):
	islands.append(island)
	
func on_boat_destroyed(boat, tireur):
	boats.erase(boat)
	var dead_player = boat.player_id
	var new_owner = tireur.player_id
	for island in islands:
		if island.island_owner == dead_player:
			island.change_owner(new_owner, false)
