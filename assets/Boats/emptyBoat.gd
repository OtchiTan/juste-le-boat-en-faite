extends CharacterBody2D

class_name emptyBoat
var speed :float = 300.0
var life = 20
var atk = 5


	
func get_damage(damage: float) -> void :
	life-= damage
	print(life)
	if life <= 0:
		queue_free()
	
func claim_Island() -> void :
	pass
