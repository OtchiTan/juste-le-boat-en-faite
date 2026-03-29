extends AIController2D

class_name AIControllerWithRaycast

var move = Vector2.ZERO

@onready var boat: Boat = $".."
@export var obs_frame_stack: int = 1
var raycast_sensor_2d:RaycastSensor2D_extended
var lastDist = -1
var c_frame_obs = []
var obs_history: Array[Array]
var cumulated_rewar = 0
var reset_with_time:bool = true
#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	c_frame_obs = raycast_sensor_2d.get_observation()
	
	if obs_history.is_empty():
		obs_history.resize(obs_frame_stack)
		obs_history.fill(c_frame_obs)
	c_frame_obs.append(move.x)
	c_frame_obs.append(move.y)
	obs_history.append(c_frame_obs)
	obs_history.remove_at(0)
	
	var stacked_obs :Array[float]= [
		randf() *2 - 1
	]

	for obs_array in obs_history:
		stacked_obs.append_array(obs_array)

	return {"obs": stacked_obs}

func get_reward() -> float:
	return reward


func get_action_space() -> Dictionary:
	var dict = {
		"shoot": {"size": 2, "action_type": "discrete"},
		"rotate_left_right": { "size": 3,  "action_type": "discrete" },
		"accelerate_decelerate": { "size": 3, "action_type": "discrete"},
	}
	dict.sort()
	return dict
	
func set_action(action) -> void:
	var newx = action["rotate_left_right"] - 1
	var newy = action["accelerate_decelerate"] - 1
	#
	#if (newx != move.x) :
	#	reward -= 0.1
	#if (newy != move.y) :
	#	reward -= 0.1
	move.x = newx
	move.y = newy
	boat.throttle = move.x
	boat.steering = move.y
	
	boat.want_to_shoot = action["shoot"]
	
	if boat.want_to_shoot :
		reward -= 10
		cumulated_rewar -= 10

func _physics_process(delta):
	if (not reset_with_time) :
		n_steps = -1
	super._physics_process(delta)
	if (needs_reset) : 
		reset()
	if (ControlModes.HUMAN == control_mode):
			move.y = Input.get_action_strength("right") - Input.get_action_strength("left")
			move.x = Input.get_action_strength("up") - Input.get_action_strength("down")
			boat.want_to_shoot = Input.get_action_strength("attack")
			boat.throttle = move.x
			boat.steering = move.y


	var min_w_dist = 1
	for i in range(0, c_frame_obs.size(), 4) :
		if c_frame_obs[i+1] == 0.0 and c_frame_obs[i] < min_w_dist :
			min_w_dist = c_frame_obs[i]
	
	#reward -= (1- min_w_dist) *0.1 * (1- min_w_dist) 
	#cumulated_rewar -= (1-min_w_dist) *0.1 * (1- min_w_dist) 
		
	#reward -= target_dist *0.00001
	#cumulated_rewar -= target_dist *0.00001
	var forward_dir = boat.global_transform.x.normalized()
	
	if (boat.target) : 
		var target_dist = (boat.target.global_position - boat.global_position).length_squared()
		var dir_to_target = (boat.target.global_position - boat.global_position).normalized()
		# 2. Vecteur "avant" du bateau (sur Godot 2D, c'est souvent global_transform.x)
		# 3. Produit scalaire
		var dot = forward_dir.dot(dir_to_target)
		#if (dot>0) : 
		#	reward += dot * dot * 0.01
		#	cumulated_rewar += dot * dot *0.01
		#else :
		#	reward += dot * dot * 0.001
		#	cumulated_rewar += dot * dot *0.001
	
	var speed = boat.linear_velocity.length()
	
	#reward += speed *0.001
	#cumulated_rewar += speed * 0.001
	super._physics_process(delta)
	
func reset():
	super.reset()
	obs_history.clear()
	cumulated_rewar = 0
	boat.reset()
	
	
func _ready():
	super._ready()
	
	boat.on_dealt_damages.connect(on_dealt_damages)
	boat.dont_die_on_life_equal_0 = true
	
	reset_after = 60 * 60 * 5


func OnSetControlMode(newvalue) :
	boat.is_training = newvalue == ControlModes.TRAINING
	boat.is_training = true

func on_dealt_damages(dmg_amount: float, targeted_boat: Boat) :
	var delta_r = dmg_amount
	delta_r += 100 if targeted_boat.life <= 0 else 0
	
	var other_controller = targeted_boat.controller
	match FactionManager.get_relation(boat, targeted_boat) :
		FactionManager.Relation.ENEMY :
			reward += delta_r * 10
			cumulated_rewar +=  delta_r * 10
			other_controller.reward -= delta_r
			other_controller.cumulated_rewar -= delta_r
		FactionManager.Relation.ALLY :
			reward -= delta_r
			cumulated_rewar -=delta_r
	
	if ( targeted_boat.life <= 0) :
		other_controller.needs_reset = true
		other_controller.done = true
		needs_reset = true
		done = true

func update(delta:float):
	pass
	
	
	
