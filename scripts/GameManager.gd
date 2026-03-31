extends Node


var boats :Array[Boat]= []
var islands = []
signal game_won()
signal game_over()
signal player_has_more_islands()
signal update_life_hud(int)
signal wind_changed(float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


var elapsed_time_since_wind_changed = 0
var change_wind_time = 1
var wind_direction = randf_range(-PI,PI)
var wind_str = 100

func _process(delta: float) -> void:
	elapsed_time_since_wind_changed += delta
	if elapsed_time_since_wind_changed > change_wind_time :
		elapsed_time_since_wind_changed = 0
		wind_direction += randf_range(-0.1,0.1)
		for boat in boats :
			boat.wind_angle = wind_direction
			boat.wind_strenght = wind_str
		wind_changed.emit(wind_direction)
		
func register_boat(boat:Boat):
	boats.append(boat)
	if boat.player_id == 0:
		boat.getDamage.connect(_on_getDamage)
		emit_signal("update_life_hud", boat.life)
	FactionManager.register_faction(boat.player_id)

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
			island.change_owner(-1, false)
	if tireur.player_id == 0:
		emit_signal("player_has_more_islands")
	check_victory(boat, tireur)

func check_victory(boat, tireur):
	var own0 = islands[0].island_owner
	var is_all_same_owner = true
	for island in islands:
		if island.island_owner != own0:
			is_all_same_owner = false
			break
	if is_all_same_owner:
		if (tireur.player_id == 0):
			print("win")
			victory()
		else:
			print("lose - pas sensé etre atteint")
	
func _on_getDamage(i):
	emit_signal("update_life_hud", i)
	
func defeat():
	print("lose")
	emit_signal("game_over")
	
func victory():
	print("win")
	emit_signal("game_won")
