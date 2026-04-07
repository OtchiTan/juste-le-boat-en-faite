extends AnimatedSprite2D

func _ready():
	visible = false
	# Cache le sprite quand l'animation est finie
	animation_finished.connect(func(): visible = false)

func fire():
	visible = true
	play("fire")
