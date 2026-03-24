extends AIController2D
class_name AIControllerBoat

@onready var character: Boat = $".."

var boat : Boat = null
var delta_dist = 0
var delta_angle = 0
var self_speed = 0
var target_rotation = 0
var target_speed = 0

#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	# relatif a l'adversaire
	var delta_position = boat.target.position - boat.position
	delta_dist = delta_position.length()
	delta_angle = Vector2.RIGHT.rotated(boat.rotation).angle_to(delta_position)
	self_speed = boat.velocity.length()
	target_rotation = boat.target.rotation - boat.rotation
	target_speed = boat.target.velocity.length()
	var obs := [
		#delta_dist,
		#delta_angle,
		self_speed,
		#target_rotation,
		#target_speed,
		boat.position.length(),
		#Vector2.RIGHT.rotated(boat.rotation).angle_to_point(Vector2.ZERO),
		boat.rotation,
		boat.position.x,
		boat.position.y
		]
	return {"obs" : obs}

func get_reward() -> float:
	reward -= 0.001 * boat.position.length()*boat.position.length()
	#reward += self_speed * 0.03
	#reward += 1000/delta_dist
	#if((PI*0.85 < abs(delta_angle) and abs(delta_angle) < PI*1.15) and 30<delta_dist and delta_dist<100 ):
		#reward += 1000
		#boat.target.controller.add_reward(-100)
	return reward


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
	pass
	
func add_reward(reward_mod):
	reward += reward_mod
