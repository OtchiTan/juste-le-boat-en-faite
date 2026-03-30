extends Control

@export var track_player: Node2D
@export_group("World Settings")
@export var world_size: Vector2 = Vector2(11200, 6400) 

var _computed_scale: Vector2 = Vector2.ONE 
var active_markers: Array[MinimapMarker] = []

func _ready():
	add_to_group("minimap_ui")
	call_deferred("_calculate_stretch_scale")

func _calculate_stretch_scale():
	if size.x == 0 or size.y == 0 or world_size.x == 0 or world_size.y == 0:
		return
	_computed_scale = Vector2(size.x / world_size.x, size.y / world_size.y)

func register_marker(marker: MinimapMarker):
	if not active_markers.has(marker):
		active_markers.append(marker)

func unregister_marker(marker: MinimapMarker):
	active_markers.erase(marker)

func _process(_delta):
	queue_redraw()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))

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
