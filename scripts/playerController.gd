extends Node
class_name PlayerController

var boat : Boat

func update(_delta):
	if boat == null:
		return

	boat.steering = 2 * (Input.get_action_strength("right") - Input.get_action_strength("left"))
	boat.throttle = 1.2 * (Input.get_action_strength("up") - Input.get_action_strength("down"))

	if Input.is_action_just_pressed("attack"):
		boat.want_to_shoot_l = true
		boat.want_to_shoot_r = true
