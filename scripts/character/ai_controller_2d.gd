extends AIController2D


var move = Vector2.ZERO

@onready var character: CharacterBody2D = $".."
@onready var target: Area2D = $"../../Target"
var lastDist = -1

var eatratio
#-- Methods that need implementing using the "extend script" option in Godot --#
func get_obs() -> Dictionary:
	var n_pos = character.position.normalized()
	var d_pos = (target.position - character.position).normalized()
	var obs := [
		n_pos.x,
		n_pos.y,
		d_pos.x,
		d_pos.y
	]
	return {"obs" : obs}

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
	
	move.x = action["move_left_right"] - 1
	move.y = action["move_up_down"] - 1
	
	var want_to_eat = action["eat"]
	if want_to_eat > 0:
		_attempt_to_eat() 
	elif character.CanCollect :
		#print("do not eat ????")
		reward -= 1
func _attempt_to_eat():
	if character.CanCollect :
		print("eat good")
		reward += 100
		target.reset_pos()
		lastDist = (target.position - character.position).length_squared()
	else:
		# Petite pénalité si elle essaie de manger dans le vide (évite le spam)
		reward -= 1
		print("eat bad")
		
func _physics_process(delta):
	var dist = (target.position - character.position).length_squared()
	var delta_dist = lastDist - dist
	if lastDist != -1 : 
		reward += delta_dist / 1000
	lastDist = dist
	super._physics_process(delta)
	
func reset():
	super.reset()
	lastDist = (target.position - character.position).length_squared()
	
