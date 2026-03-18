extends CharacterBody2D


@export var speed :float = 300.0


func _physics_process(delta: float) -> void:
	
	var Input_Direction = Vector2(
		Input.get_action_strength("right")-Input.get_action_strength("left"),
		Input.get_action_strength("down")-Input.get_action_strength("up")
	)
	
	velocity= Input_Direction * speed;

	move_and_slide()
