extends Control

@export var track_player: Node2D
@export_group("World Settings")

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

func setup_map_data(grid_size: Vector2i, terrain_map: Dictionary, islands_data: Dictionary, real_world_size: Vector2, initial_colors: Dictionary) -> void:
	_map_size = grid_size
	_island_tiles = islands_data
	world_size = real_world_size * 2
	
	_calculate_stretch_scale()
	_generate_texture(terrain_map, initial_colors)
	
	var loading_screen = get_tree().get_first_node_in_group("loading_screen")
	if loading_screen != null:
		loading_screen.close_loading_screen()

func _generate_texture(terrain_map: Dictionary, initial_colors: Dictionary) -> void:
	_minimap_image = Image.create(_map_size.x, _map_size.y, false, Image.FORMAT_RGBA8)
	var water_color = Color(0, 0, 0, 0)
	var default_land_color = Color("c2b280")

	var tile_to_island: Dictionary = {}
	for island_id in _island_tiles:
		for tile in _island_tiles[island_id]:
			tile_to_island[tile] = island_id

	for x in _map_size.x:
		for y in _map_size.y:
			var pos = Vector2i(x, y)
			if terrain_map.has(pos) and terrain_map[pos] == 0:
				if tile_to_island.has(pos):
					var id = tile_to_island[pos]
					_minimap_image.set_pixel(x, y, initial_colors.get(id, default_land_color))
				else:
					_minimap_image.set_pixel(x, y, default_land_color)
			else:
				_minimap_image.set_pixel(x, y, water_color)

	_map_texture = ImageTexture.create_from_image(_minimap_image)
	queue_redraw()

func change_island_color(island_id: int, new_color: Color) -> void:
	if not _island_tiles.has(island_id) or _minimap_image == null: 
		return
		
	for pixel in _island_tiles[island_id]:
		_minimap_image.set_pixel(pixel.x, pixel.y, new_color)
		
	_map_texture.update(_minimap_image)
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
