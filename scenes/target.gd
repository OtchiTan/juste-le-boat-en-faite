extends Area2D

@onready var aera: CollisionShape2D = $"../World/Aera"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reset_pos()

func reset_pos() :
	if (aera) :
		var rect: Rect2 = aera.shape.get_rect()
		# Calculate random X and Y within the shape's rectangle
		var x = randf_range(rect.position.x + 150, rect.end.x - 150)
		var y = randf_range(rect.position.y + 150, rect.end.y - 150 )
		# Convert local area point to global position
		position.x = x
		position.y = y

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
