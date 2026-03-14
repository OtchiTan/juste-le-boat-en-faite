extends Node2D

@onready var sea_layer: TileMapLayer = $SeaLayer
@onready var noise: FastNoiseLite = FastNoiseLite.new();

var island_locations: Array[Vector2i] = []
var terrains: Dictionary[int, Array] = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var thread: Thread

@export var island_number: int = 4
@export var distance_curve: Curve
@export var map_size: Vector2i = Vector2i(170,100)

func _ready() -> void:
	noise.seed = 3630
	
	spawn_islands()
	
	thread = Thread.new()
	thread.start(generate_map.bind())
	
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
	
func _get_tile_value(index: Vector2i) -> int:
	var result = 0
	
	var nearest_island = _get_nearest_position(index);
	var island_distance = nearest_island.distance_to(index) / map_size.x;
	var distance_sample = distance_curve.sample(island_distance)
	var noise_value = (noise.get_noise_2d(index.x, index.y) + 1.0) / 2.0
	
	result = roundi((distance_sample + noise_value) * 2.5)
	#result = roundi((distance_sample ) * 5.0)
	result = clampi(result, 0, 4)
	
	return result
	
func spawn_islands():
	for i in island_number:
		var island = Vector2i(
			rng.randi_range(0, map_size.x),
			rng.randi_range(0, map_size.y)
		)
		
		var valid_island = false
		while (!valid_island):
			valid_island = true
			for existing_island in island_locations:
				if existing_island.distance_squared_to(island) < 400:
					valid_island = false
					island = Vector2i(
						rng.randi_range(0, map_size.x),
						rng.randi_range(0, map_size.y)
					)
				
		
		island_locations.push_back(island)
	
func _get_nearest_position(index: Vector2i) -> Vector2i:
	var nearest_length = 9999999.0
	var nearest_location = Vector2i(-1,-1)
	
	for island in island_locations:
		var island_length = island.distance_squared_to(index)
		if (island_length < nearest_length):
			nearest_location = island
			nearest_length = island_length
	
	return nearest_location
