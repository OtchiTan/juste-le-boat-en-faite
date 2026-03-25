extends AIController2D


var move = Vector2.ZERO
@onready var raycast_sensor_2d: RaycastSensor2D_extended = $"../RaycastSensor2D"
@onready var character: CharacterBody2D = $".."
@onready var target: Area2D = $"../../Target"

@export var obs_frame_stack: int = 3

var lastDist = -1

var obs_history: Array[Array]

#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	var c_frame_obs = raycast_sensor_2d.get_observation()
	
	if obs_history.is_empty():
		obs_history.resize(obs_frame_stack)
		obs_history.fill(c_frame_obs)
	c_frame_obs.append(move.x)
	c_frame_obs.append(move.y)
	obs_history.append(c_frame_obs)
	obs_history.remove_at(0)
	
	var stacked_obs :Array[float]= [
		character.CanCollect,
		randf() *2 - 1
	]

	for obs_array in obs_history:
		stacked_obs.append_array(obs_array)

	return {"obs": stacked_obs}

func get_reward() -> float:
	return reward


func get_action_space() -> Dictionary:
	var dict = {
		"eat": {"size": 2, "action_type": "discrete"},
		"move_left_right": { "size": 3,  "action_type": "discrete" },
		"move_up_down": { "size": 3, "action_type": "discrete"},
	}
	dict.sort()
	return dict
	
func set_action(action) -> void:
	var newx = action["move_left_right"] - 1
	var newy = action["move_up_down"] - 1
	if (newx != move.x) :
		reward -= 1
	if (newy != move.y) :
		reward -= 1
	move.x = newx
	move.y = newy
	
	var want_to_eat = action["eat"]
	
	_attempt_to_eat()
func _attempt_to_eat():
	if character.CanCollect :
		reward += 1500
		target.reset_pos()
		lastDist = (target.position - character.position).length_squared()

func _physics_process(delta):
	if (ControlModes.HUMAN == control_mode):
			move.x = Input.get_action_strength("right") - Input.get_action_strength("left")
			move.y = Input.get_action_strength("up") - Input.get_action_strength("down")
		
		
	var dist = (target.position - character.position).length_squared()
	var delta_dist = lastDist - dist
	#if lastDist != -1 : 
		#reward += delta_dist / 10000
	lastDist = dist
	super._physics_process(delta)
	
func reset():
	super.reset()
	lastDist = (target.position - character.position).length_squared()
	obs_history.clear()
	
