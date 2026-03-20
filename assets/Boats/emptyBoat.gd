extends CharacterBody2D

class_name emptyBoat
var speed :float = 300.0
var life = 20
var atk = 5

var player_id : int = 2

func _ready():
	GameManager.register_boat(self)
	
func get_damage(damage: float, tireur) -> void :
	life-= damage
	print(life)
	if life <= 0:
		GameManager.on_boat_destroyed(self, tireur)
		queue_free()
	
func claim_Island() -> void :
	pass
