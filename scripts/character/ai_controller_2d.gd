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
	
	var forward_vector = boat.global_transform.x
	
	if obs_history.is_empty():
		obs_history.resize(obs_frame_stack)
		obs_history.fill(c_frame_obs)
	
	var normalized_rot_speed = boat.angular_velocity / 3 # Entre -1 et 1
	var normalized_speed = boat.linear_velocity.length() / 250 # Entre 0 et 1
	var normalized_speed_angle = forward_vector.angle_to(boat.linear_velocity) / PI
	
	c_frame_obs.append(normalized_rot_speed)
	c_frame_obs.append(normalized_speed)
	c_frame_obs.append(normalized_speed_angle)
	
	obs_history.append(c_frame_obs)
	obs_history.remove_at(0)
	
	var stacked_obs :Array[float]= []
	
	var min_w_dist = 2
	for i in range(0, (raycast_sensor_2d.n_rays /raycast_sensor_2d.ray_groupping) * 9 , 9) :
		if c_frame_obs[i+1] == 0.0  and c_frame_obs[i] < min_w_dist:
			min_w_dist = c_frame_obs[i]

	if min_w_dist < 0.3 :
		var inv_min = (1- min_w_dist)
		var inv_min2 = inv_min * inv_min
		var delta_r = inv_min2 * inv_min2
		reward -= delta_r
		cumulated_rewar -= delta_r
	
	for obs_array in obs_history:
		stacked_obs.append_array(obs_array)
	
	
	stacked_obs.append(move.x)
	stacked_obs.append(move.y)
	
	if boat.time_since_last_fire_left > boat.fire_cool_down:
		stacked_obs.append(1)
	else:
		stacked_obs.append((boat.time_since_last_fire_left / boat.fire_cool_down)-1)
	
	if boat.time_since_last_fire_right > boat.fire_cool_down:
		stacked_obs.append(1)
	else:
		stacked_obs.append((boat.time_since_last_fire_right / boat.fire_cool_down)-1)
	
	stacked_obs.append(boat.life / boat.original_life)
	stacked_obs.append(cumulative_rotation /( PI * 12))
	
	var relative_wind_angle = angle_difference(boat.global_rotation, boat.wind_angle) / PI
	stacked_obs.append(relative_wind_angle)
	
	# je génère 5 cases de libre à la fin... Pour des trucs bonus ?
	for i in range(5) : 
		stacked_obs.append(0)

	return {"obs": stacked_obs}

func get_reward() -> float:
	return reward


func get_action_space() -> Dictionary:
	var dict = {
		"shoot_left": {"size": 2, "action_type": "discrete"},
		"shoot_right": {"size": 2, "action_type": "discrete"},
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
	
	boat.want_to_shoot_r = action["shoot_right"]
	if boat.want_to_shoot_r :
		var truc :bool= false
		for i in [5,6,7] :
			var real_index = i * 9
			truc = truc or c_frame_obs[real_index+2]
		boat.want_to_shoot_r = truc and boat.want_to_shoot_r
	
	boat.want_to_shoot_l = action["shoot_left"]
	if boat.want_to_shoot_l :
		var truc :bool= false
		for i in [1,2,3] :
			var real_index = i * 9
			truc = truc or c_frame_obs[real_index+2]
		boat.want_to_shoot_l = truc and boat.want_to_shoot_l
var cumulative_rotation = 0

func _physics_process(delta):
	if (not reset_with_time) :
		n_steps = -1
	super._physics_process(delta)
	if (needs_reset) : 
		reset()
	if (ControlModes.HUMAN == control_mode):
			get_obs()
			move.y = Input.get_action_strength("right") - Input.get_action_strength("left")
			move.x = Input.get_action_strength("up") - Input.get_action_strength("down")
			boat.want_to_shoot_l = Input.get_action_strength("attack")
			boat.want_to_shoot_r = boat.want_to_shoot_l
			boat.throttle = move.x
			boat.steering = move.y	
		
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
	
	reward += speed *0.01 * delta
	cumulated_rewar += speed * 0.01 * delta
	
	reward -= delta * 2
	cumulated_rewar -= delta * 2
	if speed < 20 and move.x == 0 and move.y == 0 and not boat.want_to_shoot_r and not boat.want_to_shoot_l:
		reward-= delta * 60
		cumulated_rewar -= delta * 60
	
	
	
	# On ajoute la rotation effectuée à cette frame
	cumulative_rotation += boat.angular_velocity * delta
	if abs(cumulative_rotation) > PI * 4: # Plus de 2 tours complets
		reward -= 0.5 * abs(cumulative_rotation) * delta
		cumulated_rewar -= 0.5 * abs(cumulative_rotation) * delta
		cumulative_rotation *= 0.99
	super._physics_process(delta)
	
func reset():
	super.reset()
	obs_history.clear()
	cumulated_rewar = 0
	boat.reset()
	cumulative_rotation = 0
	
func _ready():
	super._ready()
	
	boat.on_dealt_damages.connect(on_dealt_damages)
	boat.dont_die_on_life_equal_0 = true
	
	reset_after = 60 * 60 * 4


func OnSetControlMode(newvalue) :
	boat.dont_die_on_life_equal_0 = newvalue == ControlModes.TRAINING
	boat.dont_die_on_life_equal_0 = true

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
			reward -= delta_r * 8
			cumulated_rewar -=delta_r * 8
	
	if ( targeted_boat.life <= 0) :
		other_controller.needs_reset = true
		other_controller.done = true

func update(delta:float):
	pass
	
	
	
