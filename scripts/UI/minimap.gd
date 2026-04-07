extends Control

@export_group("World Settings")
@export var default_sand_color: Color = Color("c2b280")
@export var default_water_color: Color = Color(0, 0, 0, 0)
@export var default_grass_color: Color = Color("60992dff")

var world_size: Vector2 = Vector2.ZERO
var _computed_scale: Vector2 = Vector2.ONE 
var active_markers: Array[MinimapMarker] = []

var _map_size: Vector2i
var _island_tiles: Dictionary
var _minimap_image: Image
var _map_texture: ImageTexture

func _ready():
	add_to_group("minimap_ui")

func _calculate_stretch_scale():
	if size.x == 0 or size.y == 0 or world_size.x == 0 or world_size.y == 0:
		return
	_computed_scale = Vector2(size.x / world_size.x, size.y / world_size.y)

func setup_map_data(grid_size: Vector2i, terrains_dict: Dictionary, islands_data: Dictionary, real_world_size: Vector2) -> void:
	_map_size = grid_size
	_island_tiles = islands_data
	world_size = real_world_size * 2
	
	_calculate_stretch_scale()
	_generate_texture(terrains_dict)
	
	var loading_screen = get_tree().get_first_node_in_group("loading_screen")
	if loading_screen != null:
		loading_screen.close_loading_screen()

func _generate_texture(terrains_dict: Dictionary) -> void:
	_minimap_image = Image.create(_map_size.x, _map_size.y, false, Image.FORMAT_RGBA8)
	
	_minimap_image.fill(default_water_color)

	for terrain_id in terrains_dict:
		var current_color = default_water_color
		
		if terrain_id == 0:
			current_color = default_grass_color
		elif terrain_id == 1:
			current_color = default_sand_color
			
		if current_color != default_water_color:
			for pos in terrains_dict[terrain_id]:
				if pos.x >= 0 and pos.x < _map_size.x and pos.y >= 0 and pos.y < _map_size.y:
					_minimap_image.set_pixel(pos.x, pos.y, current_color)

	_map_texture = ImageTexture.create_from_image(_minimap_image)
	queue_redraw()

func register_marker(marker: MinimapMarker):
	if not active_markers.has(marker):
		active_markers.append(marker)

func unregister_marker(marker: MinimapMarker):
	active_markers.erase(marker)

func _process(_delta):
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.2, 0.4, 0.6, 0.8))

	if _map_texture:
		draw_texture_rect(_map_texture, Rect2(Vector2.ZERO, size), false)

	for marker in active_markers:
		var world_pos = marker.parent.global_position
		var map_pos = world_pos * _computed_scale

		if marker.is_rect:
			var rot = marker.parent.global_rotation
			draw_set_transform(map_pos, rot, Vector2.ONE)
			
			var scaled_size = marker.marker_size * _computed_scale
			var rect = Rect2(-scaled_size / 2.0, scaled_size)
			draw_rect(rect, marker.marker_color)
			
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var scaled_radius = marker.marker_size.x * _computed_scale.x
			draw_circle(map_pos, scaled_radius, marker.marker_color)
