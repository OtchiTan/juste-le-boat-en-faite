extends AIController2D
class_name AIControllerBoatSolo

@onready var character: Boat = $".."

var text_info : String = ""
var step_reward : float = 0.0
var previous_distance : float = 0.0
var previous_steering : int = 0

func _enter_tree():
	if character:
		previous_distance = (character.targ - character.position).length()
		

#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	
	var forward_vector = Vector2.RIGHT.rotated(character.rotation)
	var relative_target_position = character.targ - character.position
	
	var relative_target_angle = forward_vector.angle_to(relative_target_position) / PI
	var relative_target_dist = relative_target_position.length() / 5000 # Environ entre 0 et 1
	var normalized_speed = character.linear_velocity.length() / 250 # Entre 0 et 1
	var normalized_rot_speed = character.angular_velocity / 1.5 # Entre -1 et 1

	var obs := [
		relative_target_angle,
		relative_target_dist,
		normalized_speed,
		normalized_rot_speed
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
	
	#character.steering = Input.get_action_strength("right") - Input.get_action_strength("left")
	#character.throttle = Input.get_action_strength("up") - Input.get_action_strength("down")

func update(delta):
		
	if needs_reset and done:
		reset()
		return
		
	if done:
		return
		
	var current_distance = (character.targ - character.position).length()
	
	var progress = previous_distance - current_distance
	step_reward += progress * 0.01
	step_reward -= 0.025
	step_reward += character.throttle * 0.01
	
	if (character.throttle == 0 and character.linear_velocity.length() < 5):
		step_reward -= 10

	if (previous_steering != character.steering):
		step_reward -= 0.05
	
	previous_distance = current_distance
	previous_steering = character.steering
	
	# win
	if current_distance < 150:
		print("----- good")
		step_reward += 1000.0 
		done = true
		needs_reset = true
	
	# loose
	if current_distance >2500:
		print("bad  -----")
		step_reward -= 200.0
		done = true
		needs_reset = true
	
	# DEBUG
	text_info = "reward : " + str(step_reward) + "\n"
	text_info += "targ coord : " + str(character.targ.x) + "|" + str(character.targ.y) + "\n"
	text_info += "dist : " + str(current_distance) + "\n"
	text_info += "throttle : " + str(character.throttle) + "\n"
	text_info += "steering : " + str(previous_steering)

func reset():
	needs_reset = false
	done = false
	step_reward = 0.0
	character.tpRandomNextFrame = true
	character.linear_velocity = Vector2.ZERO
	character.angular_velocity = 0.0
	
	character.targ.x = randi_range(-500, 500)
	character.targ.y = randi_range(-500, 500)
	
	previous_distance = (character.targ - character.position).length()



func add_reward(reward_mod):
	reward += reward_mod
