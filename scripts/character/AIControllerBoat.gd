extends AIController2D
class_name AIControllerBoat

@onready var character: Boat = $".."

var text_info : String = ""
var step_reward : float = 0.0

var previous_distance : float = 0.0
var previous_steering : int = 0

var nb_touch : int = 0

func _enter_tree():
	if character:
		previous_distance = (character.position - character.target.position).length()
		previous_steering = 0

#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	var forward_vector = character.global_transform.x
	var relative_target_position = character.target.position - character.position
	
	# self
	var normalized_rot_speed = character.angular_velocity / 1.5 # Entre -1 et 1
	var normalized_speed = character.linear_velocity.length() / 250 # Entre 0 et 1
	var normalized_speed_angle = forward_vector.angle_to(character.linear_velocity) / PI
	
	# other
	var relative_target_angle = forward_vector.angle_to(relative_target_position) / PI
	var relative_target_dist = relative_target_position.length() / 3000 # Environ entre 0 et 1
	var target_speed = character.target.linear_velocity.length() / 250
	var relative_target_rotation = character.rotation - character.target.rotation
	var norm_relative_target_rotation = (fmod(relative_target_rotation+3*PI,2*PI)-PI)/PI
	
	text_info = "normalized_rot_speed : " + str(normalized_rot_speed) + "\n"
	text_info += "normalized_speed : " + str(normalized_speed) + "\n"
	text_info += "normalized_speed_angle : " + str(normalized_speed_angle) + "\n"
	text_info += "relative_target_angle : " + str(relative_target_angle) + "\n"
	text_info += "relative_target_dist : " + str(relative_target_dist) + "\n"
	text_info += "target_speed : " + str(target_speed) + "\n"
	text_info += "norm_relative_target_rotation : " + str(norm_relative_target_rotation) + "\n"
	
	var obs := [
		normalized_rot_speed,
		normalized_speed,
		normalized_speed_angle,
		relative_target_angle,
		relative_target_dist,
		target_speed,
		norm_relative_target_rotation
		]
	return {"obs" : obs}


func get_reward() -> float:
	var current_reward = step_reward
	step_reward = 0.0 
	return current_reward


func get_action_space() -> Dictionary:
	var dict = {
		"forward": {"size": 3, "action_type": "discrete"},
		"rotation": { "size": 3,  "action_type": "discrete" },
	}
	return dict
	
func set_action(action) -> void:
	character.throttle = action["forward"] - 1
	character.steering = action["rotation"] - 1
	

func update(delta):
	
	#if(character.player_id == 1):
		#character.steering = Input.get_action_strength("right") - Input.get_action_strength("left")
		#character.throttle = Input.get_action_strength("up") - Input.get_action_strength("down")
	
	if needs_reset and done:
		reset()
		return
		
	if done:
		return
	
	### CALCULE DES RECOMPENSE
	
	step_reward -= 0.025

	var current_distance = (character.position - character.target.position).length()
	step_reward += (previous_distance - current_distance) *  0.1
	
	if (character.throttle == 0 and character.linear_velocity.length() < 5):
		step_reward -= 10

	if (previous_steering != character.steering):
		step_reward -= 0.1
	
	var forward_vector = character.global_transform.x
	var relative_target_position = character.target.position - character.position
	var relative_target_angle = forward_vector.angle_to(relative_target_position) / PI
	var relative_target_dist = relative_target_position.length()
	if(relative_target_dist<150 and relative_target_dist>50 and abs(relative_target_angle) < 0.66 and abs(relative_target_angle) > 0.33):
		step_reward += 1
		character.target.controller.step_reward -= 0.3
		nb_touch += 1
		
		if(nb_touch>200):
			print("----- 200 point Done : reset !")
			
			step_reward += 1000.0 
			done = true
			needs_reset = true
			
			character.target.controller.step_reward -= 200
			character.target.controller.done = true
			character.target.controller.needs_reset = true
	
	if relative_target_dist > 5000 :
		print("Too Far")
		step_reward -= 2000
		done = true
		needs_reset = true
		
		character.target.controller.step_reward -= 2000
		character.target.controller.done = true
		character.target.controller.needs_reset = true
	
	previous_distance = current_distance
	previous_steering = character.steering
	
	
	## DEBUG INFO GIVE TO AI
	#var forward_vector = character.global_transform.x
	#var relative_target_position = character.target.position - character.position
	## self
	#var normalized_rot_speed = character.angular_velocity / 1.5 # Entre -1 et 1
	#var normalized_speed = character.linear_velocity.length() / 250 # Entre 0 et 1
	#var normalized_speed_angle = forward_vector.angle_to(character.linear_velocity) / PI
	## other
	#var relative_target_angle = forward_vector.angle_to(relative_target_position) / PI
	#var relative_target_dist = relative_target_position.length() / 3000 # Environ entre 0 et 1
	#var target_speed = character.target.linear_velocity.length() / 250
	#var relative_target_rotation = character.rotation - character.target.rotation
	#text_info = "normalized_rot_speed : " + str(normalized_rot_speed) + "\n"
	#text_info += "normalized_speed : " + str(normalized_speed) + "\n"
	#text_info += "normalized_speed_angle : " + str(normalized_speed_angle) + "\n"
	#text_info += "relative_target_angle : " + str(relative_target_angle) + "\n"
	#text_info += "relative_target_dist : " + str(relative_target_dist) + "\n"
	#text_info += "target_speed : " + str(target_speed) + "\n"
	#text_info += "relative_target_rotation : " + str(fmod(relative_target_rotation+3*PI,2*PI)-PI) + "\n"

	
func reset():
	needs_reset = false
	done = false
	step_reward = 0.0
	nb_touch = 0
	
	character.tpRandomNextFrame = true
	character.linear_velocity = Vector2.ZERO
	character.angular_velocity = 0.0
	
	previous_distance = (character.targ - character.position).length()
	previous_steering = 0
