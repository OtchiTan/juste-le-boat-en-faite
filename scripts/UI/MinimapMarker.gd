extends Node
class_name MinimapMarker

@export var marker_color: Color = Color.RED
@export var is_rect: bool = false
@export var marker_size: Vector2 = Vector2(4.0, 4.0)

@onready var parent: Node2D = get_parent()

func _ready():
	var uis = get_tree().get_nodes_in_group("minimap_ui")
	if not uis.is_empty():
		uis[0].register_marker(self)

func _exit_tree():
	var uis = get_tree().get_nodes_in_group("minimap_ui")
	if not uis.is_empty():
		uis[0].unregister_marker(self)
