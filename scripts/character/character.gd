extends CharacterBody2D


const SPEED = 300.0

@onready var ai_controller_2d: Node2D = $AIController2D

func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = ai_controller_2d.move.x
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	direction = ai_controller_2d.move.y
	if direction : 
		velocity.y = direction * SPEED
	else :
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	move_and_slide()
	ai_controller_2d.reward += (position.x + position.y) / 1000 
	

func _on_world_body_exited(body: Node2D) -> void:
	position = Vector2(0,0)
	ai_controller_2d.reward -= 10000
	ai_controller_2d.reset()
	pass # Replace with function body.
