extends Node


var boats :Array[Boat]= []
var islands = []
signal game_won()
signal game_over()
signal player_has_more_islands()
signal update_life_hud(int)
signal wind_changed(float)
signal gold_changed(new_amount: int)
signal game_ready()

var game_is_ready := false

var is_for_training := false

var player_gold: int = 0:
	set(value):
		player_gold = value
		gold_changed.emit(player_gold)

func _ready() -> void:
	
	var sync = get_tree().get_first_node_in_group("sync_node")
	
	if not sync or sync.control_mode == sync.ControlModes.TRAINING :
		game_is_ready = true
		game_ready.emit()


	pass # Replace with function body.

func reset() -> void:
	player_gold = 0
	boats.clear()
	islands.clear()
	
var elapsed_time_since_wind_changed = 0
var change_wind_time = 1
var wind_direction = randf_range(-PI,PI)
var wind_str = 2

func _process(delta: float) -> void:
	elapsed_time_since_wind_changed += delta
	if elapsed_time_since_wind_changed > change_wind_time and not is_for_training:
		elapsed_time_since_wind_changed = 0
		wind_direction += randf_range(-0.1,0.1)
		for boat in boats :
			if is_instance_valid(boat):
				boat.wind_angle = wind_direction
				boat.wind_strenght = wind_str
		wind_changed.emit(wind_direction)
		
func register_boat(boat:Boat):
	boats.append(boat)
	
	if boat.player_id == 0:
		boat.getDamage.connect(_on_getDamage)
		emit_signal("update_life_hud", boat.life)
	FactionManager.register_faction(boat.player_id)

var ctrl_count := 0
func count_ai_controller() :
	ctrl_count+= 1
	if ctrl_count == islands.size() *2 :
		game_ready.emit()
		game_is_ready = true
		
func register_island(island):
	islands.append(island)
	island.new_owner.connect(_on_new_owner)
	
func on_boat_destroyed(boat, tireur):
	if (boat._is_player):
		defeat()
	boats.erase(boat)
	var dead_player = boat.player_id
	if (tireur) :
		var new_owner = tireur.player_id
	for island in islands:
		if island.island_owner == dead_player and island.island_owner != 0 :
			island.change_owner(-1, false)

func check_victory(tireur_id):
	if islands.size() < 2:
		return # ça arrive a la construction
	var own0 = islands[0].island_owner
	var is_all_same_owner = true
	for island in islands:
		if island.island_owner != own0:
			is_all_same_owner = false
			break
	if is_all_same_owner:
		if (tireur_id == 0):
			print("win")
			victory()
		else:
			print("lose - pas sensé etre atteint")
	
func _on_getDamage(i):
	emit_signal("update_life_hud", i)
	
func _on_new_owner():
	emit_signal("player_has_more_islands")
	
func defeat():
	print("lose")
	emit_signal("game_over")
	
func victory():
	print("win")
	emit_signal("game_won")
