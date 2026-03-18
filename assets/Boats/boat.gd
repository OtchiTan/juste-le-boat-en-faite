extends CharacterBody2D

class_name Boat
var speed :float = 300.0
var life = 20
var atk :int = 5
@export var projectile_scene: PackedScene
		
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		print("attack")
		attack()
		
	var Input_Direction = Vector2(
		Input.get_action_strength("right")-Input.get_action_strength("left"),
		Input.get_action_strength("down")-Input.get_action_strength("up")
	)
	velocity= Input_Direction * speed;

	move_and_slide()


func attack() -> void :
	var projectile = projectile_scene.instantiate()

	var direction = Vector2.RIGHT.rotated(rotation)
	projectile.position = position + direction * 50
	
	projectile.direction = direction
	projectile.degats = atk
	projectile.tireur = self  
	# ajouter à la scène
	get_parent().add_child(projectile)
	
func get_damage(damage: float) -> void :
	life-= damage
	print(life)
	if life <= 0:
		queue_free()
	
func claim_Island() -> void :
	pass
