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
var reset_with_time:bool = false
var inference_cheat:bool = true

var target_point:Vector2 # global coordonates.
var b_goto_target:float = 0 # -1 : ???? /// 0 : s'en fout /// 1 VAS Y IMMEDIATEMENT

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
	#boat.label.text = " "  + str(cumulated_rewar)

	if min_w_dist < 0.045 :
		var inv_min = (1- min_w_dist)
		var delta_r = inv_min * inv_min * 5
		add_reward(- delta_r )
	
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
	
	stacked_obs.append(boat.life / (boat.original_life as float))
	
	stacked_obs.append(cumulative_rotation /( PI * 12))
	
	var relative_wind_angle = angle_difference(boat.global_rotation, boat.wind_angle) / PI
	stacked_obs.append(relative_wind_angle)
	stacked_obs.append(boat.wind_strenght / 5.0 -0.2)
	
	var relative_target_point = target_point - boat.global_position
	var relative_target_angle = boat.get_angle_to(target_point) / PI
	
	stacked_obs.append(relative_target_angle)
	stacked_obs.append(sqrt(relative_target_point.length()) / 100.0)
	stacked_obs.append(b_goto_target)
	
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

	move.x = newx
	move.y = newy
	boat.throttle = move.x * 1.2
	boat.steering = move.y * 2
	
	boat.want_to_shoot_r = action["shoot_right"]
	boat.want_to_shoot_l = action["shoot_left"]
	
	if control_mode == ControlModes.ONNX_INFERENCE and inference_cheat:
		# empêche de trop tirer dans le vide quand on le montre.
		if boat.want_to_shoot_r :
			var truc :bool= false
			for i in [5,6,7] :
				var real_index = i * 9
				truc = truc or c_frame_obs[real_index+2]
			boat.want_to_shoot_r = truc and boat.want_to_shoot_r
		if boat.want_to_shoot_l :
			var truc :bool= false
			for i in [1,2,3] :
				var real_index = i * 9
				truc = truc or c_frame_obs[real_index+2]
			boat.want_to_shoot_l = truc and boat.want_to_shoot_l
var cumulative_rotation = 0

func update(_delta) :
	pass

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
	var rw_scale = 1
	if b_goto_target >0:
		var relative_target_point = target_point - boat.global_position
		var dist = relative_target_point.length()
		var target_radius = 150.0 # La taille de la zone d'arrivée
		
		if dist <= target_radius:
			add_reward(1.0 * b_goto_target * rw_scale) 
		elif dist <= 2 * target_radius : 
			add_reward(0.5 * b_goto_target * rw_scale)
		else :
			# Voyage voyage !! 
			var dir_to_target = relative_target_point.normalized()
			var speed_towards_target = boat.linear_velocity.dot(dir_to_target)
			if speed_towards_target < 0 :
				rw_scale *=2
			add_reward(speed_towards_target * 0.001 * b_goto_target * rw_scale, true)
	
	var speed = boat.linear_velocity.length()
	
	# SPEED & TIME reward
	add_reward(speed *0.01 * delta)
	#add_reward( - delta * 2)
	if speed < 20 and move.x == 0 and move.y == 0 and not boat.want_to_shoot_r and not boat.want_to_shoot_l:
		add_reward(- delta * 60)
	
	# On ajoute la rotation effectuée à cette frame
	cumulative_rotation += boat.angular_velocity * delta
	add_reward(-0.05 * abs(cumulative_rotation) * delta)

func reset():
	super.reset()
	obs_history.clear()
	cumulated_rewar = 0
	boat.reset()
	cumulative_rotation = 0
	
func _ready():
	super._ready()
	GameManager.count_ai_controller()
	
	boat.on_dealt_damages.connect(on_dealt_damages)
	
	reset_after = 60 * 60 * 4
	var sync = get_tree().get_first_node_in_group("sync_node")
	
	if sync :
		if sync.sync_is_ready :
			_on_sync_ready(sync)
		else  :
			sync.sync_ready.connect(_on_sync_ready)
			
func _on_sync_ready(_sync) :
	if  control_mode == ControlModes.TRAINING :
		boat.dont_die_on_life_equal_0 = true
		FactionManager.firendly_fire_on = false
		reset_with_time = true
	
func set_heuristic(h) :
	super.set_heuristic(h)
	
func OnSetControlMode(_newvalue) :
	pass

func on_dealt_damages(dmg_amount: float, targeted_boat: Boat) :
	var delta_r = dmg_amount
	delta_r += 100 if targeted_boat.life <= 0 else 0
	
	var oth_ctrl_ray2D := targeted_boat.controller as AIControllerWithRaycast
	match FactionManager.get_relation(boat, targeted_boat) :
		FactionManager.Relation.ENEMY :
			add_reward(delta_r * 10)
			if oth_ctrl_ray2D :
				oth_ctrl_ray2D.add_reward(-delta_r)
		FactionManager.Relation.ALLY :
			add_reward(- 10)
	
	if ( targeted_boat.life <= 0) :
		if (oth_ctrl_ray2D) : 
			oth_ctrl_ray2D.needs_reset = true
			oth_ctrl_ray2D.done = true
		elif control_mode == ControlModes.TRAINING : 
			targeted_boat.reset()
	
var isolateOneReward = false
var reward_scale := 1.0
func add_reward(delta, isolate:bool = false) : 
	delta *= reward_scale
	if (not isolateOneReward) || isolate : 
		reward += delta
		cumulated_rewar += delta
