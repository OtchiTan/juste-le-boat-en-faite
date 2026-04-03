extends Node2D

@onready var decoration_layer: TileMapLayer = $DecorationLayer
@onready var rng := RandomNumberGenerator.new();

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass


func _on_world_gen_on_map_ready(terrains: Dictionary[int, Array]) -> void:
	var sand_tiles = terrains.get(1)
	var num_coconut_trees = sand_tiles.size() * 0.0075
	
	for i in num_coconut_trees:
		var tree = Vector2i(rng.randi_range(2,5), 0)
		var tile_location = sand_tiles[rng.randi_range(0, sand_tiles.size() - 1)];
		decoration_layer.set_cell(tile_location, 0, tree)
		
	var grass_tiles = terrains.get(0)
	var num_grass_decorations = grass_tiles.size() * 0.0075
	
	for i in num_grass_decorations:
		var decoration = Vector2i(rng.randi_range(0,2), 0)
		var tile_location = grass_tiles[rng.randi_range(0, grass_tiles.size() - 1)]
		decoration_layer.set_cell(tile_location, rng.randi_range(1,3), decoration)
