extends CanvasLayer

@export var wind_particle: GPUParticles2D

var speed_multiplier : float = 250
var max_wind_strength : float = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.wind_changed.connect(_on_wind_changed)
	_on_wind_changed(GameManager.wind_direction)

func _on_wind_changed(wind_angle: float) -> void:
	var direction_x = cos(wind_angle)
	var direction_y = sin(wind_angle)
	wind_particle.process_material.direction = Vector3(direction_x, direction_y, 0)
	
	var current_wind_str = GameManager.wind_str - 1 #wind str between 1 and +inf
	wind_particle.process_material.initial_velocity_min = current_wind_str * speed_multiplier * 0.8
	wind_particle.process_material.initial_velocity_max = current_wind_str * speed_multiplier * 1.2
	
	wind_particle.amount_ratio = clamp(current_wind_str / max_wind_strength, 0.1, 1.0)
