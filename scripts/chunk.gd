extends Node2D

@onready var sea_layer: TileMapLayer = $SeaLayer
@onready var noise: FastNoiseLite = FastNoiseLite.new();

const CHUNK_SIZE: Vector2i = Vector2i(100,100)

func _ready() -> void:
	noise.seed = 3630
	
	generate_map()
	
func _process(_delta: float) -> void:
	pass
	
func generate_map():
	for x in CHUNK_SIZE.x:
		for y in CHUNK_SIZE.y:
			sea_layer.set_cell(Vector2i(x,y),0,Vector2i(_get_tile_value(x,y),0))

func _get_tile_value(x:float, y:float) -> int:
	var result = 0
	
	result = ((noise.get_noise_2d(x, y) + 1.0) / 2.0) * 5.0
	
	return result
