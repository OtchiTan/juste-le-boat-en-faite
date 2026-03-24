extends Node


var boats = []
var islands = []
signal game_won()
signal game_over()
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
	if (boat.player_id == 0):
		defeat()
	boats.erase(boat)
	var dead_player = boat.player_id
	var new_owner = tireur.player_id
	for island in islands:
		if island.island_owner == dead_player:
			island.change_owner(new_owner, false)
	check_victory(boat, tireur)

func check_victory(boat, tireur):
	# check rapide qui fonctionne avec le fonctionnement actuel
	if (boats.size() <= 1): 
		if (tireur.player_id == 0):
			victory()
		else:
			print("lose - pas sensé etre atteint")
			defeat()
			
	#check plus complet si on a toutes les iles
	#var own0 = islands[0].island_owner
	#var is_all_same_owner = true
	#for island in islands:
	#	if island.island_owner != own0:
	#		is_all_same_owner = false
	#		break
	#if is_all_same_owner:
	#	if (tireur.player_id == 0):
	#		print("win")
	#	else:
	#		print("lose - pas sensé etre atteint")
	
	
func defeat():
	print("lose")
	emit_signal("game_over")
	
func victory():
	print("win")
	emit_signal("game_won", )
