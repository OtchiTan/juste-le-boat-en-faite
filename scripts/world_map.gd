extends Node2D

@onready var sea_layer: TileMapLayer = $SeaLayer
@onready var terrain_noise: FastNoiseLite = FastNoiseLite.new();
@onready var sea_noise: FastNoiseLite = FastNoiseLite.new();

var island_locations: Array[Vector2i] = []
var terrains: Dictionary[int, Array] = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var thread: Thread

@export var island_number: int = 4
@export var island_size: float = 40.0
@export var map_size: Vector2i = Vector2i(170,100)
@export var island_scene: PackedScene
@export var boat_scene: PackedScene
@export var boat_offset: float = 900.0

func _ready() -> void:
	terrain_noise.seed = 3630
	terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	sea_noise.seed = 67
	sea_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	
	spawn_islands()
	
	thread = Thread.new()
	thread.start(generate_map.bind())


func spawn_island_objects():
	for i in island_locations.size(): #island_pos in island_locations:
		var island_instance = island_scene.instantiate()
		island_instance.change_owner(i, true)
		var world_pos = sea_layer.map_to_local(island_locations[i])
		island_instance.position = world_pos
		add_child(island_instance)
		spawn_boat_around_island(world_pos, i)
	
func spawn_boat_around_island(island_pos: Vector2, i:int):
	var boat_instance = boat_scene.instantiate()
	var attempt = 0
	var random_direction = Vector2.RIGHT.rotated(rng.randf_range(0, TAU))
	var tile_pos = sea_layer.local_to_map(island_pos + (random_direction * boat_offset))
	while(_get_tile_value(tile_pos) < 2 and attempt <10):
		print(random_direction)
		attempt +=1
		print("fail")
		random_direction = Vector2.RIGHT.rotated(rng.randf_range(0, TAU))
		tile_pos = sea_layer.local_to_map(island_pos + (random_direction * boat_offset))
	
	if (attempt >= 10):
		print("give up")
		var water_tiles = terrains.get(2, [])
		var rand_water = rng.randi_range(0, water_tiles.size()-1)
		boat_instance.position = water_tiles[rand_water]
	else:
		boat_instance.position = island_pos + (random_direction * boat_offset)
	boat_instance.set_as_player_and_id(i)
	add_child(boat_instance)
	
	
func _exit_tree() -> void:
	thread.wait_to_finish()
	
func _process(_delta: float) -> void:
	pass
	
func generate_map():
	for x in map_size.x:
		for y in map_size.y:
			var index = Vector2i(x,y)
			var terrain = _get_tile_value(index);
			terrains.get_or_add(terrain, []).push_back(index)
	
	call_deferred("render_terrain")

func render_terrain():
	for terrain in terrains:
		sea_layer.set_cells_terrain_connect(terrains.get(terrain), 0,terrain)
	spawn_island_objects()
	
func _get_tile_value(index: Vector2i) -> int:
	var result = 0
	
	var nearest_island = _get_distance_to_nearest_island(index);
	var island_distance = nearest_island / pow(island_size, 2);
	island_distance += terrain_noise.get_noise_2d(index.x, index.y)
	result = clampi(island_distance, 0, 4)
	
	if result > 2:
		result = 2 + (sea_noise.get_noise_2d(index.x,index.y) + 1)
	
	return result
	
func spawn_islands():
	var grid_size = sqrt(island_number)
	var cell_width = map_size.x / grid_size
	var cell_height = map_size.y / grid_size
	
	for i in range(grid_size):
		for j in range(grid_size):
			# Position de base au centre de la cellule
			var base_x = i * cell_width + (cell_width / 2.0)
			var base_y = j * cell_height + (cell_height / 2.0)
			
			# On ajoute du "jitter" (variation) pour que ça ne fasse pas trop grille
			# On limite le jitter à 30-40% de la taille de la cellule
			var offset_x = rng.randf_range(-cell_width * 0.3, cell_width * 0.3)
			var offset_y = rng.randf_range(-cell_height * 0.3, cell_height * 0.3)
			
			island_locations.push_back(Vector2i(base_x + offset_x, base_y + offset_y))
	
func _get_distance_to_nearest_island(index: Vector2i) -> float:
	var nearest_distance = 999999999.0
	
	for island in island_locations:
		var island_length = island.distance_squared_to(index)
		if (island_length < nearest_distance):
			nearest_distance = island_length
	
	return nearest_distance
