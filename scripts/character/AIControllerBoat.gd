extends AIController2D
class_name AIControllerBoat

@onready var character: Boat = $".."

#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	var obs := [
		character.position.x,
		character.position.y
	]
	return {"obs" : obs}

func get_reward() -> float:
	return reward


func get_action_space() -> Dictionary:
	return {
		"move": {
			"size": 2, 
			"action_type": "continuous"
			}
	}
	
func set_action(action) -> void:
	move.x = action["move"][0]
	move.y = action["move"][1]
	
	character.throttle = 0
	character.steering = 0
