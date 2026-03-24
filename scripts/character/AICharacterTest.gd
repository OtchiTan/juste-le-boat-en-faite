extends CharacterBody2D


const SPEED = 300.0
var CanCollect = false
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
	ai_controller_2d.reward -= 0.1 * delta
	if ($"../Label") : 
		$"../Label".text = "reward" + str(ai_controller_2d.reward)
	
	
	

func _on_world_body_exited(body: Node2D) -> void:
	position = Vector2(0,0)
	ai_controller_2d.reward -= 100
	ai_controller_2d.reset()
	pass # Replace with function body.


func _on_target_body_entered(body: Node2D) -> void:
	CanCollect = true
	pass # Replace with function body.


func _on_target_body_exited(body: Node2D) -> void:
	CanCollect = false
	pass # Replace with function body.
